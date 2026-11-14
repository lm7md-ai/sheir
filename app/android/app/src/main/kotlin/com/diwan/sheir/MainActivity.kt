package com.diwan.sheir

import android.content.ComponentCallbacks2
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var audioExtractionChannel: AudioExtractionChannel? = null
    private var diskSpaceChannel: MethodChannel? = null
    private var memoryPressureChannel: MethodChannel? = null

    companion object {
        const val DISK_CHANNEL = "com.diwan.sheir/disk_space"
        const val MEMORY_CHANNEL = "com.diwan.sheir/memory_pressure"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        audioExtractionChannel = AudioExtractionChannel(context, flutterEngine.dartExecutor.binaryMessenger)

        // 1. قناة فحص السعة التخزينية الحقيقية عبر StatFs
        diskSpaceChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISK_CHANNEL)
        diskSpaceChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getAvailableDiskSpaceMb") {
                try {
                    val path = call.argument<String>("path") ?: context.filesDir.absolutePath
                    val stat = StatFs(path)
                    val availableBytes = stat.availableBlocksLong * stat.blockSizeLong
                    val availableMb = (availableBytes / (1024 * 1024)).toInt()
                    result.success(availableMb)
                } catch (e: Exception) {
                    result.error("STATFS_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 2. قناة تنبيهات ضغط الذاكرة (onTrimMemory) لتفريغ نماذج الذكاء الاصطناعي بأمان
        memoryPressureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEMORY_CHANNEL)
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) {
            memoryPressureChannel?.invokeMethod("onTrimMemory", level)
        }
    }
}
