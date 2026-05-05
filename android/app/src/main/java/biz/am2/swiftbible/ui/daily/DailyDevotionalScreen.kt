package biz.am2.swiftbible.ui.daily

import android.app.DatePickerDialog
import android.content.Intent
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.data.Analytics
import biz.am2.swiftbible.data.DailyDevotional
import biz.am2.swiftbible.data.DevotionalRepository
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.components.MarkdownText
import biz.am2.swiftbible.ui.settings.BrandedEmpty
import biz.am2.swiftbible.ui.settings.DevotionalBg
import biz.am2.swiftbible.ui.settings.DevotionalTint
import biz.am2.swiftbible.ui.settings.EnterAnimation
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Calendar

private sealed class DevState {
    data object Loading : DevState()
    data class Loaded(val devotional: DailyDevotional) : DevState()
    data class None(val message: String? = null) : DevState()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DailyDevotionalScreen(
    appVm: AppViewModel,
    onOpenChapter: (String, Int) -> Unit,
) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var selectedDate by remember { mutableStateOf(LocalDate.now()) }
    var state by remember { mutableStateOf<DevState>(DevState.Loading) }
    var saved by remember { mutableStateOf(false) }

    val savedList by appVm.savedDevotionals.collectAsState(initial = emptyList())

    fun load(date: LocalDate) {
        scope.launch {
            state = DevState.Loading
            saved = false
            when (val r = appVm.fetchDevotional(date)) {
                is DevotionalRepository.Result.Success -> {
                    state = DevState.Loaded(r.devotional)
                    Analytics.capture(
                        Analytics.Event.DevotionalViewed,
                        mapOf("date" to r.devotional.for_date, "source" to "network")
                    )
                }
                is DevotionalRepository.Result.NotFound -> state = DevState.None()
                is DevotionalRepository.Result.Failure -> state = DevState.None(r.message)
            }
            saved = appVm.savedDevotionalForDate(date) != null
        }
    }
    LaunchedEffect(selectedDate) { load(selectedDate) }
    LaunchedEffect(savedList, selectedDate) {
        saved = savedList.any { it.forDate == selectedDate.toString() }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Devotional", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.SemiBold)
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.background),
            )
        },
        containerColor = MaterialTheme.colorScheme.background,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            DateBar(
                date = selectedDate,
                onPickDate = {
                    val cal = Calendar.getInstance()
                    cal.set(selectedDate.year, selectedDate.monthValue - 1, selectedDate.dayOfMonth)
                    DatePickerDialog(
                        ctx,
                        { _, y, m, d -> selectedDate = LocalDate.of(y, m + 1, d) },
                        cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), cal.get(Calendar.DAY_OF_MONTH),
                    ).show()
                },
                onToday = { selectedDate = LocalDate.now() },
                isFavorite = saved,
                onToggleFavorite = {
                    val current = (state as? DevState.Loaded)?.devotional ?: return@DateBar
                    if (saved) appVm.unsaveDevotional(current.for_date)
                    else appVm.saveDevotional(current)
                    saved = !saved
                },
                favoriteEnabled = state is DevState.Loaded,
                isToday = selectedDate == LocalDate.now(),
            )

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 8.dp),
            ) {
                when (val s = state) {
                    is DevState.Loading -> Loading()
                    is DevState.Loaded -> EnterAnimation {
                        Loaded(
                            devotional = s.devotional,
                            bodyStyle = TextStyle(
                                fontFamily = MaterialTheme.typography.bodyLarge.fontFamily,
                                fontSize = 17.sp(),
                                lineHeight = 26.sp(),
                                color = MaterialTheme.colorScheme.onSurface,
                            ),
                            onLinkClick = { url ->
                                handleVerseLink(url)?.let { (book, chapter, _) -> onOpenChapter(book, chapter) }
                            },
                            onOpenChapter = onOpenChapter,
                            onShare = { share(ctx, s.devotional) },
                        )
                    }
                    is DevState.None -> NoDevotional(date = selectedDate, message = s.message)
                }
                Spacer(Modifier.size(96.dp))
            }
        }
    }
}

