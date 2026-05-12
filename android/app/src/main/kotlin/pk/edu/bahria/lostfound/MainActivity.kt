package pk.edu.bahria.lostfound

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Pure vanilla shell. All hardware visualizer hooks deleted per strict privacy mandate.
        // Offline audio analysis is handled safely via native-mapped safe buffers instead.
    }
}
