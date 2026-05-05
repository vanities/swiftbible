package biz.am2.swiftbible.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.googlefonts.Font
import androidx.compose.ui.text.googlefonts.GoogleFont
import androidx.compose.ui.unit.sp
import biz.am2.swiftbible.R

private val provider = GoogleFont.Provider(
    providerAuthority = "com.google.android.gms.fonts",
    providerPackage = "com.google.android.gms",
    certificates = R.array.com_google_android_gms_fonts_certs,
)

private fun gFontFamily(name: String, weights: List<Int> = listOf(400, 500, 600, 700)) =
    FontFamily(
        weights.flatMap { w ->
            listOf(
                Font(googleFont = GoogleFont(name), fontProvider = provider, weight = FontWeight(w), style = FontStyle.Normal),
                Font(googleFont = GoogleFont(name), fontProvider = provider, weight = FontWeight(w), style = FontStyle.Italic),
            )
        }
    )

val Inter = gFontFamily("Inter")
val Lora = gFontFamily("Lora")
val SourceSerifPro = gFontFamily("Source Serif 4", listOf(400, 600, 700))
val Cormorant = gFontFamily("Cormorant Garamond", listOf(500, 600, 700))

enum class ReadingFont(val display: String, val family: FontFamily) {
    LORA("Lora (Serif)", Lora),
    SOURCE_SERIF("Source Serif", SourceSerifPro),
    CORMORANT("Cormorant Garamond", Cormorant),
    INTER("Inter (Sans)", Inter),
    ;
    companion object {
        fun fromName(s: String) = entries.firstOrNull { it.name == s } ?: LORA
    }
}

val SwiftBibleTypography = Typography(
    displayLarge = TextStyle(fontFamily = Cormorant, fontWeight = FontWeight.Bold, fontSize = 57.sp, lineHeight = 64.sp, letterSpacing = (-0.25).sp),
    displayMedium = TextStyle(fontFamily = Cormorant, fontWeight = FontWeight.Bold, fontSize = 45.sp, lineHeight = 52.sp),
    displaySmall = TextStyle(fontFamily = Cormorant, fontWeight = FontWeight.SemiBold, fontSize = 36.sp, lineHeight = 44.sp),
    headlineLarge = TextStyle(fontFamily = Cormorant, fontWeight = FontWeight.SemiBold, fontSize = 32.sp, lineHeight = 40.sp),
    headlineMedium = TextStyle(fontFamily = Cormorant, fontWeight = FontWeight.SemiBold, fontSize = 28.sp, lineHeight = 36.sp),
    headlineSmall = TextStyle(fontFamily = Lora, fontWeight = FontWeight.SemiBold, fontSize = 24.sp, lineHeight = 32.sp),
    titleLarge = TextStyle(fontFamily = Lora, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, lineHeight = 28.sp),
    titleMedium = TextStyle(fontFamily = Inter, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 24.sp, letterSpacing = 0.15.sp),
    titleSmall = TextStyle(fontFamily = Inter, fontWeight = FontWeight.Medium, fontSize = 14.sp, lineHeight = 20.sp, letterSpacing = 0.1.sp),
    bodyLarge = TextStyle(fontFamily = Lora, fontWeight = FontWeight.Normal, fontSize = 18.sp, lineHeight = 28.sp),
    bodyMedium = TextStyle(fontFamily = Inter, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp, letterSpacing = 0.25.sp),
    bodySmall = TextStyle(fontFamily = Inter, fontWeight = FontWeight.Normal, fontSize = 12.sp, lineHeight = 16.sp, letterSpacing = 0.4.sp),
    labelLarge = TextStyle(fontFamily = Inter, fontWeight = FontWeight.Medium, fontSize = 14.sp, lineHeight = 20.sp, letterSpacing = 0.1.sp),
    labelMedium = TextStyle(fontFamily = Inter, fontWeight = FontWeight.Medium, fontSize = 12.sp, lineHeight = 16.sp, letterSpacing = 0.5.sp),
    labelSmall = TextStyle(fontFamily = Inter, fontWeight = FontWeight.Medium, fontSize = 11.sp, lineHeight = 16.sp, letterSpacing = 0.5.sp),
)
