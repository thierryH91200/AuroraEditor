//
//  ThemeModel.swift
//  AuroraEditorModules/AppPreferences
//
//  Created by Lukas Pistrol on 31.03.22.
//

import SwiftUI

/// The Theme View Model. Accessible via the singleton "``ThemeModel/shared``".
///
/// **Usage:**
/// ```swift
/// @StateObject
/// private var themeModel: ThemeModel = .shared
/// ```
public final class ThemeModel: ObservableObject {

    public static let shared: ThemeModel = .init()

    /// The selected appearance in the sidebar.
    /// - **0**: dark mode themes
    /// - **1**: light mode themes
    @Published
    var selectedAppearance: Int = 0

    /// The selected tab in the main section.
    /// - **0**: Preview
    /// - **1**: Editor
    /// - **2**: Terminal
    @Published
    var selectedTab: Int = 1

    /// An array of loaded ``Theme``.
    @Published
    public var themes: [AuroraTheme] = [] {
        didSet {
            saveThemes()
            objectWillChange.send()
            Log.info("\(themes.count) themes currently, \(String(describing: selectedTheme)) selected")
        }
    }

    /// The currently selected ``Theme``.
    @Published
    public var selectedTheme: AuroraTheme? {
        didSet {
            DispatchQueue.main.async {
                AppPreferencesModel.shared.preferences.theme.selectedTheme = self.selectedTheme?.name
            }
        }
    }

    /// Only themes where ``Theme/appearance`` == ``Theme/ThemeType/dark``
    public var darkThemes: [AuroraTheme] {
        themes.filter { $0.appearance == .dark }
    }

    /// Only themes where ``Theme/appearance`` == ``Theme/ThemeType/light``
    public var lightThemes: [AuroraTheme] {
        themes.filter { $0.appearance == .light }
    }

    private init() {
        do {
            try loadThemes()
        } catch {
            Log.error(error)
        }
    }

    /// Loads a theme from a given url and appends it to ``themes``.
    /// - Parameter url: The URL of the theme
    /// - Returns: A ``Theme``
    private func load(from url: URL) throws -> AuroraTheme? {
        do {
            // get the data from the provided file
            let json = try Data(contentsOf: url)
            // decode the json into ``Theme``
            let theme = try JSONDecoder().decode(AuroraTheme.self, from: json)
            return theme
        } catch {
            Log.info("Error fetching theme: \(error)")
            try filemanager.removeItem(at: url)
            return nil
        }
    }

    /// Loads all available themes from `~/Library/Application Support/com.auroraeditor/Themes/`
    ///
    /// If no themes are available, it will create a default theme and save
    /// it to the location mentioned above.
    ///
    /// When overrides are found in `~/Library/Application Support/com.auroraeditor/preferences.json`
    /// they are applied to the loaded themes without altering the original
    /// the files in `~/Library/Application Support/com.auroraeditor/Themes/`.
    public func loadThemes() throws {
        // remove all themes from memory
        themes.removeAll()

        let url = themesURL

        var isDir: ObjCBool = false

        // check if a themes directory exists, otherwise create one
        if !filemanager.fileExists(atPath: url.path, isDirectory: &isDir) {
            try filemanager.createDirectory(at: url, withIntermediateDirectories: true)
        }

        try loadBundledThemes()

        // get all filenames in themes folder that end with `.json`
        let content = try filemanager.contentsOfDirectory(atPath: url.path).filter { $0.contains(".json") }

        let prefs = AppPreferencesModel.shared.preferences
        // load each theme from disk
        try content.forEach { file in
            let fileURL = url.appendingPathComponent(file)
            if var theme = try load(from: fileURL) {

                // get all properties of terminal and editor colors
                guard let terminalColors = try theme.terminal.allProperties() as? [String: AuroraTheme.Attributes],
                      let editorColors = try theme.editor.allProperties().filter({ $0.value is AuroraTheme.Attributes })
                        as? [String: AuroraTheme.Attributes]
                else {
                    fatalError("failed to load terminal and editor colors")
                }

                // check if there are any overrides in `preferences.json`
                if let overrides = prefs.theme.overrides[theme.name]?["terminal"] {
                    terminalColors.forEach { (key, _) in
                        if let attributes = overrides[key] {
                            theme.terminal[key] = attributes
                        }
                    }
                }
                if let overrides = prefs.theme.overrides[theme.name]?["editor"] {
                    editorColors.forEach { (key, _) in
                        if let attributes = overrides[key] {
                            theme.editor[key] = attributes
                        }
                    }
                }

                // add the theme to themes array
                self.themes.append(theme)

                // if there already is a selected theme in `preferences.json` select this theme
                // otherwise take the first in the list
                self.selectedTheme = self.themes.first { $0.name == prefs.theme.selectedTheme } ?? self.themes.first
            }
        }
    }

