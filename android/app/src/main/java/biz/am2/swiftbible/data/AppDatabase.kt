package biz.am2.swiftbible.data

import android.content.Context
import androidx.room.ColumnInfo
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Index
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow

@Entity(
    tableName = "highlights",
    indices = [Index(value = ["version", "book", "chapter", "startingVerse"], unique = true)],
)
data class Highlight(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val version: String,
    val book: String,
    val chapter: Int,
    val startingVerse: Int,
    @ColumnInfo(defaultValue = "0") val color: Long = 0xFFFFD54F,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "notes",
    indices = [Index(value = ["version", "book", "chapter", "startingVerse"], unique = true)],
)
data class NoteEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val version: String,
    val book: String,
    val chapter: Int,
    val startingVerse: Int,
    val text: String,
    val updatedAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "history",
    indices = [Index(value = ["book", "chapter"], unique = true)],
)
data class HistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val book: String,
    val chapter: Int,
    val visits: Int = 1,
    val lastVisit: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "bookmarks",
    indices = [Index(value = ["version", "book", "chapter", "startingVerse"], unique = true)],
)
data class BookmarkEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val version: String,
    val book: String,
    val chapter: Int,
    val startingVerse: Int,
    val label: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "saved_devotionals",
    indices = [Index(value = ["forDate"], unique = true)],
)
data class SavedDevotionalEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val forDate: String,
    val message: String,
    val anchorVerse: String? = null,
    val seriesName: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "donations",
    indices = [Index(value = ["purchaseToken"], unique = true)],
)
data class DonationRecord(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val purchaseToken: String,
    val productId: String,
    val amountCents: Int,
    val currency: String = "USD",
    val purchaseTime: Long = System.currentTimeMillis(),
    val status: String = "completed",
)

@Entity(
    tableName = "reading_sessions",
    indices = [
        Index(value = ["bookName", "chapterNumber"]),
        Index(value = ["dayEpoch"]),
    ],
)
data class ReadingSession(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val bookName: String,
    val chapterNumber: Int,
    val version: String,
    val startedAt: Long = System.currentTimeMillis(),
    val durationMs: Long = 0,
    // Truncated to midnight in the local calendar so streak/heatmap queries
    // are cheap. Devotional opens use bookName == "__devotional__" so they
    // count toward streak without polluting chapter aggregates.
    val dayEpoch: Long = System.currentTimeMillis(),
)

@Entity(tableName = "earned_badges")
data class EarnedBadge(
    @PrimaryKey val badgeId: String,
    val earnedAt: Long = System.currentTimeMillis(),
)

@Dao
interface HighlightDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(h: Highlight)

    @Query("DELETE FROM highlights WHERE version=:v AND book=:b AND chapter=:c AND startingVerse=:sv")
    suspend fun delete(v: String, b: String, c: Int, sv: Int)

    @Query("SELECT * FROM highlights ORDER BY createdAt DESC")
    fun all(): Flow<List<Highlight>>

    @Query("SELECT * FROM highlights WHERE book=:b AND chapter=:c")
    fun forChapter(b: String, c: Int): Flow<List<Highlight>>
}

@Dao
interface NoteDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(n: NoteEntity)

    @Query("DELETE FROM notes WHERE id=:id")
    suspend fun delete(id: Long)

    @Query("SELECT * FROM notes ORDER BY updatedAt DESC")
    fun all(): Flow<List<NoteEntity>>

    @Query("SELECT * FROM notes WHERE book=:b AND chapter=:c")
    fun forChapter(b: String, c: Int): Flow<List<NoteEntity>>

    @Query("SELECT * FROM notes WHERE version=:v AND book=:b AND chapter=:c AND startingVerse=:sv LIMIT 1")
    suspend fun forVerse(v: String, b: String, c: Int, sv: Int): NoteEntity?
}

@Dao
interface HistoryDao {
    @Query("INSERT OR REPLACE INTO history (id, book, chapter, visits, lastVisit) VALUES ((SELECT id FROM history WHERE book=:b AND chapter=:c), :b, :c, COALESCE((SELECT visits FROM history WHERE book=:b AND chapter=:c),0)+1, :now)")
    suspend fun visit(b: String, c: Int, now: Long = System.currentTimeMillis())

    @Query("SELECT * FROM history ORDER BY lastVisit DESC LIMIT 50")
    fun recent(): Flow<List<HistoryEntity>>

    @Query("SELECT * FROM history ORDER BY lastVisit DESC LIMIT 1")
    suspend fun last(): HistoryEntity?

