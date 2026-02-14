//
//  FeatureControlsSnapshotStore.swift
//  Pokedex
//
//  Created by GitHub Copilot on 14/02/26.
//

import Foundation

protocol FeatureControlsSnapshotStore {
    func load() throws -> FeatureControlsSnapshot?
    func save(_ snapshot: FeatureControlsSnapshot) throws
}

/// Simple file-based implementation used to persist the last known-good snapshot.
///
/// Disk location: by default uses the Caches directory so the OS can clean it up
/// if needed, but the app will still benefit from offline startup between runs.
final class FileFeatureControlsSnapshotStore: FeatureControlsSnapshotStore {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileURL: URL? = nil,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            self.fileURL = (caches ?? URL(fileURLWithPath: NSTemporaryDirectory()))
                .appendingPathComponent("feature_controls_snapshot.json")
        }
        self.encoder = encoder
        self.decoder = decoder
    }

    func load() throws -> FeatureControlsSnapshot? {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return nil }
        return try decoder.decode(FeatureControlsSnapshot.self, from: data)
    }

    func save(_ snapshot: FeatureControlsSnapshot) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}
