@file:OptIn(androidx.media3.common.util.UnstableApi::class)

package com.example.app_ekeflicks

import android.app.Activity
import android.app.Notification
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.view.ViewGroup
import android.widget.TextView
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.CacheDataSource
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionEventListener
import androidx.media3.exoplayer.drm.FrameworkMediaDrm
import androidx.media3.exoplayer.drm.HttpMediaDrmCallback
import androidx.media3.exoplayer.drm.OfflineLicenseHelper
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadHelper
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.media3.exoplayer.offline.DownloadService
import androidx.media3.exoplayer.scheduler.Scheduler
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView
import org.json.JSONObject
import java.io.File
import java.nio.charset.StandardCharsets
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Persistent Media3 cache and Axinom offline-license lifecycle for phone and Android TV. */
@UnstableApi
internal object OfflineMedia3 {
    private const val CACHE_DIRECTORY = "eke-media3-offline"
    private const val TOKEN_ALIAS = "eke-axinom-offline-entitlement-v1"
    private const val TOKEN_PREFS = "eke_axinom_offline_tokens"
    private val main = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newFixedThreadPool(3)
    @Volatile private var mediaCache: SimpleCache? = null
    @Volatile private var downloadManager: DownloadManager? = null

    @Synchronized
    fun cache(context: Context): SimpleCache {
        mediaCache?.let { return it }
        val appContext = context.applicationContext
        val created = SimpleCache(
            File(appContext.filesDir, CACHE_DIRECTORY),
            NoOpCacheEvictor(),
            StandaloneDatabaseProvider(appContext),
        )
        mediaCache = created
        return created
    }

    @Synchronized
    fun manager(context: Context): DownloadManager {
        downloadManager?.let { return it }
        val appContext = context.applicationContext
        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("EKEFLICKS-Media3")
        val upstream = DefaultDataSource.Factory(appContext, httpFactory)
        val created = DownloadManager(
            appContext,
            StandaloneDatabaseProvider(appContext),
            cache(appContext),
            upstream,
            worker,
        )
        created.maxParallelDownloads = 2
        created.minRetryCount = 3
        val downloadsPaused = appContext.getSharedPreferences(DOWNLOAD_SETTINGS, Context.MODE_PRIVATE)
            .getBoolean(DOWNLOADS_PAUSED_KEY, false)
        if (downloadsPaused) created.pauseDownloads() else created.resumeDownloads()
        downloadManager = created
        return created
    }

