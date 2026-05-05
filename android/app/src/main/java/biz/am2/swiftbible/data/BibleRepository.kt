package biz.am2.swiftbible.data

import android.content.Context
import biz.am2.swiftbible.model.Book
import biz.am2.swiftbible.model.BookCatalog
import biz.am2.swiftbible.model.Testament
import biz.am2.swiftbible.model.Version
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

class BibleRepository(private val appContext: Context) {

    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
    }

    private val bibleCache = mutableMapOf<Version, List<Book>>()
    private val extraCache = mutableMapOf<String, List<Book>>()

    suspend fun loadBible(version: Version): List<Book> = withContext(Dispatchers.IO) {
        bibleCache[version]?.let { return@withContext it }
        val books = if (version == Version.ORIGINAL) loadOriginal() else parse("${version.filename}.json").map { book ->
            book.apply {
                this.version = version
                testament = when (book.name) {
                    in BookCatalog.OLD_NAMES -> Testament.OLD
                    in BookCatalog.NEW_NAMES -> Testament.NEW
                    else -> Testament.OLD
                }
            }
        }
        bibleCache[version] = books
        books
    }

    private fun loadOriginal(): List<Book> {
        val hebrew = parse("hebrew.json").map { it.apply { version = Version.ORIGINAL; testament = Testament.OLD } }
        val greek = parse("greek.json").map { it.apply { version = Version.ORIGINAL; testament = Testament.NEW } }
        return hebrew + greek
    }

    suspend fun loadExtra(filename: String, testament: Testament): List<Book> = withContext(Dispatchers.IO) {
        extraCache[filename]?.let { return@withContext it }
        val books = parse("$filename.json").map { it.apply { this.testament = testament } }
        extraCache[filename] = books
        books
    }

    suspend fun loadApocrypha() = loadExtra("apocrypha", Testament.APOCRYPHA)
    suspend fun loadEnoch() = loadExtra("enoch", Testament.ENOCH)
    suspend fun loadJubilees() = loadExtra("jubilees", Testament.JUBILEES)
    suspend fun loadTestaments12() = loadExtra("testaments12", Testament.TESTAMENTS)
    suspend fun load2Enoch() = loadExtra("2enoch", Testament.SECOND_ENOCH)
    suspend fun loadDidache() = loadExtra("didache", Testament.DIDACHE)
    suspend fun load1Clement() = loadExtra("1clement", Testament.FIRST_CLEMENT)

    private fun parse(asset: String): List<Book> {
        appContext.assets.open(asset).use { stream ->
            val text = stream.bufferedReader().readText()
            return json.decodeFromString<List<Book>>(text)
        }
    }

    fun orderedBooks(books: List<Book>, canonicalOrder: List<String>): List<Book> {
        val index = books.associateBy { it.name }
        val ordered = canonicalOrder.mapNotNull { index[it] }
        val orderedNames = canonicalOrder.toSet()
        val rest = books.filter { it.name !in orderedNames }
        return ordered + rest
    }
}
