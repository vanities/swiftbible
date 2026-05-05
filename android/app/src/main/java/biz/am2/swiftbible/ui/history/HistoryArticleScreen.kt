package biz.am2.swiftbible.ui.history

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.OpenInNew
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import biz.am2.swiftbible.data.history.BodyBlock
import biz.am2.swiftbible.data.history.ChurchHistoryContent
import biz.am2.swiftbible.data.history.HistoryArticle
import biz.am2.swiftbible.data.history.HistorySource
import biz.am2.swiftbible.data.history.PullQuote
import biz.am2.swiftbible.data.history.SourceKind
import biz.am2.swiftbible.data.history.TimelineEntry
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandRedDark

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryArticleScreen(
    articleId: String,
    onBack: () -> Unit,
    onOpenArticle: (String) -> Unit,
) {
    val article = ChurchHistoryContent.article(articleId)
    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
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
        if (article == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Article not found")
            }
            return@Scaffold
        }
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 22.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            item { Header(article) }
            article.body.forEachIndexed { index, block ->
                item(key = "body-$index") { BodyBlockView(block, isOpening = index == 0) }
            }
            if (article.pullQuotes.isNotEmpty()) {
                item { Spacer(Modifier.size(2.dp)) }
                article.pullQuotes.forEach { q ->
                    item(key = "quote-${q.attribution}-${q.text.hashCode()}") { PullQuoteView(q) }
                }
            }
            if (article.sources.isNotEmpty()) {
                item { SectionLabel("Sources") }
                article.sources.forEach { s ->
                    item(key = "src-${s.title}") { SourceLink(s) }
                }
            }
            if (article.related.isNotEmpty()) {
                item { SectionLabel("Related") }
                article.related.forEach { id ->
                    val r = ChurchHistoryContent.article(id) ?: return@forEach
                    item(key = "rel-$id") { RelatedRow(r, onClick = { onOpenArticle(id) }) }
                }
            }
            item { Colophon() }
            item { Spacer(Modifier.size(48.dp)) }
        }
    }
}

@Composable
private fun Header(article: HistoryArticle) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        EraBadge(article.era)
        Spacer(Modifier.size(12.dp))
        Text(
            text = article.title,
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            color = ManuscriptInk,
        )
        Spacer(Modifier.size(8.dp))
        Text(
            text = article.subtitle,
            style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
            textAlign = TextAlign.Center,
            color = ManuscriptMutedInk,
        )
        Spacer(Modifier.size(10.dp))
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Filled.AccessTime, contentDescription = null, tint = ManuscriptMutedInk, modifier = Modifier.size(13.dp))
            Text(
                text = "${article.estimatedMinutes} min read",
                style = MaterialTheme.typography.labelSmall.copy(fontStyle = FontStyle.Italic),
                color = ManuscriptMutedInk,
            )
        }
        Spacer(Modifier.size(8.dp))
        OrnamentDivider()
    }
}

@Composable
private fun BodyBlockView(block: BodyBlock, isOpening: Boolean) {
    when (block) {
        is BodyBlock.Paragraph -> Paragraph(block.text, isOpening)
        is BodyBlock.Heading -> Heading(block.text)
        is BodyBlock.Quote -> InlineQuote(block.text, block.attribution)
        is BodyBlock.BulletList -> BulletList(block.items)
        is BodyBlock.Timeline -> TimelineList(block.entries)
        is BodyBlock.Divider -> OrnamentDivider(small = true)
    }
}

@Composable
private fun Paragraph(text: String, isOpening: Boolean) {
    if (isOpening && text.isNotBlank()) {
        Row(verticalAlignment = Alignment.Top) {
            Text(
                text = text.first().toString(),
                fontSize = 56.sp,
                fontWeight = FontWeight.Black,
                color = ManuscriptAccent,
                modifier = Modifier.padding(end = 6.dp, top = (-4).dp),
            )
            Text(
                text = text.drop(1),
                style = MaterialTheme.typography.bodyLarge.copy(lineHeight = 26.sp),
                color = ManuscriptInk,
            )
        }
    } else {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge.copy(lineHeight = 26.sp),
            color = ManuscriptInk,
        )
    }
}

@Composable
private fun Heading(text: String) {
    Column(modifier = Modifier.padding(top = 6.dp)) {
        Text(
            text = text.uppercase(),
            style = MaterialTheme.typography.labelLarge,
            color = ManuscriptAccent,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.size(4.dp))
        Box(
            modifier = Modifier
                .width(32.dp)
                .height(1.dp)
                .background(ManuscriptAccent.copy(alpha = 0.6f)),
        )
    }
}

@Composable
private fun InlineQuote(text: String, attribution: String) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .width(2.dp)
                .background(ManuscriptAccent.copy(alpha = 0.6f)),
        )
        Spacer(Modifier.size(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "“$text”",
                style = MaterialTheme.typography.bodyLarge.copy(fontStyle = FontStyle.Italic, lineHeight = 24.sp),
                color = ManuscriptInk,
            )
            Spacer(Modifier.size(8.dp))
            Text(
                text = "— $attribution",
                style = MaterialTheme.typography.bodySmall,
                color = ManuscriptMutedInk,
            )
        }
    }
}

@Composable
private fun BulletList(items: List<String>) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items.forEach { item ->
            Row(verticalAlignment = Alignment.Top) {
                Text(
                    text = "•",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = ManuscriptAccent,
                    modifier = Modifier.padding(end = 8.dp),
                )
                Text(
                    text = item,
                    style = MaterialTheme.typography.bodyMedium.copy(lineHeight = 22.sp),
                    color = ManuscriptInk,
                )
            }
        }
    }
}

