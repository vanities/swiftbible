package biz.am2.swiftbible.ui.settings

import android.Manifest
import android.app.TimePickerDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import biz.am2.swiftbible.BuildConfig
import biz.am2.swiftbible.notifications.DevotionalReminderScheduler
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandGold
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DevotionalReminderScreen(
    appVm: AppViewModel,
    onBack: () -> Unit,
) {
    val prefs by appVm.prefsState.collectAsState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var permissionDenied by remember { mutableStateOf(false) }
    var justEnabled by remember { mutableStateOf(false) }

    fun hasNotifPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        } else true
    }

    val permLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { granted ->
        if (granted) {
            permissionDenied = false
            appVm.setReminderEnabled(true)
            scope.launch {
                justEnabled = true
                delay(600)
                justEnabled = false
            }
        } else {
            permissionDenied = true
            appVm.setReminderEnabled(false)
        }
    }

    LaunchedEffect(prefs.reminderEnabled) {
        permissionDenied = prefs.reminderEnabled && !hasNotifPermission()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Devotional Reminder",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
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
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Spacer(Modifier.size(0.dp))
            HeroCard(reminderEnabled = prefs.reminderEnabled, justEnabled = justEnabled)

            // Toggle + time controls
            Surface(
                shape = RoundedCornerShape(14.dp),
                color = MaterialTheme.colorScheme.surface,
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
            ) {
                Column {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            Icons.Filled.NotificationsActive,
                            contentDescription = null,
                            tint = BrandAccent,
                            modifier = Modifier.size(22.dp),
                        )
                        Spacer(Modifier.size(12.dp))
                        Text(
                            "Daily Reminder",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.weight(1f),
                        )
                        Switch(
                            checked = prefs.reminderEnabled,
                            onCheckedChange = { wantOn ->
                                if (wantOn) {
                                    if (hasNotifPermission()) {
                                        appVm.setReminderEnabled(true)
                                        scope.launch {
                                            justEnabled = true
                                            delay(600)
                                            justEnabled = false
                                        }
                                    } else {
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                            permLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                        } else {
                                            appVm.setReminderEnabled(true)
                                        }
                                    }
                                } else {
                                    appVm.setReminderEnabled(false)
                                    permissionDenied = false
                                }
                            },
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
                                checkedTrackColor = MaterialTheme.colorScheme.primary,
                            ),
                        )
                    }

                    AnimatedVisibility(
                        visible = prefs.reminderEnabled,
                        enter = fadeIn(),
                        exit = fadeOut(),
                    ) {
                        Column {
                            HorizontalDivider()
                            TimeRow(
                                hour = prefs.reminderHour,
                                minute = prefs.reminderMinute,
                                onPick = { h, m -> appVm.setReminderTime(h, m) },
                            )
                            HorizontalDivider()
                            PresetRow(
                                hour = prefs.reminderHour,
                                minute = prefs.reminderMinute,
                                onPick = { h, m -> appVm.setReminderTime(h, m) },
                            )
                        }
                    }
                }
            }

            if (prefs.reminderEnabled) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.CheckCircle,
                        contentDescription = null,
                        tint = Color(0xFF2E7D32),
                        modifier = Modifier.size(16.dp),
                    )
                    Spacer(Modifier.size(6.dp))
                    Text(
                        "Scheduled daily at ${formatTime(prefs.reminderHour, prefs.reminderMinute)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFF2E7D32),
                    )
                }
            }

            if (permissionDenied) {
                PermissionDeniedCard(onOpen = {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    runCatching { context.startActivity(intent) }
                })
            }

            HowItWorksCard()
            DeveloperNoteCard()

            if (BuildConfig.DEBUG) {
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = MaterialTheme.colorScheme.surface,
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                if (hasNotifPermission()) {
                                    DevotionalReminderScheduler.showNow(context)
                                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    permLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                }
                            }
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Notifications, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                        Spacer(Modifier.size(12.dp))
                        Text("Send Test Notification Now", fontWeight = FontWeight.Medium)
                    }
                }
            }

            Spacer(Modifier.size(48.dp))
        }
    }
}

