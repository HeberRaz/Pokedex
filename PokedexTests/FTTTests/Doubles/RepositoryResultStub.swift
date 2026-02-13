//
//  RepositoryResultStub.swift
//  Pokedex
//
//  Created by Heber Alvarez on 13/02/26.
//
@testable import Pokedex

final class RepositoryResultStub: FeatureControlRepository {
    enum Mode { case success(FeatureControlsSnapshot), failure(Error) }
    var mode: Mode
    init(_ mode: Mode) { self.mode = mode }

    func fetchSnapshot() async throws -> FeatureControlsSnapshot {
        switch mode {
        case .success(let snap): return snap
        case .failure(let error): throw error
        }
    }
}
