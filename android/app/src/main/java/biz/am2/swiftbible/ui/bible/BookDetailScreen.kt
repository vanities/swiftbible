package biz.am2.swiftbible.ui.bible

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.OutlinedFrame
import biz.am2.swiftbible.ui.components.SectionHeader

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookDetailScreen(
    appVm: AppViewModel,
    bookName: String,
    onChapterClick: (Int) -> Unit,
    onBack: () -> Unit,
) {
    val book = appVm.bookByName(bookName)

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

        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize = 72.dp),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            if (book.description.isNotBlank()) {
                item(span = { GridItemSpan(maxLineSpan) }) {
                    OutlinedFrame(modifier = Modifier.fillMaxWidth().padding(bottom = 4.dp)) {
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
            item(span = { GridItemSpan(maxLineSpan) }) {
                SectionHeader("Chapters · ${book.chapters.size}")
            }
            items(book.chapters, key = { it.number }) { chapter ->
                ChapterTile(number = chapter.number, onClick = { onChapterClick(chapter.number) })
            }
        }
    }
}

@Composable
private fun ChapterTile(number: Int, onClick: () -> Unit) {
    val scheme = MaterialTheme.colorScheme
    val gradient = Brush.verticalGradient(
        listOf(scheme.surfaceContainerHigh, scheme.surfaceContainer),
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(gradient)
            .clickable(onClick = onClick)
            .padding(vertical = 18.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = number.toString(),
            style = MaterialTheme.typography.titleLarge,
            color = scheme.primary,
            fontWeight = FontWeight.SemiBold,
        )
    }
}
