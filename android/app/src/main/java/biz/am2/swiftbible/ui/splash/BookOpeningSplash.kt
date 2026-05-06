package biz.am2.swiftbible.ui.splash

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.tween
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val DeepNavy = Color(0xFF0D1226)
private val WarmGold = Color(0xFFD9AD52)
private val LightGold = Color(0xFFFFEDBA)
private val CoverDark = Color(0xFF2E1F14)
private val CoverLight = Color(0xFF473321)

@Composable
fun BookOpeningSplash(onFinished: () -> Unit) {
    var phase by remember { mutableStateOf(0) }

    val bookProgress by animateFloatAsState(
        targetValue = if (phase >= 1) 1f else 0f,
        animationSpec = tween(durationMillis = 700, easing = EaseOut),
        label = "book",
    )
    val glowProgress by animateFloatAsState(
        targetValue = if (phase >= 2) 1f else 0f,
        animationSpec = tween(durationMillis = 800, easing = EaseInOut),
        label = "glow",
    )
    val titleProgress by animateFloatAsState(
        targetValue = if (phase >= 3) 1f else 0f,
        animationSpec = tween(durationMillis = 500, easing = EaseOut),
        label = "title",
    )
    val verseProgress by animateFloatAsState(
        targetValue = if (phase >= 4) 1f else 0f,
        animationSpec = tween(durationMillis = 400, easing = EaseOut),
        label = "verse",
    )
    val exitProgress by animateFloatAsState(
        targetValue = if (phase >= 5) 1f else 0f,
        animationSpec = tween(durationMillis = 500, easing = EaseInOut),
        label = "exit",
    )

    val pulseTransition = rememberInfiniteTransition(label = "pulse")
    val pulse by pulseTransition.animateFloat(
        initialValue = 0.97f,
        targetValue = 1.03f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1800, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "pulse-scale",
    )

    LaunchedEffect(Unit) {
        delay(150); phase = 1
        delay(400); phase = 2
        delay(500); phase = 3
        delay(400); phase = 4
        delay(900); phase = 5
        delay(500); onFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DeepNavy)
            .alpha(1f - exitProgress),
    ) {
        AmbientGlow(progress = glowProgress)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .scale(1f + 0.12f * exitProgress),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            BibleCover(progress = bookProgress, pulse = pulse, glowProgress = glowProgress)

            Spacer(modifier = Modifier.height(36.dp))

            Text(
                text = "SwiftBible",
                color = Color.White,
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Serif,
                modifier = Modifier.alpha(titleProgress),
            )

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = "In the beginning was the Word",
                color = LightGold.copy(alpha = 0.7f),
                fontSize = 14.sp,
                fontStyle = FontStyle.Italic,
                fontFamily = FontFamily.Serif,
                modifier = Modifier.alpha(verseProgress),
            )
        }
    }
}

@Composable
private fun AmbientGlow(progress: Float) {
    Canvas(modifier = Modifier.fillMaxSize()) {
        val center = Offset(size.width / 2f, size.height / 2f - 80.dp.toPx())
        val maxRadius = 280.dp.toPx()
        val radius = maxRadius * (0.6f + 0.4f * progress)
        drawCircle(
            brush = Brush.radialGradient(
                colorStops = arrayOf(
                    0f to WarmGold.copy(alpha = 0.55f * progress),
                    0.4f to WarmGold.copy(alpha = 0.18f * progress),
                    1f to Color.Transparent,
                ),
                center = center,
                radius = radius,
            ),
            radius = radius,
            center = center,
        )
    }
}

@Composable
private fun BibleCover(progress: Float, pulse: Float, glowProgress: Float) {
    val bookW = 150.dp
    val bookH = 200.dp

    Box(
        modifier = Modifier
            .size(width = bookW, height = bookH)
            .alpha(progress)
            .scale(0.85f + 0.15f * progress * pulse),
        contentAlignment = Alignment.Center,
    ) {
        // Cover surface
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(10.dp))
                .background(
                    Brush.linearGradient(colors = listOf(CoverLight, CoverDark)),
                ),
        )

        // Inner gold trim border
        Canvas(modifier = Modifier.size(width = bookW - 18.dp, height = bookH - 18.dp)) {
            drawRoundRect(
                brush = Brush.linearGradient(
                    colors = listOf(
                        WarmGold.copy(alpha = 0.6f),
                        WarmGold.copy(alpha = 0.25f),
                    ),
                ),
                cornerRadius = androidx.compose.ui.geometry.CornerRadius(7.dp.toPx()),
                style = Stroke(width = 1.5.dp.toPx()),
            )
        }

        // Gold cross
        Canvas(modifier = Modifier.size(width = 36.dp, height = 76.dp)) {
            val w = size.width
            val h = size.height
            val barHorizontalH = 7.dp.toPx()
            val barVerticalW = 7.dp.toPx()
            val crossCenterY = h / 2f - 4.dp.toPx()

            // Vertical bar with gold gradient
            drawRect(
                brush = Brush.verticalGradient(colors = listOf(LightGold, WarmGold)),
                topLeft = Offset(w / 2f - barVerticalW / 2f, crossCenterY - 30.dp.toPx()),
                size = Size(barVerticalW, 70.dp.toPx()),
            )
            // Horizontal bar
            drawRect(
                color = WarmGold,
                topLeft = Offset(w / 2f - 18.dp.toPx(), crossCenterY - 12.dp.toPx()),
                size = Size(36.dp.toPx(), barHorizontalH),
            )
        }

        // Subtle warm glow leaking from the cross — intensifies with glowProgress
        Canvas(
            modifier = Modifier
                .size(width = 80.dp, height = 80.dp)
                .alpha(0.45f * glowProgress),
        ) {
            drawCircle(
                brush = Brush.radialGradient(
                    colorStops = arrayOf(
                        0f to LightGold.copy(alpha = 0.7f),
                        1f to Color.Transparent,
                    ),
                ),
                radius = size.width / 2f,
                center = Offset(size.width / 2f, size.height / 2f),
            )
        }
    }
}
