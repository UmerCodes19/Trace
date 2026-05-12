package pk.edu.bahria.lostfound

import android.media.audiofx.Visualizer
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VISUALIZER_METHOD_CHANNEL = "pk.edu.bahria.lostfound/visualizer_control"
    private val VISUALIZER_EVENT_CHANNEL = "pk.edu.bahria.lostfound/visualizer_events"
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Create the EventStream for real-time FFT pipe
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VISUALIZER_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    // 🚨 FIX: NEVER implicitly call releaseVisualizer() here!
                    // Calling this on stream lifecycle causes it to self-destruct when Dart reconnects!
                }
            }
        )

        // 2. Control channel to START/STOP specific audio sessions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VISUALIZER_METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVisualizer" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    val success = startVisualizer(sessionId)
                    if (success) {
                        result.success(true)
                    } else {
                        result.success(false) // Soft fail, let audio keep playing!
                    }
                }
                "stopVisualizer" -> {
                    releaseVisualizer()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVisualizer(sessionId: Int): Boolean {
        releaseVisualizer()
        
        try {
            Log.i("Visualizer", ">>> Attaching to Audio Session ID: $sessionId <<<")
            visualizer = Visualizer(sessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1] 
                scalingMode = Visualizer.SCALING_MODE_AS_PLAYED
                measurementMode = Visualizer.MEASUREMENT_MODE_PEAK_RMS
                
                setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(v: Visualizer?, data: ByteArray?, samplingRate: Int) {}
                    override fun onFftDataCapture(v: Visualizer?, data: ByteArray?, samplingRate: Int) {
                        if (data != null && eventSink != null) {
                            runOnUiThread { eventSink?.success(data) }
                        }
                    }
                }, Visualizer.getMaxCaptureRate() / 2, false, true)
                enabled = true
            }
            Log.i("Visualizer", "✅ BIND SUCCESS: Visualizer enabled for Session $sessionId")
            return true
        } catch (e: Exception) {
            Log.e("Visualizer", "⛔ CRITICAL: Visualizer binding failed for session $sessionId! Details: ${e.message}")
            return false
        }
    }

    private fun releaseVisualizer() {
        visualizer?.enabled = false
        visualizer?.release()
        visualizer = null
    }

    override fun onDestroy() {
        releaseVisualizer()
        super.onDestroy()
    }
}
