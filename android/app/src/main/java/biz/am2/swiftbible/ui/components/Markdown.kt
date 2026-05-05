package biz.am2.swiftbible.ui.components

import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp

const val MD_LINK_TAG = "md_link"

data class MarkdownBlock(val text: AnnotatedString, val type: BlockType)

enum class BlockType { H1, H2, H3, BodyParagraph, Quote }

private val LINK_REGEX = Regex("""\[([^\]]+)\]\(([^)]+)\)""")
private val BOLD_REGEX = Regex("""\*\*([^*]+?)\*\*""")
private val ITALIC_REGEX = Regex("""(?<![*_\w])\*([^*]+?)\*(?![*_\w])""")
private val UNDERSCORE_ITALIC_REGEX = Regex("""(?<![*_\w])_([^_]+?)_(?![*_\w])""")

fun parseMarkdown(
    raw: String,
    bodyColor: androidx.compose.ui.graphics.Color,
    linkColor: androidx.compose.ui.graphics.Color,
): List<MarkdownBlock> {
    val out = mutableListOf<MarkdownBlock>()
    val lines = raw.split('\n')
    val buffer = StringBuilder()
    var bufferType: BlockType? = null

    fun flush() {
        val text = buffer.toString().trim()
        if (text.isNotEmpty()) {
            val type = bufferType ?: BlockType.BodyParagraph
            out.add(MarkdownBlock(buildInline(text, bodyColor, linkColor), type))
        }
        buffer.clear()
        bufferType = null
    }

    for (line in lines) {
        val l = line.trimEnd()
        when {
            l.startsWith("# ") -> { flush(); buffer.append(l.removePrefix("# ")); bufferType = BlockType.H1; flush() }
            l.startsWith("## ") -> { flush(); buffer.append(l.removePrefix("## ")); bufferType = BlockType.H2; flush() }
            l.startsWith("### ") -> { flush(); buffer.append(l.removePrefix("### ")); bufferType = BlockType.H3; flush() }
            l.startsWith("> ") -> {
                if (bufferType != BlockType.Quote) flush()
                bufferType = BlockType.Quote
                if (buffer.isNotEmpty()) buffer.append(' ')
                buffer.append(l.removePrefix("> "))
            }
            l.isBlank() -> flush()
            else -> {
                if (bufferType != BlockType.BodyParagraph && bufferType != null) flush()
                bufferType = BlockType.BodyParagraph
                if (buffer.isNotEmpty()) buffer.append(' ')
                buffer.append(l)
            }
        }
    }
    flush()
    return out
}

private fun buildInline(
    text: String,
    bodyColor: androidx.compose.ui.graphics.Color,
    linkColor: androidx.compose.ui.graphics.Color,
): AnnotatedString = buildAnnotatedString {
    val replacements = mutableListOf<Triple<IntRange, String, String?>>()  // (range, text, linkUrl?)

    LINK_REGEX.findAll(text).forEach { m ->
        replacements.add(Triple(m.range, m.groupValues[1], m.groupValues[2]))
    }
    BOLD_REGEX.findAll(text).forEach { m ->
        if (replacements.none { it.first.first <= m.range.first && it.first.last >= m.range.last }) {
            replacements.add(Triple(m.range, "**${m.groupValues[1]}**", null))
        }
    }
    ITALIC_REGEX.findAll(text).forEach { m ->
        if (replacements.none { it.first.first <= m.range.first && it.first.last >= m.range.last }) {
            replacements.add(Triple(m.range, "*${m.groupValues[1]}*", null))
        }
    }
    UNDERSCORE_ITALIC_REGEX.findAll(text).forEach { m ->
        if (replacements.none { it.first.first <= m.range.first && it.first.last >= m.range.last }) {
            replacements.add(Triple(m.range, "_${m.groupValues[1]}_", null))
        }
    }

    replacements.sortBy { it.first.first }
    var cursor = 0
    for ((range, body, linkUrl) in replacements) {
        if (range.first > cursor) append(text.substring(cursor, range.first))
        when {
            linkUrl != null -> {
                pushStringAnnotation(MD_LINK_TAG, linkUrl)
                withStyle(SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline)) {
                    append(body)
                }
                pop()
            }
            body.startsWith("**") && body.endsWith("**") -> {
                withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(body.substring(2, body.length - 2)) }
            }
            body.startsWith("*") && body.endsWith("*") -> {
                withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(body.substring(1, body.length - 1)) }
            }
            body.startsWith("_") && body.endsWith("_") -> {
                withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(body.substring(1, body.length - 1)) }
            }
            else -> append(body)
        }
        cursor = range.last + 1
    }
    if (cursor < text.length) append(text.substring(cursor))
}

@Composable
fun MarkdownText(
    raw: String,
    bodyStyle: TextStyle,
    onLinkClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val onSurface = MaterialTheme.colorScheme.onSurface
    val link = MaterialTheme.colorScheme.primary
    val blocks = remember(raw) { parseMarkdown(raw, onSurface, link) }
    androidx.compose.foundation.layout.Column(modifier = modifier) {
        blocks.forEachIndexed { i, block ->
            val style = when (block.type) {
                BlockType.H1 -> MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold)
                BlockType.H2 -> MaterialTheme.typography.headlineSmall.copy(fontWeight = FontWeight.Bold)
                BlockType.H3 -> MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold)
                BlockType.Quote -> bodyStyle.copy(fontStyle = FontStyle.Italic, color = MaterialTheme.colorScheme.onSurfaceVariant)
                BlockType.BodyParagraph -> bodyStyle
            }
            val isHeader = block.type in listOf(BlockType.H1, BlockType.H2, BlockType.H3)
            val topPad = if (i == 0) 0.dp else if (isHeader) 16.dp else 8.dp
            ClickableMarkdownText(
                text = block.text,
                style = style,
                onLinkClick = onLinkClick,
                modifier = Modifier.padding(top = topPad),
            )
        }
    }
}

@Composable
private fun ClickableMarkdownText(
    text: AnnotatedString,
    style: TextStyle,
    onLinkClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val layoutResultState = androidx.compose.runtime.remember(text) {
        androidx.compose.runtime.mutableStateOf<androidx.compose.ui.text.TextLayoutResult?>(null)
    }
    val layoutResult = layoutResultState.value
    Text(
        text = text,
        style = style,
        modifier = modifier.pointerInput(text, layoutResult) {
            detectTapGestures { pos ->
                val lr = layoutResult ?: return@detectTapGestures
                val offset = lr.getOffsetForPosition(pos)
                text.getStringAnnotations(MD_LINK_TAG, offset, offset).firstOrNull()?.let { ann ->
                    onLinkClick(ann.item)
                }
            }
        },
        onTextLayout = { layoutResultState.value = it },
    )
}
