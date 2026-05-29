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
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Brightness3
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.CollectionsBookmark
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Drafts
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Grain
import androidx.compose.material.icons.filled.HistoryEdu
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Nightlight
import androidx.compose.material.icons.filled.RemoveRedEye
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material.icons.filled.WorkspacePremium
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
    TIME("Hours", Icons.Filled.Schedule),
    VERSIONS("Versions", Icons.Filled.Translate),
    SCRIBE("Notes", Icons.Filled.EditNote),
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
        BadgeDefinition(
            id = "collect.ot",
            category = BadgeCategory.COLLECTIBLE,
            name = "Old Testament Complete",
            description = "Read all 39 books of the Old Testament",
            icon = Icons.Filled.HistoryEdu,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "collect.nt",
            category = BadgeCategory.COLLECTIBLE,
            name = "New Testament Complete",
            description = "Read all 27 books of the New Testament",
            icon = Icons.Filled.AutoStories,
            tint = BrandRed,
        ),
        BadgeDefinition(
            id = "collect.synoptics",
            category = BadgeCategory.COLLECTIBLE,
            name = "The Synoptic Gospels",
            description = "Matthew, Mark, and Luke — the gospels seen together",
            icon = Icons.Filled.Visibility,
            tint = BrandRedDark,
        ),
        BadgeDefinition(
            id = "collect.general.epistles",
            category = BadgeCategory.COLLECTIBLE,
            name = "General Epistles",
            description = "James, 1–2 Peter, 1–3 John, and Jude",
            icon = Icons.Filled.Drafts,
            tint = BrandAccent,
        ),
        BadgeDefinition(
            id = "collect.luke.acts",
            category = BadgeCategory.COLLECTIBLE,
            name = "Luke–Acts",
            description = "Luke's two-volume work: his gospel and Acts",
            icon = Icons.Filled.CollectionsBookmark,
            tint = Color(0xFF45B8C7),
        ),
        BadgeDefinition(
            id = "collect.historical",
            category = BadgeCategory.COLLECTIBLE,
            name = "Historical Books",
            description = "Joshua through Esther",
            icon = Icons.Filled.AccountBalance,
            tint = BrandPeridot,
        ),
        BadgeDefinition(
            id = "collect.solomon",
            category = BadgeCategory.COLLECTIBLE,
            name = "Books of Solomon",
            description = "Proverbs, Ecclesiastes, and Song of Solomon",
            icon = Icons.Filled.WorkspacePremium,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "collect.megillot",
            category = BadgeCategory.COLLECTIBLE,
            name = "The Five Scrolls",
            description = "Ruth, Esther, Ecclesiastes, Song of Solomon, Lamentations",
            icon = Icons.Filled.Description,
            tint = BrandGoldLight,
        ),
        BadgeDefinition(
            id = "collect.event.pentecost",
            category = BadgeCategory.COLLECTIBLE,
            name = "Pentecost Pilgrim",
            description = "Complete the Pentecost reading plan",
            icon = Icons.Filled.LocalFireDepartment,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "collect.event.summer.psalms",
            category = BadgeCategory.COLLECTIBLE,
            name = "Summer in the Psalms",
            description = "Complete the Summer in the Psalms reading plan",
            icon = Icons.Filled.WbSunny,
            tint = BrandAccent,
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
        BadgeDefinition(
            id = "hidden.alpha.omega",
            category = BadgeCategory.HIDDEN,
            name = "Alpha and Omega",
            description = "Read Genesis 1 and Revelation 22 — the first and last chapters",
            icon = Icons.Filled.AllInclusive,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "hidden.in.the.beginning",
            category = BadgeCategory.HIDDEN,
            name = "In the Beginning",
            description = "Read Genesis 1 and John 1",
            icon = Icons.Filled.LightMode,
            tint = Color(0xFF33CC66),
        ),
        BadgeDefinition(
            id = "hidden.forty.days",
            category = BadgeCategory.HIDDEN,
            name = "Forty Days",
            description = "Reach a 40-day reading streak",
            icon = Icons.Filled.CalendarMonth,
            tint = BrandAccent,
        ),
        BadgeDefinition(
            id = "hidden.jubilee",
            category = BadgeCategory.HIDDEN,
            name = "Jubilee",
            description = "Reach a 50-day reading streak",
            icon = Icons.Filled.Celebration,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "hidden.sermon.mount",
            category = BadgeCategory.HIDDEN,
            name = "Sermon on the Mount",
            description = "Read Matthew 5, 6, and 7 in a single day",
            icon = Icons.Filled.Landscape,
            tint = BrandPeridot,
        ),
        BadgeDefinition(
            id = "hidden.longest.mile",
            category = BadgeCategory.HIDDEN,
            name = "The Longest Mile",
            description = "Read Psalm 119, the longest chapter in the Bible",
            icon = Icons.Filled.Flag,
            tint = Color(0xFF009688),
        ),
        BadgeDefinition(
            id = "hidden.hall.of.faith",
            category = BadgeCategory.HIDDEN,
            name = "Hall of Faith",
            description = "Read Hebrews 11",
            icon = Icons.Filled.Stars,
            tint = BrandGoldLight,
        ),
        BadgeDefinition(
            id = "hidden.watchnight",
            category = BadgeCategory.HIDDEN,
            name = "Watchnight",
            description = "Read as one year turns into the next",
            icon = Icons.Filled.Nightlight,
            tint = Color(0xFF5C6BC0),
        ),
        BadgeDefinition(
            id = "hidden.good.friday",
            category = BadgeCategory.HIDDEN,
            name = "Good Friday",
            description = "Read on Good Friday",
            icon = Icons.Filled.Brightness3,
            tint = BrandRedDark,
        ),
        BadgeDefinition(
            id = "hidden.ash.wednesday",
            category = BadgeCategory.HIDDEN,
            name = "Ash Wednesday",
            description = "Begin Lent in the Word",
            icon = Icons.Filled.Grain,
            tint = Color(0xFF9E9E9E),
        ),
        BadgeDefinition(
            id = "hidden.advent",
            category = BadgeCategory.HIDDEN,
            name = "Advent",
            description = "Read on all four Sundays of Advent",
            icon = Icons.Filled.Event,
            tint = BrandGold,
        ),
        BadgeDefinition(
            id = "hidden.watchers",
            category = BadgeCategory.HIDDEN,
            name = "The Watchers",
            description = "Read the Book of the Watchers, Enoch 1–36",
            icon = Icons.Filled.RemoveRedEye,
            tint = Color(0xFF45B8C7),
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

        BadgeTrack.TIME to BadgeTier.BRONZE -> 10
        BadgeTrack.TIME to BadgeTier.SILVER -> 50
        BadgeTrack.TIME to BadgeTier.GOLD -> 100
        BadgeTrack.TIME to BadgeTier.DIAMOND -> 500

        BadgeTrack.VERSIONS to BadgeTier.BRONZE -> 1
        BadgeTrack.VERSIONS to BadgeTier.SILVER -> 10
        BadgeTrack.VERSIONS to BadgeTier.GOLD -> 50
        BadgeTrack.VERSIONS to BadgeTier.DIAMOND -> 150

        BadgeTrack.SCRIBE to BadgeTier.BRONZE -> 5
        BadgeTrack.SCRIBE to BadgeTier.SILVER -> 25
        BadgeTrack.SCRIBE to BadgeTier.GOLD -> 100
        BadgeTrack.SCRIBE to BadgeTier.DIAMOND -> 300
        else -> 0
    }

    private fun tierDescription(track: BadgeTrack, tier: BadgeTier): String {
        val value = threshold(track, tier)
        return when (track) {
            BadgeTrack.STREAK -> "Read $value days in a row"
            BadgeTrack.CHAPTERS -> "Read $value chapters"
            BadgeTrack.BOOKS -> "Complete $value books"
            BadgeTrack.DEVOTIONALS -> "View $value devotionals"
            BadgeTrack.TIME -> "Spend $value hours in the Word"
            BadgeTrack.VERSIONS -> "Read $value chapters in all three translations"
            BadgeTrack.SCRIBE -> "Save $value notes and highlights"
        }
    }
}
