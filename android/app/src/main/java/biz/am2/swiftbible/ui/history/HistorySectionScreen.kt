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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccessTime
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
import biz.am2.swiftbible.data.history.HistoryArticle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistorySectionScreen(
    sectionId: String,
    onBack: () -> Unit,
    onOpenArticle: (String) -> Unit,
) {
    val section = ChurchHistoryContent.allSections.firstOrNull { it.id == sectionId }
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = section?.title.orEmpty(),
                        style = MaterialTheme.typography.titleMedium,
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
        if (section == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Text("Section not found")
            }
            return@Scaffold
        }
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 18.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(top = 6.dp, bottom = 14.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    EraBadge(section.era)
                    Spacer(Modifier.size(10.dp))
                    Text(
                        text = section.title,
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Black,
                        textAlign = TextAlign.Center,
                        color = ManuscriptInk,
                    )
                    Spacer(Modifier.size(6.dp))
                    Text(
                        text = section.subtitle,
                        style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                        textAlign = TextAlign.Center,
                        color = ManuscriptMutedInk,
                    )
                    Spacer(Modifier.size(10.dp))
                    OrnamentDivider(small = true)
                }
            }
            itemsIndexed(section.articles, key = { _, a -> a.id }) { i, article ->
                ArticleRow(article = article, index = i + 1, onClick = { onOpenArticle(article.id) })
            }
            item { Spacer(Modifier.size(48.dp)) }
        }
    }
}

@Composable
private fun ArticleRow(article: HistoryArticle, index: Int, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(10.dp),
        color = ParchmentCard,
        modifier = Modifier
            .fillMaxWidth()
            .border(0.5.dp, ParchmentBorder, RoundedCornerShape(10.dp)),
    ) {
        Column(modifier = Modifier.padding(horizontal = 18.dp, vertical = 16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "%02d".format(index),
                    style = MaterialTheme.typography.labelMedium,
                    color = ManuscriptAccent,
                    fontWeight = FontWeight.Bold,
                )
                Box(
                    modifier = Modifier
                        .width(18.dp)
                        .height(1.dp)
                        .background(ManuscriptAccent.copy(alpha = 0.6f)),
                )
                Text(
                    text = article.era.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = ManuscriptMutedInk,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                Icon(
                    Icons.Filled.AccessTime,
                    contentDescription = null,
                    tint = ManuscriptMutedInk,
                    modifier = Modifier.size(13.dp),
                )
                Spacer(Modifier.size(4.dp))
                Text(
                    text = "${article.estimatedMinutes} min",
                    style = MaterialTheme.typography.labelSmall,
                    color = ManuscriptMutedInk,
                )
            }
            Spacer(Modifier.size(8.dp))
            Text(
                text = article.title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = ManuscriptInk,
            )
            Spacer(Modifier.size(4.dp))
            Text(
                text = article.subtitle,
                style = MaterialTheme.typography.bodySmall.copy(fontStyle = FontStyle.Italic),
                color = ManuscriptMutedInk,
            )
        }
    }
}
