package biz.am2.swiftbible.ui.settings

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.StatCard
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HighlightsScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
    onOpen: (String, Int) -> Unit,
) {
    val list by appVm.highlights.collectAsState(initial = emptyList())
    val books = appVm.bible.collectAsState().value.allBooks.associateBy { it.name }
    LibraryFrame(title = "Highlights", count = list.size, onBack = onBack) {
        if (list.isEmpty()) Empty("Long-press a verse to highlight it.")
        else LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(list, key = { it.id }) { h ->
                val verseText = books[h.book]?.chapters?.firstOrNull { it.number == h.chapter }
                    ?.paragraphs?.firstOrNull { it.startingVerse == h.startingVerse }?.text ?: ""
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpen(h.book, h.chapter) }
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.Top,
                ) {
                    Box(
                        modifier = Modifier
                            .size(width = 4.dp, height = 36.dp)
                            .clip(CircleShape)
                            .background(Color(h.color)),
                    )
                    Spacer(Modifier.size(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "${h.book} ${h.chapter}:${h.startingVerse}",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Spacer(Modifier.size(4.dp))
                        Text(
                            text = verseText,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 2,
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotesScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
    onOpen: (String, Int) -> Unit,
) {
    val list by appVm.notes.collectAsState(initial = emptyList())
    LibraryFrame(title = "Notes", count = list.size, onBack = onBack) {
        if (list.isEmpty()) Empty("Long-press a verse and tap “Add note”.")
        else LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(list, key = { it.id }) { n ->
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpen(n.book, n.chapter) }
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                ) {
                    Text(
                        text = "${n.book} ${n.chapter}:${n.startingVerse}",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Spacer(Modifier.size(4.dp))
                    Text(
                        text = n.text,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 4,
                    )
                    Spacer(Modifier.size(4.dp))
                    Text(
                        text = friendly(n.updatedAt),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookmarksScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
    onOpen: (String, Int) -> Unit,
) {
    val list by appVm.bookmarks.collectAsState(initial = emptyList())
    LibraryFrame(title = "Bookmarks", count = list.size, onBack = onBack) {
        if (list.isEmpty()) Empty("Tap the bookmark icon on any verse.")
        else LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(list, key = { it.id }) { b ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpen(b.book, b.chapter) }
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                ) {
                    Text(
                        text = "${b.book} ${b.chapter}:${b.startingVerse}",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Spacer(Modifier.weight(1f))
                    Text(friendly(b.createdAt), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
    onOpen: (String, Int) -> Unit,
) {
    val list by appVm.history.collectAsState(initial = emptyList())
    LibraryFrame(title = "Reading history", count = list.size, onBack = onBack) {
        if (list.isEmpty()) Empty("Open a chapter to start tracking.")
        else LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(list, key = { it.id }) { h ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onOpen(h.book, h.chapter) }
                        .padding(horizontal = 20.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "${h.book} ${h.chapter}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onBackground,
                        )
                        Text(
                            text = friendly(h.lastVisit),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(50))
                            .background(MaterialTheme.colorScheme.primaryContainer)
                            .padding(horizontal = 10.dp, vertical = 4.dp),
                    ) {
                        Text(
                            text = "${h.visits}×",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatsScreen(appVm: AppViewModel, onBack: () -> Unit) {
    val chaptersRead by appVm.chaptersRead.collectAsState(initial = 0)
    val totalVisits by appVm.totalVisits.collectAsState(initial = 0)
    val notes by appVm.notes.collectAsState(initial = emptyList())
    val highlights by appVm.highlights.collectAsState(initial = emptyList())
    val bookmarks by appVm.bookmarks.collectAsState(initial = emptyList())

    LibraryFrame(title = "Reading stats", count = null, onBack = onBack) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                StatCard("Chapters read", chaptersRead.toString(), modifier = Modifier.weight(1f))
                StatCard("Total reads", (totalVisits ?: 0).toString(), modifier = Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                StatCard("Highlights", highlights.size.toString(), modifier = Modifier.weight(1f))
                StatCard("Notes", notes.size.toString(), modifier = Modifier.weight(1f))
            }
            StatCard("Bookmarks", bookmarks.size.toString(), modifier = Modifier.fillMaxWidth())
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TranslationInfoScreen(onBack: () -> Unit) {
    LibraryFrame(title = "About translations", count = null, onBack = onBack) {
        Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            TranslationCard(
                title = "King James Version (KJV)",
                year = "1611",
                body = "The classic English translation, formal and majestic. Public domain. The most widely cited Bible in the English language.",
            )
            TranslationCard(
                title = "American Standard Version (ASV)",
                year = "1901",
                body = "A scholarly revision aiming for literal accuracy. The basis for many later modern English translations.",
            )
            TranslationCard(
                title = "World English Bible (WEB)",
                year = "2000",
                body = "A modern English revision of the ASV. Public domain and free to share.",
            )
            TranslationCard(
                title = "Original (Hebrew & Greek)",
                year = "Source texts",
                body = "Old Testament from the Hebrew Masoretic tradition, New Testament from the Greek Textus Receptus. Read with care — render the source.",
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TextSourcesScreen(onBack: () -> Unit) {
    LibraryFrame(title = "Text sources", count = null, onBack = onBack) {
        Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SourceItem(
                "Apocrypha",
                "Deuterocanonical books recognized by the Catholic and Orthodox traditions: Tobit, Judith, Wisdom of Solomon, Ecclesiasticus (Sirach), Baruch, 1 & 2 Maccabees, additions to Esther and Daniel, plus Orthodox-only books.",
            )
            SourceItem(
                "Book of Enoch (1 Enoch)",
                "Pseudepigraphic Jewish work in five sections: Watchers, Parables, Astronomical Book, Dream Visions, Epistle. Quoted in Jude 1:14–15.",
            )
            SourceItem(
                "Jubilees",
                "Second Temple Jewish text retelling Genesis–Exodus through the framework of jubilee years.",
            )
            SourceItem(
                "Testaments of the Twelve Patriarchs",
                "Pseudepigraphic farewell speeches attributed to each of Jacob's twelve sons.",
            )
            SourceItem(
                "2 Enoch (Secrets of Enoch)",
                "A separate ascension narrative from the Slavonic Enoch tradition.",
            )
            SourceItem(
                "Didache",
                "Early-Christian church manual, c. 1st–2nd century. The 'Teaching of the Twelve Apostles'.",
            )
            SourceItem(
                "1 Clement",
                "An early epistle from the church at Rome to the church at Corinth, c. AD 96.",
            )
        }
    }
}

@Composable
private fun TranslationCard(title: String, year: String, body: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .padding(20.dp),
    ) {
        Column {
            Text(year.uppercase(), style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.size(8.dp))
            Text(body, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun SourceItem(title: String, body: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .padding(16.dp),
    ) {
        Column {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.size(6.dp))
            Text(body, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LibraryFrame(
    title: String,
    count: Int?,
    onBack: () -> Unit,
    content: @Composable () -> Unit,
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(title, fontWeight = FontWeight.SemiBold)
                        if (count != null && count > 0) {
                            Spacer(Modifier.size(8.dp))
                            biz.am2.swiftbible.ui.components.PillBadge(
                                text = count.toString(),
                                color = MaterialTheme.colorScheme.primaryContainer,
                                onColor = MaterialTheme.colorScheme.onPrimaryContainer,
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            content()
        }
    }
}

@Composable
private fun Empty(message: String) {
    Box(modifier = Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
        Text(message, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodyLarge)
    }
}

private fun friendly(ts: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - ts
    val secs = diff / 1000
    val mins = secs / 60
    val hours = mins / 60
    val days = hours / 24
    return when {
        secs < 60 -> "Just now"
        mins < 60 -> "${mins}m ago"
        hours < 24 -> "${hours}h ago"
        days < 7 -> "${days}d ago"
        else -> SimpleDateFormat("MMM d, yyyy", Locale.getDefault()).format(Date(ts))
    }
}
