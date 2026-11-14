package com.diwan.sheir

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var audioExtractionChannel: AudioExtractionChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioExtractionChannel = AudioExtractionChannel(context, flutterEngine.dartExecutor.binaryMessenger)
    }
}
