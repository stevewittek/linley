# Linley 0.1 verification

- Xcode: 26.6 (build 17F113)
- iOS SDK: 26.5
- Minimum deployment target: iOS/iPadOS 17.0
- App build: passed for generic iOS Simulator
- Test target compilation: passed (`TEST BUILD SUCCEEDED`)
- Live simulator: installed and launched on iPad Pro 11-inch (M5), iOS 26.5
- Screenshot: `../linley-ipad-preview.png`
- Unit-test execution: not completed; Xcode's test runner did not return, so the run was stopped. The test bundle itself compiled and linked successfully.

No backend, analytics, tracking, advertising, accounts, upload services, or third-party packages are present.
# Linley 0.3 verification

Verified on October 3, 2026:

- Xcode physical-device build completed successfully.
- Version `0.3.0` build `3` was signed for the Netherwood development team.
- The app installed successfully on a connected 10th-generation iPad.
- `com.netherwooddatapartners.linley` launched successfully on that iPad.
- The two-unit-test suite passed on the connected iPad with zero failures.
- The repository contains no third-party package dependencies or backend configuration.

The simulator test suite was not run in this pass because the Mac's simulator storage is currently redirected to an external development volume. The physical-device build, launch, and unit tests are verified; hands-on feature feedback remains for Lorelei and Dad.
