#!/usr/bin/env python3
"""Fails when a firefox-ios merge brought back what AkhiBrowser removed, and lists what it newly turned on.

Usage: firefox_sync_guard.py <commit before the merge>
"""

import re
import subprocess
import sys
from pathlib import Path

CLIENT = "firefox-ios/Client"
# file, pattern that must stay (a regular expression), what it keeps away
MUST_STAY = [
    (f"{CLIENT}/Application/AppLaunchUtil.swift", r"prefSendCrashReports\) \?\? false", "crash reports off"),
    (f"{CLIENT}/Telemetry/TelemetryWrapper.swift", r"prefSendUsageData\) \?\? false", "telemetry off"),
    (f"{CLIENT}/Telemetry/TelemetryWrapper.swift", r"SponsoredShortcuts\) \?\? false", "sponsored shortcuts off"),
    (
        f"{CLIENT}/Frontend/Settings/Main/AppSettingsTableViewController.swift",
        r"Experiments\.setTelemetrySetting\(profile\.prefs\.boolForKey\(AppConstants\.prefSendUsageData\) \?\? false\)",
        "experiments off",
    ),
    (
        f"{CLIENT}/FeatureFlags/UserFeaturePreferenceManager.swift",
        r"\.hntSponsoredShortcuts \{\s*return false",
        "sponsored shortcuts off",
    ),
    (f"{CLIENT}/Frontend/Home/Homepage/Merino/MerinoState.swift", r"ASPocketStories\) \?\? false", "Pocket stories off"),
    (
        f"{CLIENT}/Frontend/Settings/HomepageSettings/HomePageSettingViewController.swift",
        r"ASPocketStories,\s*defaultValue: false",
        "Pocket stories off in the settings",
    ),
    (f"{CLIENT}/ContentBlocker/ContentBlocker.swift", r"AkhiProtection\.shared\.adBlockRuleList", "the ad blocker"),
    (
        f"{CLIENT}/Frontend/Browser/BrowserViewController/Views/BrowserViewController.swift",
        r"^import AkhiKit$",
        "AkhiKit's protection",
    ),
]
# file, pattern that must stay away, what it brings back
MUST_GO = [
    (f"{CLIENT}/TermsOfServiceManager.swift", r"ManagePreferenceAgreement", "the onboarding line about sending data"),
]
# a data or sponsored default turned back on anywhere in the app
DEFAULT_ON = re.compile(
    r"boolForKey\((AppConstants\.(prefSendUsageData|prefStudiesToggle|prefSendCrashReports)"
    r"|PrefsKeys\.UserFeatureFlagPrefs\.ASPocketStories|PrefsKeys\.FeatureFlags\.SponsoredShortcuts)\)\s*\?\?\s*true"
)


def main():
    before = sys.argv[1]
    failures = []
    for path, pattern, keeps in MUST_STAY:
        file = Path(path)
        if not file.exists() or not re.search(pattern, file.read_text(encoding="utf-8"), re.M):
            failures.append(f"- `{path}` lost `{pattern}`: {keeps}")
    for path, pattern, brings in MUST_GO:
        file = Path(path)
        if file.exists() and re.search(pattern, file.read_text(encoding="utf-8"), re.M):
            failures.append(f"- `{path}` has `{pattern}` again: {brings}")
    for file in Path(CLIENT).rglob("*.swift"):
        for number, line in enumerate(file.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if DEFAULT_ON.search(line):
                failures.append(f"- `{file.as_posix()}:{number}` turns a data or sponsored default on")
    diff = subprocess.run(
        ["git", "diff", before, "HEAD", "--", f"{CLIENT}/*.swift"],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    ).stdout
    turned_on = sorted(set(re.findall(r"^\+.*boolForKey\(([\w.]+)\)\s*\?\?\s*true", diff, re.M)))
    print("### What the merge turned on by default, to look at")
    print("\n".join(f"- `{name}`" for name in turned_on) or "Nothing.")
    if failures:
        print("### Brought back or lost, the merge stops here")
        print("\n".join(failures))
        sys.exit(1)


if __name__ == "__main__":
    main()