@Composable
private fun HeroCard(reminderEnabled: Boolean, justEnabled: Boolean) {
    val transition = rememberInfiniteTransition(label = "bell")
    val scale by transition.animateFloat(
        initialValue = 1f,
        targetValue = if (justEnabled) 1.15f else 1.04f,
        animationSpec = infiniteRepeatable(
            animation = tween(1400),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "bellScale",
    )
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(96.dp)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(
                        listOf(BrandGold.copy(alpha = 0.20f), BrandGold.copy(alpha = 0.10f)),
                    )
                )
                .scale(scale),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = if (reminderEnabled) Icons.Filled.NotificationsActive else Icons.Filled.Notifications,
                contentDescription = null,
                tint = BrandGold,
                modifier = Modifier.size(40.dp),
            )
        }
        Spacer(Modifier.size(16.dp))
        Text(
            "Never miss your daily reflection",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.size(8.dp))
        Text(
            "A gentle reminder each day to pause, reflect, and grow in scripture.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun TimeRow(hour: Int, minute: Int, onPick: (Int, Int) -> Unit) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                TimePickerDialog(
                    context,
                    { _, h, m -> onPick(h, m) },
                    hour,
                    minute,
                    false,
                ).show()
            }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "Time",
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f),
        )
        Text(
            formatTime(hour, minute),
            style = MaterialTheme.typography.bodyLarge,
            color = BrandAccent,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun PresetRow(hour: Int, minute: Int, onPick: (Int, Int) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        PresetChip("Morning", 7, 0, hour, minute, onPick, modifier = Modifier.weight(1f))
        PresetChip("Midday", 12, 0, hour, minute, onPick, modifier = Modifier.weight(1f))
        PresetChip("Evening", 21, 0, hour, minute, onPick, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun PresetChip(
    label: String,
    h: Int,
    m: Int,
    selectedH: Int,
    selectedM: Int,
    onPick: (Int, Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val selected = selectedH == h && selectedM == m
    val bg = if (selected) BrandAccent.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceContainer
    val fg = if (selected) BrandAccent else MaterialTheme.colorScheme.onSurfaceVariant
    Surface(
        onClick = { onPick(h, m) },
        shape = RoundedCornerShape(50),
        color = bg,
        modifier = modifier.border(
            1.dp,
            if (selected) BrandAccent.copy(alpha = 0.4f) else Color.Transparent,
            RoundedCornerShape(50),
        ),
    ) {
        Box(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                label,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = fg,
            )
        }
    }
}

@Composable
private fun PermissionDeniedCard(onOpen: () -> Unit) {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = Color(0xFFFFF4E0),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, Color(0xFFFFB74D).copy(alpha = 0.5f), RoundedCornerShape(14.dp)),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.Warning, contentDescription = null, tint = Color(0xFFE65100))
            Spacer(Modifier.size(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    "Notifications Disabled",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    "Enable notifications in your device settings to receive reminders.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.size(8.dp))
            Button(onClick = onOpen) { Text("Open") }
        }
    }
}

@Composable
private fun HowItWorksCard() {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = BrandAccent, modifier = Modifier.size(18.dp))
                Spacer(Modifier.size(8.dp))
                Text("How it works", fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.size(8.dp))
            Text(
                "Each day, a new devotional is generated from scripture. Set a reminder to build it into your routine — even a few minutes of daily reflection adds up.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun DeveloperNoteCard() {
    Surface(
        shape = RoundedCornerShape(14.dp),
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(14.dp)),
    ) {
        Row(modifier = Modifier.padding(16.dp)) {
            Box(
                modifier = Modifier
                    .size(width = 3.dp, height = 56.dp)
                    .background(BrandGold.copy(alpha = 0.6f), RoundedCornerShape(2.dp)),
            )
            Spacer(Modifier.size(12.dp))
            Column {
                Text(
                    "I like to read the daily devotional before bed during my wind-down routine. It's a nice way to reflect on the day and settle in with something meaningful.",
                    style = MaterialTheme.typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(Modifier.size(6.dp))
                Text(
                    "— Adam, developer",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun HorizontalDivider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .size(1.dp)
            .background(MaterialTheme.colorScheme.outlineVariant),
    )
}

private fun formatTime(hour: Int, minute: Int): String {
    val h12 = when {
        hour == 0 -> 12
        hour > 12 -> hour - 12
        else -> hour
    }
    val ampm = if (hour < 12) "AM" else "PM"
    return String.format(Locale.US, "%d:%02d %s", h12, minute, ampm)
}
