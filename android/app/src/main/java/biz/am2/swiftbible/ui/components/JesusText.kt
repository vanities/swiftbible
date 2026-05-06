package biz.am2.swiftbible.ui.components

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle

private val JESUS_TAG = Regex("<JESUS>(.*?)</JESUS>", RegexOption.DOT_MATCHES_ALL)

/**
 * Strip `<JESUS>...</JESUS>` markers from verse text and optionally render the
 * content between them in red. Mirrors iOS `ParagraphParser`.
 */
fun parseJesusText(text: String, jesusRed: Boolean, redColor: Color): AnnotatedString =
    buildAnnotatedString {
        var cursor = 0
        for (match in JESUS_TAG.findAll(text)) {
            if (match.range.first > cursor) {
                append(text.substring(cursor, match.range.first))
            }
            val inner = match.groupValues[1]
            if (jesusRed) {
                withStyle(SpanStyle(color = redColor)) { append(inner) }
            } else {
                append(inner)
            }
            cursor = match.range.last + 1
        }
        if (cursor < text.length) append(text.substring(cursor))
    }

/** Strip JESUS tags from text without applying any styling — for searching/sharing. */
fun stripJesusTags(text: String): String = text.replace("<JESUS>", "").replace("</JESUS>", "")
