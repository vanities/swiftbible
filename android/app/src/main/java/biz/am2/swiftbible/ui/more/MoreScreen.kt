package biz.am2.swiftbible.ui.more

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Brush
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.data.AppEvent
import biz.am2.swiftbible.data.AppEventRegistry
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.settings.EnterAnimation
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandGoldLight
import biz.am2.swiftbible.ui.theme.BrandRed
import biz.am2.swiftbible.ui.theme.BrandRedDark

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoreScreen(
    appVm: AppViewModel,
    onOpen: (String) -> Unit,
    onOpenChapter: (String, Int) -> Unit,
) {
    val prefs by appVm.prefsState.collectAsState()
    val highlights by appVm.highlights.collectAsState(initial = emptyList())
    val notes by appVm.notes.collectAsState(initial = emptyList())
    val saved by appVm.savedDevotionals.collectAsState(initial = emptyList())
    val history by appVm.history.collectAsState(initial = emptyList())
    val badgesEarned by appVm.badgesEarnedCount.collectAsState(initial = 0)

    val events = AppEventRegistry.visible(
        forceAll = biz.am2.swiftbible.BuildConfig.DEBUG && prefs.forceShowEvents,
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "More",
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        EnterAnimation {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            events.forEach { event ->
                EventCard(event = event, onClick = { handleEvent(event, onOpenChapter, onOpen) })
            }

            HistoryHeroCard(onClick = { onOpen("church_history") })

            if (prefs.lastBook != null) {
                BibleBookmarkCard(
                    book = prefs.lastBook!!,
                    chapter = prefs.lastChapter,
                    onClick = { onOpenChapter(prefs.lastBook!!, prefs.lastChapter) },
                )
            }

            Text(
                text = "YOUR LIBRARY",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(top = 4.dp),
            )

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                LibraryTile(
                    label = "Highlights",
                    icon = Icons.Filled.Brush,
                    bgColor = Color(0xFFFFF4D4),
                    iconColor = BrandGold,
                    count = highlights.size,
                    onClick = { onOpen("highlights") },
                    modifier = Modifier.weight(1f),
                )
                LibraryTile(
                    label = "Notes",
                    icon = Icons.Filled.Edit,
                    bgColor = Color(0xFFCFEEEA),
                    iconColor = BrandAccent,
                    count = notes.size,
                    onClick = { onOpen("notes") },
                    modifier = Modifier.weight(1f),
                )
                LibraryTile(
                    label = "Devotionals",
                    icon = Icons.Filled.Favorite,
                    bgColor = Color(0xFFFFD6D2),
                    iconColor = BrandRed,
                    count = saved.size,
                    onClick = { onOpen("saved_devotionals") },
                    modifier = Modifier.weight(1f),
                )
            }
            HistoryRow(
                count = history.size,
                onClick = { onOpen("history") },
            )

            ProgressCard(
                badgesEarned = badgesEarned,
                onClick = { onOpen("progress") },
            )

            SettingsCard(onClick = { onOpen("settings_detail") })

            Spacer(Modifier.size(16.dp))
            Text(
                text = "swiftbible · v1.0",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.size(72.dp))
        }
        }
    }
}

private fun handleEvent(
    event: AppEvent,
    onOpenChapter: (String, Int) -> Unit,
    onOpen: (String) -> Unit,
) {
    when (val a = event.action) {
        is biz.am2.swiftbible.data.EventAction.OpenVerse -> onOpenChapter(a.book, a.chapter)
        is biz.am2.swiftbible.data.EventAction.OpenDevotional -> onOpen("daily")
        biz.am2.swiftbible.data.EventAction.OpenEvent -> onOpen("event/${event.id}")
    }
}

@Composable
private fun EventCard(event: AppEvent, onClick: () -> Unit) {
    val accent = event.accent.color
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, accent.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
    ) {
        Column {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(140.dp)
                    .background(
                        Brush.verticalGradient(listOf(accent.copy(alpha = 0.6f), accent.copy(alpha = 0.9f)))
                    ),
                contentAlignment = Alignment.BottomStart,
            ) {
                if (event.bannerRes != null) {
                    androidx.compose.foundation.Image(
                        painter = androidx.compose.ui.res.painterResource(id = event.bannerRes),
                        contentDescription = null,
                        contentScale = androidx.compose.ui.layout.ContentScale.Crop,
                        modifier = Modifier.fillMaxWidth().height(140.dp),
                    )
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp)
                            .background(
                                Brush.verticalGradient(
                                    listOf(Color.Transparent, Color.Black.copy(alpha = 0.45f))
                                )
                            ),
                    )
                }
                Box(
                    modifier = Modifier
                        .padding(12.dp)
                        .clip(RoundedCornerShape(50))
                        .background(accent)
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                ) {
                    Text(
                        text = "${event.iconEmoji} HAPPENING NOW",
                        color = Color.White,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        event.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Text(
                        event.subtitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                androidx.compose.material3.Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = accent,
                )
            }
        }
    }
}

