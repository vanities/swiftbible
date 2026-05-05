package biz.am2.swiftbible.ui.settings

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.NavigateNext
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Brush
import androidx.compose.material.icons.filled.Brightness6
import androidx.compose.material.icons.filled.ColorLens
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.model.Version
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.SectionHeader
import biz.am2.swiftbible.ui.theme.ReadingFont
import biz.am2.swiftbible.ui.theme.ReadingTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    appVm: AppViewModel,
    onOpen: (String) -> Unit,
) {
    val prefs by appVm.prefsState.collectAsState()
    val chaptersRead by appVm.chaptersRead.collectAsState(initial = 0)
    val totalVisits by appVm.totalVisits.collectAsState(initial = 0)

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
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
            // Stats summary
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                biz.am2.swiftbible.ui.components.StatCard(
                    label = "Chapters",
                    value = chaptersRead.toString(),
                    modifier = Modifier.weight(1f),
                )
                biz.am2.swiftbible.ui.components.StatCard(
                    label = "Reads",
                    value = (totalVisits ?: 0).toString(),
                    modifier = Modifier.weight(1f),
                )
            }

            SectionHeader("My library")
            NavRow(Icons.Filled.Brush, "Highlights") { onOpen("highlights") }
            NavRow(Icons.Filled.Edit, "Notes") { onOpen("notes") }
            NavRow(Icons.Filled.Bookmark, "Bookmarks") { onOpen("bookmarks") }
            NavRow(Icons.Filled.History, "Reading history") { onOpen("history") }
            NavRow(Icons.Filled.Layers, "Reading stats") { onOpen("stats") }

            SectionHeader("Translation")
            VersionRow(prefs.version) { appVm.setVersion(it) }
            NavRow(Icons.Filled.Translate, "About translations") { onOpen("translations") }
            NavRow(Icons.AutoMirrored.Filled.LibraryBooks, "Text sources") { onOpen("text_sources") }

            SectionHeader("Reading")
            ThemeRow(prefs.theme) { appVm.setTheme(it) }
            FontRow(prefs.fontFamily) { appVm.setFontFamily(it) }
            FontSizeRow(prefs.fontSize) { appVm.setFontSize(it) }
            ToggleRow(
                label = "Jesus’s words in red",
                checked = prefs.jesusRed,
                onChange = { appVm.setJesusRed(it) },
            )
            ToggleRow(
                label = "Show passage summaries",
                checked = prefs.showSummaries,
                onChange = { appVm.setShowSummaries(it) },
            )
            ToggleRow(
                label = "Group OT/NT by tradition",
                checked = prefs.showThematic,
                onChange = { appVm.setShowThematic(it) },
            )

            SectionHeader("Text sources")
            ToggleRow("Show Apocrypha", prefs.showApocrypha) { appVm.setShowApocrypha(it) }
            ToggleRow("Show Book of Enoch", prefs.showEnoch) { appVm.setShowEnoch(it) }
            ToggleRow("Show Jubilees", prefs.showJubilees) { appVm.setShowJubilees(it) }
            ToggleRow("Show Testaments of the Twelve Patriarchs", prefs.showTestaments) { appVm.setShowTestaments(it) }
            ToggleRow("Show 2 Enoch (Secrets of Enoch)", prefs.show2Enoch) { appVm.setShow2Enoch(it) }
            ToggleRow("Show Didache", prefs.showDidache) { appVm.setShowDidache(it) }
            ToggleRow("Show 1 Clement", prefs.show1Clement) { appVm.setShow1Clement(it) }

            Spacer(Modifier.size(40.dp))
            About()
            Spacer(Modifier.size(96.dp))
        }
    }
}

@Composable
private fun NavRow(icon: ImageVector, title: String, onClick: () -> Unit) {
    Surface(onClick = onClick, color = Color.Transparent, modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(MaterialTheme.colorScheme.surfaceContainer),
                contentAlignment = Alignment.Center,
            ) {
                Icon(icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
            }
            Spacer(Modifier.size(14.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.weight(1f),
            )
            Icon(
                Icons.AutoMirrored.Filled.NavigateNext,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f),
            color = MaterialTheme.colorScheme.onBackground,
        )
        Switch(
            checked = checked,
            onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
                checkedTrackColor = MaterialTheme.colorScheme.primary,
            ),
        )
    }
}

@Composable
private fun VersionRow(current: Version, onPick: (Version) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(MaterialTheme.colorScheme.surfaceContainer),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Translate, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.size(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text("Version", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onBackground)
            Text(current.displayName, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        Box {
            OutlinedButton(onClick = { expanded = true }, shape = RoundedCornerShape(20.dp)) {
                Text(current.shortName)
            }
            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                Version.entries.forEach { v ->
                    DropdownMenuItem(
                        text = {
                            Column {
                                Text(v.shortName, fontWeight = FontWeight.SemiBold)
                                Text(v.displayName, style = MaterialTheme.typography.bodySmall)
                            }
                        },
                        onClick = { onPick(v); expanded = false },
                    )
                }
            }
        }
    }
}

@Composable
private fun ThemeRow(current: ReadingTheme, onPick: (ReadingTheme) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(MaterialTheme.colorScheme.surfaceContainer),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Brightness6, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.size(14.dp))
        Text("Theme", style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onBackground)
        Box {
            OutlinedButton(onClick = { expanded = true }, shape = RoundedCornerShape(20.dp)) {
                Text(current.display)
            }
            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                ReadingTheme.entries.forEach { t ->
                    DropdownMenuItem(text = { Text(t.display) }, onClick = { onPick(t); expanded = false })
                }
            }
        }
    }
}

@Composable
private fun FontRow(current: ReadingFont, onPick: (ReadingFont) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(MaterialTheme.colorScheme.surfaceContainer),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.ColorLens, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.size(14.dp))
        Text("Font", style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onBackground)
        Box {
            OutlinedButton(onClick = { expanded = true }, shape = RoundedCornerShape(20.dp)) {
                Text(current.display.substringBefore(' '))
            }
            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                ReadingFont.entries.forEach { f ->
                    DropdownMenuItem(text = { Text(f.display) }, onClick = { onPick(f); expanded = false })
                }
            }
        }
    }
}

@Composable
private fun FontSizeRow(value: Int, onChange: (Int) -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Font size", style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f), color = MaterialTheme.colorScheme.onBackground)
            Text("$value", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
        }
        Slider(
            value = value.toFloat(),
            onValueChange = { onChange(it.toInt()) },
            valueRange = 12f..30f,
            steps = 17,
        )
    }
}

@Composable
private fun About() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp),
    ) {
        Column {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Info, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.size(8.dp))
                Text("About SwiftBible", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.size(8.dp))
            Text(
                text = "Version 1.0\nOpen source. No ads. No tracking.\nbiz.am2.swiftbible",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
