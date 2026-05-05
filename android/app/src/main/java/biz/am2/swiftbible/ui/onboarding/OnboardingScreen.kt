package biz.am2.swiftbible.ui.onboarding

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.components.BrandMark
import biz.am2.swiftbible.ui.components.PeridotGradient
import biz.am2.swiftbible.ui.theme.BrandDeepNavy
import kotlinx.coroutines.launch

private data class Page(val title: String, val body: String, val icon: ImageVector)

private val pages = listOf(
    Page(
        title = "A library of sacred texts",
        body = "Read the Bible in KJV, ASV, WEB, plus the Apocrypha, Book of Enoch, Jubilees, and more — all offline.",
        icon = Icons.AutoMirrored.Filled.MenuBook,
    ),
    Page(
        title = "Highlight and reflect",
        body = "Long-press any verse to highlight in six colors, write a note, or save a bookmark.",
        icon = Icons.Filled.Edit,
    ),
    Page(
        title = "Daily devotional",
        body = "A fresh verse and reflection every day, drawn from the texts you’ve enabled.",
        icon = Icons.Filled.AutoAwesome,
    ),
    Page(
        title = "Made with care",
        body = "Open source, no ads, no tracking. Just scripture.",
        icon = Icons.Filled.Favorite,
    ),
)

@Composable
fun OnboardingScreen(onDone: () -> Unit) {
    val pagerState = rememberPagerState(pageCount = { pages.size })
    val scope = rememberCoroutineScope()

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = BrandDeepNavy,
    ) {
        Column(modifier = Modifier.fillMaxSize().padding(24.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BrandMark(size = 36)
                Spacer(Modifier.size(10.dp))
                Text(
                    text = "SwiftBible",
                    style = MaterialTheme.typography.titleLarge,
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                TextButton(onClick = onDone) {
                    Text("Skip", color = Color.White.copy(alpha = 0.7f))
                }
            }

            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
            ) { page ->
                PageContent(pages[page])
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.Center,
            ) {
                pages.indices.forEach { i ->
                    val w by animateFloatAsState(
                        targetValue = if (pagerState.currentPage == i) 24f else 8f,
                        label = "dot",
                    )
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .size(width = w.dp, height = 8.dp)
                            .clip(CircleShape)
                            .background(
                                if (pagerState.currentPage == i)
                                    Brush.horizontalGradient(listOf(Color(0xFFBFD900), Color(0xFF00BFD9)))
                                else
                                    Brush.linearGradient(listOf(Color.White.copy(alpha = 0.25f), Color.White.copy(alpha = 0.25f))),
                            ),
                    )
                }
            }

            Button(
                onClick = {
                    if (pagerState.currentPage == pages.lastIndex) onDone()
                    else scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(28.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = BrandDeepNavy),
            ) {
                Text(
                    text = if (pagerState.currentPage == pages.lastIndex) "Begin reading" else "Next",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

@Composable
private fun PageContent(page: Page) {
    Column(
        modifier = Modifier.fillMaxSize().padding(top = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(160.dp)
                .clip(CircleShape)
                .background(PeridotGradient),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                page.icon,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(72.dp),
            )
        }
        Spacer(Modifier.size(40.dp))
        Text(
            text = page.title,
            style = MaterialTheme.typography.headlineMedium,
            color = Color.White,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.size(16.dp))
        Text(
            text = page.body,
            style = MaterialTheme.typography.bodyLarge,
            color = Color.White.copy(alpha = 0.85f),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp),
        )
    }
}
