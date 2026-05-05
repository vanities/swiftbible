package biz.am2.swiftbible.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import biz.am2.swiftbible.R
import biz.am2.swiftbible.data.AppEventRegistry
import biz.am2.swiftbible.ui.bible.BibleScreen
import biz.am2.swiftbible.ui.bible.BookDetailScreen
import biz.am2.swiftbible.ui.bible.ChapterDetailScreen
import biz.am2.swiftbible.ui.daily.DailyDevotionalScreen
import biz.am2.swiftbible.ui.events.EventDetailScreen
import biz.am2.swiftbible.ui.more.MoreScreen
import biz.am2.swiftbible.ui.onboarding.OnboardingScreen
import biz.am2.swiftbible.ui.search.SearchScreen
import biz.am2.swiftbible.ui.donations.DonationCelebrationDialog
import biz.am2.swiftbible.ui.donations.DonationHistoryScreen
import biz.am2.swiftbible.ui.donations.DonationPromptDialog
import biz.am2.swiftbible.ui.history.ChurchHistoryScreen
import biz.am2.swiftbible.ui.history.HistoryArticleScreen
import biz.am2.swiftbible.ui.history.HistorySectionScreen
import biz.am2.swiftbible.ui.settings.BookmarksScreen
import biz.am2.swiftbible.ui.settings.DevotionalReminderScreen
import biz.am2.swiftbible.ui.settings.HighlightsScreen
import biz.am2.swiftbible.ui.settings.HistoryScreen
import biz.am2.swiftbible.ui.settings.NotesScreen
import biz.am2.swiftbible.ui.settings.SavedDevotionalsScreen
import biz.am2.swiftbible.ui.settings.SettingsScreen
import biz.am2.swiftbible.ui.settings.StatsScreen
import biz.am2.swiftbible.ui.settings.TextSourcesScreen
import biz.am2.swiftbible.ui.settings.TranslationInfoScreen

private sealed class Tab(val route: String, val labelRes: Int, val icon: ImageVector) {
    object Bible : Tab("bible", R.string.tab_bible, Icons.AutoMirrored.Filled.MenuBook)
    object Devotional : Tab("daily", R.string.tab_daily, Icons.Filled.WbTwilight)
    object Search : Tab("search", R.string.tab_search, Icons.Filled.Search)
    object More : Tab("settings", R.string.tab_settings, Icons.Filled.GridView)
}

private val tabs = listOf(Tab.Bible, Tab.Devotional, Tab.More, Tab.Search)

