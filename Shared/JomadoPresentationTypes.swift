import Foundation
import SwiftUI

public enum RoutineType: String, Codable, CaseIterable, Hashable, Sendable {
    case hydration
    case exercise
    case stretching
    case eyeCare
    case posture
    case breathing
    case meditation
    case yoga
    case sleep
    case custom
    case generic

    public var displayName: String {
        switch self {
        case .hydration: "Hydration"
        case .exercise: "Exercise"
        case .stretching: "Stretching"
        case .eyeCare: "Eye Care"
        case .posture: "Posture"
        case .breathing: "Breathing"
        case .meditation: "Meditation"
        case .yoga: "Yoga"
        case .sleep: "Wind Down"
        case .custom: "Custom"
        case .generic: "Wellness"
        }
    }

    public var symbolName: String {
        switch self {
        case .hydration: "drop.fill"
        case .exercise: "figure.run"
        case .stretching: "figure.flexibility"
        case .eyeCare: "eye.fill"
        case .posture: "figure.stand"
        case .breathing: "wind"
        case .meditation: "figure.mind.and.body"
        case .yoga: "figure.yoga"
        case .sleep: "moon.stars.fill"
        case .custom: "sparkles"
        case .generic: "heart.fill"
        }
    }

    public var defaultCompletionLabel: String {
        switch self {
        case .hydration: "I drank water"
        case .exercise: "Workout done"
        case .stretching: "Done stretching"
        case .eyeCare: "Took my eye break"
        case .posture: "Posture reset done"
        case .breathing: "Breathing done"
        case .meditation: "Meditation complete"
        case .yoga: "Yoga done"
        case .sleep: "Started wind-down"
        case .custom, .generic: "Done"
        }
    }

    public var accentHex: String {
        switch self {
        case .hydration, .generic: "13BDEB"
        case .exercise: "23C987"
        case .stretching: "FF8A2B"
        case .eyeCare: "7C5CFC"
        case .posture: "FF6B6B"
        case .breathing: "2BC9C3"
        case .meditation: "8F68E8"
        case .yoga: "9A4DCC"
        case .sleep: "4E67D6"
        case .custom: "1597F4"
        }
    }
}

public enum ReminderPersonality: String, Codable, CaseIterable, Hashable, Sendable {
    case gentle
    case cute
    case playful
    case cheeky
    case charming
    case dramatic
    case strict
    case focused
}

public enum ReminderIntensity: String, Codable, CaseIterable, Hashable, Sendable {
    case soft
    case balanced
    case firm
}

public enum CompanionMascot: String, Codable, CaseIterable, Hashable, Sendable {
    case momo
    case momoMint
    case momoViolet
}

public enum ReminderUrgencyStage: String, Codable, CaseIterable, Hashable, Sendable {
    case normal
    case lightOverdue
    case mediumOverdue
    case redZone
    case completed

    public static func resolve(dueDate: Date, now: Date = .now, isCompleted: Bool = false) -> Self {
        if isCompleted { return .completed }

        let overdue = now.timeIntervalSince(dueDate)
        return switch overdue {
        case ..<180: .normal
        case ..<600: .lightOverdue
        case ..<1_200: .mediumOverdue
        default: .redZone
        }
    }

    public var label: String {
        switch self {
        case .normal: "Due now"
        case .lightOverdue: "A little late"
        case .mediumOverdue: "Overdue"
        case .redZone: "Needs attention"
        case .completed: "Completed"
        }
    }

    public var accentHex: String {
        switch self {
        case .normal: "13BDEB"
        case .lightOverdue: "F7C948"
        case .mediumOverdue: "FF8A2B"
        case .redZone: "FF4D5A"
        case .completed: "34C759"
        }
    }
}

public enum MascotExpression: String, Codable, CaseIterable, Hashable, Sendable {
    case idle
    case hello
    case waiting
    case hopeful
    case pouty
    case concerned
    case urgent
    case sleepy
    case focused
    case proud
    case celebrating
    case cheeky
    case dramatic

    public var accessibilityDescription: String {
        switch self {
        case .idle: "Momo rests calmly"
        case .hello: "Momo waves hello"
        case .waiting: "Momo waits attentively"
        case .hopeful: "Momo smiles hopefully"
        case .pouty: "Momo has a gentle pout"
        case .concerned: "Momo looks concerned"
        case .urgent: "Momo looks ready for action"
        case .sleepy: "Momo looks sleepy"
        case .focused: "Momo looks focused"
        case .proud: "Momo looks proud"
        case .celebrating: "Momo celebrates"
        case .cheeky: "Momo gives a cheeky wink"
        case .dramatic: "Momo strikes a dramatic pose"
        }
    }
}

public enum MascotAnimationCue: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case idleFloat
    case gentleBounce
    case wave
    case blink
    case pout
    case concernedPulse
    case dramaticWobble
    case breathe
    case celebrate
}

public extension Color {
    init(jomadoHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        switch cleaned.count {
        case 8:
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            alpha = Double(value & 0xFF) / 255
        default:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            alpha = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public extension ReminderPersonality {
    var displayName: String {
        switch self {
        case .gentle: "Gentle"
        case .cute: "Cute"
        case .playful: "Playful"
        case .cheeky: "Cheeky"
        case .charming: "Charming"
        case .dramatic: "Dramatic"
        case .strict: "Strict"
        case .focused: "Focused"
        }
    }
}

public extension ReminderIntensity {
    var displayName: String { rawValue.capitalized }
}

public extension CompanionMascot {
    var displayName: String {
        switch self {
        case .momo: "Momo Blue"
        case .momoMint: "Momo Mint"
        case .momoViolet: "Momo Violet"
        }
    }
}
