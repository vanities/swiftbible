package biz.am2.swiftbible.ui.daily

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.BrandMark
import biz.am2.swiftbible.ui.components.PeridotGradient
import biz.am2.swiftbible.ui.components.SectionHeader
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandAccentLight
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandGoldLight
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private data class DailyVerse(
    val book: String,
    val chapter: Int,
    val verse: Int,
    val text: String,
    val theme: String,
    val reflection: String,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DailyDevotionalScreen(
    appVm: AppViewModel,
    onOpenChapter: (String, Int) -> Unit,
) {
    val bible by appVm.bible.collectAsState()
    val today = remember { LocalDate.now() }
    val daily = remember(bible.allBooks.size, today) { selectDaily(bible.allBooks, today) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                        BrandMark(size = 28)
                        Spacer(Modifier.size(10.dp))
                        Text(
                            text = "Daily Devotional",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        if (daily == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = androidx.compose.ui.Alignment.Center) {
                Text("Loading…")
            }
            return@Scaffold
        }
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
        ) {
            DateBanner(today = today)
            Spacer(Modifier.size(16.dp))
            VerseCard(daily, onOpen = { onOpenChapter(daily.book, daily.chapter) })
            Spacer(Modifier.size(20.dp))
            SectionHeader("Reflection")
            ReflectionBlock(daily.reflection)
            Spacer(Modifier.size(20.dp))
            SectionHeader("This Theme")
            ThemeBadge(daily.theme)
            Spacer(Modifier.size(72.dp))
        }
    }
}

@Composable
private fun DateBanner(today: LocalDate) {
    Column {
        Text(
            text = today.format(DateTimeFormatter.ofPattern("EEEE")).uppercase(),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.SemiBold,
        )
        Text(
            text = today.format(DateTimeFormatter.ofPattern("MMMM d, yyyy")),
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun VerseCard(d: DailyVerse, onOpen: () -> Unit) {
    val gradient = Brush.linearGradient(listOf(BrandAccent, BrandAccentLight))
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(gradient)
            .clickable(onClick = onOpen)
            .padding(24.dp),
    ) {
        Column {
            Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.AutoAwesome,
                    contentDescription = null,
                    tint = BrandGoldLight,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    text = "VERSE OF THE DAY",
                    style = MaterialTheme.typography.labelMedium,
                    color = BrandGoldLight,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            Spacer(Modifier.size(14.dp))
            Text(
                text = "“${d.text}”",
                style = MaterialTheme.typography.headlineSmall,
                color = androidx.compose.ui.graphics.Color.White,
                fontWeight = FontWeight.Medium,
                fontStyle = FontStyle.Italic,
                lineHeight = 32.sp(),
            )
            Spacer(Modifier.size(14.dp))
            Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                Text(
                    text = "${d.book} ${d.chapter}:${d.verse}",
                    style = MaterialTheme.typography.titleMedium,
                    color = BrandGoldLight,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = "Open chapter",
                    style = MaterialTheme.typography.labelLarge,
                    color = androidx.compose.ui.graphics.Color.White,
                )
                Spacer(Modifier.size(6.dp))
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = androidx.compose.ui.graphics.Color.White,
                )
            }
        }
    }
}

@Composable
private fun ReflectionBlock(text: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .padding(20.dp),
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface,
        )
    }
}

@Composable
private fun ThemeBadge(theme: String) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(PeridotGradient)
            .padding(horizontal = 16.dp, vertical = 8.dp),
    ) {
        Text(
            text = theme,
            color = androidx.compose.ui.graphics.Color.White,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

private fun selectDaily(books: List<biz.am2.swiftbible.model.Book>, date: LocalDate): DailyVerse? {
    if (books.isEmpty()) return null
    val seed = date.toEpochDay()
    val themes = listOf("Faith", "Hope", "Love", "Peace", "Joy", "Strength", "Wisdom", "Courage")
    val theme = themes[(seed % themes.size).toInt().let { if (it < 0) it + themes.size else it }]
    val reflections = listOf(
        "Sit with this verse for a moment. What word stands out to you today? Why might that be?",
        "Read it slowly, three times. Notice what you feel — and bring that to prayer.",
        "Where in your life today does this verse meet you? Where does it challenge you?",
        "What would change in your day if you let this be true?",
        "Pray it back to God in your own words. Don’t rush the silence.",
        "Memorize a single phrase. Carry it with you between meetings, drives, and chores.",
        "Whose face came to mind as you read? What does this verse ask of you toward them?",
    )
    val reflection = reflections[(seed % reflections.size).toInt().let { if (it < 0) it + reflections.size else it }]

    val book = books[(seed.toInt() % books.size + books.size) % books.size]
    val chapter = book.chapters[(seed.toInt() / 7 % book.chapters.size + book.chapters.size) % book.chapters.size]
    val paragraph = chapter.paragraphs[(seed.toInt() / 13 % chapter.paragraphs.size + chapter.paragraphs.size) % chapter.paragraphs.size]
    val firstSentence = paragraph.text.split('.', '!', '?').firstOrNull { it.isNotBlank() }?.trim()?.let { "$it." } ?: paragraph.text
    return DailyVerse(
        book = book.name,
        chapter = chapter.number,
        verse = paragraph.startingVerse,
        text = firstSentence,
        theme = theme,
        reflection = reflection,
    )
}

private fun Int.sp() = androidx.compose.ui.unit.TextUnit(this.toFloat(), androidx.compose.ui.unit.TextUnitType.Sp)
