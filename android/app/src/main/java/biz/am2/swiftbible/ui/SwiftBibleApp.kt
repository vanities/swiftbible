package biz.am2.swiftbible.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
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
import biz.am2.swiftbible.R
import biz.am2.swiftbible.ui.bible.BibleScreen
import biz.am2.swiftbible.ui.bible.BookDetailScreen
import biz.am2.swiftbible.ui.bible.ChapterDetailScreen
import biz.am2.swiftbible.ui.daily.DailyDevotionalScreen
import biz.am2.swiftbible.ui.onboarding.OnboardingScreen
import biz.am2.swiftbible.ui.search.SearchScreen
import biz.am2.swiftbible.ui.settings.BookmarksScreen
import biz.am2.swiftbible.ui.settings.HighlightsScreen
import biz.am2.swiftbible.ui.settings.HistoryScreen
import biz.am2.swiftbible.ui.settings.NotesScreen
import biz.am2.swiftbible.ui.settings.SettingsScreen
import biz.am2.swiftbible.ui.settings.StatsScreen
import biz.am2.swiftbible.ui.settings.TextSourcesScreen
import biz.am2.swiftbible.ui.settings.TranslationInfoScreen

private sealed class Tab(val route: String, val labelRes: Int, val icon: ImageVector) {
    object Bible : Tab("bible", R.string.tab_bible, Icons.AutoMirrored.Filled.MenuBook)
    object Daily : Tab("daily", R.string.tab_daily, Icons.Filled.AutoAwesome)
    object Search : Tab("search", R.string.tab_search, Icons.Filled.Search)
    object Settings : Tab("settings", R.string.tab_settings, Icons.Filled.Settings)
}

private val tabs = listOf(Tab.Bible, Tab.Daily, Tab.Search, Tab.Settings)

@Composable
fun SwiftBibleApp(appVm: AppViewModel) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val prefs by appVm.prefsState.collectAsState()

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
            composable(Tab.Daily.route) {
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
            composable(Tab.Settings.route) {
                SettingsScreen(
                    appVm = appVm,
                    onOpen = { route -> navController.navigate(route) },
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
        }
    }
}

private fun encode(s: String): String = java.net.URLEncoder.encode(s, "UTF-8")
private fun decode(s: String): String = java.net.URLDecoder.decode(s, "UTF-8")
