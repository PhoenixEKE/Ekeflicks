package com.example.app_ekeflicks

import android.content.Context
import android.view.View
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import java.io.File

@OptIn(UnstableApi::class)
internal class PlayReadyTvPlayerView(
    context: Context,
    creationParams: Map<String, Any?>,
) : PlatformView {
    private val playerView = PlayerView(context)
    private val player: ExoPlayer

    init {
        val manifestUrl = creationParams["manifestUrl"]?.toString().orEmpty()
        val licenseUrl = creationParams["licenseUrl"]?.toString().orEmpty()
        val entitlement = creationParams["entitlementToken"]?.toString().orEmpty()
        require(manifestUrl.startsWith("https://")) { "A signed HTTPS DASH manifest is required." }
        require(licenseUrl.startsWith("https://")) { "An HTTPS PlayReady license endpoint is required." }
        require(entitlement.isNotBlank()) { "The Axinom entitlement message is required." }

        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("EKEFLICKS-AndroidTV")
        val cacheKey = creationParams["cacheKey"]?.toString().orEmpty()
        val cacheFactory = CacheDataSource.Factory()
            .setCache(getStreamCache(context))
            .setUpstreamDataSourceFactory(DefaultDataSource.Factory(context, httpFactory))
            .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
            .setCacheKeyFactory { dataSpec ->
                // Do not persist signed query tokens in cache metadata.
                "$cacheKey:${dataSpec.uri.path.orEmpty()}:${dataSpec.position}:${dataSpec.length}"
            }
        val mediaSourceFactory = DefaultMediaSourceFactory(cacheFactory)
        player = ExoPlayer.Builder(context)
            .setMediaSourceFactory(mediaSourceFactory)
            .build()

        val drm = MediaItem.DrmConfiguration.Builder(C.PLAYREADY_UUID)
            .setLicenseUri(licenseUrl)
            .setLicenseRequestHeaders(mapOf("X-AxDRM-Message" to entitlement))
            .build()
        val mediaItem = MediaItem.Builder()
            .setUri(manifestUrl)
            .setMimeType(MimeTypes.APPLICATION_MPD)
            .setDrmConfiguration(drm)
            .build()

        playerView.useController = true
        playerView.controllerAutoShow = true
        playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        playerView.player = player
        player.setMediaItem(mediaItem)
        player.prepare()
        player.playWhenReady = true
        ACTIVE_PLAYERS.add(player)
    }

    override fun getView(): View = playerView

    override fun dispose() {
        ACTIVE_PLAYERS.remove(player)
        RESUME_AFTER_PAUSE.remove(player)
        playerView.player = null
        player.release()
    }

    companion object {
        const val VIEW_TYPE = "ekeflicks/playready-tv-player"
        private const val MAX_TEMP_CACHE_BYTES = 256L * 1024L * 1024L
        @Volatile private var streamCache: SimpleCache? = null
        private val ACTIVE_PLAYERS = Collections.newSetFromMap(
            ConcurrentHashMap<ExoPlayer, Boolean>(),
        )

        private val RESUME_AFTER_PAUSE = ConcurrentHashMap<ExoPlayer, Boolean>()

        fun pauseAll() {
            ACTIVE_PLAYERS.forEach { player ->
                if (player.playWhenReady) {
                    RESUME_AFTER_PAUSE[player] = true
                }
                player.pause()
            }
        }

        fun resumeAll() {
            ACTIVE_PLAYERS.forEach { player ->
                if (RESUME_AFTER_PAUSE.remove(player) == true) {
                    player.play()
                }
            }
        }

        @Synchronized
        private fun getStreamCache(context: Context): SimpleCache {
            streamCache?.let { return it }
            val directory = File(context.cacheDir, "eke-drm-stream-cache")
            val created = SimpleCache(
                directory,
                LeastRecentlyUsedCacheEvictor(MAX_TEMP_CACHE_BYTES),
                StandaloneDatabaseProvider(context.applicationContext),
            )
            streamCache = created
            return created
        }
    }

    class Factory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            @Suppress("UNCHECKED_CAST")
            val params = args as? Map<String, Any?> ?: emptyMap()
            return PlayReadyTvPlayerView(context, params)
        }
    }
}
