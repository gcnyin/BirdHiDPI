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
        XCTAssertNil(AppLanguage.automatic.localizationCode)
        XCTAssertEqual(AppLanguage.english.localizationCode, "en")
        XCTAssertEqual(AppLanguage.simplifiedChinese.localizationCode, "zh-Hans")
    }
}
