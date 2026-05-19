package biz.am2.swiftbible.data

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Brightness4
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Forest
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MilitaryTech
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.WbTwilight
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material.icons.outlined.Article
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandGoldLight
import biz.am2.swiftbible.ui.theme.BrandPeridot
import biz.am2.swiftbible.ui.theme.BrandRed
import biz.am2.swiftbible.ui.theme.BrandRedDark

enum class BadgeTrack(val displayName: String, val icon: ImageVector) {
    STREAK("Streak", Icons.Filled.LocalFireDepartment),
    CHAPTERS("Chapters", Icons.AutoMirrored.Filled.MenuBook),
    BOOKS("Books", Icons.Filled.Book),
    DEVOTIONALS("Devotionals", Icons.Filled.WbTwilight),
}

enum class BadgeTier(val displayName: String, val color: Color, val accent: Color, val order: Int) {
    BRONZE("Bronze", Color(0xFFCC8033), Color(0xFF8C4D1A), 0),
    SILVER("Silver", Color(0xFFBFBFC7), Color(0xFF8C8C99), 1),
    GOLD("Gold", Color(0xFFFFD633), Color(0xFFBF8C0D), 2),
    DIAMOND("Diamond", Color(0xFFBFF2FF), Color(0xFF73BFF2), 3),
}

enum class BadgeCategory { TIER, COLLECTIBLE, HIDDEN }

data class BadgeDefinition(
    val id: String,
    val category: BadgeCategory,
    val name: String,
    val description: String,
    val icon: ImageVector,
    val tint: Color,
    val track: BadgeTrack? = null,
    val tier: BadgeTier? = null,
    val threshold: Int? = null,
)

object BadgeRegistry {

    val tiers: List<BadgeDefinition> = BadgeTrack.values().flatMap { track ->
        BadgeTier.values().map { tier ->
            BadgeDefinition(
                id = "tier.${track.name.lowercase()}.${tier.name.lowercase()}",
                category = BadgeCategory.TIER,
                name = "${tier.displayName} ${track.displayName}",
                description = tierDescription(track, tier),
                icon = track.icon,
                tint = tier.color,
                track = track,
                tier = tier,
                threshold = threshold(track, tier),
            )
        }
    }

    val collectibles: List<BadgeDefinition> = listOf(
        BadgeDefinition(
            id = "collect.gospels",
            category = BadgeCategory.COLLECTIBLE,
            name = "All Four Gospels",
            description = "Read Matthew, Mark, Luke, and John end to end",
            icon = Icons.Filled.MilitaryTech,
            tint = BrandRed,
        ),
        BadgeDefinition(
            id = "collect.pentateuch",
            category = BadgeCategory.COLLECTIBLE,
            name = "The Pentateuch",
            description = "Complete the five books of Moses",
            icon = Icons.Outlined.Article,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "collect.major.prophets",
            category = BadgeCategory.COLLECTIBLE,
            name = "Major Prophets",
            description = "Isaiah, Jeremiah, Lamentations, Ezekiel, Daniel",
            icon = Icons.Filled.Whatshot,
            tint = BrandAccent,
        ),
        BadgeDefinition(
            id = "collect.minor.prophets",
            category = BadgeCategory.COLLECTIBLE,
            name = "Minor Prophets",
            description = "All twelve, Hosea through Malachi",
            icon = Icons.Filled.Forest,
            tint = BrandPeridot,
        ),
        BadgeDefinition(
            id = "collect.pauline",
            category = BadgeCategory.COLLECTIBLE,
            name = "Pauline Epistles",
            description = "All thirteen letters of Paul",
            icon = Icons.Filled.Email,
            tint = BrandRedDark,
        ),
        BadgeDefinition(
            id = "collect.wisdom",
            category = BadgeCategory.COLLECTIBLE,
            name = "Wisdom Books",
            description = "Job, Psalms, Proverbs, Ecclesiastes, Song of Solomon",
            icon = Icons.Filled.Lightbulb,
            tint = BrandGoldLight,
        ),
        BadgeDefinition(
            id = "collect.enoch",
            category = BadgeCategory.COLLECTIBLE,
            name = "Enoch Complete",
            description = "Read all five sections of the Book of Enoch",
            icon = Icons.Filled.AutoAwesome,
            tint = Color(0xFF45B8C7),
        ),
        BadgeDefinition(
            id = "collect.apocrypha",
            category = BadgeCategory.COLLECTIBLE,
            name = "Apocrypha Complete",
            description = "Read every deuterocanonical book",
            icon = Icons.AutoMirrored.Filled.MenuBook,
            tint = Color(0xFF6B5BBF),
        ),
        BadgeDefinition(
            id = "collect.whole.counsel",
            category = BadgeCategory.COLLECTIBLE,
            name = "Whole Counsel",
            description = "Read every book of the Protestant canon at least once",
            icon = Icons.Filled.Check,
            tint = BrandPeridot,
        ),
    )