@Composable
fun SwiftBibleApp(appVm: AppViewModel) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val prefs by appVm.prefsState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current
    val activity = context as? android.app.Activity
    val showDonation by appVm.showDonationPrompt.collectAsState()
    val celebration by appVm.donationCelebration.collectAsState()
    val pendingReview by appVm.pendingReviewRequest.collectAsState()
    val scope = androidx.compose.runtime.rememberCoroutineScope()

    androidx.compose.runtime.LaunchedEffect(pendingReview) {
        if (pendingReview && activity != null) {
            scope.launch { biz.am2.swiftbible.donations.InAppReviewService.request(activity) }
            appVm.consumeReviewRequest()
        }
    }

    AnimatedVisibility(
        visible = !prefs.onboarded,
        enter = fadeIn(),
        exit = fadeOut() + slideOutHorizontally(),
    ) {
        OnboardingScreen(onDone = { appVm.setOnboarded(true) })
    }
    if (!prefs.onboarded) return

    Scaffold(
        bottomBar = {
            val showBottom = currentRoute in tabs.map { it.route }
            AnimatedVisibility(
                visible = showBottom,
                enter = fadeIn() + slideInHorizontally(),
                exit = fadeOut() + slideOutHorizontally(),
            ) {
                NavigationBar(
                    containerColor = MaterialTheme.colorScheme.surfaceContainer,
                    tonalElevation = 0.dp,
                ) {
                    tabs.forEach { tab ->
                        val selected = currentRoute?.startsWith(tab.route) == true
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                if (!selected) {
                                    navController.navigate(tab.route) {
                                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                            },
                            icon = { Icon(tab.icon, contentDescription = null) },
                            label = { Text(stringResource(tab.labelRes)) },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = MaterialTheme.colorScheme.onPrimary,
                                selectedTextColor = MaterialTheme.colorScheme.primary,
                                indicatorColor = MaterialTheme.colorScheme.primary,
                                unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                                unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                            ),
                        )
                    }
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = Tab.Bible.route,
            modifier = Modifier.padding(padding),
        ) {
            composable(Tab.Bible.route) {
                BibleScreen(
                    appVm = appVm,
                    onBookClick = { name -> navController.navigate("book/${encode(name)}") },
                    onResume = { book, chapter -> navController.navigate("chapter/${encode(book)}/$chapter") },
                )
            }
            composable("book/{name}") { entry ->
                val name = decode(entry.arguments?.getString("name") ?: "")
                BookDetailScreen(
                    appVm = appVm,
                    bookName = name,
                    onChapterClick = { ch -> navController.navigate("chapter/${encode(name)}/$ch") },
                    onBack = { navController.popBackStack() },
                )
            }
            composable("chapter/{name}/{chapter}") { entry ->
                val name = decode(entry.arguments?.getString("name") ?: "")
                val ch = entry.arguments?.getString("chapter")?.toIntOrNull() ?: 1
                ChapterDetailScreen(
                    appVm = appVm,
                    bookName = name,
                    chapterNumber = ch,
                    onBack = { navController.popBackStack() },
                    onJumpChapter = { newCh ->
                        navController.navigate("chapter/${encode(name)}/$newCh") {
                            popUpTo("book/${encode(name)}")
                        }
                    },
                    onCrossRef = { refBook, refChapter ->
                        navController.navigate("chapter/${encode(refBook)}/$refChapter")
                    },
                )
            }
            composable(Tab.Devotional.route) {
                DailyDevotionalScreen(
                    appVm = appVm,
                    onOpenChapter = { book, chapter -> navController.navigate("chapter/${encode(book)}/$chapter") },
                )
            }
            composable(Tab.Search.route) {
                SearchScreen(
                    appVm = appVm,
                    onResultClick = { book, chapter ->
                        navController.navigate("chapter/${encode(book)}/$chapter")
                    },
                )
            }
            composable(Tab.More.route) {
                MoreScreen(
                    appVm = appVm,
                    onOpen = { route -> navController.navigate(route) },
                    onOpenChapter = { book, ch -> navController.navigate("chapter/${encode(book)}/$ch") },
                )
            }
            composable("settings_detail") {
                SettingsScreen(
                    appVm = appVm,
                    onOpen = { route -> navController.navigate(route) },
                    onBack = { navController.popBackStack() },
                )
            }
            composable("reminder") {
                DevotionalReminderScreen(
                    appVm = appVm,
                    onBack = { navController.popBackStack() },
                )
            }
            composable("saved_devotionals") {
                SavedDevotionalsScreen(
                    appVm = appVm,
                    onBack = { navController.popBackStack() },
                )
            }
            composable("highlights") {
                HighlightsScreen(
                    appVm = appVm,
                    onBack = { navController.popBackStack() },
                    onOpen = { book, chapter -> navController.navigate("chapter/${encode(book)}/$chapter") },
                )
            }
            composable("notes") {
                NotesScreen(
                    appVm = appVm,
                    onBack = { navController.popBackStack() },
                    onOpen = { book, chapter -> navController.navigate("chapter/${encode(book)}/$chapter") },
                )
            }
            composable("history") {
                HistoryScreen(
                    appVm = appVm,
                    onBack = { navController.popBackStack() },
                    onOpen = { book, chapter -> navController.navigate("chapter/${encode(book)}/$chapter") },
                )
            }
            composable("bookmarks") {
                BookmarksScreen(
                    appVm = appVm,
                    onBack = { navController.popBackStack() },
                    onOpen = { book, chapter -> navController.navigate("chapter/${encode(book)}/$chapter") },
                )
            }
            composable("stats") {
                StatsScreen(appVm = appVm, onBack = { navController.popBackStack() })
            }
            composable("translations") {
                TranslationInfoScreen(onBack = { navController.popBackStack() })
            }
            composable("text_sources") {
                TextSourcesScreen(onBack = { navController.popBackStack() })
            }
            composable("event/{id}") { entry ->
                val id = entry.arguments?.getString("id") ?: ""
                val event = AppEventRegistry.byId(id)
                if (event != null) {
                    EventDetailScreen(
                        event = event,
                        onBack = { navController.popBackStack() },
                        onOpenInBible = { book, ch, _ ->
                            navController.popBackStack()
                            navController.navigate("chapter/${encode(book)}/$ch")
                        },
                    )
                }
            }
            composable("donation_history") {
                DonationHistoryScreen(appVm = appVm, onBack = { navController.popBackStack() })
            }
            composable("church_history") {
                ChurchHistoryScreen(
                    onBack = { navController.popBackStack() },
                    onOpenSection = { id -> navController.navigate("church_history_section/$id") },
                )
            }
            composable("church_history_section/{id}") { entry ->
                val id = entry.arguments?.getString("id") ?: ""
                HistorySectionScreen(
                    sectionId = id,
                    onBack = { navController.popBackStack() },
                    onOpenArticle = { aid -> navController.navigate("church_history_article/$aid") },
                )
            }
            composable("church_history_article/{id}") { entry ->
                val id = entry.arguments?.getString("id") ?: ""
                HistoryArticleScreen(
                    articleId = id,
                    onBack = { navController.popBackStack() },
                    onOpenArticle = { aid -> navController.navigate("church_history_article/$aid") },
                )
            }
        }
    }

    if (showDonation && activity != null) {
        DonationPromptDialog(
            appVm = appVm,
            activity = activity,
            onDismiss = { appVm.dismissDonationPrompt() },
        )
    }

    celebration?.let { record ->
        DonationCelebrationDialog(
            record = record,
            onDismiss = { appVm.dismissDonationCelebration() },
        )
    }
}

private fun encode(s: String): String = java.net.URLEncoder.encode(s, "UTF-8")
private fun decode(s: String): String = java.net.URLDecoder.decode(s, "UTF-8")
