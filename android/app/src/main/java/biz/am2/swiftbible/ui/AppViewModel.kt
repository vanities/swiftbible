package biz.am2.swiftbible.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import biz.am2.swiftbible.data.Analytics
import biz.am2.swiftbible.data.AppDatabase
import biz.am2.swiftbible.data.BibleRepository
import biz.am2.swiftbible.data.BookmarkEntity
import biz.am2.swiftbible.data.DailyDevotional
import biz.am2.swiftbible.data.DevotionalRepository
import biz.am2.swiftbible.data.Highlight
import biz.am2.swiftbible.data.HistoryEntity
import biz.am2.swiftbible.data.NoteEntity
import biz.am2.swiftbible.data.SavedDevotionalEntity
import biz.am2.swiftbible.data.SummariesRepository
import biz.am2.swiftbible.data.UserPreferences
import biz.am2.swiftbible.model.Book
import biz.am2.swiftbible.model.BookCatalog
import biz.am2.swiftbible.model.Version
import biz.am2.swiftbible.ui.onboarding.OnboardingFeature
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class BibleState(
    val loading: Boolean = true,
    val version: Version = Version.KJV,
    val oldTestament: List<Book> = emptyList(),
    val newTestament: List<Book> = emptyList(),
    val apocrypha: List<Book> = emptyList(),
    val enoch: List<Book> = emptyList(),
    val jubilees: List<Book> = emptyList(),
    val testaments: List<Book> = emptyList(),
    val secondEnoch: List<Book> = emptyList(),
    val didache: List<Book> = emptyList(),
    val firstClement: List<Book> = emptyList(),
) {
    val allBooks: List<Book>
        get() = oldTestament + newTestament + apocrypha + enoch + jubilees +
            testaments + secondEnoch + didache + firstClement
}

class AppViewModel(application: Application) : AndroidViewModel(application) {

    val repository = BibleRepository(application)
    val summaries = SummariesRepository(application)
    val devotionals = DevotionalRepository(application)
    val prefs = UserPreferences(application)
    val db = AppDatabase.get(application)

    private val _bible = MutableStateFlow(BibleState())
    val bible: StateFlow<BibleState> = _bible.asStateFlow()

