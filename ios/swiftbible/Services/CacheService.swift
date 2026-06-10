//
//  CacheService.swift
//  swiftbible
//
//  Cache service for managing file-based storage of devotionals and other app data
//

import Foundation

class CacheService {
    static let shared = CacheService()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let devotionalsCacheDirectory: URL
    private let expirationDays = 90

    private init() {
        // Get the app's Documents directory
        guard let documentsDirectory = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Unable to access documents directory")
        }

        // Create cache directory structure
        cacheDirectory = documentsDirectory.appendingPathComponent("Cache")
        devotionalsCacheDirectory = cacheDirectory.appendingPathComponent("Devotionals")

        // Create directories if they don't exist
        createDirectoriesIfNeeded()
    }

    // MARK: - Directory Management

    private func createDirectoriesIfNeeded() {
        let directories = [cacheDirectory, devotionalsCacheDirectory]

        for directory in directories where !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
    }

    // MARK: - Devotional Caching

    func saveDevotional(_ devotional: DailyDevotional, for date: Date) {
        let dateString = formatDate(date)
        let fileURL = devotionalsCacheDirectory
            .appendingPathComponent("\(dateString).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(devotional)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving devotional to cache: \(error)")
        }
    }

    func loadDevotional(for date: Date) -> DailyDevotional? {
        let dateString = formatDate(date)
        let fileURL = devotionalsCacheDirectory
            .appendingPathComponent("\(dateString).json")

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let devotional = try decoder.decode(DailyDevotional.self, from: data)
            return devotional
        } catch {
            print("Error loading devotional from cache: \(error)")
            return nil
        }
    }

    // MARK: - Cache Management

    func clearAllCache() {
        do {
            // Remove entire cache directory
            if fileManager.fileExists(atPath: cacheDirectory.path) {
                try fileManager.removeItem(at: cacheDirectory)
            }

            // Recreate directories
            createDirectoriesIfNeeded()
        } catch {
            print("Error clearing cache: \(error)")
        }
    }

    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0

        guard fileManager.fileExists(atPath: cacheDirectory.path) else {
            return 0
        }

        if let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(
                        forKeys: [.fileSizeKey]
                    )
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                } catch {
                    print("Error getting file size: \(error)")
                }
            }
        }

        return totalSize
    }

    func getCacheSizeFormatted() -> String {
        let bytes = getCacheSize()

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file

        return formatter.string(fromByteCount: bytes)
    }

    func cleanExpiredCache() {
        guard let enumerator = fileManager.enumerator(
            at: devotionalsCacheDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let expirationDate = Calendar.current.date(
            byAdding: .day,
            value: -expirationDays,
            to: Date()
        ) ?? Date()

        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(
                    forKeys: [.creationDateKey]
                )

                if let creationDate = resourceValues.creationDate,
                   creationDate < expirationDate {
                    try fileManager.removeItem(at: fileURL)
                    print("Removed expired cache file: \(fileURL.lastPathComponent)")
                }
            } catch {
                print("Error processing file for expiration: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
