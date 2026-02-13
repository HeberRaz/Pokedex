//
//  UserDefaultsLocalOverrideStoreTests.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//

import XCTest
@testable import Pokedex

final class UserDefaultsLocalOverrideStoreTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsLocalOverrideStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName) // start clean
    }

    override func tearDown() {
        if let suiteName {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Bool overrides

    func test_boolOverride_setAndGet_returnsStoredValue() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setBoolOverride(true, for: "flag_a")
        XCTAssertEqual(store.overrideBool(for: "flag_a"), true)

        store.setBoolOverride(false, for: "flag_a")
        XCTAssertEqual(store.overrideBool(for: "flag_a"), false)
    }

    func test_boolOverride_remove_returnsNil() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setBoolOverride(true, for: "flag_a")
        store.setBoolOverride(nil as Bool?, for: "flag_a")

        XCTAssertNil(store.overrideBool(for: "flag_a"))
    }

    // MARK: - Variant overrides

    func test_variantOverride_setAndGet_returnsStoredVariant() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setVariantOverride(.a, for: "exp_a")
        XCTAssertEqual(store.overrideVariant(for: "exp_a"), .a)

        store.setVariantOverride(.b, for: "exp_a")
        XCTAssertEqual(store.overrideVariant(for: "exp_a"), .b)
    }

    func test_variantOverride_remove_returnsNil() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setVariantOverride(.a, for: "exp_a")
        store.setVariantOverride(nil as ExperimentVariant?, for: "exp_a")

        XCTAssertNil(store.overrideVariant(for: "exp_a"))
    }

    // MARK: - Throttle overrides

    func test_throttleOverride_setAndGet_returnsStoredConfig() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setThrottleOverride(ThrottleConfig(maxPerMinute: 3), for: "throttle_a")

        let config = store.overrideThrottle(for: "throttle_a")
        XCTAssertEqual(config?.maxPerMinute, 3)
    }

    func test_throttleOverride_remove_returnsNil() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setThrottleOverride(ThrottleConfig(maxPerMinute: 3), for: "throttle_a")
        store.setThrottleOverride(nil as ThrottleConfig?, for: "throttle_a")

        XCTAssertNil(store.overrideThrottle(for: "throttle_a"))
    }

    func test_throttleOverride_zeroOrInvalid_returnsNil() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        // Guard: if someone writes 0 manually, store should interpret as "no override".
        userDefaults.set(0, forKey: "ftt.override.throttle.throttle_a")
        XCTAssertNil(store.overrideThrottle(for: "throttle_a"))
    }

    // MARK: - Clear

    func test_clear_id_removesAllOverrideTypesForThatId() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setBoolOverride(true, for: "x")
        store.setVariantOverride(.b, for: "x")
        store.setThrottleOverride(ThrottleConfig(maxPerMinute: 5), for: "x")

        store.clear(id: "x")

        XCTAssertNil(store.overrideBool(for: "x"))
        XCTAssertNil(store.overrideVariant(for: "x"))
        XCTAssertNil(store.overrideThrottle(for: "x"))
    }

    func test_clearAll_removesAllOverridesForAllIds() {
        let store = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)

        store.setBoolOverride(true, for: "flag_1")
        store.setBoolOverride(false, for: "flag_2")
        store.setVariantOverride(.a, for: "exp_1")
        store.setThrottleOverride(ThrottleConfig(maxPerMinute: 2), for: "throttle_1")

        store.clearAll()

        XCTAssertNil(store.overrideBool(for: "flag_1"))
        XCTAssertNil(store.overrideBool(for: "flag_2"))
        XCTAssertNil(store.overrideVariant(for: "exp_1"))
        XCTAssertNil(store.overrideThrottle(for: "throttle_1"))
    }

    // MARK: - Guardrails

    func test_overridesDisabled_readsNil_andWritesNoOp_butClearStillWorks() {
        let storeEnabled = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: true)
        storeEnabled.setBoolOverride(true, for: "flag_a")
        XCTAssertEqual(storeEnabled.overrideBool(for: "flag_a"), true)

        // Now use disabled store on same suite
        let storeDisabled = UserDefaultsLocalOverrideStore(userDefaults: userDefaults, isOverridesEnabled: false)

        // Reads should be nil when disabled
        XCTAssertNil(storeDisabled.overrideBool(for: "flag_a"))

        // Writes should be no-op when disabled
        storeDisabled.setBoolOverride(false, for: "flag_a")

        // Still nil for disabled reads
        XCTAssertNil(storeDisabled.overrideBool(for: "flag_a"))

        // But "enabled" store still sees old value because disabled writes did nothing
        XCTAssertEqual(storeEnabled.overrideBool(for: "flag_a"), true)

        // Clear should still work even when disabled (hygiene)
        storeDisabled.clearAll()
        XCTAssertNil(storeEnabled.overrideBool(for: "flag_a"))
    }
}
