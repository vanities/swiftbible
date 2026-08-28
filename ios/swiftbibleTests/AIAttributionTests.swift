//
//  AIAttributionTests.swift
//  swiftbibleTests
//
//  The devotional row's `model` column is rendered into the AI-attribution
//  disclosure the user reads. When the Edge Function moved from gpt-5.4 to the
//  GPT-5.6 family (Sol/Terra/Luna), the old renderer did a naive "gpt-" ->
//  "GPT-" swap, which turned "gpt-5.6-terra" into "GPT-5.6-terra". These pin
//  the tiered-id formatting and the fallback, both of which are user-visible.
//
//  Mirrored on Android by
//  android/app/src/test/java/biz/am2/swiftbible/ui/AIAttributionTest.kt.
//

import XCTest
@testable import swiftbible

final class AIAttributionTests: XCTestCase {

    /// displayName is private; exercise it through the public disclosure text.
    private func rendered(_ model: String?) -> String {
        AIAttribution.devotionalSingle(model: model)
    }

    func testTieredModelIdRendersWithSpacedCapitalizedTier() {
        XCTAssertTrue(rendered("gpt-5.6-terra").contains("GPT-5.6 Terra"),
                      "tiered id should render as 'GPT-5.6 Terra', got: \(rendered("gpt-5.6-terra"))")
        XCTAssertTrue(rendered("gpt-5.6-sol").contains("GPT-5.6 Sol"))
        XCTAssertTrue(rendered("gpt-5.6-luna").contains("GPT-5.6 Luna"))
    }

    func testTieredModelIdDoesNotRenderWithTrailingHyphen() {
        XCTAssertFalse(rendered("gpt-5.6-terra").contains("GPT-5.6-terra"),
                       "the old naive prefix swap leaked a hyphenated tier into the UI")
    }

    func testTwoPartModelIdStillRenders() {
        XCTAssertTrue(rendered("gpt-5.4").contains("GPT-5.4"))
    }

    func testLegacyMiniIdRenders() {
        XCTAssertTrue(rendered("gpt-5.4-mini").contains("GPT-5.4 Mini"))
    }

    func testNilAndEmptyFallBackToCurrentModel() {
        XCTAssertTrue(rendered(nil).contains(AIAttribution.fallbackModel))
        XCTAssertTrue(rendered("").contains(AIAttribution.fallbackModel))
    }

    /// The fallback is what older rows (no `model` value) display, so it should
    /// track whatever the Edge Function currently generates with.
    func testFallbackIsTheCurrentGenerationModel() {
        XCTAssertEqual(AIAttribution.fallbackModel, "GPT-5.6 Terra")
    }
}
