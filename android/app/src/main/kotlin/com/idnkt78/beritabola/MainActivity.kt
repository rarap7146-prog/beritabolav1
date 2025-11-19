package com.idnkt78.beritabola

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.idnkt78.beritabola/foreground_service"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val matchId = call.argument<Int>("matchId")
                    if (matchId != null) {
                        val intent = Intent(this, LiveMatchForegroundService::class.java).apply {
                            action = LiveMatchForegroundService.ACTION_START
                            putExtra(LiveMatchForegroundService.EXTRA_MATCH_ID, matchId)
                        }
                        startService(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Match ID is required", null)
                    }
                }
                "stopService" -> {
                    val intent = Intent(this, LiveMatchForegroundService::class.java).apply {
                        action = LiveMatchForegroundService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
