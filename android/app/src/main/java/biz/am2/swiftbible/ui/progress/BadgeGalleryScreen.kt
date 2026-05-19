package biz.am2.swiftbible.ui.progress

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.data.Analytics
import biz.am2.swiftbible.data.BadgeDefinition
import biz.am2.swiftbible.data.BadgeRegistry
import biz.am2.swiftbible.data.BadgeTier
import biz.am2.swiftbible.data.BadgeTrack
import biz.am2.swiftbible.ui.AppViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BadgeGalleryScreen(appVm: AppViewModel, onBack: () -> Unit) {
    val earnedFlow by appVm.db.earnedBadgeDao().all().collectAsState(initial = emptyList())
    val earnedIds = remember(earnedFlow) { earnedFlow.map { it.badgeId }.toSet() }

    LaunchedEffect(Unit) {
        Analytics.capture(
            Analytics.Event.BadgeGalleryViewed,
            mapOf("earned" to earnedIds.size, "total" to BadgeRegistry.all.size),
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Achievements", fontWeight = FontWeight.SemiBold) },
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            TierLadder(earnedIds = earnedIds)
            CollectiblesSection(earnedIds = earnedIds)
            HiddenSection(earnedIds = earnedIds)
            Spacer(Modifier.size(48.dp))
        }
    }
}

@Composable
private fun TierLadder(earnedIds: Set<String>) {
    SectionHeader("Tiers", "Bronze → Diamond across four tracks")
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        for (track in BadgeTrack.values()) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(track.icon, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.size(6.dp))
                    Text(
                        track.displayName.uppercase(),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
                Spacer(Modifier.size(6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                    for (tier in BadgeTier.values()) {
                        val def = BadgeRegistry.tier(track, tier)
                        BadgeCell(
                            def = def,
                            earned = def.id in earnedIds,
                            revealed = true,
                            nameOverride = tier.displayName,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CollectiblesSection(earnedIds: Set<String>) {
    SectionHeader("Collectibles", "Read meaningful groupings end to end")
    val rows = BadgeRegistry.collectibles.chunked(2)
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        for (row in rows) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                for (def in row) {
                    BadgeCell(
                        def = def,
                        earned = def.id in earnedIds,
                        revealed = true,
                        modifier = Modifier.weight(1f),
                    )
                }
                repeat(2 - row.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun HiddenSection(earnedIds: Set<String>) {
    val earnedHidden = BadgeRegistry.hidden.count { it.id in earnedIds }
    SectionHeader(
        title = "Hidden Achievements",
        subtitle = "$earnedHidden of ${BadgeRegistry.hidden.size} discovered",
    )
    val rows = BadgeRegistry.hidden.chunked(2)
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        for (row in rows) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                for (def in row) {
                    val isEarned = def.id in earnedIds
                    BadgeCell(
                        def = def,
                        earned = isEarned,
                        revealed = isEarned,
                        modifier = Modifier.weight(1f),
                    )
                }
                repeat(2 - row.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String, subtitle: String) {
    Column {
        Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Text(subtitle, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun BadgeCell(
    def: BadgeDefinition,
    earned: Boolean,
    revealed: Boolean,
    nameOverride: String? = null,
    modifier: Modifier = Modifier,
) {
    val circleFill = when {
        !revealed -> Color.Gray.copy(alpha = 0.18f)
        earned -> def.tint.copy(alpha = 0.85f)
        else -> def.tint.copy(alpha = 0.18f)
    }
    val iconColor = if (earned) Color.White else def.tint
    val borderColor = if (earned) def.tint.copy(alpha = 0.6f) else Color.Transparent
    val displayedName = if (!revealed) "Hidden" else (nameOverride ?: def.name)
    val displayedDesc = if (!revealed) "Keep reading to discover" else def.description

    Surface(
        shape = RoundedCornerShape(12.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = modifier.border(1.5.dp, borderColor, RoundedCornerShape(12.dp)),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .size(60.dp)
                    .clip(CircleShape)
                    .background(circleFill),
                contentAlignment = Alignment.Center,
            ) {
                if (revealed) {
                    Icon(def.icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(24.dp))
                } else {
                    Text("?", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.size(8.dp))
            Text(
                text = displayedName,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
                maxLines = 2,
                color = if (revealed) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = displayedDesc,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                maxLines = 2,
            )
            if (earned) {
                Spacer(Modifier.size(4.dp))
                Text(
                    text = "EARNED",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = def.tint,
                )
            }
        }
    }
}