    @Query("SELECT COUNT(*) FROM history")
    fun chaptersRead(): Flow<Int>

    @Query("SELECT SUM(visits) FROM history")
    fun totalVisits(): Flow<Int?>
}

@Dao
interface BookmarkDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(b: BookmarkEntity)

    @Query("DELETE FROM bookmarks WHERE id=:id")
    suspend fun delete(id: Long)

    @Query("SELECT * FROM bookmarks ORDER BY createdAt DESC")
    fun all(): Flow<List<BookmarkEntity>>
}

@Dao
interface SavedDevotionalDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(d: SavedDevotionalEntity)

    @Query("DELETE FROM saved_devotionals WHERE forDate=:date")
    suspend fun deleteByDate(date: String)

    @Query("SELECT * FROM saved_devotionals ORDER BY forDate DESC")
    fun all(): Flow<List<SavedDevotionalEntity>>

    @Query("SELECT * FROM saved_devotionals WHERE forDate=:date LIMIT 1")
    suspend fun byDate(date: String): SavedDevotionalEntity?
}

@Dao
interface DonationDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(d: DonationRecord)

    @Query("SELECT * FROM donations ORDER BY purchaseTime DESC")
    fun all(): Flow<List<DonationRecord>>

    @Query("SELECT COALESCE(SUM(amountCents), 0) FROM donations WHERE status='completed'")
    fun totalPaidCents(): Flow<Int>

    @Query("SELECT COUNT(*) FROM donations WHERE status='completed'")
    fun donationCount(): Flow<Int>
}

@Dao
interface ReadingSessionDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(session: ReadingSession): Long

    @Query("SELECT * FROM reading_sessions ORDER BY startedAt DESC LIMIT :limit")
    fun recent(limit: Int = 20): Flow<List<ReadingSession>>

    @Query("SELECT * FROM reading_sessions WHERE bookName != '__devotional__'")
    suspend fun allBookSessions(): List<ReadingSession>

    @Query("SELECT * FROM reading_sessions WHERE bookName=:book")
    suspend fun forBook(book: String): List<ReadingSession>

    @Query("SELECT * FROM reading_sessions ORDER BY dayEpoch DESC")
    suspend fun allByDay(): List<ReadingSession>

    @Query("SELECT * FROM reading_sessions WHERE dayEpoch >= :sinceEpoch")
    suspend fun since(sinceEpoch: Long): List<ReadingSession>

    @Query("SELECT * FROM reading_sessions WHERE bookName=:book AND chapterNumber=:chapter AND dayEpoch=:day LIMIT 1")
    suspend fun forBookChapterOnDay(book: String, chapter: Int, day: Long): ReadingSession?

    @Query("SELECT COUNT(*) FROM reading_sessions WHERE bookName='__devotional__'")
    suspend fun devotionalCount(): Int

    @Query("SELECT COUNT(DISTINCT bookName || '-' || chapterNumber) FROM reading_sessions WHERE bookName != '__devotional__'")
    fun distinctChaptersRead(): Flow<Int>
}

@Dao
interface EarnedBadgeDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(badge: EarnedBadge): Long

    @Query("SELECT * FROM earned_badges")
    fun all(): Flow<List<EarnedBadge>>

    @Query("SELECT badgeId FROM earned_badges")
    suspend fun earnedIds(): List<String>

    @Query("SELECT COUNT(*) FROM earned_badges")
    fun count(): Flow<Int>
}

@Database(
    entities = [
        Highlight::class,
        NoteEntity::class,
        HistoryEntity::class,
        BookmarkEntity::class,
        SavedDevotionalEntity::class,
        DonationRecord::class,
        ReadingSession::class,
        EarnedBadge::class,
    ],
    version = 4,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun highlightDao(): HighlightDao
    abstract fun noteDao(): NoteDao
    abstract fun historyDao(): HistoryDao
    abstract fun bookmarkDao(): BookmarkDao
    abstract fun savedDevotionalDao(): SavedDevotionalDao
    abstract fun donationDao(): DonationDao
    abstract fun readingSessionDao(): ReadingSessionDao
    abstract fun earnedBadgeDao(): EarnedBadgeDao

    companion object {
        @Volatile private var instance: AppDatabase? = null
        fun get(context: Context): AppDatabase = instance ?: synchronized(this) {
            instance ?: Room.databaseBuilder(context.applicationContext, AppDatabase::class.java, "swiftbible.db")
                .fallbackToDestructiveMigration()
                .build().also { instance = it }
        }
    }
}
