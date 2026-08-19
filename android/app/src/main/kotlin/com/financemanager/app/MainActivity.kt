package com.financemanager.app

import com.google_mlkit_text_recognition.GoogleMlKitTextRecognitionPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        try {
            flutterEngine.plugins.add(GoogleMlKitTextRecognitionPlugin())
        } catch (_: Exception) {
            // Ignore duplicate registration if the generated registrant already added it.
        }
    }
}
