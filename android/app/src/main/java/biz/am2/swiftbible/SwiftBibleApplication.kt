package biz.am2.swiftbible

import android.app.Application
import biz.am2.swiftbible.data.Analytics

class SwiftBibleApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Analytics.init(this)
    }
}
