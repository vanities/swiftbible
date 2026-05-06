package biz.am2.swiftbible.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

enum class ReadingTheme(val display: String) {
    LIGHT("Light"),
    DARK("Dark"),
    SEPIA("Sepia"),
    SYSTEM("System default");

    companion object {
        fun fromName(s: String) = entries.firstOrNull { it.name == s } ?: SYSTEM
    }
}

private val LightColors = lightColorScheme(
    primary = BrandAccent,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFCFEEEA),
    onPrimaryContainer = Color(0xFF003B36),
    secondary = BrandGold,
    onSecondary = BrandDeepNavy,
    secondaryContainer = Color(0xFFFFEDBA),
    onSecondaryContainer = Color(0xFF4A3A12),
    tertiary = BrandGreen,
    error = BrandRed,
    background = Color(0xFFFFFBF7),
    onBackground = Color(0xFF1B1A18),
    surface = Color(0xFFFFFBF7),
    onSurface = Color(0xFF1B1A18),
    surfaceVariant = Color(0xFFEDE8E0),
    onSurfaceVariant = Color(0xFF4D4B47),
    outline = Color(0xFF7E7B73),
    outlineVariant = Color(0xFFD0CDC5),
    surfaceContainer = Color(0xFFF6F1E9),
    surfaceContainerHigh = Color(0xFFEFEAE0),
    surfaceContainerHighest = Color(0xFFE8E2D6),
    inversePrimary = BrandAccentLight,
    inverseSurface = Color(0xFF2D2C29),
    inverseOnSurface = Color(0xFFF5F0E6),
)

private val DarkColors = darkColorScheme(
    primary = BrandAccentLight,
    onPrimary = Color(0xFF003B36),
    primaryContainer = Color(0xFF005D55),
    onPrimaryContainer = Color(0xFFCFEEEA),
    secondary = BrandGoldLight,
    onSecondary = BrandDeepNavy,
    secondaryContainer = Color(0xFF6B4F22),
    onSecondaryContainer = Color(0xFFFFEDBA),
    tertiary = Color(0xFF6FE39F),
    error = Color(0xFFFF6B6B),
    background = BrandDeepNavy,
    onBackground = Color(0xFFE8E6E0),
    surface = Color(0xFF131A35),
    onSurface = Color(0xFFE8E6E0),
    surfaceVariant = Color(0xFF1E2747),
    onSurfaceVariant = Color(0xFFC2C7DD),
    outline = Color(0xFF8C92AB),
    outlineVariant = Color(0xFF3E455F),
    surfaceContainer = Color(0xFF161D38),
    surfaceContainerHigh = Color(0xFF1B2240),
    surfaceContainerHighest = Color(0xFF222B4D),
)

private val SepiaColors = lightColorScheme(
    primary = Color(0xFF8C5A1C),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFAE2BF),
    onPrimaryContainer = Color(0xFF3A2407),
    secondary = BrandGold,
    onSecondary = Color.White,
    tertiary = BrandAccent,
    error = BrandRedDark,
    background = Color(0xFFFBF1DD),
    onBackground = Color(0xFF3A2A14),
    surface = Color(0xFFFBF1DD),
    onSurface = Color(0xFF3A2A14),
    surfaceVariant = Color(0xFFEFDDB7),
    onSurfaceVariant = Color(0xFF5A4626),
    outline = Color(0xFF8E7144),
    outlineVariant = Color(0xFFD9C7A4),
    surfaceContainer = Color(0xFFF4E6CB),
    surfaceContainerHigh = Color(0xFFEEDBB7),
    surfaceContainerHighest = Color(0xFFE7CFA1),
)

val LocalReadingTheme = staticCompositionLocalOf { ReadingTheme.SYSTEM }

/** Parses `#RRGGBB` or `RRGGBB`. Returns null on empty/bad input. */
private fun parseHexColor(hex: String): Color? {
    val trimmed = hex.trim().removePrefix("#")
    if (trimmed.length != 6) return null
    return runCatching { Color(android.graphics.Color.parseColor("#$trimmed")) }.getOrNull()
}

@Composable
fun SwiftBibleTheme(
    theme: ReadingTheme = ReadingTheme.SYSTEM,
    customAccentHex: String = "",
    content: @Composable () -> Unit,
) {
    val systemDark = isSystemInDarkTheme()
    val baseColors = when (theme) {
        ReadingTheme.LIGHT -> LightColors
        ReadingTheme.DARK -> DarkColors
        ReadingTheme.SEPIA -> SepiaColors
        ReadingTheme.SYSTEM -> if (systemDark) DarkColors else LightColors
    }
    val accent = parseHexColor(customAccentHex)
    val colors = if (accent != null) {
        baseColors.copy(
            primary = accent,
            inversePrimary = accent.copy(alpha = 0.85f),
        )
    } else baseColors
    val view = LocalView.current
    val isDark = theme == ReadingTheme.DARK || (theme == ReadingTheme.SYSTEM && systemDark)
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            val controller = WindowCompat.getInsetsController(window, view)
            controller.isAppearanceLightStatusBars = !isDark
            controller.isAppearanceLightNavigationBars = !isDark
        }
    }
    MaterialTheme(colorScheme = colors, typography = SwiftBibleTypography, content = content)
}
