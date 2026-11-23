package com.namazalert.namaz_alert

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "namaz_alert/audio"
        ).setMethodCallHandler { call, result ->
            if (call.method == "setAdhanVolume") {
                val percent = (call.argument<Int>("percent") ?: 100)
                    .coerceIn(0, 100)
                val audioManager =
                    getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                val volume = (maxVolume * percent / 100.0).roundToInt()
                    .coerceIn(0, maxVolume)

                audioManager.setStreamVolume(
                    AudioManager.STREAM_ALARM,
                    volume,
                    0
                )
                result.success(volume)
            } else {
                result.notImplemented()
            }
        }
    }
}
