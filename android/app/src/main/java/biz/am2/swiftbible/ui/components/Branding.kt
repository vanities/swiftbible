package biz.am2.swiftbible.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandCyan
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandGoldLight
import biz.am2.swiftbible.ui.theme.BrandGreen
import biz.am2.swiftbible.ui.theme.BrandPeridot

val PeridotGradient = Brush.linearGradient(listOf(BrandPeridot, BrandGreen, BrandCyan))
val GoldGradient = Brush.linearGradient(listOf(BrandGoldLight, BrandGold))
val AccentGlowGradient = Brush.verticalGradient(
    0.0f to BrandAccent.copy(alpha = 0.18f),
    0.6f to BrandAccent.copy(alpha = 0.05f),
    1.0f to Color.Transparent,
)

@Composable
fun BrandMark(modifier: Modifier = Modifier, size: Int = 32) {
    Box(
        modifier = modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(PeridotGradient),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = "✦",
            color = Color.White,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Black,
        )
    }
}

@Composable
fun SectionHeader(text: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(width = 3.dp, height = 18.dp)
                .background(GoldGradient, shape = RoundedCornerShape(2.dp)),
        )
        Spacer(Modifier.width(10.dp))
        Text(
            text = text.uppercase(),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.width(12.dp))
        Box(
            modifier = Modifier
                .height(1.dp)
                .fillMaxWidth()
                .background(MaterialTheme.colorScheme.outlineVariant),
        )
    }
}

@Composable
fun GlowBar(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(64.dp)
            .background(AccentGlowGradient),
    )
}

@Composable
fun PillBadge(
    text: String,
    color: Color = MaterialTheme.colorScheme.primary,
    onColor: Color = MaterialTheme.colorScheme.onPrimary,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(color)
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(
            text = text,
            color = onColor,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
fun GradientDivider(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(
                Brush.horizontalGradient(
                    0f to Color.Transparent,
                    0.5f to MaterialTheme.colorScheme.outlineVariant,
                    1f to Color.Transparent,
                ),
            ),
    )
}

@Composable
fun OutlinedFrame(
    modifier: Modifier = Modifier,
    cornerRadius: Int = 16,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius.dp))
            .background(MaterialTheme.colorScheme.surfaceContainer)
            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(cornerRadius.dp)),
    ) { content() }
}

@Composable
fun StatCard(label: String, value: String, modifier: Modifier = Modifier) {
    OutlinedFrame(modifier = modifier) {
        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = label.uppercase(),
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
