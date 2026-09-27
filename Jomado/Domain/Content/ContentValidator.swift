import Foundation

enum ContentValidationError: Error, Equatable, LocalizedError {
    case unsupportedSchema(Int)
    case emptyPack
    case duplicateID(String)
    case localeMismatch(itemID: String)
    case unsafeItem(String)
    case invalidCharacter(itemID: String)
    case emptyField(itemID: String, field: String)
    case fieldTooLong(itemID: String, field: String, limit: Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            "Unsupported content schema version \(version)."
        case .emptyPack:
            "The content pack has no items."
        case .duplicateID(let id):
            "Duplicate content ID: \(id)."
        case .localeMismatch(let itemID):
            "Content item \(itemID) does not match the pack locale."
        case .unsafeItem(let id):
            "Content item \(id) has not passed required safety review."
        case .invalidCharacter(let itemID):
            "Content item \(itemID) references an unsupported mascot."
        case .emptyField(let itemID, let field):
            "Content item \(itemID) has an empty \(field)."
        case .fieldTooLong(let itemID, let field, let limit):
            "Content item \(itemID) exceeds the \(limit)-character limit for \(field)."
        }
    }
}

enum ContentValidator {
    private struct TextRule {
        let name: String
        let text: String
        let limit: Int
    }

    static func validate(_ pack: ContentPack) throws {
        guard pack.schemaVersion == 1 else {
            throw ContentValidationError.unsupportedSchema(pack.schemaVersion)
        }
        guard !pack.items.isEmpty else {
            throw ContentValidationError.emptyPack
        }

        var identifiers = Set<String>()

        for item in pack.items {
            guard identifiers.insert(item.id).inserted else {
                throw ContentValidationError.duplicateID(item.id)
            }
            guard item.locale == pack.pack.locale else {
                throw ContentValidationError.localeMismatch(itemID: item.id)
            }
            guard item.safety.medicalClaimReviewed, item.safety.ageSafe else {
                throw ContentValidationError.unsafeItem(item.id)
            }
            guard item.mascot.character == "momo" else {
                throw ContentValidationError.invalidCharacter(itemID: item.id)
            }

            let rules = [
                TextRule(name: "notification.title", text: item.variants.notification.title, limit: 32),
                TextRule(name: "notification.body", text: item.variants.notification.body, limit: 90),
                TextRule(name: "liveActivity.headline", text: item.variants.liveActivity.headline, limit: 26),
                TextRule(name: "liveActivity.body", text: item.variants.liveActivity.body, limit: 72),
                TextRule(name: "liveActivity.compactStatus", text: item.variants.liveActivity.compactStatus, limit: 10),
                TextRule(name: "inApp.eyebrow", text: item.variants.inApp.eyebrow, limit: 24),
                TextRule(name: "inApp.headline", text: item.variants.inApp.headline, limit: 36),
                TextRule(name: "inApp.body", text: item.variants.inApp.body, limit: 160),
                TextRule(name: "inApp.completionLabel", text: item.variants.inApp.completionLabel, limit: 32),
                TextRule(name: "mascot.accessibilityLabel", text: item.mascot.accessibilityLabel, limit: 80)
            ]

            for rule in rules {
                let trimmed = rule.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    throw ContentValidationError.emptyField(itemID: item.id, field: rule.name)
                }
                guard rule.text.count <= rule.limit else {
                    throw ContentValidationError.fieldTooLong(
                        itemID: item.id,
                        field: rule.name,
                        limit: rule.limit
                    )
                }
            }

            if let tip = item.variants.inApp.tip, tip.count > 120 {
                throw ContentValidationError.fieldTooLong(
                    itemID: item.id,
                    field: "inApp.tip",
                    limit: 120
                )
            }
        }
    }
}

