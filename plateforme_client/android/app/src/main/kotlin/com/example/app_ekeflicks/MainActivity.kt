package com.example.app_ekeflicks

import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.DownloadService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

@UnstableApi
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            PlayReadyTvPlayerView.VIEW_TYPE,
            PlayReadyTvPlayerView.Factory(),
        )
        OfflineMedia3.manager(applicationContext)
        DownloadService.start(applicationContext, EkeOfflineDownloadService::class.java)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ekeflicks/offline")
            .setMethodCallHandler { call, result ->
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                when (call.method) {
                    "download" -> OfflineMedia3.enqueue(applicationContext, args, result)
                    "list" -> OfflineMedia3.list(applicationContext, result)
                    "remove" -> OfflineMedia3.remove(
                        applicationContext,
                        args["assetId"]?.toString().orEmpty(),
                        result,
                    )
                    "pause" -> {
                        OfflineMedia3.pause(applicationContext)
                        result.success(null)
                    }
                    "resume" -> {
                        OfflineMedia3.resume(applicationContext)
                        result.success(null)
                    }
                    "play" -> OfflineMedia3.play(
                        this,
                        args["assetId"]?.toString().orEmpty(),
                        result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        PlayReadyTvPlayerView.resumeAll()
    }

    override fun onPause() {
        PlayReadyTvPlayerView.pauseAll()
        super.onPause()
    }
}
