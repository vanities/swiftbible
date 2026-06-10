//
//  BibleServiceTests.swift
//  swiftbibleTests
//
//  Pins the bundled-data loading paths (and therefore the generic
//  collection loader): every collection must decode, be non-empty, and be
//  stamped with the right testament.
//

import XCTest
@testable import swiftbible

final class BibleServiceTests: XCTestCase {
    private let service = BibleService.shared

    func testKJVLoadsFullProtestantCanon() {
        let (old, new) = service.fetchBibleData(version: .kjv)
        XCTAssertEqual(old.count, 39)
        XCTAssertEqual(new.count, 27)
    }

    func testFetchBookFindsCanonicalBook() throws {
        let genesis = try XCTUnwrap(service.fetchBook(named: "Genesis", version: .kjv))
        XCTAssertEqual(genesis.chapters.count, 50)
        XCTAssertEqual(genesis.testament, .old)
    }

    func testEnochLoadsItsFiveSections() {
        let enoch = service.fetchEnochData()
        XCTAssertEqual(enoch.count, 5)
        XCTAssertTrue(enoch.allSatisfy { $0.testament == .enoch })
    }

    func testStandaloneCollectionsLoadAndAreStamped() {
        XCTAssertFalse(service.fetchApocryphaData().isEmpty)
        XCTAssertTrue(service.fetchApocryphaData().allSatisfy { $0.testament == .apocrypha })
        XCTAssertFalse(service.fetchJubileesData().isEmpty)
        XCTAssertTrue(service.fetchJubileesData().allSatisfy { $0.testament == .jubilees })
        XCTAssertFalse(service.fetchTestamentsData().isEmpty)
        XCTAssertFalse(service.fetchSecondEnochData().isEmpty)
        XCTAssertFalse(service.fetchDidacheData().isEmpty)
        XCTAssertFalse(service.fetchFirstClementData().isEmpty)
    }

    func testFetchBookFallsBackToStandaloneCollections() throws {
        let watchers = try XCTUnwrap(service.fetchBook(named: "The Book of the Watchers"))
        XCTAssertEqual(watchers.testament, .enoch)
    }
}
