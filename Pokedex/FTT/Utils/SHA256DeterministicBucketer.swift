//
//  SHA256DeterministicBucketer.swift
//  Pokedex
//
//  Created by Heber Alvarez on 12/02/26.
//

import Foundation
import CryptoKit

/// Deterministic bucketer using SHA256. Portable to Android:
/// - Build key: "\(userId)|\(controlId)"
/// - SHA256 over UTF-8 bytes
/// - Take first 8 bytes as UInt64 (big-endian)
/// - bucket = Int(value % 100)
/// ⚠️ Check with Android, this should be homologated I think
final class SHA256DeterministicBucketer: DeterministicBucketer {

    func bucket(for controlId: String, userId: String) -> Int {
        let key = "\(userId)|\(controlId)"
        let data = Data(key.utf8)

        let digest = SHA256.hash(data: data)

        // Take first 8 bytes -> UInt64 (big-endian)
        let first8 = digest.prefix(8)
        var value: UInt64 = 0
        for byte in first8 {
            value = (value << 8) | UInt64(byte)
        }

        return Int(value % 100)
    }
}