@Composable
private fun HistoryHeroCard(onClick: () -> Unit) {
    val dark = androidx.compose.foundation.isSystemInDarkTheme()
    val cardBg = if (dark) MaterialTheme.colorScheme.surfaceContainer else Color(0xFFF7E9C7)
    val titleInk = if (dark) MaterialTheme.colorScheme.onBackground else Color(0xFF2E1A0B)
    val bodyInk = if (dark) MaterialTheme.colorScheme.onSurfaceVariant else Color(0xFF5A4423)
    val mutedInk = if (dark) MaterialTheme.colorScheme.onSurfaceVariant else Color(0xFF806239)
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(18.dp),
        color = cardBg,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, BrandGold.copy(alpha = 0.30f), RoundedCornerShape(18.dp)),
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(modifier = Modifier.width(16.dp).height(1.dp).background(BrandGold.copy(alpha = 0.85f)))
                Spacer(Modifier.size(6.dp))
                Text(
                    text = "LEARN",
                    style = MaterialTheme.typography.labelMedium,
                    color = BrandGold,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.size(6.dp))
                Box(modifier = Modifier.width(16.dp).height(1.dp).background(BrandGold.copy(alpha = 0.85f)))
                Spacer(Modifier.weight(1f))
                Text(text = "📜", style = MaterialTheme.typography.titleLarge)
            }
            Spacer(Modifier.size(12.dp))
            Text(
                text = "History of the\nChristian Church",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Black,
                color = titleInk,
            )
            Spacer(Modifier.size(8.dp))
            Text(
                text = "Two thousand years — from the patriarchs to today, in 29 articles.",
                style = MaterialTheme.typography.bodyMedium.copy(fontStyle = androidx.compose.ui.text.font.FontStyle.Italic),
                color = bodyInk,
            )
            Spacer(Modifier.size(12.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(BrandGold.copy(alpha = 0.32f)),
            )
            Spacer(Modifier.size(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "9 SECTIONS · 29 ARTICLES",
                    style = MaterialTheme.typography.labelSmall,
                    color = mutedInk,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                androidx.compose.material3.Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = BrandGold,
                )
            }
        }
    }
}

@Composable
private fun BibleBookmarkCard(book: String, chapter: Int, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(width = 4.dp, height = 36.dp)
                    .background(BrandRedDark, RoundedCornerShape(2.dp)),
            )
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "BIBLE BOOKMARK",
                    style = MaterialTheme.typography.labelSmall,
                    color = BrandRedDark,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = "$book $chapter",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            androidx.compose.material3.Icon(
                Icons.AutoMirrored.Filled.ArrowForward,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun LibraryTile(
    label: String,
    icon: ImageVector,
    bgColor: Color,
    iconColor: Color,
    count: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier.border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(bgColor),
                contentAlignment = Alignment.Center,
            ) {
                androidx.compose.material3.Icon(icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(22.dp))
            }
            Spacer(Modifier.size(12.dp))
            Text(label, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.size(4.dp))
            Text(
                text = if (count > 0) "$count" else " ",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun HistoryRow(count: Int, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFEEF7C6)),
                contentAlignment = Alignment.Center,
            ) {
                androidx.compose.material3.Icon(
                    Icons.AutoMirrored.Filled.MenuBook,
                    contentDescription = null,
                    tint = Color(0xFF7AA800),
                )
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("Reading History", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    text = if (count == 0) "Open chapters to start tracking your journey"
                    else "$count chapter${if (count == 1) "" else "s"} visited",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            androidx.compose.material3.Icon(
                Icons.AutoMirrored.Filled.ArrowForward,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun ProgressCard(badgesEarned: Int, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFFFE0B2)),
                contentAlignment = Alignment.Center,
            ) {
                androidx.compose.material3.Icon(
                    Icons.Filled.LocalFireDepartment,
                    contentDescription = null,
                    tint = Color(0xFFFF9800),
                )
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("Progress", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    text = if (badgesEarned == 0) "Streak, heatmap, and 35 achievements"
                    else "$badgesEarned badge${if (badgesEarned == 1) "" else "s"} earned",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun SettingsCard(onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Color(0xFFCFEEEA)),
                contentAlignment = Alignment.Center,
            ) {
                androidx.compose.material3.Icon(Icons.Filled.Settings, contentDescription = null, tint = BrandAccent)
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("Settings", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(
                    text = "Translations, fonts, notifications, and more",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}
