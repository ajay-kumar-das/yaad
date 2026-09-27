import Foundation

actor ContentRepository {
    private(set) var activePack: ContentPack?
    private(set) var lastValidationError: String?

    func loadBundledPack() {
        let bundle = Bundle.main
        let url = bundle.url(
            forResource: "starter-reminders",
            withExtension: "json",
            subdirectory: "Content/en"
        ) ?? bundle.url(forResource: "starter-reminders", withExtension: "json")

        guard let url else {
            activePack = nil
            lastValidationError = "The bundled starter content pack is missing."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let pack = try decoder.decode(ContentPack.self, from: data)
            try ContentValidator.validate(pack)
            activePack = pack
            lastValidationError = nil
        } catch {
            activePack = nil
            lastValidationError = error.localizedDescription
        }
    }

    func select(
        context: ContentSelectionContext,
        exposures: [ContentExposure]
    ) -> ReminderContentItem {
        guard let items = activePack?.items else {
            return .safeFallback(for: context.stage, routineType: context.routineType)
        }

        return ContentSelector.select(
            from: items,
            context: context,
            exposures: exposures
        ) ?? .safeFallback(for: context.stage, routineType: context.routineType)
    }
}
