//
//  LocalDataReset.swift
//  Norma
//
//  Backs "reset all data" in Settings. Everything lives on this device with
//  no server copy, so this is irreversible. Deleting the profile sends the
//  app back to onboarding on its own.
//

import Foundation
import SwiftData

@MainActor
enum LocalDataReset {
    static func wipeAll(in context: ModelContext) throws {
        NotificationService.cancelAll()
        try context.delete(model: Bill.self)
        try context.delete(model: UserProfile.self)
        try context.save()
    }
}
