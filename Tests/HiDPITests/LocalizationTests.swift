import XCTest
@testable import HiDPI

@MainActor
final class LocalizationTests: XCTestCase {
    func testLanguageSelectionPersistsAndAutomaticRemovesOverride() {
        let defaults = UserDefaults.standard
        let previousValue = defaults.object(forKey: AppLanguage.defaultsKey)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: AppLanguage.defaultsKey)
            } else {
                defaults.removeObject(forKey: AppLanguage.defaultsKey)
            }
        }

        let settings = LocalizationSettings()
        settings.language = .english
        XCTAssertEqual(defaults.string(forKey: AppLanguage.defaultsKey), "en")

        settings.language = .simplifiedChinese
        XCTAssertEqual(defaults.string(forKey: AppLanguage.defaultsKey), "zh-Hans")

        settings.language = .automatic
        XCTAssertNil(defaults.object(forKey: AppLanguage.defaultsKey))
    }

    func testSupportedLanguageCodes() {
        XCTAssertEqual(
            AppLanguage.allCases.compactMap(\.localizationCode),
            ["en", "zh-Hans", "zh-Hant", "fr", "de", "it", "es", "pt", "sv", "nb", "ga"]
        )
    }

    func testLanguageMenuUsesNativeNamesAndBCP47CodeOrder() {
        XCTAssertEqual(
            Array(AppLanguage.menuCases.dropFirst()).map(\.rawValue),
            ["de", "en", "es", "fr", "ga", "it", "nb", "pt", "sv", "zh-Hans", "zh-Hant"]
        )
        XCTAssertEqual(AppLanguage.german.displayName, "Deutsch")
        XCTAssertEqual(AppLanguage.french.displayName, "Français")
        XCTAssertEqual(AppLanguage.traditionalChinese.displayName, "繁體中文")
        XCTAssertEqual(AppLanguage.norwegianBokmal.displayName, "Norsk bokmål")
    }
}
