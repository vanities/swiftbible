package biz.am2.swiftbible.ui.bible

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import biz.am2.swiftbible.data.ResolvedBookIntro
import biz.am2.swiftbible.data.SummariesSourceInfo
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.GradientDivider

/**
 * The "About this book" screen reached from the frame above the chapter list.
 * Shows the longer-form introduction (authorship, date, historical setting,
 * and purpose) for a book, drawn from the user's selected summary source with
 * a fallback chain, and attributes whichever source supplied it.
 *
 * Mirrors `BookIntroView` on iOS. When no source covers the book (only
 * possible via stale navigation), the short catalog description stands in.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookIntroScreen(
    appVm: AppViewModel,
    bookName: String,
    onBack: () -> Unit,
) {
    val prefs by appVm.prefsState.collectAsState()
    val book = appVm.bookByName(bookName)
    var resolved by remember(bookName) { mutableStateOf<ResolvedBookIntro?>(null) }
    var loaded by remember(bookName) { mutableStateOf(false) }

    LaunchedEffect(bookName) {
        resolved = appVm.bookIntroduction(bookName)
        loaded = true
        biz.am2.swiftbible.data.Analytics.capture(
            biz.am2.swiftbible.data.Analytics.Event.BookIntroViewed,
            mapOf("book" to bookName, "source" to (resolved?.attribution?.shortName ?: "none")),
        )
    }

    Scaffold(
        topBar = {
            // No app-bar title: the in-content "Introduction to <book>" header is
            // the screen's title and respects the reader's font, which a system
            // app-bar title can't (mirrors BookIntroView on iOS).
            TopAppBar(
                title = {},
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
        if (!loaded) {
            Box(modifier = Modifier.fillMaxSize().padding(padding))
            return@Scaffold
        }

        val intro = resolved
        val fallbackParagraphs = listOfNotNull(book?.description?.takeIf { it.isNotBlank() })
        if (intro == null && fallbackParagraphs.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Introduction not available")
            }
            return@Scaffold
        }

        IntroBody(
            title = intro?.intro?.title ?: bookName,
            paragraphs = intro?.intro?.paragraphs ?: fallbackParagraphs,
            attribution = intro?.attribution,
            fontSize = prefs.fontSize,
            fontFamily = prefs.fontFamily.family,
            modifier = Modifier.fillMaxSize().padding(padding),
        )
    }
}

@Composable
private fun IntroBody(
    title: String,
    paragraphs: List<String>,
    attribution: SummariesSourceInfo?,
    fontSize: Int,
    fontFamily: FontFamily,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        item {
            Text(
                text = title,
                fontSize = (fontSize + 6).sp,
                fontFamily = fontFamily,
                fontWeight = FontWeight.Bold,
                lineHeight = (fontSize + 6).sp * 1.3f,
                color = MaterialTheme.colorScheme.onBackground,
            )
        }
        items(paragraphs.size) { index ->
            Text(
                text = paragraphs[index],
                fontSize = fontSize.sp,
                fontFamily = fontFamily,
                lineHeight = fontSize.sp * 1.55f,
                color = MaterialTheme.colorScheme.onBackground,
            )
        }
        if (attribution != null) {
            item { Attribution(attribution) }
        }
        item { Spacer(Modifier.size(48.dp)) }
    }
}

@Composable
private fun Attribution(source: SummariesSourceInfo) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        GradientDivider(modifier = Modifier.padding(bottom = 4.dp))
        Text(
            text = source.name,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = "${source.attribution} · ${source.license}",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
