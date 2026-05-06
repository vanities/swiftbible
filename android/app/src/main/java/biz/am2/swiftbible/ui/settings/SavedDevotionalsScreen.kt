package biz.am2.swiftbible.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.data.SavedDevotionalEntity
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.MarkdownText

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedDevotionalsScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
) {
    val list by appVm.savedDevotionals.collectAsState(initial = emptyList())
    var openDevotional by remember { mutableStateOf<SavedDevotionalEntity?>(null) }
    var confirmDelete by remember { mutableStateOf<SavedDevotionalEntity?>(null) }

    LibraryFrame(title = "Saved Devotionals", count = list.size, onBack = onBack) {
        if (list.isEmpty()) {
            BrandedEmpty(
                icon = Icons.Filled.Favorite,
                tint = DevotionalTint,
                bg = DevotionalBg,
                title = "No saved devotionals yet",
                subtitle = "Tap the heart on any devotional to save it for later.",
            )
        } else EnterAnimation {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(list, key = { it.id }) { d ->
                    SavedRow(
                        d = d,
                        onTap = { openDevotional = d },
                        onDelete = { confirmDelete = d },
                    )
                }
            }
        }
    }

    openDevotional?.let { d ->
        AlertDialog(
            onDismissRequest = { openDevotional = null },
            title = {
                Column {
                    Text(d.forDate, style = MaterialTheme.typography.labelMedium, color = DevotionalTint, fontWeight = FontWeight.SemiBold)
                    if (!d.anchorVerse.isNullOrBlank()) {
                        Text(d.anchorVerse, fontWeight = FontWeight.SemiBold)
                    }
                }
            },
            text = {
                Column(modifier = Modifier.fillMaxWidth()) {
                    MarkdownText(
                        raw = biz.am2.swiftbible.ui.components.stripJesusTags(d.message),
                        bodyStyle = TextStyle(
                            fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                            fontSize = 15.sp(),
                            lineHeight = 22.sp(),
                            color = MaterialTheme.colorScheme.onSurface,
                        ),
                        onLinkClick = {},
                    )
                }
            },
            confirmButton = { TextButton(onClick = { openDevotional = null }) { Text("Close") } },
        )
    }

    confirmDelete?.let { d ->
        AlertDialog(
            onDismissRequest = { confirmDelete = null },
            title = { Text("Remove from saved?") },
            text = { Text("This will remove the devotional for ${d.forDate} from your saved list.") },
            confirmButton = {
                TextButton(onClick = {
                    appVm.unsaveDevotional(d.forDate)
                    confirmDelete = null
                }) { Text("Remove", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = null }) { Text("Cancel") } },
        )
    }
}

@Composable
private fun SavedRow(
    d: SavedDevotionalEntity,
    onTap: () -> Unit,
    onDelete: () -> Unit,
) {
    Surface(
        onClick = onTap,
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(DevotionalBg),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.Favorite,
                    contentDescription = null,
                    tint = DevotionalTint,
                    modifier = Modifier.size(20.dp),
                )
            }
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(d.forDate, style = MaterialTheme.typography.labelMedium, color = DevotionalTint, fontWeight = FontWeight.SemiBold)
                if (!d.anchorVerse.isNullOrBlank()) {
                    Text(d.anchorVerse, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                }
                if (!d.seriesName.isNullOrBlank()) {
                    Text(d.seriesName, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Filled.Delete, contentDescription = "Remove", tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

private fun Int.sp() = androidx.compose.ui.unit.TextUnit(this.toFloat(), androidx.compose.ui.unit.TextUnitType.Sp)
