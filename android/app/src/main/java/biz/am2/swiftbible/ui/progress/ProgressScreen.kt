package biz.am2.swiftbible.ui.progress

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.BuildConfig
import biz.am2.swiftbible.data.Analytics
import biz.am2.swiftbible.data.BadgeRegistry
import biz.am2.swiftbible.data.BadgeTier
import biz.am2.swiftbible.data.BadgeTrack
import biz.am2.swiftbible.data.CanonicalBibleBooks
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.ToastCoordinator
import biz.am2.swiftbible.ui.theme.BrandAccent
import androidx.compose.material.icons.filled.Schedule
import biz.am2.swiftbible.data.ReadingSession
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandGreen
import biz.am2.swiftbible.ui.theme.BrandPeridot
import kotlin.math.roundToInt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class ProgressSnapshot(
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val freezeActive: Boolean = false,
    val chaptersRead: Int = 0,
    val booksCompleted: Int = 0,
    val totalBooks: Int = 66,
    val heatmap: Map<Long, Int> = emptyMap(),
    val bookProgress: List<BookProgressEntry> = emptyList(),
    val earnedCount: Int = 0,
    val tierByTrack: Map<BadgeTrack, BadgeTier?> = emptyMap(),
    val readingTimeMs: Long = 0,
    val recentSessions: List<ReadingSession> = emptyList(),
)

data class BookProgressEntry(
    val name: String,
    val totalChapters: Int,
    val readChapters: Int,
) {
    val percent: Float = if (totalChapters > 0) readChapters.toFloat() / totalChapters else 0f
    val isComplete: Boolean = readChapters >= totalChapters
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProgressScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
    onOpenGallery: () -> Unit,
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    var snapshot by remember { mutableStateOf(ProgressSnapshot()) }

    LaunchedEffect(Unit) {
        withContext(Dispatchers.IO) {
            appVm.badgeService.checkBadges()
            snapshot = appVm.progressSnapshot()
        }
        Analytics.capture(
            Analytics.Event.ProgressViewed,
            mapOf(
                "current_streak" to snapshot.currentStreak,
                "longest_streak" to snapshot.longestStreak,
                "chapters_read" to snapshot.chaptersRead,
                "books_completed" to snapshot.booksCompleted,
                "freeze_active" to snapshot.freezeActive,
                "badges_earned" to snapshot.earnedCount,
            ),
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Progress", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (BuildConfig.DEBUG) {
                        IconButton(onClick = { ToastCoordinator.enqueueDebugSample() }) {
                            Icon(Icons.Filled.AutoAwesome, contentDescription = "Trigger test toast")
                        }
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
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            CanonRingCard(snapshot)
            StatsGrid(snapshot)
            AchievementsCard(snapshot = snapshot, onClick = onOpenGallery)
            HeatmapCard(snapshot.heatmap, weeks = 12)
            BookCompletionCard(snapshot.bookProgress)
            RecentReadingCard(snapshot.recentSessions)
            Spacer(Modifier.size(48.dp))
        }
    }
}