    private func loadBundledThemes() throws {
        let bundledThemeNames: [String] = [
            "auroraeditor-xcode-dark",
            "auroraeditor-xcode-light",
            "auroraeditor-github-dark",
            "auroraeditor-github-light"
        ]
        for themeName in bundledThemeNames {
            guard let defaultUrl = Bundle.main.url(forResource: themeName, withExtension: "json") else {
                return
            }
            let json = try Data(contentsOf: defaultUrl)
            let jsonObject = try JSONSerialization.jsonObject(with: json)
            let prettyJSON = try JSONSerialization.data(withJSONObject: jsonObject,
                                                        options: .prettyPrinted)

            try prettyJSON.write(to: themesURL.appendingPathComponent("\(themeName).json"), options: .atomic)
        }
    }

    /// Removes all overrides of the given theme in
    /// `~/Library/Application Support/com.auroraeditor/preferences.json`
    ///
    /// After removing overrides, themes are reloaded
    /// from `~/Library/Application Support/com.auroraeditor/Themes`. See ``loadThemes()``
    /// for more information.
    ///
    /// - Parameter theme: The theme to reset
    public func reset(_ theme: AuroraTheme) {
        AppPreferencesModel.shared.preferences.theme.overrides[theme.name] = [:]
        do {
            try self.loadThemes()
        } catch {
            Log.error(error)
        }
    }

    /// Removes the given theme from `–/Library/Application Support/com.auroraeditor/Themes`
    ///
    /// After removing the theme, themes are reloaded
    /// from `~/Library/Application Support/com.auroraeditor/Themes`. See ``loadThemes()``
    /// for more information.
    ///
    /// - Parameter theme: The theme to delete
    public func delete(_ theme: AuroraTheme) {
        let url = themesURL
            .appendingPathComponent(theme.name)
            .appendingPathExtension("json")
        do {
            // remove the theme from the list
            try filemanager.removeItem(at: url)

            // remove from overrides in `preferences.json`
            AppPreferencesModel.shared.preferences.theme.overrides.removeValue(forKey: theme.name)

            // reload themes
            try self.loadThemes()
        } catch {
            Log.error(error)
        }
    }

    /// Saves changes on theme properties to `overrides`
    /// in `~/Library/Application Support/com.auroraeditor/preferences.json`.
    private func saveThemes() {
        let url = themesURL
        themes.forEach { theme in
            do {
                // load the original theme from `~/Library/Application Support/com.auroraeditor/Themes/`
                let originalUrl = url.appendingPathComponent(theme.name).appendingPathExtension("json")
                let originalData = try Data(contentsOf: originalUrl)
                let originalTheme = try JSONDecoder().decode(AuroraTheme.self, from: originalData)

                // get properties of the current theme as well as the original
                guard let terminalColors = try theme.terminal.allProperties() as? [String: AuroraTheme.Attributes],
                      let editorColors = try theme.editor.allProperties().filter({ $0.value is AuroraTheme.Attributes })
                        as? [String: AuroraTheme.Attributes],
                      let oTermColors = try originalTheme.terminal.allProperties() as? [String: AuroraTheme.Attributes],
                      let oEditColors = try originalTheme.editor.allProperties()
                        .filter({ $0.value is AuroraTheme.Attributes }) as? [String: AuroraTheme.Attributes]
                else {
                    throw NSError()
                }

                // compare the properties and if there are differences, save to overrides
                // in `preferences.json
                var newAttr: [String: [String: AuroraTheme.Attributes]] = ["terminal": [:], "editor": [:]]
                terminalColors.forEach { (key, value) in
                    if value != oTermColors[key] {
                        newAttr["terminal"]?[key] = value
                    }
                }

                editorColors.forEach { (key, value) in
                    if value != oEditColors[key] {
                        newAttr["editor"]?[key] = value
                    }
                }
                DispatchQueue.main.async {
                    AppPreferencesModel.shared.preferences.theme.overrides[theme.name] = newAttr
                }

            } catch {
                Log.error(error)
            }
        }
    }

    /// Default instance of the `FileManager`
    private let filemanager = FileManager.default

    /// The base folder url `~/Library/Application Support/com.auroraeditor/`
    private var baseURL: URL {
        guard let url = try? filemanager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return filemanager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library")
                .appendingPathComponent("Application Support")
                .appendingPathComponent("com.auroraeditor")
        }

        return url.appendingPathComponent(
            "com.auroraeditor",
            isDirectory: true
        )
    }

    /// The URL of the `themes` folder
    internal var themesURL: URL {
        baseURL.appendingPathComponent("Themes", isDirectory: true)
    }
}
