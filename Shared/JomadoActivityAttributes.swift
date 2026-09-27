import ActivityKit
import Foundation

public struct JomadoActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public let stage: ReminderUrgencyStage
        public let headline: String
        public let message: String
        public let compactStatus: String
        public let dueDate: Date
        public let expression: MascotExpression
        public let animationCue: MascotAnimationCue
        public let isCompleted: Bool

        public init(
            stage: ReminderUrgencyStage,
            headline: String,
            message: String,
            compactStatus: String,
            dueDate: Date,
            expression: MascotExpression,
            animationCue: MascotAnimationCue,
            isCompleted: Bool
        ) {
            self.stage = stage
            self.headline = headline
            self.message = message
            self.compactStatus = compactStatus
            self.dueDate = dueDate
            self.expression = expression
            self.animationCue = animationCue
            self.isCompleted = isCompleted
        }
    }

    public let occurrenceID: String
    public let routineID: String
    public let routineType: RoutineType
    public let routineName: String
    public let completionLabel: String
    public let mascotID: String

    public init(
        occurrenceID: String,
        routineID: String,
        routineType: RoutineType,
        routineName: String,
        completionLabel: String,
        mascotID: String
    ) {
        self.occurrenceID = occurrenceID
        self.routineID = routineID
        self.routineType = routineType
        self.routineName = routineName
        self.completionLabel = completionLabel
        self.mascotID = mascotID
    }
}

