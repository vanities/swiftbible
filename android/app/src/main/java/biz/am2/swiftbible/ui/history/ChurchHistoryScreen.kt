package biz.am2.swiftbible.ui.history

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.data.history.ChurchHistoryContent
import biz.am2.swiftbible.data.history.HistorySection
import biz.am2.swiftbible.ui.theme.BrandGold

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChurchHistoryScreen(
    onBack: () -> Unit,
    onOpenSection: (String) -> Unit,
) {
    val sections = ChurchHistoryContent.allSections
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "History",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = ParchmentBg),
            )
        },
        containerColor = ParchmentBg,
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 18.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            item { Masthead() }
            items(sections, key = { it.id }) { section ->
                SectionCard(
                    section = section,
                    isFeatured = section.id == sections.first().id,
                    onClick = { onOpenSection(section.id) },
                )
            }
            item { Footer() }
            item { Spacer(Modifier.size(48.dp)) }
        }
    }
}

@Composable
private fun Masthead() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        OrnamentDivider()
        Spacer(Modifier.size(10.dp))
        Text(
            text = "A BRIEF HISTORY OF",
            style = MaterialTheme.typography.labelMedium,
            color = ManuscriptAccent,
            fontWeight = FontWeight.SemiBold,
        )
        Text(
            text = "the Christian Church",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Black,
            fontStyle = FontStyle.Italic,
            textAlign = TextAlign.Center,
            color = ManuscriptInk,
        )
        Spacer(Modifier.size(4.dp))
        Text(
            text = "From the patriarchs to today — Israel, the canon,\nthe councils, the splits, and the practices of worship.",
            style = MaterialTheme.typography.bodySmall.copy(fontStyle = FontStyle.Italic),
            textAlign = TextAlign.Center,
            color = ManuscriptMutedInk,
        )
    }
}

@Composable
private fun SectionCard(
    section: HistorySection,
    isFeatured: Boolean,
    onClick: () -> Unit,
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(14.dp),
        color = ParchmentCard,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, ParchmentBorder, RoundedCornerShape(14.dp)),
    ) {
        Column(modifier = Modifier.padding(if (isFeatured) 24.dp else 20.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                EraBadge(section.era)
                Spacer(Modifier.weight(1f))
                Text(text = section.emoji, style = MaterialTheme.typography.titleLarge)
            }
            Spacer(Modifier.size(14.dp))
            Text(
                text = section.title,
                style = if (isFeatured) MaterialTheme.typography.headlineMedium else MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = ManuscriptInk,
            )
            Spacer(Modifier.size(6.dp))
            Text(
                text = section.subtitle,
                style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                color = ManuscriptMutedInk,
            )
            Spacer(Modifier.size(14.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(ManuscriptAccent.copy(alpha = 0.35f)),
            )
            Spacer(Modifier.size(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "${section.articles.size} ARTICLES",
                    style = MaterialTheme.typography.labelSmall,
                    color = ManuscriptMutedInk,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = ManuscriptAccent,
                )
            }
        }
    }
}

@Composable
private fun Footer() {
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        OrnamentDivider(small = true)
        Spacer(Modifier.size(8.dp))
        Text(
            text = "Written from a neutral, descriptive perspective.\nEvery claim links to primary or scholarly sources.",
            style = MaterialTheme.typography.labelSmall.copy(fontStyle = FontStyle.Italic),
            textAlign = TextAlign.Center,
            color = ManuscriptMutedInk,
        )
    }
}

@Composable
internal fun OrnamentDivider(small: Boolean = false) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(
            modifier = Modifier
                .width(if (small) 18.dp else 30.dp)
                .height(1.dp)
                .background(ManuscriptAccent.copy(alpha = if (small) 0.5f else 1f)),
        )
        Text(text = "◆", color = ManuscriptAccent.copy(alpha = if (small) 0.7f else 1f), style = MaterialTheme.typography.labelSmall)
        Box(
            modifier = Modifier
                .width(if (small) 18.dp else 30.dp)
                .height(1.dp)
                .background(ManuscriptAccent.copy(alpha = if (small) 0.5f else 1f)),
        )
    }
}

@Composable
internal fun EraBadge(era: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(modifier = Modifier.width(12.dp).height(1.dp).background(ManuscriptAccent.copy(alpha = 0.8f)))
        Text(
            text = era.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = ManuscriptAccent,
            fontWeight = FontWeight.SemiBold,
        )
        Box(modifier = Modifier.width(12.dp).height(1.dp).background(ManuscriptAccent.copy(alpha = 0.8f)))
    }
}

// Light parchment values; dark values pull from the system Material palette
// so history blends with the rest of the app instead of standing out.
private val ParchmentBgLight = androidx.compose.ui.graphics.Color(0xFFFAF3E0)
private val ParchmentCardLight = androidx.compose.ui.graphics.Color(0xFFFFF8EA)
private val ParchmentBorderLight = androidx.compose.ui.graphics.Color(0x33806239)
private val ManuscriptInkLight = androidx.compose.ui.graphics.Color(0xFF2E1A0B)
private val ManuscriptMutedInkLight = androidx.compose.ui.graphics.Color(0xFF806239)

internal val ParchmentBg: androidx.compose.ui.graphics.Color
    @androidx.compose.runtime.Composable
    @androidx.compose.runtime.ReadOnlyComposable
    get() = if (androidx.compose.foundation.isSystemInDarkTheme()) {
        androidx.compose.material3.MaterialTheme.colorScheme.background
    } else ParchmentBgLight

internal val ParchmentCard: androidx.compose.ui.graphics.Color
    @androidx.compose.runtime.Composable
    @androidx.compose.runtime.ReadOnlyComposable
    get() = if (androidx.compose.foundation.isSystemInDarkTheme()) {
        androidx.compose.material3.MaterialTheme.colorScheme.surfaceContainer
    } else ParchmentCardLight

internal val ParchmentBorder: androidx.compose.ui.graphics.Color
    @androidx.compose.runtime.Composable
    @androidx.compose.runtime.ReadOnlyComposable
    get() = if (androidx.compose.foundation.isSystemInDarkTheme()) {
        androidx.compose.material3.MaterialTheme.colorScheme.outlineVariant
    } else ParchmentBorderLight

internal val ManuscriptInk: androidx.compose.ui.graphics.Color
    @androidx.compose.runtime.Composable
    @androidx.compose.runtime.ReadOnlyComposable
    get() = if (androidx.compose.foundation.isSystemInDarkTheme()) {
        androidx.compose.material3.MaterialTheme.colorScheme.onBackground
    } else ManuscriptInkLight

internal val ManuscriptMutedInk: androidx.compose.ui.graphics.Color
    @androidx.compose.runtime.Composable
    @androidx.compose.runtime.ReadOnlyComposable
    get() = if (androidx.compose.foundation.isSystemInDarkTheme()) {
        androidx.compose.material3.MaterialTheme.colorScheme.onSurfaceVariant
    } else ManuscriptMutedInkLight

internal val ManuscriptAccent = BrandGold
