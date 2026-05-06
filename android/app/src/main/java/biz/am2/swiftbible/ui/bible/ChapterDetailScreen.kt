package biz.am2.swiftbible.ui.bible

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Brush
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
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
    targetVerse: Int? = null,
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

    LaunchedEffect(bookName, chapterNumber) {
        biz.am2.swiftbible.data.Analytics.capture(
            biz.am2.swiftbible.data.Analytics.Event.ChapterViewed,
            mapOf("book" to bookName, "chapter" to chapterNumber),
        )
    }

    Scaffold(
        topBar = {
            if (!prefs.hideBars) {
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
                            onClick = {
                                biz.am2.swiftbible.data.Analytics.capture(
                                    biz.am2.swiftbible.data.Analytics.Event.ChapterNavigated,
                                    mapOf("book" to bookName, "from" to chapterNumber, "to" to (chapterNumber - 1), "direction" to "previous"),
                                )
                                onJumpChapter(chapterNumber - 1)
                            },
                            enabled = chapterNumber > 1,
                        ) {
                            Icon(Icons.AutoMirrored.Filled.NavigateBefore, contentDescription = "Previous chapter")
                        }
                        IconButton(
                            onClick = {
                                biz.am2.swiftbible.data.Analytics.capture(
                                    biz.am2.swiftbible.data.Analytics.Event.ChapterNavigated,
                                    mapOf("book" to bookName, "from" to chapterNumber, "to" to (chapterNumber + 1), "direction" to "next"),
                                )
                                onJumpChapter(chapterNumber + 1)
                            },
                            enabled = chapterNumber < totalChapters,
                        ) {
                            Icon(Icons.AutoMirrored.Filled.NavigateNext, contentDescription = "Next chapter")
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.background,
                    ),
                )
            }
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        if (chapter == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Chapter not found")
            }
            return@Scaffold
        }

        val passageByVerse = remember(passages) { passages.associateBy { it.startVerse } }
        val listState = androidx.compose.foundation.lazy.rememberLazyListState()
        LaunchedEffect(targetVerse, chapter.paragraphs.size) {
            if (targetVerse != null) {
                val index = chapter.paragraphs.indexOfFirst { it.startingVerse <= targetVerse &&
                    (chapter.paragraphs.find { p -> p.startingVerse > it.startingVerse && p.startingVerse <= targetVerse } == null) }
                if (index >= 0) listState.animateScrollToItem(index)
            }
        }
        LazyColumn(
            state = listState,
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(chapter.paragraphs, key = { it.startingVerse }) { paragraph ->
                Column {
                    if (prefs.showSummaries) {
                        passageByVerse[paragraph.startingVerse]?.let { summary ->
                            Text(
                                text = summary.title,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onBackground,
                                modifier = Modifier.padding(top = 12.dp, bottom = 4.dp),
                            )
                        }
                    }
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
                        onLongPress = {
                            biz.am2.swiftbible.data.Analytics.capture(
                                biz.am2.swiftbible.data.Analytics.Event.VerseActionMenu,
                                mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to paragraph.startingVerse),
                            )
                            highlightVerse = paragraph.startingVerse
                        },
                        onCrossRef = onCrossRef,
                        onNote = {
                            biz.am2.swiftbible.data.Analytics.capture(
                                biz.am2.swiftbible.data.Analytics.Event.VerseNoteOpened,
                                mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to paragraph.startingVerse),
                            )
                            noteVerse = paragraph.startingVerse
                        },
                        onBookmark = { appVm.toggleBookmark(bookName, chapterNumber, paragraph.startingVerse) },
                    )
                }
            }
            item { Spacer(Modifier.size(64.dp)) }
        }
    }

    val ctx = androidx.compose.ui.platform.LocalContext.current
    var explainVerse by remember { mutableStateOf<Triple<String, Int, Int>?>(null) }
    highlightVerse?.let { verse ->
        val verseText = biz.am2.swiftbible.ui.components.stripJesusTags(
            chapter?.paragraphs?.firstOrNull { it.startingVerse == verse }?.text.orEmpty()
        )
        VerseActionSheet(
            verseRef = "$bookName $chapterNumber:$verse",
            verseText = verseText,
            currentColor = highlightMap[verse],
            isBookmarked = verse in bookmarkSet,
            hasNote = verse in noteMap,
            onDismiss = { highlightVerse = null },
            onPickColor = { color ->
                if (color == null) {
                    appVm.removeHighlight(bookName, chapterNumber, verse)
                    biz.am2.swiftbible.data.Analytics.capture(
                        biz.am2.swiftbible.data.Analytics.Event.VerseUnhighlighted,
                        mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to verse),
                    )
                } else {
                    appVm.addHighlight(bookName, chapterNumber, verse, color)
                    biz.am2.swiftbible.data.Analytics.capture(
                        biz.am2.swiftbible.data.Analytics.Event.VerseHighlighted,
                        mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to verse, "color" to color),
                    )
                    appVm.recordHappyMoment()
                }
                highlightVerse = null
            },
            onAddNote = { highlightVerse = null; noteVerse = verse },
            onToggleBookmark = {
                appVm.toggleBookmark(bookName, chapterNumber, verse)
                biz.am2.swiftbible.data.Analytics.capture(
                    biz.am2.swiftbible.data.Analytics.Event.VerseBookmarked,
                    mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to verse),
                )
                appVm.recordHappyMoment()
                highlightVerse = null
            },
            onCopy = {
                copyVerse(ctx, "$bookName $chapterNumber:$verse", verseText)
                biz.am2.swiftbible.data.Analytics.capture(biz.am2.swiftbible.data.Analytics.Event.VerseCopied)
                highlightVerse = null
            },
            onShare = {
                shareVerse(ctx, "$bookName $chapterNumber:$verse", verseText)
                biz.am2.swiftbible.data.Analytics.capture(
                    biz.am2.swiftbible.data.Analytics.Event.VerseShared,
                    mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to verse),
                )
                appVm.recordHappyMoment()
                highlightVerse = null
            },
            onExplain = {
                explainVerse = Triple(bookName, chapterNumber, verse)
                biz.am2.swiftbible.data.Analytics.capture(
                    biz.am2.swiftbible.data.Analytics.Event.VerseExplained,
                    mapOf("book" to bookName, "chapter" to chapterNumber, "verse" to verse),
                )
                appVm.recordHappyMoment()
                highlightVerse = null
            },
        )
    }

    explainVerse?.let { (b, c, v) ->
        val verseText = biz.am2.swiftbible.ui.components.stripJesusTags(
            chapter?.paragraphs?.firstOrNull { it.startingVerse == v }?.text.orEmpty()
        )
        ExplainSheet(
            verseRef = "$b $c:$v",
            verseText = verseText,
            onDismiss = { explainVerse = null },
        )
    }

    noteVerse?.let { verse ->
        NoteDialog(
            initial = noteMap[verse] ?: "",
            verseRef = "$bookName $chapterNumber:$verse",
            onDismiss = { noteVerse = null },
            onSave = { text ->
                appVm.saveNote(bookName, chapterNumber, verse, text)
                if (text.isNotBlank()) appVm.recordHappyMoment()
                noteVerse = null
            },
        )
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
    var layoutResult by remember(paragraph.startingVerse) { mutableStateOf<androidx.compose.ui.text.TextLayoutResult?>(null) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(highlightColor?.copy(alpha = 0.35f) ?: Color.Transparent)
            .pointerInput(paragraph.startingVerse, layoutResult) {
                detectTapGestures(
                    onLongPress = { onLongPress() },
                    onTap = { pos ->
                        val lr = layoutResult ?: return@detectTapGestures
                        val offset = lr.getOffsetForPosition(pos)
                        annotated.getStringAnnotations(CROSS_REF_TAG, offset, offset).firstOrNull()?.let { ann ->
                            val parts = ann.item.split('|')
                            if (parts.size == 3) {
                                val ch = parts[1].toIntOrNull() ?: return@let
                                onCrossRef(parts[0], ch)
                            }
                        }
                    },
                )
            }
            .padding(horizontal = 4.dp, vertical = 4.dp),
    ) {
        Column {
            Text(
                text = annotated,
                style = textStyle,
                modifier = Modifier.fillMaxWidth(),
                onTextLayout = { layoutResult = it },
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

private val INLINE_VERSE_MARKER = Regex("""\b(\d+):(\d+)([a-z]?)\b""")

private data class VerseAnnotation(val start: Int, val end: Int, val isRef: Boolean, val payload: String)

private fun buildVerseText(
    paragraph: Paragraph,
    bookName: String,
    jesusRed: Boolean,
    verseNumberColor: Color,
    bodyColor: Color,
    refColor: Color,
): AnnotatedString = buildAnnotatedString {
    appendVerseNumber("${paragraph.startingVerse} ", verseNumberColor)

    val text = paragraph.text
    val refs = CrossReference.findReferences(text)
    val refRanges = refs.map { it.start until it.endExclusive }

    // KJV (and similar) inlines additional verse markers like "1:15" mid-paragraph.
    // Render those as superscript verse numbers, matching iOS ParagraphView behaviour.
    val inlineMarkers = INLINE_VERSE_MARKER.findAll(text)
        .filter { m -> refRanges.none { r -> m.range.first in r } }
        .map { m -> VerseAnnotation(m.range.first, m.range.last + 1, isRef = false, payload = m.groupValues[2] + m.groupValues[3]) }
        .toList()

    val annotations = (refs.map {
        VerseAnnotation(it.start, it.endExclusive, isRef = true, payload = "${it.book}|${it.chapter}|${it.verse}")
    } + inlineMarkers).sortedBy { it.start }

    val highlightSpeech = jesusRed && bookName in GOSPEL_BOOKS
    var i = 0
    for (ann in annotations) {
        if (ann.start > i) {
            appendJesusAware(text.substring(i, ann.start), highlightSpeech)
        }
        if (ann.isRef) {
            pushStringAnnotation(CROSS_REF_TAG, ann.payload)
            withStyle(
                SpanStyle(
                    color = refColor,
                    fontWeight = FontWeight.SemiBold,
                    textDecoration = androidx.compose.ui.text.style.TextDecoration.Underline,
                )
            ) {
                append(text.substring(ann.start, ann.end))
            }
            pop()
        } else {
            // Drop any trailing space after the marker so the body still flows naturally.
            appendVerseNumber(" ${ann.payload} ", verseNumberColor)
        }
        i = ann.end
        // Skip a single trailing space so we don't render double-spaces around the marker.
        if (!ann.isRef && i < text.length && text[i] == ' ') i++
    }
    if (i < text.length) {
        appendJesusAware(text.substring(i), highlightSpeech)
    }
}

private val JESUS_REGEX = Regex("<JESUS>(.*?)</JESUS>", RegexOption.DOT_MATCHES_ALL)

private fun androidx.compose.ui.text.AnnotatedString.Builder.appendJesusAware(
    text: String,
    highlightSpeech: Boolean,
) {
    var cursor = 0
    for (m in JESUS_REGEX.findAll(text)) {
        if (m.range.first > cursor) append(text.substring(cursor, m.range.first))
        val inner = m.groupValues[1]
        if (highlightSpeech) {
            withStyle(SpanStyle(color = BrandRed)) { append(inner) }
        } else {
            append(inner)
        }
        cursor = m.range.last + 1
    }
    if (cursor < text.length) append(text.substring(cursor))
}

private fun androidx.compose.ui.text.AnnotatedString.Builder.appendVerseNumber(num: String, color: Color) {
    withStyle(
        SpanStyle(
            fontWeight = FontWeight.Bold,
            color = color,
            fontSize = 14.sp,
            baselineShift = androidx.compose.ui.text.style.BaselineShift(0.4f),
        )
    ) {
        append(num)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun VerseActionSheet(
    verseRef: String,
    verseText: String,
    currentColor: Long?,
    isBookmarked: Boolean,
    hasNote: Boolean,
    onDismiss: () -> Unit,
    onPickColor: (Long?) -> Unit,
    onAddNote: () -> Unit,
    onToggleBookmark: () -> Unit,
    onCopy: () -> Unit,
    onShare: () -> Unit,
    onExplain: () -> Unit,
) {
    val palette = listOf(
        0xFFFFD54FL to "Gold",
        0xFFB39DDBL to "Lavender",
        0xFFA5D6A7L to "Mint",
        0xFFEF9A9AL to "Rose",
        0xFF80DEEAL to "Sky",
        0xFFFFAB91L to "Coral",
    )
    androidx.compose.material3.ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 12.dp),
        ) {
            Text(verseRef, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
            Text(
                text = verseText,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 3,
                modifier = Modifier.padding(top = 4.dp),
            )
            Spacer(Modifier.size(16.dp))
            Text("HIGHLIGHT", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.size(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                palette.forEach { (color, _) ->
                    val isCurrent = currentColor == color
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(50))
                            .background(Color(color))
                            .clickable { onPickColor(color) }
                            .then(
                                if (isCurrent) Modifier.border(
                                    2.dp,
                                    MaterialTheme.colorScheme.onSurface,
                                    RoundedCornerShape(50)
                                ) else Modifier
                            ),
                    )
                }
                if (currentColor != null) {
                    TextButton(onClick = { onPickColor(null) }) {
                        Text("Remove", color = MaterialTheme.colorScheme.error)
                    }
                }
            }

            Spacer(Modifier.size(20.dp))
            Row(horizontalArrangement = Arrangement.SpaceEvenly, modifier = Modifier.fillMaxWidth()) {
                ActionTile("Note", Icons.Filled.Edit, accent = hasNote, onClick = onAddNote)
                ActionTile(
                    if (isBookmarked) "Bookmarked" else "Bookmark",
                    if (isBookmarked) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                    accent = isBookmarked,
                    onClick = onToggleBookmark,
                )
                ActionTile("Copy", Icons.Filled.ContentCopy, onClick = onCopy)
                ActionTile("Share", Icons.Filled.Share, onClick = onShare)
                ActionTile("Explain", Icons.Filled.AutoAwesome, onClick = onExplain)
            }
            Spacer(Modifier.size(24.dp))
        }
    }
}

@Composable
private fun ActionTile(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, accent: Boolean = false, onClick: () -> Unit) {
    Column(
        modifier = Modifier.clickable(onClick = onClick).padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(if (accent) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceContainer),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = if (accent) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp),
            )
        }
        Spacer(Modifier.size(4.dp))
        Text(label, style = MaterialTheme.typography.labelSmall)
    }
}

private fun shareVerse(ctx: android.content.Context, ref: String, text: String) {
    val intent = android.content.Intent(android.content.Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(android.content.Intent.EXTRA_TEXT, "$ref — $text")
    }
    ctx.startActivity(android.content.Intent.createChooser(intent, "Share verse"))
}

private fun copyVerse(ctx: android.content.Context, ref: String, text: String) {
    val cm = ctx.getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
    cm.setPrimaryClip(android.content.ClipData.newPlainText("verse", "$ref — $text"))
    android.widget.Toast.makeText(ctx, "Copied", android.widget.Toast.LENGTH_SHORT).show()
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