@Composable
private fun DateBar(
    date: LocalDate,
    onPickDate: () -> Unit,
    onToday: () -> Unit,
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    favoriteEnabled: Boolean,
    isToday: Boolean,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(MaterialTheme.colorScheme.surfaceContainer)
                .clickable(onClick = onPickDate)
                .padding(horizontal = 12.dp, vertical = 8.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.CalendarToday,
                    contentDescription = "Pick date",
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    text = date.format(DateTimeFormatter.ofPattern("MMM d, yyyy")),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
        }
        Spacer(Modifier.size(8.dp))
        IconButton(onClick = onToday, enabled = !isToday) {
            Icon(Icons.Filled.Today, contentDescription = "Today")
        }
        Spacer(Modifier.weight(1f))
        IconButton(onClick = onToggleFavorite, enabled = favoriteEnabled) {
            Icon(
                if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                contentDescription = if (isFavorite) "Saved" else "Save",
                tint = if (isFavorite) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun Loading() {
    Box(modifier = Modifier.fillMaxSize().padding(top = 80.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.size(16.dp))
            Text("Loading devotional…", color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun Loaded(
    devotional: DailyDevotional,
    bodyStyle: TextStyle,
    onLinkClick: (String) -> Unit,
    onOpenChapter: (String, Int) -> Unit,
    onShare: () -> Unit,
) {
    Column {
        if (!devotional.series_name.isNullOrBlank()) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(MaterialTheme.colorScheme.secondaryContainer)
                    .padding(horizontal = 12.dp, vertical = 6.dp),
            ) {
                Text(
                    text = "${devotional.series_name}${devotional.series_part?.let { " · Part $it" } ?: ""}",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            Spacer(Modifier.size(8.dp))
        }
        if (!devotional.holiday_name.isNullOrBlank()) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(MaterialTheme.colorScheme.primaryContainer)
                    .padding(horizontal = 12.dp, vertical = 6.dp),
            ) {
                Text(
                    text = devotional.holiday_name,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            Spacer(Modifier.size(12.dp))
        }
        if (!devotional.anchor_verse.isNullOrBlank()) {
            val parsed = remember(devotional.anchor_verse) { parseReference(devotional.anchor_verse) }
            val anchorText = "${devotional.for_date} — ${devotional.anchor_verse}"
            val anchorModifier = if (parsed != null) {
                Modifier
                    .clickable { onOpenChapter(parsed.first, parsed.second) }
                    .padding(bottom = 12.dp)
            } else {
                Modifier.padding(bottom = 12.dp)
            }
            Text(
                text = anchorText,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = if (parsed != null) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onBackground,
                modifier = anchorModifier,
            )
        }
        MarkdownText(
            raw = devotional.message,
            bodyStyle = bodyStyle,
            onLinkClick = onLinkClick,
        )
    }
}

@Composable
private fun NoDevotional(date: LocalDate, message: String?) {
    val subtitle = if (date.isAfter(LocalDate.now())) {
        "Come back on ${date.format(DateTimeFormatter.ofPattern("MMMM d"))} — your devotional will be waiting."
    } else if (message != null) {
        "Couldn't load: $message"
    } else "We may have missed this one. Try a different date."
    BrandedEmpty(
        icon = Icons.Filled.AutoAwesome,
        tint = DevotionalTint,
        bg = DevotionalBg,
        title = "No devotional for this day",
        subtitle = subtitle,
    )
}

private fun handleVerseLink(url: String): Triple<String, Int, Int>? {
    if (!url.startsWith("swiftbible://verse")) return null
    val u = android.net.Uri.parse(url)
    val book = u.getQueryParameter("book") ?: return null
    val chapter = u.getQueryParameter("chapter")?.toIntOrNull() ?: return null
    val verse = u.getQueryParameter("verse")?.toIntOrNull() ?: 1
    return Triple(book, chapter, verse)
}

private val REFERENCE_REGEX = Regex("""^([1-3]?\s?[A-Za-z]+(?:\s[A-Za-z]+)*?)\s+(\d+)(?::\d+)?""")

private fun parseReference(raw: String): Pair<String, Int>? {
    val match = REFERENCE_REGEX.find(raw.trim()) ?: return null
    val book = match.groupValues[1].replace(Regex("""\s+"""), " ").trim()
    val chapter = match.groupValues[2].toIntOrNull() ?: return null
    return book to chapter
}

private fun share(ctx: android.content.Context, devotional: DailyDevotional) {
    val text = (devotional.anchor_verse?.let { "$it\n\n" } ?: "") + devotional.message
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    ctx.startActivity(Intent.createChooser(intent, "Share devotional"))
}

private fun Int.sp() = androidx.compose.ui.unit.TextUnit(this.toFloat(), androidx.compose.ui.unit.TextUnitType.Sp)
