package biz.am2.swiftbible.ui.search

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SearchOff
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.settings.BrandedEmpty
import biz.am2.swiftbible.ui.settings.EnterAnimation
import biz.am2.swiftbible.ui.settings.StatsBg
import biz.am2.swiftbible.ui.settings.StatsTint

private data class Hit(val book: String, val chapter: Int, val verse: Int, val text: String)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    appVm: AppViewModel,
    onResultClick: (book: String, chapter: Int) -> Unit,
) {
    val bible by appVm.bible.collectAsState()
    var query by remember { mutableStateOf("") }

    val hits by remember(bible, query) {
        derivedStateOf {
            if (query.length < 2) emptyList()
            else bible.allBooks.flatMap { book ->
                book.chapters.flatMap { ch ->
                    ch.paragraphs.mapNotNull { p ->
                        if (p.text.contains(query, ignoreCase = true)) {
                            Hit(book.name, ch.number, p.startingVerse, p.text)
                        } else null
                    }
                }
            }.take(500)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Search",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            TextField(
                value = query,
                onValueChange = { query = it },
                placeholder = { Text("Word or phrase…", color = MaterialTheme.colorScheme.onSurfaceVariant) },
                singleLine = true,
                leadingIcon = {
                    Icon(Icons.Filled.Search, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                },
                colors = TextFieldDefaults.colors(
                    unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainer,
                    focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
                    unfocusedIndicatorColor = Color.Transparent,
                    focusedIndicatorColor = Color.Transparent,
                ),
                shape = RoundedCornerShape(28.dp),
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            )

            when {
                query.length < 2 -> BrandedEmpty(
                    icon = Icons.Filled.Search,
                    tint = StatsTint,
                    bg = StatsBg,
                    title = "Search the Bible",
                    subtitle = "Type a word or phrase to find it across every loaded book.",
                )
                hits.isEmpty() -> BrandedEmpty(
                    icon = Icons.Filled.SearchOff,
                    tint = StatsTint,
                    bg = StatsBg,
                    title = "No matches",
                    subtitle = "Nothing matched “$query”. Try a shorter word or different spelling.",
                )
                else -> EnterAnimation {
                    Column(modifier = Modifier.fillMaxSize()) {
                        Text(
                            text = "${hits.size} result${if (hits.size == 1) "" else "s"}${if (hits.size >= 500) " (truncated)" else ""}",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 20.dp, vertical = 4.dp),
                        )
                        LazyColumn(modifier = Modifier.fillMaxSize()) {
                            items(hits, key = { "${it.book}-${it.chapter}-${it.verse}" }) { hit ->
                                HitRow(hit, query, onClick = { onResultClick(hit.book, hit.chapter) })
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HitRow(hit: Hit, query: String, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 12.dp),
    ) {
        Text(
            text = "${hit.book} ${hit.chapter}:${hit.verse}",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onBackground,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.size(4.dp))
        Text(
            text = highlightedText(hit.text, query),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 5,
        )
    }
}

@Composable
private fun highlightedText(text: String, query: String) = buildAnnotatedString {
    val lower = text.lowercase()
    val q = query.lowercase()
    var i = 0
    while (i < text.length) {
        val idx = lower.indexOf(q, i)
        if (idx == -1) {
            append(text.substring(i))
            return@buildAnnotatedString
        }
        append(text.substring(i, idx))
        withStyle(
            SpanStyle(
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold,
                background = MaterialTheme.colorScheme.primaryContainer,
            )
        ) {
            append(text.substring(idx, idx + q.length))
        }
        i = idx + q.length
    }
}
