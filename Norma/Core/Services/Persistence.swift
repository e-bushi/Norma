//
//  Persistence.swift
//  Norma
//
//  One place for "save, and if it fails put the context back." Callers show
//  `saveFailure` instead of swallowing the error.
//

import Foundation
import SwiftData

@MainActor
enum Persistence {
    static let saveFailure = "couldn't save. try again."

    static func save(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}
