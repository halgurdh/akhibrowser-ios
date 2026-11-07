// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import Shared
import UIKit

enum ContentBlockingConfig {
    enum Prefs {
        static let StrengthKey = "prefkey.trackingprotection.strength"
        static let EnabledKey = "prefkey.trackingprotection.normalbrowsing"
    }

    enum Defaults {
        static let NormalBrowsing = !AppInfo.isChinaEdition
    }
}

enum AkhiBlockedCategory: Equatable {
    case adult
    case haram
}

enum AkhiSiteProtectionError: LocalizedError {
    case missingFilter(String)
    case malformedFilter(String)

    var errorDescription: String? {
        switch self {
        case .missingFilter(let name):
            return "Missing Akhi domain filter asset: \(name)"
        case .malformedFilter(let name):
            return "Malformed Akhi domain filter asset: \(name)"
        }
    }
}

struct AkhiSiteProtection {
    static let shared: Result<AkhiSiteProtection, Error> = Result {
        try AkhiSiteProtection(bundle: .main)
    }

    private let adultHashes: [Int64]
    private let haramHashes: [Int64]

    init(adultHashes: [Int64], haramHashes: [Int64]) {
        self.adultHashes = adultHashes
        self.haramHashes = haramHashes
    }

    init(bundle: Bundle) throws {
        adultHashes = try Self.loadHashes(named: "AkhiAdultDomains", bundle: bundle)
        haramHashes = try Self.loadHashes(named: "AkhiHaramDomains", bundle: bundle)
    }

    func blockedCategory(for url: URL) -> AkhiBlockedCategory? {
        guard let host = url.host else { return nil }
        let domain = Self.normalizedDomain(host)
        guard !domain.isEmpty else { return nil }

        if Self.isHaramName(domain) {
            return .haram
        }

        var parent = domain
        while let separator = parent.firstIndex(of: ".") {
            let hash = Self.hash(parent)
            if Self.contains(hash, in: adultHashes) {
                return .adult
            }
            if Self.contains(hash, in: haramHashes) {
                return .haram
            }
            parent = String(parent[parent.index(after: separator)...])
        }
        return nil
    }

    static func safeSearchURL(for url: URL) -> URL? {
        guard let host = url.host?.lowercased() else { return nil }
        let parameter: (name: String, value: String)?

        if (host.hasPrefix("google.") || host.contains(".google.")) && url.path == "/search" {
            parameter = ("safe", "active")
        } else if (host == "bing.com" || host.hasSuffix(".bing.com")) && url.path == "/search" {
            parameter = ("adlt", "strict")
        } else if (host == "duckduckgo.com" || host.hasSuffix(".duckduckgo.com")),
                  URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: {
                      $0.name == "q"
                  }) == true {
            parameter = ("kp", "1")
        } else if host == "search.yahoo.com", url.path.hasPrefix("/search") {
            parameter = ("vm", "r")
        } else {
            return nil
        }

        guard let parameter,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.queryItems?.first(where: { $0.name == parameter.name })?.value != parameter.value
        else {
            return nil
        }

        components.queryItems = (components.queryItems ?? []).filter { $0.name != parameter.name }
        components.queryItems?.append(URLQueryItem(name: parameter.name, value: parameter.value))
        return components.url
    }

    static func hash(_ domain: String) -> Int64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in domain.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001b3
        }
        return Int64(bitPattern: hash)
    }

    private static func loadHashes(named name: String, bundle: Bundle) throws -> [Int64] {
        guard let data = NSDataAsset(name: name, bundle: bundle)?.data else {
            throw AkhiSiteProtectionError.missingFilter(name)
        }
        guard data.count.isMultiple(of: MemoryLayout<Int64>.size) else {
            throw AkhiSiteProtectionError.malformedFilter(name)
        }

        let hashes = stride(from: 0, to: data.count, by: MemoryLayout<Int64>.size).map { offset in
            var value: UInt64 = 0
            for byteIndex in 0..<MemoryLayout<Int64>.size {
                value |= UInt64(data[offset + byteIndex]) << (byteIndex * 8)
            }
            return Int64(bitPattern: value)
        }
        guard zip(hashes, hashes.dropFirst()).allSatisfy({ $0.0 < $0.1 }) else {
            throw AkhiSiteProtectionError.malformedFilter(name)
        }
        return hashes
    }

    private static func contains(_ hash: Int64, in hashes: [Int64]) -> Bool {
        var lowerBound = 0
        var upperBound = hashes.count
        while lowerBound < upperBound {
            let middle = lowerBound + (upperBound - lowerBound) / 2
            if hashes[middle] < hash {
                lowerBound = middle + 1
            } else {
                upperBound = middle
            }
        }
        return lowerBound < hashes.count && hashes[lowerBound] == hash
    }

    private static func normalizedDomain(_ host: String) -> String {
        var domain = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if domain.hasPrefix("www.") {
            domain.removeFirst(4)
        }
        return domain
    }

    private static func isHaramName(_ domain: String) -> Bool {
        let labels = domain.split(separator: ".").map(String.init)
        guard let tld = labels.last else { return false }
        let restrictedTLDs: Set<String> = [
            "casino", "bet", "poker", "bingo", "lotto", "beer", "vodka", "wine", "cannabis"
        ]
        let restrictedWords = [
            "casino", "poker", "vodka", "whisky", "whiskey", "liquor", "brewery", "bourbon",
            "tequila", "cannabis", "marijuana"
        ]
        let restrictedLabels: Set<String> = ["betting", "beer", "wine", "wines", "weed", "vape", "cbd", "slots"]
        guard !restrictedTLDs.contains(tld) else { return true }

        return labels.dropLast().contains { label in
            restrictedWords.contains(where: { label.contains($0) })
                || label.split(separator: "-").contains { restrictedLabels.contains(String($0)) }
        }
    }
}

