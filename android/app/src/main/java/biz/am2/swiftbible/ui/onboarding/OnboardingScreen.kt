package biz.am2.swiftbible.ui.onboarding

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ProgressIndicatorDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.R
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandDeepNavy
import biz.am2.swiftbible.ui.theme.BrandGold
import kotlinx.coroutines.launch

/**
 * Versioned onboarding flow. Mirrors iOS [`OnboardingView`]:
 * – New installs see every available feature.
 * – Returning users see only features added since their last completion
 *   (a "What's New" spotlight).
 *
 * Caller passes the precomputed `features` list (from
 * `AppViewModel.pendingOnboardingFeatures`); on completion we mark them seen.
 */
@Composable
fun OnboardingScreen(
    features: List<OnboardingFeature>,
    onDone: () -> Unit,
    onSetReminder: () -> Unit = {},
) {
    if (features.isEmpty()) {
        onDone()
        return
    }

    val pagerState = rememberPagerState(pageCount = { features.size })
    val scope = rememberCoroutineScope()
    val showsProgressChrome = features.size > 1
    val isLastPage = pagerState.currentPage == features.lastIndex

    androidx.compose.runtime.LaunchedEffect(Unit) {
        biz.am2.swiftbible.data.Analytics.capture(
            biz.am2.swiftbible.data.Analytics.Event.OnboardingStarted,
            mapOf("feature_count" to features.size),
        )
    }
    androidx.compose.runtime.LaunchedEffect(pagerState.currentPage) {
        val feature = features.getOrNull(pagerState.currentPage) ?: return@LaunchedEffect
        biz.am2.swiftbible.data.Analytics.capture(
            biz.am2.swiftbible.data.Analytics.Event.OnboardingFeatureViewed,
            mapOf("feature" to feature.name, "index" to pagerState.currentPage),
        )
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = BrandDeepNavy,
    ) {
        Column(modifier = Modifier.fillMaxSize().padding(24.dp)) {
            HeaderRow(
                stepLabel = if (showsProgressChrome) "Step ${pagerState.currentPage + 1} of ${features.size}" else null,
                onSkip = {
                    biz.am2.swiftbible.data.Analytics.capture(
                        biz.am2.swiftbible.data.Analytics.Event.OnboardingSkipped,
                        mapOf("at_index" to pagerState.currentPage, "feature_count" to features.size),
                    )
                    onDone()
                },
            )

            if (showsProgressChrome) {
                Spacer(Modifier.size(8.dp))
                val progress by animateFloatAsState(
                    targetValue = (pagerState.currentPage + 1).toFloat() / features.size.toFloat(),
                    animationSpec = tween(350, easing = EaseInOut),
                    label = "progress",
                )
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier.fillMaxWidth().height(6.dp).clip(CircleShape),
                    color = BrandAccent,
                    trackColor = Color.White.copy(alpha = 0.18f),
                    strokeCap = ProgressIndicatorDefaults.LinearStrokeCap,
                )
            }

            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) { page ->
                FeaturePage(
                    feature = features[page],
                    pageIndex = page,
                    isActive = pagerState.currentPage == page,
                    onSetReminder = onSetReminder,
                )
            }

            Button(
                onClick = {
                    if (isLastPage) {
                        biz.am2.swiftbible.data.Analytics.capture(
                            biz.am2.swiftbible.data.Analytics.Event.OnboardingCompleted,
                            mapOf("feature_count" to features.size),
                        )
                        onDone()
                    } else scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(28.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = BrandDeepNavy),
            ) {
                Text(
                    text = if (isLastPage) "Start Reading" else "Continue",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

@Composable
private fun HeaderRow(stepLabel: String?, onSkip: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Image(
            painter = painterResource(id = R.mipmap.ic_launcher_foreground),
            contentDescription = null,
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(8.dp)),
        )
        Spacer(Modifier.size(10.dp))
        Text(
            text = "SwiftBible",
            style = MaterialTheme.typography.titleLarge,
            color = Color.White,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.weight(1f))
        if (stepLabel != null) {
            Text(
                text = stepLabel,
                style = MaterialTheme.typography.labelMedium,
                color = Color.White.copy(alpha = 0.7f),
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(Modifier.size(12.dp))
        }
        TextButton(onClick = onSkip) {
            Text("Skip", color = Color.White.copy(alpha = 0.7f))
        }
    }
}

@Composable
private fun FeaturePage(
    feature: OnboardingFeature,
    pageIndex: Int,
    isActive: Boolean,
    onSetReminder: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(top = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        when (feature) {
            OnboardingFeature.WELCOME -> WelcomeHero(pageIndex = pageIndex)
            OnboardingFeature.DAILY_REMINDER -> ReminderBellHero(pageIndex = pageIndex)
            OnboardingFeature.EXPLAIN -> ExplainHero(pageIndex = pageIndex)
        }

        Spacer(Modifier.size(40.dp))

        AnimatedVisibility(
            visible = isActive,
            enter = fadeIn(animationSpec = tween(500, delayMillis = 200, easing = EaseOut)) +
                slideInVertically(
                    animationSpec = tween(500, delayMillis = 200, easing = EaseOut),
                    initialOffsetY = { it / 4 },
                ),
        ) {
            Text(
                text = feature.title,
                style = MaterialTheme.typography.headlineMedium,
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center,
            )
        }

        Spacer(Modifier.size(16.dp))

        AnimatedVisibility(
            visible = isActive,
            enter = fadeIn(animationSpec = tween(500, delayMillis = 450, easing = EaseOut)) +
                slideInVertically(
                    animationSpec = tween(500, delayMillis = 450, easing = EaseOut),
                    initialOffsetY = { it / 4 },
                ),
        ) {
            Text(
                text = feature.subtitle,
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.85f),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 16.dp),
            )
        }

        Spacer(Modifier.size(24.dp))

        AnimatedVisibility(
            visible = isActive,
            enter = fadeIn(animationSpec = tween(500, delayMillis = 700, easing = EaseOut)),
        ) {
            when (feature) {
                OnboardingFeature.WELCOME -> WelcomeExtras()
                OnboardingFeature.DAILY_REMINDER -> ReminderCta(onSetReminder = onSetReminder)
                OnboardingFeature.EXPLAIN -> ExplainBadge()
            }
        }
    }
}

/** Halo Effect — strong brand impression on first page. */
@Composable
private fun WelcomeHero(pageIndex: Int) {
    val transition = rememberInfiniteTransition(label = "welcome-$pageIndex")
    val pulse by transition.animateFloat(
        initialValue = 0.96f,
        targetValue = 1.04f,
        animationSpec = infiniteRepeatable(
            animation = tween(2200, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "welcome-pulse",
    )
    Image(
        painter = painterResource(id = R.mipmap.ic_launcher_foreground),
        contentDescription = null,
        modifier = Modifier
            .size(180.dp)
            .scale(pulse)
            .clip(RoundedCornerShape(40.dp)),
    )
}

/** Reciprocity: a verse gift, then the open-source/free/no-ads identity badge. */
@Composable
private fun WelcomeExtras() {
    val (verseText, verseRef) = remember { OnboardingFeature.dailyWelcomeVerse() }
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(BrandAccent.copy(alpha = 0.10f))
                .padding(16.dp),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "“$verseText”",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    fontStyle = FontStyle.Italic,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    text = verseRef,
                    style = MaterialTheme.typography.labelMedium,
                    color = Color.White.copy(alpha = 0.7f),
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
        Spacer(Modifier.size(12.dp))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
        ) {
            BadgeChip(Icons.Filled.Bolt, "Free")
            Spacer(Modifier.size(8.dp))
            BadgeChip(Icons.Filled.Code, "Open Source")
            Spacer(Modifier.size(8.dp))
            BadgeChip(Icons.Filled.FavoriteBorder, "No Ads")
        }
    }
}

@Composable
private fun BadgeChip(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color.White.copy(alpha = 0.75f),
            modifier = Modifier.size(14.dp),
        )
        Spacer(Modifier.size(4.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = Color.White.copy(alpha = 0.75f),
            fontWeight = FontWeight.SemiBold,
        )
    }
}