    fun enqueue(context: Context, args: Map<*, *>, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            val assetId = args["assetId"]?.toString().orEmpty()
            val manifestUrl = args["manifestUrl"]?.toString().orEmpty()
            val platform = args["platform"]?.toString().orEmpty()
            val drmSystem = args["drmSystem"]?.toString().orEmpty()
            val drmRequired = args["drmRequired"] == true
            val licenseUrl = args["licenseUrl"]?.toString().orEmpty()
            val entitlement = args["entitlementToken"]?.toString().orEmpty()
            require(assetId.isNotBlank()) { "Missing asset identifier." }
            require(manifestUrl.startsWith("https://")) { "A signed HTTPS manifest is required." }
            if (drmRequired) {
                require(drmSystem == "widevine" || drmSystem == "playready") {
                    "This Android device does not support the selected offline DRM."
                }
                require(licenseUrl.startsWith("https://") && entitlement.isNotBlank()) {
                    "The Axinom offline license is incomplete."
                }
            }

            val scheme = if (drmRequired) schemeFor(drmSystem) else null
            val drmConfiguration = if (scheme != null) {
                MediaItem.DrmConfiguration.Builder(scheme)
                    .setLicenseUri(licenseUrl)
                    .setLicenseRequestHeaders(mapOf("X-AxDRM-Message" to entitlement))
                    .build()
            } else {
                null
            }
            val mediaItemBuilder = MediaItem.Builder()
                .setMediaId(assetId)
                .setUri(manifestUrl)
                .setMimeType(MimeTypes.APPLICATION_MPD)
            if (drmConfiguration != null) {
                mediaItemBuilder.setDrmConfiguration(drmConfiguration)
            }
            val mediaItem = mediaItemBuilder.build()
            val appContext = context.applicationContext
            val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(
                appContext,
                DefaultHttpDataSource.Factory().setUserAgent("EKEFLICKS-Media3"),
            )
            val helper = DownloadHelper.Factory()
                .setRenderersFactory(DefaultRenderersFactory(appContext))
                .setDataSourceFactory(dataSourceFactory)
                .create(mediaItem)
            helper.prepare(object : DownloadHelper.Callback {
                override fun onPrepared(prepared: DownloadHelper) {
                    try {
                        val metadata = JSONObject()
                            .put("title", args["title"]?.toString().orEmpty())
                            .put("posterUrl", args["posterUrl"]?.toString().orEmpty())
                            .put("profileId", args["profileId"]?.toString().orEmpty())
                            .put("platform", platform)
                            .put("drmSystem", drmSystem)
                            .put("drmRequired", drmRequired)
                            .put("licenseUrl", licenseUrl)
                            .put("expiresAt", args["expiresAt"]?.toString().orEmpty())
                            .put("serverLicenseId", args["serverLicenseId"]?.toString().orEmpty())
                        val request = prepared.getDownloadRequest(
                            assetId,
                            metadata.toString().toByteArray(StandardCharsets.UTF_8),
                        )
                        var licenseFormat: Format? = null
                        if (drmRequired) {
                            outer@ for (periodIndex in 0 until prepared.periodCount) {
                                val groups = prepared.getTrackGroups(periodIndex)
                                for (groupIndex in 0 until groups.length) {
                                    val group = groups.get(groupIndex)
                                    for (formatIndex in 0 until group.length) {
                                        val format = group.getFormat(formatIndex)
                                        if (format.drmInitData != null) {
                                            licenseFormat = Format.Builder()
                                                .setDrmInitData(format.drmInitData)
                                                .build()
                                            break@outer
                                        }
                                    }
                                }
                            }
                            requireNotNull(licenseFormat) {
                                "The DASH manifest has no initialization data for offline DRM."
                            }
                        }
                        prepared.release()

                        worker.execute {
                            try {
                                val keySetId = if (drmRequired) {
                                    acquireOfflineLicense(
                                        appContext,
                                        scheme!!,
                                        licenseUrl,
                                        entitlement,
                                        licenseFormat!!,
                                    )
                                } else {
                                    null
                                }
                                if (drmRequired) {
                                    EncryptedTokenVault.save(appContext, assetId, entitlement)
                                }
                                val downloadable = if (keySetId != null) {
                                    request.copyWithKeySetId(keySetId)
                                } else {
                                    request
                                }
                                main.post {
                                    try {
                                        DownloadService.sendAddDownload(
                                            appContext,
                                            EkeOfflineDownloadService::class.java,
                                            downloadable,
                                            false,
                                        )
                                        result.success(mapOf("assetId" to assetId, "status" to "queued"))
                                    } catch (error: Exception) {
                                        EncryptedTokenVault.delete(appContext, assetId)
                                        result.error("OFFLINE_QUEUE_FAILED", "Could not queue the offline download.", null)
                                    }
                                }
                            } catch (error: Exception) {
                                main.post {
                                    result.error(
                                        "OFFLINE_LICENSE_FAILED",
                                        "Axinom could not issue a persistent license for this video.",
                                        null,
                                    )
                                }
                            }
                        }
                    } catch (error: Exception) {
                        prepared.release()
                        result.error("OFFLINE_PREPARE_FAILED", "Could not prepare this DASH download.", null)
                    }
                }

                override fun onPrepareError(prepared: DownloadHelper, error: java.io.IOException) {
                    prepared.release()
                    result.error("OFFLINE_MANIFEST_FAILED", "Could not read the signed DASH manifest.", null)
                }
            })
        } catch (error: Exception) {
            result.error("OFFLINE_DOWNLOAD_INVALID", error.message ?: "Invalid offline download request.", null)
        }
    }

    fun list(context: Context, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            val downloadManager = manager(context)
            val rows = ArrayList<Map<String, Any?>>()
            val cursor = downloadManager.downloadIndex.getDownloads(IntArray(0))
            try {
                while (cursor.moveToNext()) {
                    val download = cursor.download
                    val data = download.request.data
                    val metadata = if (data.isEmpty()) JSONObject() else JSONObject(
                        String(data, StandardCharsets.UTF_8),
                    )
                    val percent = download.percentDownloaded
                    val status = if (
                        downloadManager.downloadsPaused &&
                        download.state == Download.STATE_QUEUED
                    ) {
                        "paused"
                    } else {
                        stateName(download.state)
                    }
                    rows.add(
                        mapOf(
                            "assetId" to download.request.id,
                            "title" to metadata.optString("title", "Vidéo"),
                            "posterUrl" to metadata.optString("posterUrl", ""),
                            "profileId" to metadata.optString("profileId", ""),
                            "platform" to metadata.optString("platform", ""),
                            "status" to status,
                            "progress" to if (percent.isNaN()) 0.0 else percent.toDouble().coerceIn(0.0, 100.0),
                            "serverLicenseId" to metadata.optString("serverLicenseId", ""),
                            "expiresAt" to metadata.optString("expiresAt", ""),
                            "error" to if (download.state == Download.STATE_FAILED) "failed" else "",
                        ),
                    )
                }
            } finally {
                cursor.close()
            }
            result.success(rows)
        } catch (error: Exception) {
            result.error("OFFLINE_LIST_FAILED", "Could not read offline downloads.", null)
        }
    }

    fun remove(context: Context, assetId: String, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            require(assetId.isNotBlank()) { "Missing video identifier." }
            val current = manager(context).downloadIndex.getDownload(assetId)
            val metadata = current?.request?.data?.let {
                if (it.isEmpty()) JSONObject() else JSONObject(String(it, StandardCharsets.UTF_8))
            }
            val keySetId = current?.request?.keySetId
            val drmSystem = metadata?.optString("drmSystem").orEmpty()
            val licenseUrl = metadata?.optString("licenseUrl").orEmpty()
            val entitlement = EncryptedTokenVault.read(context, assetId)
            worker.execute {
                if (keySetId != null && drmSystem.isNotEmpty() && licenseUrl.isNotEmpty() && entitlement != null) {
                    try {
                        releaseOfflineLicense(
                            context.applicationContext,
                            schemeFor(drmSystem),
                            licenseUrl,
                            entitlement,
                            keySetId,
                        )
                    } catch (_: Exception) {
                        // Local deletion must work when the device is offline.
                    }
                }
                EncryptedTokenVault.delete(context, assetId)
                main.post {
                    try {
                        DownloadService.sendRemoveDownload(
                            context.applicationContext,
                            EkeOfflineDownloadService::class.java,
                            assetId,
                            false,
                        )
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("OFFLINE_REMOVE_FAILED", "Could not remove this offline download.", null)
                    }
                }
            }
        } catch (error: Exception) {
            result.error("OFFLINE_REMOVE_FAILED", "Could not remove this offline download.", null)
        }
    }

    fun pause(context: Context) {
        context.getSharedPreferences(DOWNLOAD_SETTINGS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(DOWNLOADS_PAUSED_KEY, true)
            .apply()
        DownloadService.sendPauseDownloads(
            context.applicationContext,
            EkeOfflineDownloadService::class.java,
            false,
        )
    }

    fun resume(context: Context) {
        context.getSharedPreferences(DOWNLOAD_SETTINGS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(DOWNLOADS_PAUSED_KEY, false)
            .apply()
        DownloadService.sendResumeDownloads(
            context.applicationContext,
            EkeOfflineDownloadService::class.java,
            false,
        )
    }

    fun play(activity: Activity, assetId: String, result: io.flutter.plugin.common.MethodChannel.Result) {
        try {
            require(assetId.isNotBlank()) { "Missing video identifier." }
            val download = manager(activity).downloadIndex.getDownload(assetId)
                ?: throw IllegalStateException("The offline file is missing.")
            require(download.state == Download.STATE_COMPLETED) {
                "The download is not complete yet."
            }
            val metadata = metadata(download.request)
            val expiresAt = metadata.optString("expiresAt")
            if (expiresAt.isNotBlank()) {
                val expiryMillis = parseExpiresAtMillis(expiresAt)
                    ?: throw IllegalArgumentException("The offline license expiry is invalid.")
                require(expiryMillis > System.currentTimeMillis()) {
                    "The offline license has expired."
                }
            }
            activity.startActivity(
                Intent(activity, OfflinePlaybackActivity::class.java)
                    .putExtra(OfflinePlaybackActivity.EXTRA_ASSET_ID, assetId),
            )
            result.success(null)
        } catch (error: Exception) {
            result.error(
                "OFFLINE_PLAY_FAILED",
                error.message ?: "This video is not available offline.",
                null,
            )
        }
    }

    internal fun downloadForPlayback(context: Context, assetId: String): Download? =
        manager(context).downloadIndex.getDownload(assetId)

    internal fun metadata(request: DownloadRequest): JSONObject =
        JSONObject(String(request.data, StandardCharsets.UTF_8))

    private fun parseExpiresAtMillis(value: String): Long? {
        val normalized = value
            .replace(Regex("\\.(\\d{3})\\d+"), ".$1")
            .replace("Z", "+0000")
            .replace(Regex("([+-]\\d{2}):(\\d{2})$"), "$1$2")
        val patterns = listOf("yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ")
        for (pattern in patterns) {
            try {
                val formatter = java.text.SimpleDateFormat(pattern, java.util.Locale.US)
                formatter.isLenient = false
                val parsed = formatter.parse(normalized)
                if (parsed != null) return parsed.time
            } catch (_: Exception) {
                // Try the next ISO-8601 precision.
            }
        }
        return null
    }

    private fun stateName(state: Int): String = when (state) {
        Download.STATE_QUEUED, Download.STATE_RESTARTING -> "queued"
        Download.STATE_DOWNLOADING -> "downloading"
        Download.STATE_COMPLETED -> "completed"
        Download.STATE_FAILED -> "failed"
        Download.STATE_STOPPED -> "paused"
        Download.STATE_REMOVING -> "removing"
        else -> "queued"
    }

    private fun schemeFor(drmSystem: String) = when (drmSystem.lowercase()) {
        "widevine" -> C.WIDEVINE_UUID
        "playready" -> C.PLAYREADY_UUID
        else -> throw IllegalArgumentException("Unsupported Android DRM system.")
    }

    private fun acquireOfflineLicense(
        context: Context,
        scheme: java.util.UUID,
        licenseUrl: String,
        entitlement: String,
        format: Format,
    ): ByteArray {
        val httpFactory = DefaultHttpDataSource.Factory().setUserAgent("EKEFLICKS-Media3")
        val callback = HttpMediaDrmCallback(licenseUrl, false, httpFactory)
        callback.setKeyRequestProperty("X-AxDRM-Message", entitlement)
        val sessionManager = DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(scheme, FrameworkMediaDrm.DEFAULT_PROVIDER)
            .build(callback)
        sessionManager.setMode(DefaultDrmSessionManager.MODE_DOWNLOAD, null)
        val helper = OfflineLicenseHelper(
            sessionManager,
            DrmSessionEventListener.EventDispatcher(),
        )
        return try {
            helper.downloadLicense(format)
        } finally {
            helper.release()
        }
    }

    private fun releaseOfflineLicense(
        context: Context,
        scheme: java.util.UUID,
        licenseUrl: String,
        entitlement: String,
        keySetId: ByteArray,
    ) {
        val httpFactory = DefaultHttpDataSource.Factory().setUserAgent("EKEFLICKS-Media3")
        val callback = HttpMediaDrmCallback(licenseUrl, false, httpFactory)
        callback.setKeyRequestProperty("X-AxDRM-Message", entitlement)
        val sessionManager = DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(scheme, FrameworkMediaDrm.DEFAULT_PROVIDER)
            .build(callback)
        val helper = OfflineLicenseHelper(
            sessionManager,
            DrmSessionEventListener.EventDispatcher(),
        )
        try {
            helper.releaseLicense(keySetId)
        } finally {
            helper.release()
        }
    }
}

private const val OFFLINE_DOWNLOAD_CHANNEL_ID = "eke_offline_downloads"
private const val OFFLINE_DOWNLOAD_NOTIFICATION_ID = 7421
private const val DOWNLOAD_SETTINGS = "eke_media3_downloads"
private const val DOWNLOADS_PAUSED_KEY = "paused"

@UnstableApi
class EkeOfflineDownloadService : DownloadService(
    OFFLINE_DOWNLOAD_NOTIFICATION_ID,
    DownloadService.DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
    OFFLINE_DOWNLOAD_CHANNEL_ID,
    R.string.offline_downloads_channel,
    R.string.offline_downloads_channel_description,
) {
    override fun getDownloadManager(): DownloadManager = OfflineMedia3.manager(this)

    override fun getScheduler(): Scheduler? = null

    override fun getForegroundNotification(
        downloads: MutableList<Download>,
        notMetRequirements: Int,
    ): Notification {
        val active = downloads.filter { it.state == Download.STATE_DOWNLOADING }
        val progressValues = active.mapNotNull { download ->
            val progress = download.percentDownloaded
            if (progress.isNaN() || progress < 0f) null else progress
        }
        val progress = if (progressValues.isEmpty()) 0 else progressValues.average().toInt()
        val message = when {
            notMetRequirements != 0 -> "En attente du réseau ou des conditions requises."
            active.isNotEmpty() -> "${active.size} téléchargement(s) en cours."
            else -> "Préparation du téléchargement hors ligne."
        }
        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, OFFLINE_DOWNLOAD_CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return notificationBuilder
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(getString(R.string.offline_downloads_channel))
            .setContentText(message)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setProgress(100, progress, progressValues.isEmpty())
            .build()
    }
}

private object EncryptedTokenVault {
    private fun secretKey(): SecretKey {
        val store = java.security.KeyStore.getInstance("AndroidKeyStore")
        store.load(null)
        val existing = store.getKey("eke-axinom-offline-entitlement-v1", null)
        if (existing is SecretKey) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                "eke-axinom-offline-entitlement-v1",
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }

    fun save(context: Context, id: String, token: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.iv + cipher.doFinal(token.toByteArray(StandardCharsets.UTF_8))
        context.getSharedPreferences("eke_axinom_offline_tokens", Context.MODE_PRIVATE)
            .edit()
            .putString(id, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .apply()
    }

    fun read(context: Context, id: String): String? {
        val stored = context.getSharedPreferences("eke_axinom_offline_tokens", Context.MODE_PRIVATE)
            .getString(id, null) ?: return null
        return try {
            val bytes = Base64.decode(stored, Base64.NO_WRAP)
            val iv = bytes.copyOfRange(0, 12)
            val ciphertext = bytes.copyOfRange(12, bytes.size)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(128, iv))
            String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8)
        } catch (_: Exception) {
            null
        }
    }

    fun delete(context: Context, id: String) {
        context.getSharedPreferences("eke_axinom_offline_tokens", Context.MODE_PRIVATE)
            .edit()
            .remove(id)
            .apply()
    }
}

