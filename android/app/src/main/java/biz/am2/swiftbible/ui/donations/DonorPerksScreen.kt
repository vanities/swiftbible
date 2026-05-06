package biz.am2.swiftbible.ui.donations

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandAccentDark
import biz.am2.swiftbible.ui.theme.BrandAccentLight
import biz.am2.swiftbible.ui.theme.BrandCyan
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandGreen
import biz.am2.swiftbible.ui.theme.BrandPeridot
import biz.am2.swiftbible.ui.theme.BrandRed

/**
 * Mirrors iOS `DonorPerksView`. A small thank-you + a curated palette of
 * accent colors the donor can choose from. The chosen hex propagates through
 * `MaterialTheme.colorScheme.primary` via `SwiftBibleTheme(customAccentHex = …)`.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DonorPerksScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
) {
    val prefs by appVm.prefsState.collectAsState()
    val current = prefs.customAccentHex

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Donor Perks", fontWeight = FontWeight.SemiBold) },
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
                .verticalScroll(rememberScrollState()),
        ) {
            ThankYouCard()

            Spacer(Modifier.size(24.dp))
            SectionHeader("Custom accent color")
            SubText(
                "Changes the color of toggles, links, and active tabs throughout the app.",
            )
            Spacer(Modifier.size(12.dp))

            AccentPalette(
                currentHex = current,
                onPick = { appVm.setCustomAccentHex(it) },
            )

            if (current.isNotBlank()) {
                Spacer(Modifier.size(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                ) {
                    TextButton(onClick = { appVm.setCustomAccentHex("") }) {
                        Text(
                            "Reset to default",
                            color = MaterialTheme.colorScheme.error,
                            fontWeight = FontWeight.SemiBold,
                        )
                    }
                }
            }

            Spacer(Modifier.size(48.dp))
        }
    }
}

@Composable
private fun ThankYouCard() {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 16.dp),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Favorite,
                    contentDescription = null,
                    tint = BrandRed,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    "Thank you",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
            Spacer(Modifier.size(8.dp))
            Text(
                "Your donation helps keep SwiftBible online and free for everyone. " +
                    "Here are some perks as a thank you.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
            )
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text = text.uppercase(),
        modifier = Modifier.padding(start = 20.dp, top = 8.dp, bottom = 4.dp),
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.primary,
        fontWeight = FontWeight.SemiBold,
    )
}

@Composable
private fun SubText(text: String) {
    Text(
        text = text,
        modifier = Modifier.padding(horizontal = 20.dp),
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

private data class Swatch(val hex: String, val color: Color, val name: String)

private val palette: List<Swatch> = listOf(
    Swatch("#00B4A0", BrandAccent, "Brand Teal"),
    Swatch("#00C8B4", BrandAccentLight, "Aqua"),
    Swatch("#007A6D", BrandAccentDark, "Forest Teal"),
    Swatch("#00BFD9", BrandCyan, "Sky Cyan"),
    Swatch("#33CC66", BrandGreen, "Verdant"),
    Swatch("#BFD900", BrandPeridot, "Peridot"),
    Swatch("#D9AD52", BrandGold, "Gold"),
    Swatch("#CC3333", BrandRed, "Crimson"),
    Swatch("#7C5CFF", Color(0xFF7C5CFF), "Royal"),
    Swatch("#E879F9", Color(0xFFE879F9), "Orchid"),
    Swatch("#F97316", Color(0xFFF97316), "Sunset"),
    Swatch("#1E40AF", Color(0xFF1E40AF), "Deep Blue"),
)

@Composable
private fun AccentPalette(currentHex: String, onPick: (String) -> Unit) {
    val rows = palette.chunked(4)
    Column(modifier = Modifier.padding(horizontal = 16.dp)) {
        rows.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
            ) {
                row.forEach { swatch ->
                    SwatchTile(
                        swatch = swatch,
                        selected = swatch.hex.equals(currentHex, ignoreCase = true),
                        onPick = { onPick(swatch.hex) },
                    )
                }
                // Pad short rows so the swatches stay aligned.
                repeat(4 - row.size) {
                    Spacer(Modifier.size(64.dp))
                }
            }
        }
    }
}

@Composable
private fun SwatchTile(swatch: Swatch, selected: Boolean, onPick: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clickable(onClick = onPick)
            .padding(4.dp),
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(swatch.color)
                .border(
                    width = if (selected) 3.dp else 0.dp,
                    color = MaterialTheme.colorScheme.onBackground,
                    shape = CircleShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            if (selected) {
                Icon(
                    Icons.Filled.Check,
                    contentDescription = "Selected",
                    tint = Color.White,
                )
            }
        }
        Spacer(Modifier.size(6.dp))
        Text(
            swatch.name,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
