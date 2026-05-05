package biz.am2.swiftbible.ui.bible

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.NavigateBefore
import androidx.compose.material.icons.automirrored.filled.NavigateNext
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Brush
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import biz.am2.swiftbible.data.CrossReference
import biz.am2.swiftbible.data.PassageSummary
import biz.am2.swiftbible.data.UserPreferences
import biz.am2.swiftbible.model.Paragraph
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.theme.BrandRed
import kotlinx.coroutines.flow.first
import androidx.compose.foundation.text.ClickableText
import androidx.compose.ui.text.TextStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChapterDetailScreen(
    appVm: AppViewModel,
    bookName: String,
    chapterNumber: Int,
    onBack: () -> Unit,
    onJumpChapter: (Int) -> Unit,
    onCrossRef: (String, Int) -> Unit,
) {
    val book = appVm.bookByName(bookName)
    val chapter = book?.chapters?.firstOrNull { it.number == chapterNumber }
    val totalChapters = book?.chapters?.size ?: 0
    val prefs by appVm.prefsState.collectAsState()
    val highlights by appVm.db.highlightDao().forChapter(bookName, chapterNumber).collectAsState(initial = emptyList())
    val notes by appVm.db.noteDao().forChapter(bookName, chapterNumber).collectAsState(initial = emptyList())
    val bookmarks by appVm.bookmarks.collectAsState(initial = emptyList())
    val bookmarkSet = remember(bookmarks, bookName, chapterNumber) {
        bookmarks.filter { it.book == bookName && it.chapter == chapterNumber }.map { it.startingVerse }.toSet()
    }

    var chapterTitle by remember(bookName, chapterNumber) { mutableStateOf<String?>(null) }
    var passages by remember(bookName, chapterNumber) { mutableStateOf<List<PassageSummary>>(emptyList()) }

    LaunchedEffect(bookName, chapterNumber) {
        appVm.visitChapter(bookName, chapterNumber)
        chapterTitle = appVm.chapterTitle(bookName, chapterNumber)
        passages = appVm.passageSummaries(bookName, chapterNumber)
    }

    var noteVerse by remember { mutableStateOf<Int?>(null) }
    var highlightVerse by remember { mutableStateOf<Int?>(null) }

    val highlightMap = highlights.associate { it.startingVerse to it.color }
    val noteMap = notes.associate { it.startingVerse to it.text }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "$bookName $chapterNumber",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.SemiBold,
                        )
                        chapterTitle?.let {
                            Text(
                                text = it,
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.primary,
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(
                        onClick = { onJumpChapter(chapterNumber - 1) },
                        enabled = chapterNumber > 1,
                    ) {
                        Icon(Icons.AutoMirrored.Filled.NavigateBefore, contentDescription = "Previous chapter")
                    }
                    IconButton(
                        onClick = { onJumpChapter(chapterNumber + 1) },
                        enabled = chapterNumber < totalChapters,
                    ) {
                        Icon(Icons.AutoMirrored.Filled.NavigateNext, contentDescription = "Next chapter")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        if (chapter == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Chapter not found")
            }
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 24.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            if (prefs.showSummaries && passages.isNotEmpty()) {
                item(key = "summaries") {
                    PassageSummariesCard(passages)
                }
            }
            items(chapter.paragraphs, key = { it.startingVerse }) { paragraph ->
                ParagraphRow(
                    paragraph = paragraph,
                    fontSize = prefs.fontSize.sp,
                    fontFamily = prefs.fontFamily.family,
                    bookName = bookName,
                    jesusRed = prefs.jesusRed,
                    isFirst = paragraph.startingVerse == chapter.paragraphs.first().startingVerse,
                    highlightColor = highlightMap[paragraph.startingVerse]?.let { Color(it) },
                    hasNote = noteMap[paragraph.startingVerse] != null,
                    isBookmarked = paragraph.startingVerse in bookmarkSet,
                    onLongPress = { highlightVerse = paragraph.startingVerse },
                    onCrossRef = onCrossRef,
                    onNote = { noteVerse = paragraph.startingVerse },
                    onBookmark = { appVm.toggleBookmark(bookName, chapterNumber, paragraph.startingVerse) },
                )
            }
            item { Spacer(Modifier.size(64.dp)) }
        }
    }

    highlightVerse?.let { verse ->
        HighlightDialog(
            currentColor = highlightMap[verse],
            onDismiss = { highlightVerse = null },
            onPick = { color ->
                if (color == null) appVm.removeHighlight(bookName, chapterNumber, verse)
                else appVm.addHighlight(bookName, chapterNumber, verse, color)
                highlightVerse = null
            },
            onAddNote = { highlightVerse = null; noteVerse = verse },
        )
    }

    noteVerse?.let { verse ->
        NoteDialog(
            initial = noteMap[verse] ?: "",
            verseRef = "$bookName $chapterNumber:$verse",
            onDismiss = { noteVerse = null },
            onSave = { text ->
                appVm.saveNote(bookName, chapterNumber, verse, text)
                noteVerse = null
            },
        )
    }
}