    val hidden: List<BadgeDefinition> = listOf(
        BadgeDefinition(
            id = "hidden.night.owl",
            category = BadgeCategory.HIDDEN,
            name = "Night Owl",
            description = "Read between midnight and 3 a.m.",
            icon = Icons.Filled.Bedtime,
            tint = Color(0xFF5C6BC0),
        ),
        BadgeDefinition(
            id = "hidden.early.bird",
            category = BadgeCategory.HIDDEN,
            name = "Early Bird",
            description = "Read before 6 a.m.",
            icon = Icons.Filled.WbSunny,
            tint = Color(0xFFFFA726),
        ),
        BadgeDefinition(
            id = "hidden.marathon",
            category = BadgeCategory.HIDDEN,
            name = "Marathon",
            description = "Read ten or more chapters in a single day",
            icon = Icons.Filled.DirectionsRun,
            tint = BrandAccent,
        ),
        BadgeDefinition(
            id = "hidden.pentecost",
            category = BadgeCategory.HIDDEN,
            name = "Pentecost",
            description = "Read Acts 2 on Pentecost Sunday",
            icon = Icons.Filled.LocalFireDepartment,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "hidden.resurrection.sunday",
            category = BadgeCategory.HIDDEN,
            name = "Resurrection Sunday",
            description = "Read on Easter morning",
            icon = Icons.Filled.WbSunny,
            tint = BrandGoldLight,
        ),
        BadgeDefinition(
            id = "hidden.christmas.story",
            category = BadgeCategory.HIDDEN,
            name = "Christmas Story",
            description = "Read Luke 2 on Christmas Day",
            icon = Icons.Filled.Star,
            tint = BrandRed,
        ),
        BadgeDefinition(
            id = "hidden.all.voices",
            category = BadgeCategory.HIDDEN,
            name = "All Voices",
            description = "View all four AI devotional tracks in one week",
            icon = Icons.Filled.Group,
            tint = BrandAccent,
        ),
        BadgeDefinition(
            id = "hidden.series.completionist",
            category = BadgeCategory.HIDDEN,
            name = "Series Completionist",
            description = "Finish a full four-week Sunday devotional series",
            icon = Icons.Filled.EmojiEvents,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "hidden.phoenix",
            category = BadgeCategory.HIDDEN,
            name = "Phoenix",
            description = "Recover a streak after a freeze",
            icon = Icons.Filled.Whatshot,
            tint = Color(0xFFFF7043),
        ),
        BadgeDefinition(
            id = "hidden.late.wisdom",
            category = BadgeCategory.HIDDEN,
            name = "Late Wisdom",
            description = "Read Proverbs after 10 p.m.",
            icon = Icons.Filled.Brightness4,
            tint = Color(0xFF8E24AA),
        ),
    )

    val all: List<BadgeDefinition> = tiers + collectibles + hidden

    fun definition(id: String): BadgeDefinition? = all.firstOrNull { it.id == id }

    fun tier(track: BadgeTrack, tier: BadgeTier): BadgeDefinition =
        tiers.first { it.track == track && it.tier == tier }

    fun threshold(track: BadgeTrack, tier: BadgeTier): Int = when (track to tier) {
        BadgeTrack.STREAK to BadgeTier.BRONZE -> 7
        BadgeTrack.STREAK to BadgeTier.SILVER -> 30
        BadgeTrack.STREAK to BadgeTier.GOLD -> 100
        BadgeTrack.STREAK to BadgeTier.DIAMOND -> 365

        BadgeTrack.CHAPTERS to BadgeTier.BRONZE -> 50
        BadgeTrack.CHAPTERS to BadgeTier.SILVER -> 250
        BadgeTrack.CHAPTERS to BadgeTier.GOLD -> 1000
        BadgeTrack.CHAPTERS to BadgeTier.DIAMOND -> 1189

        BadgeTrack.BOOKS to BadgeTier.BRONZE -> 5
        BadgeTrack.BOOKS to BadgeTier.SILVER -> 20
        BadgeTrack.BOOKS to BadgeTier.GOLD -> 50
        BadgeTrack.BOOKS to BadgeTier.DIAMOND -> 66

        BadgeTrack.DEVOTIONALS to BadgeTier.BRONZE -> 30
        BadgeTrack.DEVOTIONALS to BadgeTier.SILVER -> 100
        BadgeTrack.DEVOTIONALS to BadgeTier.GOLD -> 365
        BadgeTrack.DEVOTIONALS to BadgeTier.DIAMOND -> 1000
        else -> 0
    }

    private fun tierDescription(track: BadgeTrack, tier: BadgeTier): String {
        val value = threshold(track, tier)
        return when (track) {
            BadgeTrack.STREAK -> "Read $value days in a row"
            BadgeTrack.CHAPTERS -> "Read $value chapters"
            BadgeTrack.BOOKS -> "Complete $value books"
            BadgeTrack.DEVOTIONALS -> "View $value devotionals"
        }
    }
}
