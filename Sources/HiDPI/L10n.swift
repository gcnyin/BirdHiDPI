import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case automatic
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case spanish = "es"
    case portuguese = "pt"
    case swedish = "sv"
    case norwegianBokmal = "nb"
    case irish = "ga"

    static let defaultsKey = "appLanguage"

    var id: String { rawValue }

    var localizationCode: String? {
        self == .automatic ? nil : rawValue
    }

    static var menuCases: [AppLanguage] {
        [.automatic] + allCases
            .filter { $0 != .automatic }
            .sorted { $0.rawValue < $1.rawValue }
    }

    var displayName: String {
        switch self {
        case .automatic:
            return L10n.tr("language.automatic", fallback: "Automatic")
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .italian:
            return "Italiano"
        case .spanish:
            return "Español"
        case .portuguese:
            return "Português"
        case .swedish:
            return "Svenska"
        case .norwegianBokmal:
            return "Norsk bokmål"
        case .irish:
            return "Gaeilge"
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