@Composable
private fun TimelineList(entries: List<TimelineEntry>) {
    Column {
        entries.forEachIndexed { i, entry ->
            Row(verticalAlignment = Alignment.Top) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(14.dp)) {
                    Box(
                        modifier = Modifier
                            .padding(top = 6.dp)
                            .size(8.dp)
                            .clip(androidx.compose.foundation.shape.CircleShape)
                            .background(ManuscriptAccent),
                    )
                    if (i < entries.size - 1) {
                        Box(
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .width(1.dp)
                                .background(ManuscriptAccent.copy(alpha = 0.35f))
                                .height(40.dp),
                        )
                    }
                }
                Spacer(Modifier.size(14.dp))
                Column(modifier = Modifier.padding(bottom = 14.dp)) {
                    Text(
                        text = entry.year,
                        style = MaterialTheme.typography.labelMedium,
                        color = ManuscriptAccent,
                        fontWeight = FontWeight.Bold,
                    )
                    Text(
                        text = entry.event,
                        style = MaterialTheme.typography.bodyMedium.copy(lineHeight = 22.sp),
                        color = ManuscriptInk,
                    )
                }
            }
        }
    }
}

@Composable
private fun PullQuoteView(quote: PullQuote) {
    Box(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .height(140.dp)
                .background(ManuscriptAccent),
        )
        Column(
            modifier = Modifier
                .padding(start = 14.dp, end = 14.dp, top = 4.dp, bottom = 4.dp)
                .fillMaxWidth()
                .background(BrandGoldLight.copy(alpha = 0.30f), RoundedCornerShape(6.dp))
                .padding(horizontal = 16.dp, vertical = 18.dp),
        ) {
            Text(
                text = "“",
                fontSize = 56.sp,
                fontWeight = FontWeight.Bold,
                color = ManuscriptAccent.copy(alpha = 0.55f),
                modifier = Modifier.padding(bottom = (-12).dp),
            )
            Text(
                text = quote.text,
                style = MaterialTheme.typography.titleMedium.copy(fontStyle = FontStyle.Italic, lineHeight = 26.sp),
                color = ManuscriptInk,
            )
            Spacer(Modifier.size(12.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .width(20.dp)
                        .height(1.dp)
                        .background(ManuscriptAccent),
                )
                Spacer(Modifier.size(8.dp))
                Column {
                    Text(
                        text = quote.attribution.uppercase(),
                        style = MaterialTheme.typography.labelSmall,
                        color = ManuscriptAccent,
                        fontWeight = FontWeight.SemiBold,
                    )
                    quote.context?.let { ctx ->
                        Text(
                            text = ctx,
                            style = MaterialTheme.typography.labelSmall.copy(fontStyle = FontStyle.Italic),
                            color = ManuscriptMutedInk,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = text.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = ManuscriptAccent,
            fontWeight = FontWeight.Bold,
        )
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(ManuscriptAccent.copy(alpha = 0.4f)),
        )
    }
}

@Composable
private fun SourceLink(source: HistorySource) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val clickable = source.url != null
    val outerModifier = if (clickable) {
        Modifier.fillMaxWidth().clickable {
            val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(source.url))
            runCatching { context.startActivity(intent) }
        }
    } else {
        Modifier.fillMaxWidth()
    }
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = ParchmentCard,
        modifier = outerModifier.border(0.5.dp, ParchmentBorder, RoundedCornerShape(8.dp)),
    ) {
        Row(modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.Top) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(badgeColor(source.kind))
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            ) {
                Text(
                    text = source.kind.label.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                )
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = source.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = ManuscriptInk,
                )
                source.author?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.labelSmall.copy(fontStyle = FontStyle.Italic),
                        color = ManuscriptMutedInk,
                    )
                }
                source.note?.let {
                    Text(text = it, style = MaterialTheme.typography.labelSmall, color = ManuscriptMutedInk)
                }
            }
            if (clickable) {
                Spacer(Modifier.size(4.dp))
                Icon(
                    Icons.Filled.OpenInNew,
                    contentDescription = null,
                    tint = ManuscriptAccent,
                    modifier = Modifier.size(14.dp).padding(top = 2.dp),
                )
            }
        }
    }
}

@Composable
private fun RelatedRow(article: HistoryArticle, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(8.dp),
        color = ParchmentCard,
        modifier = Modifier
            .fillMaxWidth()
            .border(0.5.dp, ParchmentBorder, RoundedCornerShape(8.dp)),
    ) {
        Row(modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = article.title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = ManuscriptInk)
                Text(
                    text = article.subtitle,
                    style = MaterialTheme.typography.labelSmall.copy(fontStyle = FontStyle.Italic),
                    color = ManuscriptMutedInk,
                )
            }
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, tint = ManuscriptAccent)
        }
    }
}

@Composable
private fun Colophon() {
    Column(modifier = Modifier.fillMaxWidth().padding(top = 12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        OrnamentDivider(small = true)
        Spacer(Modifier.size(6.dp))
        Text(
            text = "Fin.",
            style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
            color = ManuscriptMutedInk,
        )
    }
}

private fun badgeColor(kind: SourceKind): Color = when (kind) {
    SourceKind.PRIMARY -> BrandRedDark
    SourceKind.SCHOLARLY -> Color(0xFF2E1F14)
    SourceKind.ENCYCLOPEDIA -> BrandAccent
    SourceKind.SCRIPTURE -> BrandGoldLight2
}

private val BrandGoldLight = Color(0xFFFFEDBA)
private val BrandGoldLight2 = Color(0xFFD9AD52)
