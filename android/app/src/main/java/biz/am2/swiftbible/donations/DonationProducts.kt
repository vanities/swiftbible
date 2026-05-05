package biz.am2.swiftbible.donations

object DonationProducts {
    const val DONATE_3 = "donation_3"
    const val DONATE_5 = "donation_5"
    const val DONATE_10 = "donation_10"
    const val DONATE_25 = "donation_25"
    const val DONATE_50 = "donation_50"

    val ALL_IDS: List<String> = listOf(DONATE_3, DONATE_5, DONATE_10, DONATE_25, DONATE_50)

    fun amountCents(productId: String): Int = when (productId) {
        DONATE_3 -> 299
        DONATE_5 -> 499
        DONATE_10 -> 999
        DONATE_25 -> 2499
        DONATE_50 -> 4999
        else -> 0
    }

    fun productIdForDollars(dollars: Int): String = when (dollars) {
        3 -> DONATE_3
        5 -> DONATE_5
        10 -> DONATE_10
        25 -> DONATE_25
        50 -> DONATE_50
        else -> DONATE_5
    }
}
