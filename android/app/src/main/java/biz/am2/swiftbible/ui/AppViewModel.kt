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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
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

    val highlights: Flow<List<Highlight>> = db.highlightDao().all()
    val notes: Flow<List<NoteEntity>> = db.noteDao().all()
    val history: Flow<List<HistoryEntity>> = db.historyDao().recent()
    val bookmarks: Flow<List<BookmarkEntity>> = db.bookmarkDao().all()
    val savedDevotionals: Flow<List<SavedDevotionalEntity>> = db.savedDevotionalDao().all()
    val chaptersRead: Flow<Int> = db.historyDao().chaptersRead()
    val totalVisits: Flow<Int?> = db.historyDao().totalVisits()

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
    fun setShowSummaries(b: Boolean) = viewModelScope.launch { prefs.setShowSummaries(b) }
    fun setHideBars(b: Boolean) = viewModelScope.launch { prefs.setHideBars(b) }
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

    suspend fun chapterTitle(book: String, chapter: Int) = summaries.chapterTitle(book, chapter)
    suspend fun passageSummaries(book: String, chapter: Int) = summaries.passageSummaries(book, chapter)

    companion object {
        val Factory = object : ViewModelProvider.AndroidViewModelFactory() {
            override fun <T : ViewModel> create(modelClass: Class<T>, extras: androidx.lifecycle.viewmodel.CreationExtras): T {
                @Suppress("UNCHECKED_CAST")
                return AppViewModel(extras[ViewModelProvider.AndroidViewModelFactory.APPLICATION_KEY]!!) as T
            }
        }
    }
}
