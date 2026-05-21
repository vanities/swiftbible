package biz.am2.swiftbible.ui.bible

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.NavigateNext
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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.OutlinedFrame

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookDetailScreen(
    appVm: AppViewModel,
    bookName: String,
    onChapterClick: (Int) -> Unit,
    onBack: () -> Unit,
) {
    val book = appVm.bookByName(bookName)
    var titles by remember(bookName) { mutableStateOf<Map<Int, String>>(emptyMap()) }
    // Reactive set of chapters the user has read (scrolled to end + >=30s);
    // updates live as the reading_sessions table changes.
    val readChapters by remember(bookName) { appVm.readChaptersForBook(bookName) }
        .collectAsState(initial = emptySet())

    LaunchedEffect(bookName) {
        biz.am2.swiftbible.data.Analytics.capture(
            biz.am2.swiftbible.data.Analytics.Event.BookOpened,
            mapOf("book" to bookName),
        )
        val chapters = book?.chapters ?: return@LaunchedEffect
        val resolved = mutableMapOf<Int, String>()
        for (ch in chapters) {
            appVm.chapterTitle(bookName, ch.number)?.let { resolved[ch.number] = it }
        }
        titles = resolved
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = bookName,
                        style = MaterialTheme.typography.titleLarge,
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
        if (book == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Book not found")
            }
            return@Scaffold
        }

        LazyColumn(
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            if (book.description.isNotBlank()) {
                item {
                    OutlinedFrame(modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)) {
                        Column(modifier = Modifier.padding(16.dp)) {
                            Text(
                                text = "About this book",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                            Text(
                                text = book.description,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.padding(top = 6.dp),
                            )
                        }
                    }
                }
            }
            items(book.chapters, key = { it.number }) { chapter ->
                ChapterRow(
                    number = chapter.number,
                    title = titles[chapter.number],
                    isRead = chapter.number in readChapters,
                    onClick = { onChapterClick(chapter.number) },
                )
            }
        }
    }
}

@Composable
private fun ChapterRow(
    number: Int,
    title: String?,
    isRead: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 4.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Chapter $number",
                style = MaterialTheme.typography.bodyLarge,
                // Read chapters tint their title in the accent color (mirrors iOS).
                color = if (isRead) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onBackground,
            )
            if (!title.isNullOrBlank()) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        Icon(
            Icons.AutoMirrored.Filled.NavigateNext,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