@Composable
private fun CanonRingCard(snapshot: ProgressSnapshot) {
    // Canonical (OT + NT) chapters read, capped per book — a true "% of the
    // 66-book canon", excluding apocrypha/Enoch.
    val canonicalRead = snapshot.bookProgress.sumOf { minOf(it.readChapters, it.totalChapters) }
    val total = 1189
    val fraction = (canonicalRead.toFloat() / total).coerceIn(0f, 1f)
    val percent = (fraction * 100).roundToInt()
    val trackColor = MaterialTheme.colorScheme.surfaceVariant
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(modifier = Modifier.size(150.dp), contentAlignment = Alignment.Center) {
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(6.dp),
                ) {
                    val stroke = 12.dp.toPx()
                    drawArc(
                        color = trackColor,
                        startAngle = 0f,
                        sweepAngle = 360f,
                        useCenter = false,
                        style = Stroke(width = stroke),
                    )
                    drawArc(
                        color = BrandPeridot,
                        startAngle = -90f,
                        sweepAngle = 360f * fraction,
                        useCenter = false,
                        style = Stroke(width = stroke, cap = StrokeCap.Round),
                    )
                }
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        "$percent%",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        "of the Bible",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            Spacer(Modifier.size(8.dp))
            Text(
                "$canonicalRead of 1,189 chapters read",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun StatsGrid(snapshot: ProgressSnapshot) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Filled.LocalFireDepartment,
            tint = Color(0xFFFF9800),
            label = "Current Streak",
            value = "${snapshot.currentStreak}d",
            subtitle = if (snapshot.freezeActive) "Freeze in use" else null,
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Filled.EmojiEvents,
            tint = BrandPeridot,
            label = "Longest Streak",
            value = "${snapshot.longestStreak}d",
        )
    }
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Filled.Book,
            tint = BrandAccent,
            label = "Chapters Read",
            value = "${snapshot.chaptersRead}",
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Filled.Check,
            tint = BrandGold,
            label = "Books Completed",
            value = "${snapshot.booksCompleted}/${snapshot.totalBooks}",
        )
    }
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Filled.Schedule,
            tint = BrandGreen,
            label = "Time in the Word",
            value = formatReadingDuration(snapshot.readingTimeMs),
        )
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun StatCard(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    tint: Color,
    label: String,
    value: String,
    subtitle: String? = null,
) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier.border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(28.dp))
            Spacer(Modifier.size(6.dp))
            Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (subtitle != null) {
                Text(subtitle, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun RecentReadingCard(sessions: List<ReadingSession>) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Recent Reading", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.size(12.dp))
            if (sessions.isEmpty()) {
                Text(
                    "Start reading to see your history",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            } else {
                sessions.forEachIndexed { idx, s ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("${s.bookName} ${s.chapterNumber}", style = MaterialTheme.typography.bodyMedium)
                            Text(
                                relativeTime(s.startedAt),
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                        Text(
                            formatReadingDuration(s.durationMs),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    if (idx < sessions.lastIndex) Spacer(Modifier.size(10.dp))
                }
            }
        }
    }
}

private fun formatReadingDuration(ms: Long): String {
    val totalMinutes = ms / 60000
    val hours = totalMinutes / 60
    val minutes = totalMinutes % 60
    return when {
        hours > 0 -> "${hours}h ${minutes}m"
        minutes > 0 -> "${minutes}m"
        else -> "<1m"
    }
}

private fun relativeTime(epochMs: Long): String =
    android.text.format.DateUtils.getRelativeTimeSpanString(
        epochMs,
        System.currentTimeMillis(),
        android.text.format.DateUtils.MINUTE_IN_MILLIS,
    ).toString()

@Composable
private fun AchievementsCard(snapshot: ProgressSnapshot, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Achievements", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                Text(
                    text = "${snapshot.earnedCount}/${BadgeRegistry.all.size}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(Modifier.size(4.dp))
                Icon(
                    Icons.Filled.ChevronRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.size(12.dp))
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                BadgeTrack.values().toList().chunked(4).forEach { rowTracks ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        rowTracks.forEach { track ->
                            TierMedal(
                                track = track,
                                tier = snapshot.tierByTrack[track],
                                modifier = Modifier.weight(1f),
                            )
                        }
                        // Keep medals at a consistent 1/4 width when the last row is short.
                        repeat(4 - rowTracks.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun TierMedal(track: BadgeTrack, tier: BadgeTier?, modifier: Modifier = Modifier) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(tier?.color ?: Color.Gray.copy(alpha = 0.2f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = track.icon,
                contentDescription = null,
                tint = if (tier == null) MaterialTheme.colorScheme.onSurfaceVariant else Color.White,
                modifier = Modifier.size(20.dp),
            )
        }
        Spacer(Modifier.size(4.dp))
        Text(
            text = tier?.displayName ?: "—",
            style = MaterialTheme.typography.labelSmall,
            color = if (tier == null) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
        )
        Text(
            text = track.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun HeatmapCard(counts: Map<Long, Int>, weeks: Int) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Last $weeks weeks", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.size(10.dp))

            val oneDayMs = 24L * 60 * 60 * 1000
            val today = biz.am2.swiftbible.data.ReadingStatsRepository.startOfDay(System.currentTimeMillis())
            val weekday = java.util.Calendar.getInstance().apply { timeInMillis = today }
                .get(java.util.Calendar.DAY_OF_WEEK) - 1 // 0-indexed Sunday

            Row(
                horizontalArrangement = Arrangement.spacedBy(3.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                for (weekIdx in 0 until weeks) {
                    val weeksAgo = weeks - 1 - weekIdx
                    Column(
                        verticalArrangement = Arrangement.spacedBy(3.dp),
                        modifier = Modifier.weight(1f),
                    ) {
                        for (dayIdx in 0 until 7) {
                            val baseOffset = -weekday + dayIdx - (weeksAgo * 7)
                            val day = today + baseOffset * oneDayMs
                            val isFuture = day > today
                            val count = counts[day] ?: 0
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .aspectRatio(1f)
                                    .clip(RoundedCornerShape(3.dp))
                                    .background(if (isFuture) Color.Gray.copy(alpha = 0.08f) else heatColor(count)),
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.size(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Less", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.size(6.dp))
                for (level in 0..4) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(heatColor(level)),
                    )
                    Spacer(Modifier.size(4.dp))
                }
                Text("More", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

private fun heatColor(level: Int): Color {
    val accent = BrandAccent
    return when {
        level <= 0 -> Color.Gray.copy(alpha = 0.15f)
        level == 1 -> accent.copy(alpha = 0.35f)
        level == 2 -> accent.copy(alpha = 0.55f)
        level in 3..4 -> accent.copy(alpha = 0.75f)
        else -> accent
    }
}

@Composable
private fun BookCompletionCard(books: List<BookProgressEntry>) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Bible Books", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                val complete = books.count { it.isComplete }
                Text(
                    text = "$complete/${books.size}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.size(12.dp))
            // 6-column grid, no LazyVerticalGrid (we're inside a verticalScroll)
            val rows = books.chunked(6)
            for (row in rows) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    for (book in row) {
                        BookCell(book, modifier = Modifier.weight(1f))
                    }
                    // Pad incomplete trailing rows
                    repeat(6 - row.size) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
                Spacer(Modifier.size(6.dp))
            }
        }
    }
}

@Composable
private fun BookCell(book: BookProgressEntry, modifier: Modifier = Modifier) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f)
                .clip(RoundedCornerShape(6.dp)),
        ) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .background(Color.Gray.copy(alpha = 0.12f)),
            )
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .background((if (book.isComplete) BrandPeridot else BrandAccent).copy(alpha = book.percent.coerceIn(0f, 1f))),
            )
            if (book.isComplete) {
                Icon(
                    Icons.Filled.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier
                        .size(14.dp)
                        .align(Alignment.Center),
                )
            }
        }
        Spacer(Modifier.size(2.dp))
        Text(
            text = CanonicalBibleBooks.shortNames[book.name] ?: book.name,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
        )
    }
}
