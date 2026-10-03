package com.example.app_ekeflicks

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            PlayReadyTvPlayerView.VIEW_TYPE,
            PlayReadyTvPlayerView.Factory(),
        )
    }

    override fun onPause() {
        PlayReadyTvPlayerView.pauseAll()
        super.onPause()
    }
}