@Composable
private fun PassageSummariesCard(passages: List<PassageSummary>) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .padding(16.dp),
    ) {
        Column {
            Text(
                text = "AT A GLANCE",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(Modifier.size(8.dp))
            passages.forEach { summary ->
                Row(
                    modifier = Modifier.padding(vertical = 4.dp),
                    verticalAlignment = Alignment.Top,
                ) {
                    Box(
                        modifier = Modifier
                            .size(width = 28.dp, height = 22.dp),
                        contentAlignment = Alignment.TopEnd,
                    ) {
                        Text(
                            text = "v${summary.startVerse}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.secondary,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.End,
                        )
                    }
                    Spacer(Modifier.size(8.dp))
                    Text(
                        text = summary.title,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                    )
                }
            }
        }
    }
}

@Composable
private fun ParagraphRow(
    paragraph: Paragraph,
    fontSize: androidx.compose.ui.unit.TextUnit,
    fontFamily: androidx.compose.ui.text.font.FontFamily,
    bookName: String,
    jesusRed: Boolean,
    isFirst: Boolean,
    highlightColor: Color?,
    hasNote: Boolean,
    isBookmarked: Boolean,
    onLongPress: () -> Unit,
    onCrossRef: (String, Int) -> Unit,
    onNote: () -> Unit,
    onBookmark: () -> Unit,
) {
    val scheme = MaterialTheme.colorScheme
    val annotated = buildVerseText(paragraph, bookName, jesusRed, scheme.secondary, scheme.onSurface, scheme.primary)
    val textStyle = TextStyle(
        fontSize = fontSize,
        fontFamily = fontFamily,
        lineHeight = fontSize * 1.55f,
        color = scheme.onBackground,
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(highlightColor?.copy(alpha = 0.35f) ?: Color.Transparent)
            .pointerInput(paragraph.startingVerse) {
                detectTapGestures(
                    onLongPress = { onLongPress() },
                )
            }
            .padding(horizontal = 4.dp, vertical = 4.dp),
    ) {
        Column {
            ClickableText(
                text = annotated,
                style = textStyle,
                modifier = Modifier.fillMaxWidth(),
                onClick = { offset ->
                    annotated.getStringAnnotations(CROSS_REF_TAG, offset, offset).firstOrNull()?.let { ann ->
                        val parts = ann.item.split('|')
                        if (parts.size == 3) {
                            val ch = parts[1].toIntOrNull() ?: return@ClickableText
                            onCrossRef(parts[0], ch)
                        }
                    }
                },
            )
            if (hasNote || isBookmarked) {
                Row(
                    modifier = Modifier.padding(top = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    if (hasNote) {
                        Icon(
                            Icons.Filled.Edit,
                            contentDescription = "Has note",
                            tint = scheme.tertiary,
                            modifier = Modifier
                                .size(16.dp)
                                .clickable { onNote() },
                        )
                    }
                    if (isBookmarked) {
                        Icon(
                            Icons.Filled.Bookmark,
                            contentDescription = "Bookmarked",
                            tint = scheme.secondary,
                            modifier = Modifier
                                .size(16.dp)
                                .clickable { onBookmark() },
                        )
                    }
                }
            }
        }
    }
}

private val GOSPEL_BOOKS = setOf("Matthew", "Mark", "Luke", "John")

private const val CROSS_REF_TAG = "crossref"

private fun buildVerseText(
    paragraph: Paragraph,
    bookName: String,
    jesusRed: Boolean,
    verseNumberColor: Color,
    bodyColor: Color,
    refColor: Color,
): AnnotatedString = buildAnnotatedString {
    withStyle(
        SpanStyle(
            fontWeight = FontWeight.Bold,
            color = verseNumberColor,
            fontSize = 14.sp,
            baselineShift = androidx.compose.ui.text.style.BaselineShift(0.4f),
        )
    ) {
        append("${paragraph.startingVerse} ")
    }
    val text = paragraph.text
    val refs = CrossReference.findReferences(text)
    val highlightSpeech = jesusRed && bookName in GOSPEL_BOOKS
    var i = 0
    for (ref in refs) {
        if (ref.start > i) {
            if (highlightSpeech) highlightQuotes(text.substring(i, ref.start), bodyColor)
            else append(text.substring(i, ref.start))
        }
        pushStringAnnotation(CROSS_REF_TAG, "${ref.book}|${ref.chapter}|${ref.verse}")
        withStyle(
            SpanStyle(
                color = refColor,
                fontWeight = FontWeight.SemiBold,
                textDecoration = androidx.compose.ui.text.style.TextDecoration.Underline,
            )
        ) {
            append(text.substring(ref.start, ref.endExclusive))
        }
        pop()
        i = ref.endExclusive
    }
    if (i < text.length) {
        if (highlightSpeech) highlightQuotes(text.substring(i), bodyColor)
        else append(text.substring(i))
    }
}

private fun androidx.compose.ui.text.AnnotatedString.Builder.highlightQuotes(text: String, bodyColor: Color) {
    var i = 0
    val openers = setOf('"', '“')
    val closers = mapOf('“' to '”', '"' to '"')
    while (i < text.length) {
        val ch = text[i]
        if (ch in openers) {
            val close = closers[ch] ?: '"'
            val end = text.indexOf(close, i + 1)
            if (end > i) {
                withStyle(SpanStyle(color = BrandRed, fontStyle = FontStyle.Normal)) {
                    append(text.substring(i, end + 1))
                }
                i = end + 1
                continue
            }
        }
        append(ch)
        i++
    }
}

@Composable
private fun HighlightDialog(
    currentColor: Long?,
    onDismiss: () -> Unit,
    onPick: (Long?) -> Unit,
    onAddNote: () -> Unit,
) {
    val palette = listOf(
        0xFFFFD54F to "Gold",
        0xFFB39DDB to "Lavender",
        0xFFA5D6A7 to "Mint",
        0xFFEF9A9A to "Rose",
        0xFF80DEEA to "Sky",
        0xFFFFAB91 to "Coral",
    )
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Mark this verse") },
        text = {
            Column {
                Text("Choose a color or add a note")
                Spacer(Modifier.size(16.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    palette.forEach { (color, label) ->
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(50))
                                .background(Color(color))
                                .clickable { onPick(color) },
                        )
                    }
                }
                if (currentColor != null) {
                    Spacer(Modifier.size(12.dp))
                    TextButton(onClick = { onPick(null) }) {
                        Text("Remove highlight", color = MaterialTheme.colorScheme.error)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onAddNote) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Edit, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.size(6.dp))
                    Text("Add note")
                }
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

@Composable
private fun NoteDialog(
    initial: String,
    verseRef: String,
    onDismiss: () -> Unit,
    onSave: (String) -> Unit,
) {
    var text by remember { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Note · $verseRef") },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { text = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("Your reflection on this verse…") },
                minLines = 4,
            )
        },
        confirmButton = { TextButton(onClick = { onSave(text) }) { Text("Save") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}
