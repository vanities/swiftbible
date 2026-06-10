package biz.am2.swiftbible.widget

import android.content.Context
import android.os.Build
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.material3.ColorProviders
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import biz.am2.swiftbible.MainActivity
import biz.am2.swiftbible.R
import biz.am2.swiftbible.data.DevotionalRepository
import biz.am2.swiftbible.ui.theme.DarkColors
import biz.am2.swiftbible.ui.theme.LightColors
import java.time.LocalDate

private const val TAG = "DailyDevotionalWidget"

/** Follows system light/dark using the app's brand color schemes. */
private val WidgetColors = ColorProviders(light = LightColors, dark = DarkColors)

/** What a widget instance renders — the Android mirror of iOS `DevotionalEntry`. */
data class DevotionalWidgetEntry(
    val title: String,
    val heading: String?,
    val preview: String,
)

/**
 * Home-screen "Daily Devotional" widget — mirrors the iOS widget in
 * ios/swiftbibleWidget/DailyVerseWidget.swift. Compact size matches the iOS
 * systemSmall layout, the wide size matches systemMedium. Tapping anywhere
 * opens the app the same way the devotional reminder notification does.
 */
class DailyDevotionalWidget : GlanceAppWidget() {

    companion object {
        private val COMPACT = DpSize(120.dp, 120.dp)
        private val WIDE = DpSize(250.dp, 120.dp)
    }

    override val sizeMode = SizeMode.Responsive(setOf(COMPACT, WIDE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val entry = loadEntry(context)
        provideContent {
            GlanceTheme(colors = WidgetColors) {
                DevotionalWidgetContent(entry)
            }
        }
    }

    /**
     * Loads today's devotional through the app's repository — cache first,
     * then the get-daily-devotional Edge Function on a miss. On total failure
     * falls back to the same copy the iOS widget shows.
     */
    private suspend fun loadEntry(context: Context): DevotionalWidgetEntry {
        val today = LocalDate.now()
        return when (val result = DevotionalRepository(context).fetch(today)) {
            is DevotionalRepository.Result.Success -> {
                Log.d(TAG, "[widget] loaded devotional for $today (${result.devotional.message.length} chars)")
                DevotionalWidgetEntry(
                    title = WidgetDevotionalFormatter.dateTitle(today),
                    heading = WidgetDevotionalFormatter.heading(result.devotional.message),
                    preview = WidgetDevotionalFormatter.preview(result.devotional.message),
                )
            }
            is DevotionalRepository.Result.NotFound -> {
                Log.w(TAG, "[widget] no devotional published for $today")
                fallbackEntry()
            }
            is DevotionalRepository.Result.Failure -> {
                Log.w(TAG, "[widget] devotional fetch failed for $today: ${result.message}")
                fallbackEntry()
            }
        }
    }

    private fun fallbackEntry() = DevotionalWidgetEntry(
        title = "Daily Devotional",
        heading = null,
        preview = "Open SwiftBible to load today's devotional.",
    )
}

@Composable
private fun DevotionalWidgetContent(entry: DevotionalWidgetEntry) {
    val size = LocalSize.current
    val modifier = GlanceModifier
        .fillMaxSize()
        .appWidgetBackground()
        .background(GlanceTheme.colors.widgetBackground)
        .widgetCornerRadius()
        .padding(12.dp)
        .clickable(actionStartActivity<MainActivity>())
    if (size.width >= 250.dp) {
        WideLayout(entry, modifier)
    } else {
        CompactLayout(entry, modifier)
    }
}

/** Mirror of the iOS systemSmall view: icon + label row, preview, date. */
@Composable
private fun CompactLayout(entry: DevotionalWidgetEntry, modifier: GlanceModifier) {
    Column(modifier = modifier) {
        HeaderRow(label = "Devotional")
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            text = entry.preview,
            maxLines = 6,
            style = TextStyle(fontSize = 12.sp, color = GlanceTheme.colors.onSurface),
        )
        Spacer(modifier = GlanceModifier.defaultWeight())
        Text(
            text = entry.title,
            maxLines = 1,
            style = TextStyle(fontSize = 11.sp, color = GlanceTheme.colors.onSurfaceVariant),
        )
    }
}

/** Mirror of the iOS systemMedium view: icon + date row, heading, preview. */
@Composable
private fun WideLayout(entry: DevotionalWidgetEntry, modifier: GlanceModifier) {
    Column(modifier = modifier) {
        HeaderRow(label = entry.title)
        Spacer(modifier = GlanceModifier.height(4.dp))
        if (entry.heading != null) {
            Text(
                text = entry.heading,
                maxLines = 2,
                style = TextStyle(
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = GlanceTheme.colors.onSurface,
                ),
            )
            Spacer(modifier = GlanceModifier.height(4.dp))
        }
        Text(
            text = entry.preview,
            style = TextStyle(fontSize = 12.sp, color = GlanceTheme.colors.onSurfaceVariant),
        )
    }
}

@Composable
private fun HeaderRow(label: String) {
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.Vertical.CenterVertically,
    ) {
        Image(
            provider = ImageProvider(R.drawable.ic_widget_devotional),
            contentDescription = null,
            modifier = GlanceModifier.size(14.dp),
            colorFilter = ColorFilter.tint(GlanceTheme.colors.secondary),
        )
        Spacer(modifier = GlanceModifier.width(4.dp))
        Text(
            text = label,
            maxLines = 1,
            style = TextStyle(
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = GlanceTheme.colors.onSurfaceVariant,
            ),
        )
    }
}

/** System widget corner radius on Android 12+, a close approximation below. */
private fun GlanceModifier.widgetCornerRadius(): GlanceModifier =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        cornerRadius(android.R.dimen.system_app_widget_background_radius)
    } else {
        cornerRadius(16.dp)
    }
