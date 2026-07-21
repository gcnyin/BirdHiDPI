import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case automatic
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    static let defaultsKey = "appLanguage"

    var id: String { rawValue }

    var localizationCode: String? {
        self == .automatic ? nil : rawValue
    }

    var localizedName: String {
        switch self {
        case .automatic:
            return L10n.tr("language.automatic", fallback: "Automatic")
        case .english:
            return L10n.tr("language.english", fallback: "English")
        case .simplifiedChinese:
            return L10n.tr("language.simplifiedChinese", fallback: "Simplified Chinese")
        }
    }
}

@MainActor
final class LocalizationSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            if language == .automatic {
                UserDefaults.standard.removeObject(forKey: AppLanguage.defaultsKey)
            } else {
                UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.defaultsKey)
            }
        }
    }

    init() {
        let storedValue = UserDefaults.standard.string(forKey: AppLanguage.defaultsKey)
        language = storedValue.flatMap(AppLanguage.init(rawValue:)) ?? .automatic
    }
}

enum L10n {
    static func tr(_ key: String, fallback: String) -> String {
        localizedBundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    static func format(_ key: String, fallback: String, _ arguments: CVarArg...) -> String {
        String(
            format: tr(key, fallback: fallback),
            locale: Locale.current,
            arguments: arguments
        )
    }

    static func modeName(isHiDPI: Bool) -> String {
        isHiDPI
            ? tr("mode.hidpi", fallback: "HiDPI")
            : tr("mode.lodpi", fallback: "LoDPI")
    }

    private static var localizedBundle: Bundle {
        guard let storedValue = UserDefaults.standard.string(forKey: AppLanguage.defaultsKey),
              let language = AppLanguage(rawValue: storedValue),
              let localizationCode = language.localizationCode,
              let path = Bundle.main.path(forResource: localizationCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
