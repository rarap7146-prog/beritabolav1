package com.idnkt78.beritabola

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

class LiveMatchForegroundService : Service() {
    
    private var wakeLock: PowerManager.WakeLock? = null
    private var updateJob: Job? = null
    private var matchId: Int = 0
    
    companion object {
        const val CHANNEL_ID = "live_match_tracking"
        const val NOTIFICATION_ID = 999
        const val ACTION_START = "START_TRACKING"
        const val ACTION_STOP = "STOP_TRACKING"
        const val EXTRA_MATCH_ID = "match_id"
        const val API_KEY = "91829c7254923be05777fc60f4696d98"
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        // Acquire wake lock to keep CPU running
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "BeritaBola::LiveMatchWakeLock"
        )
        wakeLock?.acquire(2 * 60 * 60 * 1000L) // 2 hours max
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                matchId = intent.getIntExtra(EXTRA_MATCH_ID, 0)
                startForeground(NOTIFICATION_ID, createNotification("Loading...", ""))
                startUpdating()
            }
            ACTION_STOP -> {
                stopSelf()
            }
        }
        return START_STICKY
    }
    
    private fun startUpdating() {
        updateJob?.cancel()
        updateJob = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                try {
                    updateMatchData()
                    delay(15000) // 15 seconds
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    
    private suspend fun updateMatchData() {
        try {
            val url = URL("https://v3.football.api-sports.io/fixtures?id=$matchId")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("x-rapidapi-key", API_KEY)
            connection.setRequestProperty("x-rapidapi-host", "v3.football.api-sports.io")
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().readText()
                val json = JSONObject(response)
                
                if (json.getInt("results") > 0) {
                    val fixture = json.getJSONArray("response").getJSONObject(0)
                    val status = fixture.getJSONObject("fixture").getJSONObject("status")
                    val teams = fixture.getJSONObject("teams")
                    val goals = fixture.getJSONObject("goals")
                    
                    val statusShort = status.getString("short")
                    val elapsed = status.optInt("elapsed", 0)
                    val homeTeam = teams.getJSONObject("home").getString("name")
                    val awayTeam = teams.getJSONObject("away").getString("name")
                    val homeGoals = goals.optInt("home", 0)
                    val awayGoals = goals.optInt("away", 0)
                    
                    // Check if match is still live
                    val isLive = listOf("1H", "2H", "HT", "ET", "P").contains(statusShort)
                    
                    if (isLive) {
                        val statusText = when (statusShort) {
                            "1H" -> "Babak 1 - $elapsed'"
                            "2H" -> "Babak 2 - $elapsed'"
                            "HT" -> "Istirahat"
                            "ET" -> "Extra Time - $elapsed'"
                            "P" -> "Adu Penalti"
                            else -> "$statusShort - $elapsed'"
                        }
                        
                        val title = "⚽ LIVE: $statusText"
                        val content = "$homeTeam $homeGoals - $awayGoals $awayTeam"
                        
                        withContext(Dispatchers.Main) {
                            val notification = createNotification(title, content)
                            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            notificationManager.notify(NOTIFICATION_ID, notification)
                        }
                    } else {
                        // Match ended, stop service
                        stopSelf()
                    }
                }
            }
            connection.disconnect()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun createNotification(title: String, content: String): Notification {
        val stopIntent = Intent(this, LiveMatchForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Create delete intent to handle notification dismiss
        val deleteIntent = Intent(this, LiveMatchForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val deletePendingIntent = PendingIntent.getService(
            this, 1, deleteIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val openIntent = packageManager.getLaunchIntentForPackage(packageName)
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(false) // Allow dismiss
            .setAutoCancel(false) // Don't auto-cancel on click
            .setContentIntent(openPendingIntent)
            .setDeleteIntent(deletePendingIntent) // Handle dismiss
            .addAction(R.mipmap.ic_launcher, "Berhenti Lacak", stopPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Live Match Updates",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Real-time updates for tracked live matches"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        updateJob?.cancel()
        wakeLock?.release()
        
        // Clear SharedPreferences to sync with Flutter
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().apply {
            remove("flutter.tracked_live_match_id")
            remove("flutter.tracked_live_match_id_data")
            apply()
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}