/** Bouncing gold bell — analogue of iOS `symbolEffect(.bounce)` on `bell.badge.fill`. */
@Composable
private fun ReminderBellHero(pageIndex: Int) {
    val transition = rememberInfiniteTransition(label = "bell-$pageIndex")
    val bounce by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1400, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "bell-bounce",
    )
    val tilt by transition.animateFloat(
        initialValue = -6f,
        targetValue = 6f,
        animationSpec = infiniteRepeatable(
            animation = tween(1100, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "bell-tilt",
    )
    Box(
        modifier = Modifier
            .size(180.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(160.dp)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(
                        listOf(
                            BrandGold.copy(alpha = 0.32f),
                            BrandGold.copy(alpha = 0.08f),
                        ),
                    ),
                ),
        )
        Icon(
            imageVector = Icons.Filled.Notifications,
            contentDescription = null,
            tint = BrandGold,
            modifier = Modifier
                .size(72.dp)
                .rotate(tilt)
                .offset(y = (-bounce * 6f).dp),
        )
    }
}

/** Pulsing teal sparkles — analogue of iOS `symbolEffect(.pulse)` on `sparkles`. */
@Composable
private fun ExplainHero(pageIndex: Int) {
    val transition = rememberInfiniteTransition(label = "explain-$pageIndex")
    val pulse by transition.animateFloat(
        initialValue = 0.92f,
        targetValue = 1.12f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "explain-pulse",
    )
    val haloAlpha by transition.animateFloat(
        initialValue = 0.55f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1600, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "explain-halo",
    )
    Box(
        modifier = Modifier.size(180.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(160.dp)
                .scale(haloAlpha)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(
                        listOf(
                            BrandAccent.copy(alpha = 0.35f),
                            BrandAccent.copy(alpha = 0.08f),
                            Color.Transparent,
                        ),
                    ),
                ),
        )
        Icon(
            imageVector = Icons.Filled.AutoAwesome,
            contentDescription = null,
            tint = BrandAccent,
            modifier = Modifier
                .size(72.dp)
                .scale(pulse),
        )
    }
}

/** "On-device AI" pill — same identity badge that appears in the explain sheet. */
@Composable
private fun ExplainBadge() {
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(BrandAccent.copy(alpha = 0.18f)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Spacer(Modifier.size(14.dp))
        Icon(
            imageVector = Icons.Filled.AutoAwesome,
            contentDescription = null,
            tint = BrandAccent,
            modifier = Modifier.size(14.dp),
        )
        Spacer(Modifier.size(6.dp))
        Text(
            text = "Runs on-device — private",
            style = MaterialTheme.typography.labelMedium,
            color = BrandAccent,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(vertical = 8.dp),
        )
        Spacer(Modifier.size(14.dp))
    }
}

@Composable
private fun ReminderCta(onSetReminder: () -> Unit) {
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(BrandGold.copy(alpha = 0.18f)),
    ) {
        TextButton(onClick = onSetReminder) {
            Text(
                text = "Set Reminder Time",
                color = BrandGold,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}
