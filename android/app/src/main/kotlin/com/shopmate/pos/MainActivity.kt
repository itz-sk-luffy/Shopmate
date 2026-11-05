package com.shopmate.pos

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val DEVICE_CHANNEL = "com.shopmate.pos/device_info"
    private val LAUNCHER_CHANNEL = "com.shopmate.pos/launcher_icon"
    private var deviceChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val devChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
        deviceChannel = devChannel
        devChannel.setMethodCallHandler { call, result ->
            if (call.method == "isLowRamDevice") {
                val actManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                val isLowRam = actManager?.isLowRamDevice ?: false
                result.success(isLowRam)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLauncherIcon" -> {
                    val preset = call.argument<Int>("preset") ?: 1
                    try {
                        val pm = packageManager
                        val pkg = packageName
                        val aliases = listOf(
                            "com.shopmate.pos.MainActivityPreset1",
                            "com.shopmate.pos.MainActivityPreset2",
                            "com.shopmate.pos.MainActivityPreset3",
                            "com.shopmate.pos.MainActivityPreset4"
                        )

                        for (i in 1..4) {
                            val aliasName = aliases[i - 1]
                            val comp = ComponentName(pkg, aliasName)
                            val state = if (i == preset) {
                                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                            } else {
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                            }
                            pm.setComponentEnabledSetting(
                                comp,
                                state,
                                PackageManager.DONT_KILL_APP
                            )
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to change launcher icon: ${e.message}", null)
                    }
                }
                "getCurrentLauncherIcon" -> {
                    try {
                        val pm = packageManager
                        val pkg = packageName
                        val aliases = listOf(
                            "com.shopmate.pos.MainActivityPreset1",
                            "com.shopmate.pos.MainActivityPreset2",
                            "com.shopmate.pos.MainActivityPreset3",
                            "com.shopmate.pos.MainActivityPreset4"
                        )
                        var activePreset = 1
                        for (i in 1..4) {
                            val comp = ComponentName(pkg, aliases[i - 1])
                            val state = pm.getComponentEnabledSetting(comp)
                            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                                activePreset = i
                                break
                            }
                        }
                        result.success(activePreset)
                    } catch (e: Exception) {
                        result.success(1)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= TRIM_MEMORY_RUNNING_LOW || level == TRIM_MEMORY_MODERATE || level == TRIM_MEMORY_BACKGROUND) {
            deviceChannel?.invokeMethod("onMemoryPressure", mapOf("level" to level))
        }
    }

    override fun onLowMemory() {
        super.onLowMemory()
        deviceChannel?.invokeMethod("onMemoryPressure", mapOf("level" to -1))
    }
}
