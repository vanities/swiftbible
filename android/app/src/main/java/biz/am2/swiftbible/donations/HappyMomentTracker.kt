package biz.am2.swiftbible.donations

import biz.am2.swiftbible.data.UserPreferences

object HappyMomentTracker {
    val REVIEW_MILESTONES = setOf(3, 10, 25)
    val DONATION_MILESTONES = setOf(6, 15, 40)

    sealed class Action {
        object None : Action()
        object PromptReview : Action()
        object PromptDonation : Action()
    }

    suspend fun record(prefs: UserPreferences): Action {
        val next = prefs.incrementHappyMomentCount()
        return when {
            next in REVIEW_MILESTONES -> Action.PromptReview
            next in DONATION_MILESTONES -> Action.PromptDonation
            else -> Action.None
        }
    }
}
