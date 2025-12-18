package com.example.hellocppswift

import android.os.Bundle
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val textView = TextView(this).apply {
            textSize = 24f
            textAlignment = TextView.TEXT_ALIGNMENT_CENTER
            setPadding(32, 32, 32, 32)
            gravity = Gravity.CENTER
        }

        val sum = com.example.hellocppswift.HelloCppSwift.addNumbers(10, 5)
        val product = com.example.hellocppswift.HelloCppSwift.multiplyNumbers(10, 5)

        textView.text = "C++ via Swift Calculations:\n\n10 + 5 = $sum\n10 × 5 = $product"

        val container = FrameLayout(this).apply {
            setPadding(0, 200, 0, 0)
            addView(textView)
        }

        setContentView(container)
    }
}
