package com.example.flutter_application_1
import io.flutter.embedding.android.FlutterFragmentActivity // <--- IMPORTANT IMPORT

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity :FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Allow screenshots by clearing FLAG_SECURE
        allowScreenshots()
    }
    
    override fun onResume() {
        super.onResume()
        // Ensure screenshots are always allowed, even after app resumes
        allowScreenshots()
    }
    
    private fun allowScreenshots() {
        // Clear FLAG_SECURE to allow screenshots throughout the app
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
