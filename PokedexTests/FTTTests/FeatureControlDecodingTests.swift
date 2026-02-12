//
//  FeatureControlDecodingTests.swift
//  PokedexTests
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation
@testable import Pokedex
import XCTest

final class FeatureControlsDecodingTests: XCTestCase {

    func test_decodesSnapshot() throws {
        let json = """
        {
          "schemaVersion": 1,
          "controls": [
            { "id": "checkout_new_flow", "type": "flag", "enabled": false },
            { "id": "checkout_new_flow_rollout", "type": "rollout", "enabled": true, "percentage": 20 },
            { "id": "home_header_experiment", "type": "experiment", "enabled": true, "variants": { "A": 50, "B": 50 } },
            { "id": "login_attempts", "type": "throttle", "enabled": true, "maxPerMinute": 3 }
          ]
        }
        """

        let data = Data(json.utf8)
        let snapshot = try FeatureControlsDecoding.decode(from: data)

        XCTAssertEqual(snapshot.schemaVersion, 1)
        XCTAssertEqual(snapshot.controls.count, 4)

        let flag = snapshot.controls.first(where: { $0.id == "checkout_new_flow" })
        XCTAssertEqual(flag?.type, .flag)
        XCTAssertEqual(flag?.enabled, false)

        let rollout = snapshot.controls.first(where: { $0.type == .rollout })
        XCTAssertEqual(rollout?.percentage, 20)

        let exp = snapshot.controls.first(where: { $0.type == .experiment })
        XCTAssertEqual(exp?.variants?["A"], 50)

        let throttle = snapshot.controls.first(where: { $0.type == .throttle })
        XCTAssertEqual(throttle?.maxPerMinute, 3)
    }
}
