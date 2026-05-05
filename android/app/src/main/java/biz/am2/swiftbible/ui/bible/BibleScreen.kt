package biz.am2.swiftbible.ui.bible

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
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.model.Book
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.SectionHeader

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BibleScreen(
    appVm: AppViewModel,
    onBookClick: (String) -> Unit,
    onResume: (String, Int) -> Unit,
) {
    val bible by appVm.bible.collectAsState()
    val prefs by appVm.prefsState.collectAsState()
    var query by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Bible (${bible.version.shortName})",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                    )
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
            SearchField(query = query, onChange = { query = it })

            if (bible.loading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                }
            } else {
                val titles = SectionTitles.fromStrings()
                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    if (prefs.lastBook != null && query.isBlank()) {
                        item(key = "resume") {
                            ResumeCard(
                                book = prefs.lastBook!!,
                                chapter = prefs.lastChapter,
                                onClick = { onResume(prefs.lastBook!!, prefs.lastChapter) },
                            )
                        }
                    }
                    bookSection(titles.ot, filter(bible.oldTestament, query), onBookClick)
                    bookSection(titles.nt, filter(bible.newTestament, query), onBookClick)
                    if (bible.apocrypha.isNotEmpty()) bookSection(titles.apocrypha, filter(bible.apocrypha, query), onBookClick)
                    if (bible.enoch.isNotEmpty()) bookSection(titles.enoch, filter(bible.enoch, query), onBookClick)
                    if (bible.jubilees.isNotEmpty()) bookSection(titles.jubilees, filter(bible.jubilees, query), onBookClick)
                    if (bible.testaments.isNotEmpty()) bookSection(titles.testaments, filter(bible.testaments, query), onBookClick)
                    if (bible.secondEnoch.isNotEmpty()) bookSection(titles.secondEnoch, filter(bible.secondEnoch, query), onBookClick)
                    if (bible.didache.isNotEmpty()) bookSection(titles.didache, filter(bible.didache, query), onBookClick)
                    if (bible.firstClement.isNotEmpty()) bookSection(titles.firstClement, filter(bible.firstClement, query), onBookClick)
                    item(key = "footer_spacer") { Spacer(Modifier.height(72.dp)) }
                }
            }
        }
    }
}

@Composable
private fun SearchField(query: String, onChange: (String) -> Unit) {
    TextField(
        value = query,
        onValueChange = onChange,
        placeholder = { Text("Search books…", color = MaterialTheme.colorScheme.onSurfaceVariant) },
        singleLine = true,
        leadingIcon = {
            Icon(
                Icons.Filled.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
        colors = TextFieldDefaults.colors(
            unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainer,
            focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
            unfocusedIndicatorColor = Color.Transparent,
            focusedIndicatorColor = Color.Transparent,
            disabledIndicatorColor = Color.Transparent,
        ),
        shape = RoundedCornerShape(28.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
    )
}

@Composable
private fun ResumeCard(book: String, chapter: Int, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.PlayArrow,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                )
            }
            Spacer(Modifier.size(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Continue reading",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f),
                )
                Text(
                    text = "$book $chapter",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
        }
    }
}

@Composable
private fun BookListItem(book: Book, onClick: (String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick(book.name) }
            .padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = book.name,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onBackground,
            )
            if (book.description.isNotBlank()) {
                Text(
                    text = book.description,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Light,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                )
            }
        }
        Icon(
            Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
        )
    }
}

private data class SectionTitles(
    val ot: String,
    val nt: String,
    val apocrypha: String,
    val enoch: String,
    val jubilees: String,
    val testaments: String,
    val secondEnoch: String,
    val didache: String,
    val firstClement: String,
) {
    companion object {
        @Composable
        fun fromStrings() = SectionTitles(
            ot = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_old_testament),
            nt = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_new_testament),
            apocrypha = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_apocrypha),
            enoch = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_enoch),
            jubilees = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_jubilees),
            testaments = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_testaments),
            secondEnoch = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_2enoch),
            didache = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_didache),
            firstClement = androidx.compose.ui.res.stringResource(biz.am2.swiftbible.R.string.section_1clement),
        )
    }
}

private fun filter(books: List<Book>, query: String): List<Book> =
    if (query.isBlank()) books else books.filter { it.name.contains(query, ignoreCase = true) }

private fun LazyListScope.bookSection(
    title: String,
    books: List<Book>,
    onBookClick: (String) -> Unit,
) {
    if (books.isEmpty()) return
    item(key = "header_$title") { SectionHeader(title) }
    items(books, key = { "${title}_${it.name}" }) { book ->
        BookListItem(book = book, onClick = onBookClick)
    }
}
