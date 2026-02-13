//
//  FallbackFeatureControlRepository.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//


import Foundation
import os

/// Tries `primary` first. If it fails (throws), it falls back to `fallback`.
/// This keeps the Service unchanged: it still calls `refresh()` and stores snapshot.
final class FallbackFeatureControlRepository: FeatureControlRepository {
    private let primary: FeatureControlRepository
    private let fallback: FeatureControlRepository
    private let onPrimaryError: (@Sendable (Error) -> Void)?
    private let logger = Logger(subsystem: "com.heber.Pokedex", category: "FTT.Repository")

    init(primary: FeatureControlRepository,
         fallback: FeatureControlRepository,
         onPrimaryError: (@Sendable (Error) -> Void)? = nil) {
        self.primary = primary
        self.fallback = fallback
        self.onPrimaryError = onPrimaryError
    }

    func fetchSnapshot() async throws -> FeatureControlsSnapshot {
        do {
            return try await primary.fetchSnapshot()
        } catch {
#if DEBUG
            logger.error("[FTT] primary repo failed: \(String(describing: error), privacy: .public)")
#endif

            onPrimaryError?(error)
            return try await fallback.fetchSnapshot()
        }
    }
}