/** Native Media3 surface that reads the persistent download index and DRM key set. */
@UnstableApi
class OfflinePlaybackActivity : Activity() {
    private var player: ExoPlayer? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        val assetId = intent.getStringExtra(EXTRA_ASSET_ID).orEmpty()
        try {
            val download = OfflineMedia3.downloadForPlayback(this, assetId)
                ?: throw IllegalStateException("The offline file is missing.")
            val metadata = OfflineMedia3.metadata(download.request)
            val drmSystem = metadata.optString("drmSystem")
            val drmRequired = metadata.optBoolean("drmRequired")
            val licenseUrl = metadata.optString("licenseUrl")
            val builder = MediaItem.Builder()
                .setMediaId(assetId)
                .setUri(download.request.uri)
                .setMimeType(download.request.mimeType ?: MimeTypes.APPLICATION_MPD)
                .setStreamKeys(download.request.streamKeys)
            if (drmRequired) {
                val keySetId = download.request.keySetId
                    ?: throw IllegalStateException("The persistent DRM key is missing.")
                builder.setDrmConfiguration(
                    MediaItem.DrmConfiguration.Builder(
                        if (drmSystem == "playready") C.PLAYREADY_UUID else C.WIDEVINE_UUID,
                    )
                        .setLicenseUri(licenseUrl)
                        .setKeySetId(keySetId)
                        .build(),
                )
            }
            val http = DefaultHttpDataSource.Factory().setUserAgent("EKEFLICKS-Media3")
            val cacheSource = CacheDataSource.Factory()
                .setCache(OfflineMedia3.cache(this))
                .setUpstreamDataSourceFactory(DefaultDataSource.Factory(this, http))
                .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
            val mediaSourceFactory = DefaultMediaSourceFactory(cacheSource)
            val exo = ExoPlayer.Builder(this)
                .setMediaSourceFactory(mediaSourceFactory)
                .build()
            player = exo
            val view = PlayerView(this).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                )
                useController = true
                controllerAutoShow = true
                this.player = exo
            }
            setContentView(view)
            exo.setMediaItem(builder.build())
            exo.prepare()
            exo.playWhenReady = true
        } catch (error: Exception) {
            setContentView(
                TextView(this).apply {
                    text = error.message ?: "Cette vidéo n’est pas disponible hors connexion."
                    setPadding(32, 48, 32, 48)
                },
            )
        }
    }

    override fun onStop() {
        player?.pause()
        super.onStop()
    }

    override fun onDestroy() {
        player?.release()
        player = null
        super.onDestroy()
    }

    companion object {
        const val EXTRA_ASSET_ID = "asset_id"
    }
}
