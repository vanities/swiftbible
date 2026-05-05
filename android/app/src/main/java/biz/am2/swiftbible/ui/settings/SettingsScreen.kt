package biz.am2.swiftbible.ui.settings

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.NavigateNext
import androidx.compose.material.icons.filled.Brightness6
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.ColorLens
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.automirrored.filled.LibraryBooks
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.IconButton
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
    onBack: (() -> Unit)? = null,
) {
    val prefs by appVm.prefsState.collectAsState()

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
                navigationIcon = {
                    if (onBack != null) {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
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
                label = "Hide bars while reading",
                checked = prefs.hideBars,
                onChange = { appVm.setHideBars(it) },
            )

            SectionHeader("Notifications")
            NavRow(Icons.Filled.Notifications, "Devotional Reminder") { onOpen("reminder") }

            SectionHeader("Bible translation")
            VersionRow(prefs.version) { appVm.setVersion(it) }
            ToggleRow(
                label = "Group books by tradition",
                checked = prefs.showThematic,
                onChange = { appVm.setShowThematic(it) },
            )
            NavRow(Icons.Filled.Translate, "About translations") { onOpen("translations") }

            SectionHeader("Library extras")
            ToggleRow("Apocrypha", prefs.showApocrypha) { appVm.setShowApocrypha(it) }
            ToggleRow("Book of Enoch", prefs.showEnoch) { appVm.setShowEnoch(it) }
            ToggleRow("2 Enoch (Secrets of Enoch)", prefs.show2Enoch) { appVm.setShow2Enoch(it) }
            ToggleRow("Book of Jubilees", prefs.showJubilees) { appVm.setShowJubilees(it) }
            ToggleRow("Testaments of the Twelve Patriarchs", prefs.showTestaments) { appVm.setShowTestaments(it) }
            ToggleRow("Didache", prefs.showDidache) { appVm.setShowDidache(it) }
            ToggleRow("1 Clement", prefs.show1Clement) { appVm.setShow1Clement(it) }

            SectionHeader("About")
            NavRow(Icons.AutoMirrored.Filled.LibraryBooks, "Text sources") { onOpen("text_sources") }
            AboutLinks()

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
private fun AboutLinks() {
    val context = androidx.compose.ui.platform.LocalContext.current
    NavRow(Icons.Filled.Email, "Contact us") {
        val intent = android.content.Intent(android.content.Intent.ACTION_SENDTO).apply {
            data = android.net.Uri.parse("mailto:mischke@proton.me?subject=swiftbible%20Android")
        }
        runCatching { context.startActivity(intent) }
    }
    NavRow(Icons.Filled.BugReport, "Report a bug") {
        val intent = android.content.Intent(android.content.Intent.ACTION_SENDTO).apply {
            data = android.net.Uri.parse("mailto:mischke@proton.me?subject=swiftbible%20Android%20Bug")
        }
        runCatching { context.startActivity(intent) }
    }
    NavRow(Icons.Filled.Code, "View source on GitHub") {
        val intent = android.content.Intent(
            android.content.Intent.ACTION_VIEW,
            android.net.Uri.parse("https://github.com/vanities/swiftbible"),
        )
        runCatching { context.startActivity(intent) }
    }
    NavRow(Icons.Filled.Public, "Website") {
        val intent = android.content.Intent(
            android.content.Intent.ACTION_VIEW,
            android.net.Uri.parse("https://am2.biz/swiftbible"),
        )
        runCatching { context.startActivity(intent) }
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