enum BlockingStrength: String {
    case basic
    case strict

    static let allOptions: [BlockingStrength] = [.basic, .strict]
}

extension BlockingStrength {
    var settingStatus: String {
        switch self {
        case .basic:
            return .TrackingProtectionOptionBlockListLevelStandardStatus
        case .strict:
            return .TrackingProtectionOptionBlockListLevelStrict
        }
    }

    var settingTitle: String {
        switch self {
        case .basic:
            return .TrackingProtectionOptionBlockListLevelStandard
        case .strict:
            return .TrackingProtectionOptionBlockListLevelStrict
        }
    }

    var settingSubtitle: String {
        switch self {
        case .basic:
            return .TrackingProtectionStandardLevelDescription
        case .strict:
            return .TrackingProtectionStrictLevelDescription
        }
    }

    static func accessibilityId(for strength: BlockingStrength) -> String {
        switch strength {
        case .basic:
            return AccessibilityIdentifiers.Settings.TrackingProtection.basic
        case .strict:
            return AccessibilityIdentifiers.Settings.TrackingProtection.strict
        }
    }
}

/// Firefox-specific implementation of tab content blocking.
@MainActor
final class FirefoxTabContentBlocker: TabContentBlocker, TabContentScript, FeatureFlaggable {
    let userPrefs: Prefs

    private var isAdBlockingEnabled: Bool {
        return featureFlagsProvider.isEnabled(.adBlocker) && (userPrefs.boolForKey(PrefsKeys.BlockAds) ?? false)
    }

    private func currentRules() -> [String] {
        var rules = isEnabled ? BlocklistFileName.listsForMode(strict: blockingStrengthPref == .strict) : []
        if isAdBlockingEnabled {
            rules.append(ASAdBlockerListFetcher.adBlockerRecordID)
        }
        return rules
    }

    class func name() -> String {
        return "TrackingProtectionStats"
    }

    var isUserEnabled: Bool? {
        didSet {
            guard let tab = tab as? Tab else { return }
            setupForTab()
            TabEvent.post(.didChangeContentBlocking, for: tab)
            tab.reload()
        }
    }

    override var isEnabled: Bool {
        if let enabled = isUserEnabled {
            return enabled
        }

        return isEnabledInPref
    }

    var isEnabledInPref: Bool {
        return userPrefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing
    }

    var blockingStrengthPref: BlockingStrength {
        return userPrefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap(BlockingStrength.init) ?? .basic
    }

    init(
        tab: ContentBlockerTab,
        prefs: Prefs,
        statsRecorder: TrackerBlockStatsStore? = nil
    ) {
        userPrefs = prefs
        super.init(tab: tab)
        self.statsRecorder = statsRecorder ?? DefaultTrackerBlockStatsStoreUtility(prefs: prefs)
        setupForTab()
    }

    func setupForTab(completion: (() -> Void)? = nil) {
        guard let tab = tab else { return }
        let rules = currentRules()
        logger.log("Setup tracking protection for tab: \(tab)", level: .info, category: .adblock)
        ContentBlocker.shared.setupTrackingProtection(
            forTab: tab,
            isEnabled: isEnabled || isAdBlockingEnabled,
            rules: rules,
            completion: completion
        )
    }

    override func notifiedTabSetupRequired() {
        guard let tab = self.tab as? Tab else { return }
        self.logger.log("Notified tab setup required", level: .info, category: .adblock)
        self.setupForTab(completion: { tab.reload() })
        TabEvent.post(.didChangeContentBlocking, for: tab)
    }

    override func currentlyEnabledLists() -> [String] {
        return currentRules()
    }

    override func notifyContentBlockingChanged() {
        guard let tab = tab as? Tab else { return }
        TabEvent.post(.didChangeContentBlocking, for: tab)
    }

    func noImageMode(enabled: Bool) {
        guard let tab = tab else { return }
        ContentBlocker.shared.noImageMode(enabled: enabled, forTab: tab)
    }
}

// Static methods to access user prefs for tracking protection
extension FirefoxTabContentBlocker {
    static func setTrackingProtection(enabled: Bool, prefs: Prefs) {
        let key = ContentBlockingConfig.Prefs.EnabledKey
        prefs.setBool(enabled, forKey: key)
        ContentBlocker.shared.prefsChanged()
    }

    static func isTrackingProtectionEnabled(prefs: Prefs) -> Bool {
        return prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing
    }

    static func toggleTrackingProtectionEnabled(prefs: Prefs) {
        let isEnabled = FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: prefs)
        setTrackingProtection(enabled: !isEnabled, prefs: prefs)
    }
}