    val prefsState = prefs.snapshot.stateIn(viewModelScope, SharingStarted.Eagerly, UserPreferences.Snapshot())
    val prefsLoaded: StateFlow<Boolean> = prefs.snapshot
        .map { true }
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    /**
     * Onboarding cases this device can actually run. Resolved once on launch
     * because availability is per-device (e.g. EXPLAIN requires Gemini Nano).
     * The seed value is empty so the gate stays closed until the real check
     * resolves — preventing a flash of an unsupported page.
     */
    private val availableOnboardingCases: StateFlow<List<OnboardingFeature>> = flow {
        emit(OnboardingFeature.availableCases())
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    /**
     * Onboarding features the user should see next.
     *
     * - First launch (`onboarded == false`): every available feature (full welcome tour).
     * - Subsequent launches: only features added since the last completion ("What's New").
     *
     * Mirrors `OnboardingPreferences.pendingFeatures()` on iOS. The list is empty
     * when the user is up-to-date, which gates the onboarding sheet off.
     */
    val pendingOnboardingFeatures: StateFlow<List<OnboardingFeature>> = combine(
        prefs.snapshot,
        availableOnboardingCases,
    ) { snap, available ->
        if (available.isEmpty()) {
            emptyList()
        } else if (!snap.onboarded) {
            available
        } else {
            available.filter { it.id !in snap.seenOnboardingFeatures }
        }
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())

    val highlights: Flow<List<Highlight>> = db.highlightDao().all()
    val notes: Flow<List<NoteEntity>> = db.noteDao().all()
    val history: Flow<List<HistoryEntity>> = db.historyDao().recent()
    val bookmarks: Flow<List<BookmarkEntity>> = db.bookmarkDao().all()
    val savedDevotionals: Flow<List<SavedDevotionalEntity>> = db.savedDevotionalDao().all()
    val chaptersRead: Flow<Int> = db.historyDao().chaptersRead()
    val totalVisits: Flow<Int?> = db.historyDao().totalVisits()
    val donations: Flow<List<biz.am2.swiftbible.data.DonationRecord>> = db.donationDao().all()
    val totalDonatedCents: Flow<Int> = db.donationDao().totalPaidCents()

    private val _showDonationPrompt = MutableStateFlow(false)
    val showDonationPrompt: StateFlow<Boolean> = _showDonationPrompt.asStateFlow()
    private val _donationCelebration = MutableStateFlow<biz.am2.swiftbible.data.DonationRecord?>(null)
    val donationCelebration: StateFlow<biz.am2.swiftbible.data.DonationRecord?> = _donationCelebration.asStateFlow()
    private val _pendingReviewRequest = MutableStateFlow(false)
    val pendingReviewRequest: StateFlow<Boolean> = _pendingReviewRequest.asStateFlow()

    init {
        viewModelScope.launch {
            biz.am2.swiftbible.donations.DonationService.get(application).events.collect { event ->
                when (event) {
                    is biz.am2.swiftbible.donations.DonationService.Event.Completed -> {
                        _donationCelebration.value = event.record
                    }
                    else -> { /* surface failure UI later if needed */ }
                }
            }
        }
        // Kick off Gemini Nano model download on supported devices so the
        // first Explain tap doesn't sit on the loading spinner. No-ops on
        // unsupported devices.
        viewModelScope.launch {
            biz.am2.swiftbible.data.GeminiNanoExplainer.prefetchModel()
        }
    }

    suspend fun fetchDevotional(date: java.time.LocalDate) = devotionals.fetch(date)

    suspend fun savedDevotionalForDate(date: java.time.LocalDate): SavedDevotionalEntity? =
        db.savedDevotionalDao().byDate(date.toString())

    fun saveDevotional(d: DailyDevotional) = viewModelScope.launch {
        db.savedDevotionalDao().upsert(
            SavedDevotionalEntity(
                forDate = d.for_date,
                message = d.message,
                anchorVerse = d.anchor_verse,
                seriesName = d.series_name,
            )
        )
        Analytics.capture(Analytics.Event.DevotionalViewed, mapOf("date" to d.for_date, "saved" to true))
    }

    fun unsaveDevotional(date: String) = viewModelScope.launch {
        db.savedDevotionalDao().deleteByDate(date)
    }

    init {
        viewModelScope.launch {
            val s = prefs.snapshot.first()
            loadBibleFor(s.version)
            if (s.showApocrypha) loadApocrypha()
            if (s.showEnoch) loadEnoch()
            if (s.showJubilees) loadJubilees()
            if (s.showTestaments) loadTestaments()
            if (s.show2Enoch) loadSecondEnoch()
            if (s.showDidache) loadDidache()
            if (s.show1Clement) loadFirstClement()
        }
    }

    fun setVersion(v: Version) {
        viewModelScope.launch {
            prefs.setVersion(v)
            loadBibleFor(v)
        }
    }

    private suspend fun loadBibleFor(v: Version) {
        _bible.value = _bible.value.copy(loading = true, version = v)
        val all = repository.loadBible(v)
        val ot = repository.orderedBooks(all.filter { it.name in BookCatalog.OLD_NAMES }, BookCatalog.OLD_NAMES)
        val nt = repository.orderedBooks(all.filter { it.name in BookCatalog.NEW_NAMES }, BookCatalog.NEW_NAMES)
        _bible.value = _bible.value.copy(loading = false, version = v, oldTestament = ot, newTestament = nt)
    }

    fun loadApocrypha() = viewModelScope.launch {
        if (_bible.value.apocrypha.isEmpty()) {
            val books = repository.loadApocrypha()
            _bible.value = _bible.value.copy(
                apocrypha = repository.orderedBooks(books, BookCatalog.APOCRYPHA_NAMES)
            )
        }
    }

    fun loadEnoch() = viewModelScope.launch {
        if (_bible.value.enoch.isEmpty()) _bible.value = _bible.value.copy(enoch = repository.loadEnoch())
    }
    fun loadJubilees() = viewModelScope.launch {
        if (_bible.value.jubilees.isEmpty()) _bible.value = _bible.value.copy(jubilees = repository.loadJubilees())
    }
    fun loadTestaments() = viewModelScope.launch {
        if (_bible.value.testaments.isEmpty()) _bible.value = _bible.value.copy(testaments = repository.loadTestaments12())
    }
    fun loadSecondEnoch() = viewModelScope.launch {
        if (_bible.value.secondEnoch.isEmpty()) _bible.value = _bible.value.copy(secondEnoch = repository.load2Enoch())
    }
    fun loadDidache() = viewModelScope.launch {
        if (_bible.value.didache.isEmpty()) _bible.value = _bible.value.copy(didache = repository.loadDidache())
    }
    fun loadFirstClement() = viewModelScope.launch {
        if (_bible.value.firstClement.isEmpty()) _bible.value = _bible.value.copy(firstClement = repository.load1Clement())
    }

    fun setShowApocrypha(b: Boolean) = viewModelScope.launch { prefs.setShowApocrypha(b); if (b) loadApocrypha() }
    fun setShowEnoch(b: Boolean) = viewModelScope.launch { prefs.setShowEnoch(b); if (b) loadEnoch() }
    fun setShowJubilees(b: Boolean) = viewModelScope.launch { prefs.setShowJubilees(b); if (b) loadJubilees() }
    fun setShowTestaments(b: Boolean) = viewModelScope.launch { prefs.setShowTestaments(b); if (b) loadTestaments() }
    fun setShow2Enoch(b: Boolean) = viewModelScope.launch { prefs.setShow2Enoch(b); if (b) loadSecondEnoch() }
    fun setShowDidache(b: Boolean) = viewModelScope.launch { prefs.setShowDidache(b); if (b) loadDidache() }
    fun setShow1Clement(b: Boolean) = viewModelScope.launch { prefs.setShow1Clement(b); if (b) loadFirstClement() }
    fun setShowThematic(b: Boolean) = viewModelScope.launch { prefs.setShowThematic(b) }
    fun setJesusRed(b: Boolean) = viewModelScope.launch { prefs.setJesusRed(b) }
    fun setFontSize(n: Int) = viewModelScope.launch { prefs.setFontSize(n) }
    fun setFontFamily(f: biz.am2.swiftbible.ui.theme.ReadingFont) = viewModelScope.launch { prefs.setFontFamily(f) }
    fun setTheme(t: biz.am2.swiftbible.ui.theme.ReadingTheme) = viewModelScope.launch { prefs.setTheme(t) }
    fun setOnboarded(b: Boolean) = viewModelScope.launch { prefs.setOnboarded(b) }

    /** Mark the given onboarding features as seen and flag the user as onboarded. */
    fun completeOnboarding(features: List<OnboardingFeature>) = viewModelScope.launch {
        prefs.markOnboardingFeaturesSeen(features.map { it.id })
        prefs.setOnboarded(true)
    }

    /** Wipe seen features + onboarded flag so the next launch re-runs the full tour. */
    fun replayOnboarding() = viewModelScope.launch { prefs.resetOnboarding() }
    fun setShowSummaries(b: Boolean) = viewModelScope.launch { prefs.setShowSummaries(b) }
    fun setHideBars(b: Boolean) = viewModelScope.launch { prefs.setHideBars(b) }
    fun setForceShowEvents(b: Boolean) = viewModelScope.launch { prefs.setForceShowEvents(b) }
    fun setLast(book: String, chapter: Int) = viewModelScope.launch { prefs.setLast(book, chapter) }

    fun setReminderEnabled(b: Boolean) = viewModelScope.launch {
        prefs.setReminderEnabled(b)
        val ctx = getApplication<Application>()
        if (b) {
            val s = prefs.snapshot.first()
            biz.am2.swiftbible.notifications.DevotionalReminderScheduler
                .schedule(ctx, s.reminderHour, s.reminderMinute)
        } else {
            biz.am2.swiftbible.notifications.DevotionalReminderScheduler.cancel(ctx)
        }
    }

    fun setReminderTime(hour: Int, minute: Int) = viewModelScope.launch {
        prefs.setReminderTime(hour, minute)
        val s = prefs.snapshot.first()
        if (s.reminderEnabled) {
            biz.am2.swiftbible.notifications.DevotionalReminderScheduler
                .schedule(getApplication(), hour, minute)
        }
    }

    fun bookByName(name: String): Book? = bible.value.allBooks.firstOrNull { it.name == name }

    fun addHighlight(book: String, chapter: Int, verse: Int, color: Long) = viewModelScope.launch {
        val v = bible.value.version.shortName
        db.highlightDao().upsert(Highlight(version = v, book = book, chapter = chapter, startingVerse = verse, color = color))
    }

    fun removeHighlight(book: String, chapter: Int, verse: Int) = viewModelScope.launch {
        val v = bible.value.version.shortName
        db.highlightDao().delete(v, book, chapter, verse)
    }

    fun saveNote(book: String, chapter: Int, verse: Int, text: String) = viewModelScope.launch {
        val v = bible.value.version.shortName
        if (text.isBlank()) {
            db.noteDao().forVerse(v, book, chapter, verse)?.let { db.noteDao().delete(it.id) }
        } else {
            db.noteDao().upsert(NoteEntity(version = v, book = book, chapter = chapter, startingVerse = verse, text = text))
        }
    }

    fun toggleBookmark(book: String, chapter: Int, verse: Int) = viewModelScope.launch {
        val v = bible.value.version.shortName
        db.bookmarkDao().upsert(BookmarkEntity(version = v, book = book, chapter = chapter, startingVerse = verse))
    }

    fun visitChapter(book: String, chapter: Int) = viewModelScope.launch {
        db.historyDao().visit(book, chapter)
        prefs.setLast(book, chapter)
    }

    fun recordHappyMoment() = viewModelScope.launch {
        if (biz.am2.swiftbible.BuildConfig.DEBUG) return@launch
        when (biz.am2.swiftbible.donations.HappyMomentTracker.record(prefs)) {
            biz.am2.swiftbible.donations.HappyMomentTracker.Action.PromptReview -> {
                _pendingReviewRequest.value = true
            }
            biz.am2.swiftbible.donations.HappyMomentTracker.Action.PromptDonation -> {
                if (!prefs.snapshot.first().donationOptOut) _showDonationPrompt.value = true
            }
            biz.am2.swiftbible.donations.HappyMomentTracker.Action.None -> {}
        }
    }

    fun consumeReviewRequest() {
        _pendingReviewRequest.value = false
    }

    fun showDonationPrompt() {
        _showDonationPrompt.value = true
    }

    fun dismissDonationPrompt(optOut: Boolean = false) = viewModelScope.launch {
        _showDonationPrompt.value = false
        if (optOut) prefs.setDonationOptOut(true)
    }

    fun dismissDonationCelebration() {
        _donationCelebration.value = null
    }

    suspend fun chapterTitle(book: String, chapter: Int) =
        summaries.chapterTitle(book, chapter, prefsState.value.summarySource)
    suspend fun passageSummaries(book: String, chapter: Int) =
        summaries.passageSummaries(book, chapter, prefsState.value.summarySource)

    fun setSummarySource(source: biz.am2.swiftbible.data.SummarySource) =
        viewModelScope.launch { prefs.setSummarySource(source) }

    fun setDonationOptOut(optOut: Boolean) =
        viewModelScope.launch { prefs.setDonationOptOut(optOut) }

    private val _cacheSizeBytes = MutableStateFlow(0L)
    val cacheSizeBytes: StateFlow<Long> = _cacheSizeBytes.asStateFlow()

    fun refreshCacheSize() = viewModelScope.launch {
        _cacheSizeBytes.value = devotionals.cacheSizeBytes()
    }

    fun clearAllCache() = viewModelScope.launch {
        devotionals.clearAllCache()
        _cacheSizeBytes.value = devotionals.cacheSizeBytes()
    }

    fun setCustomAccentHex(hex: String) = viewModelScope.launch { prefs.setCustomAccentHex(hex) }

    /**
     * True when the user has shown active financial support (donations) — gates donor-perks UI.
     * In DEBUG builds, always true so we can preview the screen.
     */
    val canAccessDonorPerks: StateFlow<Boolean> = totalDonatedCents
        .map { biz.am2.swiftbible.BuildConfig.DEBUG || it > 0 }
        .stateIn(viewModelScope, SharingStarted.Eagerly, biz.am2.swiftbible.BuildConfig.DEBUG)

    companion object {
        val Factory = object : ViewModelProvider.AndroidViewModelFactory() {
            override fun <T : ViewModel> create(modelClass: Class<T>, extras: androidx.lifecycle.viewmodel.CreationExtras): T {
                @Suppress("UNCHECKED_CAST")
                return AppViewModel(extras[ViewModelProvider.AndroidViewModelFactory.APPLICATION_KEY]!!) as T
            }
        }
    }
}
