import Foundation

enum CompletionVerificationMethod: String, Codable, Hashable, Sendable {
    case trustBased
    case healthData
    case cameraAnalysis
}

struct CompletionVerificationRequest: Hashable, Sendable {
    let occurrenceID: UUID
    let routineID: UUID
    let routineType: RoutineType
    let requestedAt: Date
}

struct CompletionVerificationResult: Hashable, Sendable {
    let method: CompletionVerificationMethod
    let isVerified: Bool
    let verifiedAt: Date
}

protocol RoutineCompletionVerifying: Sendable {
    var method: CompletionVerificationMethod { get }
    func verify(_ request: CompletionVerificationRequest) async throws -> CompletionVerificationResult
}

struct TrustBasedCompletionVerifier: RoutineCompletionVerifying {
    let method: CompletionVerificationMethod = .trustBased

    func verify(_ request: CompletionVerificationRequest) async throws -> CompletionVerificationResult {
        CompletionVerificationResult(
            method: method,
            isVerified: true,
            verifiedAt: request.requestedAt
        )
    }
}

/// V1 intentionally resolves every routine to trust-based explicit completion.
/// Future HealthKit/camera implementations can be registered per routine type
/// without changing the reminder state machine or completion semantics.
struct CompletionVerificationRegistry: Sendable {
    private let defaultVerifier: any RoutineCompletionVerifying

    init(defaultVerifier: any RoutineCompletionVerifying = TrustBasedCompletionVerifier()) {
        self.defaultVerifier = defaultVerifier
    }

    func verifier(for routineType: RoutineType) -> any RoutineCompletionVerifying {
        defaultVerifier
    }
}
