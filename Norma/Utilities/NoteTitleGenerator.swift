//
//  NoteTitleGenerator.swift
//  Norma
//
//  Generates a stable, brand-voice placeholder title for an unnamed note.
//  Seeded by note ID so the same note always renders the same title across
//  reloads, processes, and devices.
//

import Foundation

enum NoteTitleGenerator {
    private static let determiners = [
        "a", "the", "today's", "another"
    ]

    private static let adjectives = [
        "quiet", "small", "quick", "stray",
        "brief", "idle", "soft", "passing",
        "short", "new"
    ]

    private static let nouns = [
        "thought", "page", "entry", "fragment", "draft",
        "moment", "glance", "confession", "receipt", "ledger",
        "witness", "tally", "count", "line", "scrap",
        "chapter", "footnote", "margin", "record", "note"
    ]

    // Adjective+noun pairings that don't read well — filtered out.
    private static let blockedAdjectiveNounPairs: Set<String> = [
        "idle ledger", "idle confession", "idle witness",
        "idle receipt", "idle tally", "idle count",
        "soft tally", "soft count", "soft ledger",
        "stray ledger", "stray witness",
        "passing tally", "passing count"
    ]

    static func title(for noteId: UUID) -> String {
        var rng = SeededRNG(seed: noteId.stableSeed)

        switch rng.next() % 3 {
        case 0:
            return "today"
        case 1:
            return "\(pick(determiners, &rng)) \(pick(nouns, &rng))"
        default:
            for _ in 0..<8 {
                let adj = pick(adjectives, &rng)
                let noun = pick(nouns, &rng)
                if !blockedAdjectiveNounPairs.contains("\(adj) \(noun)") {
                    let det = pick(determiners, &rng)
                    return "\(det) \(adj) \(noun)"
                }
            }
            return "\(pick(determiners, &rng)) \(pick(nouns, &rng))"
        }
    }

    private static func pick<T>(_ array: [T], _ rng: inout SeededRNG) -> T {
        array[Int(rng.next() % UInt64(array.count))]
    }
}

private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEFCAFEBABE : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

private extension UUID {
    // FNV-1a hash of the UUID's raw bytes — stable across processes & devices.
    var stableSeed: UInt64 {
        var hash: UInt64 = 0xCBF29CE484222325
        withUnsafeBytes(of: uuid) { buffer in
            for byte in buffer {
                hash ^= UInt64(byte)
                hash &*= 0x100000001B3
            }
        }
        return hash
    }
}
