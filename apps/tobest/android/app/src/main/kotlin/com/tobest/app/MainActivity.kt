package com.tobest.app

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onResume() {
        super.onResume()
        // FLAG_SECURE يُطبَّق من Dart عبر flutter_windowmanager
    }
}
