package biz.am2.swiftbible.ui.events

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.OpenInNew
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import biz.am2.swiftbible.data.AppEvent
import biz.am2.swiftbible.data.AppEventRegistry
import biz.am2.swiftbible.data.EventReadingDay
import biz.am2.swiftbible.ui.components.MarkdownText
import biz.am2.swiftbible.ui.theme.BrandRed
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventDetailScreen(
    event: AppEvent,
    onBack: () -> Unit,
    onOpenInBible: (book: String, chapter: Int, verse: Int) -> Unit,
) {
    val pagerState = rememberPagerState(
        initialPage = AppEventRegistry.todayReadingIndex(event),
        pageCount = { event.readingPlan.size },
    )
    val accent = event.accent.color

    LaunchedEffect(event.id) {
        biz.am2.swiftbible.data.Analytics.capture(
            biz.am2.swiftbible.data.Analytics.Event.TabSwitched,
            mapOf("event" to event.id),
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        event.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxSize().weight(1f),
            ) { idx ->
                val day = event.readingPlan[idx]
                EventDayPage(
                    day = day,
                    dayNumber = idx + 1,
                    totalDays = event.readingPlan.size,
                    accent = accent,
                    isUnlocked = isUnlocked(day),
                    onOpenInBible = { onOpenInBible(day.passage.book, day.passage.chapter, day.passage.startVerse) },
                )
            }
            PageDots(pagerState.currentPage, event.readingPlan.size, accent)
        }
    }
}

@Composable
private fun PageDots(current: Int, total: Int, accent: Color) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 14.dp),
        horizontalArrangement = Arrangement.Center,
    ) {
        repeat(total) { idx ->
            val isCurrent = idx == current
            Box(
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .size(if (isCurrent) 8.dp else 6.dp)
                    .clip(CircleShape)
                    .background(if (isCurrent) accent else accent.copy(alpha = 0.3f)),
            )
        }
    }
}

private fun isUnlocked(day: EventReadingDay, today: LocalDate = LocalDate.now()): Boolean =
    biz.am2.swiftbible.BuildConfig.DEBUG || !day.date.isAfter(today)

@Composable
private fun EventDayPage(
    day: EventReadingDay,
    dayNumber: Int,
    totalDays: Int,
    accent: Color,
    isUnlocked: Boolean,
    onOpenInBible: () -> Unit,
) {
    val dateFormatter = DateTimeFormatter.ofPattern("EEEE, MMMM d")
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp, vertical = 20.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "DAY $dayNumber OF $totalDays",
                style = MaterialTheme.typography.labelSmall,
                color = accent,
                fontWeight = FontWeight.Bold,
                letterSpacing = 2.sp,
            )
            Text(
                text = "  ·  ${day.date.format(dateFormatter)}",
                style = MaterialTheme.typography.labelSmall,
                color = accent.copy(alpha = 0.85f),
                fontStyle = FontStyle.Italic,
            )
        }
        Spacer(Modifier.size(10.dp))
        Text(
            text = day.theme,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Black,
            color = MaterialTheme.colorScheme.onBackground,
            lineHeight = 34.sp,
        )
        Spacer(Modifier.size(14.dp))
        PassagePill(label = day.passage.displayLabel, accent = accent)

        if (isUnlocked) {
            Spacer(Modifier.size(20.dp))
            JesusAwareReflection(text = day.reflection, accent = accent)
            Spacer(Modifier.size(24.dp))
            OpenInBibleButton(label = day.passage.displayLabel, accent = accent, onClick = onOpenInBible)
        } else {
            Spacer(Modifier.size(40.dp))
            LockedPlaceholder(day = day, accent = accent)
        }
        Spacer(Modifier.size(48.dp))
    }
}

@Composable
private fun PassagePill(label: String, accent: Color) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(accent.copy(alpha = 0.12f))
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.MenuBook, contentDescription = null, tint = accent, modifier = Modifier.size(14.dp))
        Spacer(Modifier.size(6.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelLarge,
            color = accent,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun JesusAwareReflection(text: String, accent: Color) {
    val segments = parseSegments(text)
    val bodyStyle = MaterialTheme.typography.bodyLarge.copy(lineHeight = 26.sp)
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        segments.forEach { segment ->
            when (segment) {
                is Segment.Markdown -> MarkdownText(
                    raw = segment.text,
                    bodyStyle = bodyStyle,
                    onLinkClick = {},
                )
                is Segment.JesusQuote -> Row(verticalAlignment = Alignment.Top) {
                    Box(
                        modifier = Modifier
                            .padding(top = 4.dp)
                            .size(width = 3.dp, height = 22.dp)
                            .background(BrandRed),
                    )
                    Spacer(Modifier.size(12.dp))
                    Text(
                        text = segment.text,
                        style = MaterialTheme.typography.bodyLarge.copy(fontStyle = FontStyle.Italic),
                        color = BrandRed,
                    )
                }
            }
        }
    }
}

private sealed class Segment {
    data class Markdown(val text: String) : Segment()
    data class JesusQuote(val text: String) : Segment()
}

private fun parseSegments(source: String): List<Segment> {
    val out = mutableListOf<Segment>()
    val buffer = StringBuilder()
    fun flush() {
        val joined = buffer.toString().trim()
        if (joined.isNotEmpty()) out.add(Segment.Markdown(joined))
        buffer.clear()
    }
    source.lines().forEach { rawLine ->
        val line = rawLine.trimStart()
        if (line.startsWith("> [J] ")) {
            flush()
            out.add(Segment.JesusQuote(line.removePrefix("> [J] ")))
        } else {
            buffer.appendLine(rawLine)
        }
    }
    flush()
    return out
}

@Composable
private fun OpenInBibleButton(label: String, accent: Color, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(accent)
            .clickable(onClick = onClick)
            .padding(vertical = 14.dp, horizontal = 16.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.OpenInNew, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
        Spacer(Modifier.size(8.dp))
        Text(
            text = "Read $label in Bible",
            color = Color.White,
            fontWeight = FontWeight.SemiBold,
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}

@Composable
private fun LockedPlaceholder(day: EventReadingDay, accent: Color) {
    val today = LocalDate.now()
    val days = ChronoUnit.DAYS.between(today, day.date).toInt().coerceAtLeast(0)
    val unlocksLabel = when {
        days == 1 -> "Unlocks tomorrow"
        days in 2..7 -> "Unlocks in $days days"
        else -> "Unlocks ${day.date.format(DateTimeFormatter.ofPattern("EEEE, MMMM d"))}"
    }
    val comeBack = if (days == 1) "tomorrow"
        else "on ${day.date.format(DateTimeFormatter.ofPattern("EEEE, MMMM d"))}"

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(accent.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Lock, contentDescription = null, tint = accent.copy(alpha = 0.85f), modifier = Modifier.size(34.dp))
        }
        Spacer(Modifier.size(18.dp))
        Text(
            text = unlocksLabel,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.size(8.dp))
        Text(
            text = "Each day's reading unlocks on its date — come back $comeBack to continue the plan.",
            style = MaterialTheme.typography.bodyMedium,
            fontStyle = FontStyle.Italic,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 12.dp),
        )
    }
}
