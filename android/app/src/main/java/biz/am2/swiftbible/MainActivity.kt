package biz.am2.swiftbible

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.viewmodel.compose.viewModel
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.SwiftBibleApp
import biz.am2.swiftbible.ui.theme.SwiftBibleTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val appVm: AppViewModel = viewModel(factory = AppViewModel.Factory)
            val prefs by appVm.prefsState.collectAsState()
            SwiftBibleTheme(theme = prefs.theme) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    SwiftBibleApp(appVm = appVm)
                }
            }
        }
    }
}
