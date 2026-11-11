# Sonekk

A Dopamine-style launcher for Nyxian Clean, blue theme on non-jailbroken iOS: one button runs the
session sequence and deep-links into Nyxian.

## UI

The interface is a direct port of Dopamine's Objective-C UI, not a look-alike:

| Dopamine file | Used here |
|---|---|
| `DOHeaderView` | header with wordmark and subtitle lines |
| `DOActionMenuView` / `DOActionMenuButton` | translucent rows with chevrons |
| `DOThemeManager` / `DOTheme` / `Themes.plist` | menu and window colors |
| `DOLyricsLogView` / `DOLyricsLogItemView` | full-screen log, 40pt lines, spinner to checkmark |
| `DODoubleHelixIndicator` | loading indicator next to the "Jailbreaking" title |
| `DOProgressiveBlurView` | progressive blur mask over the log |
| `JBJailbreakButton` | `DOJailbreakButton` without the DOUIManager dependency |
| `DOMainViewController` layout | stack view, 30pt padding, 73pt rows, 60pt button placeholder |

`Background_Blue.jpg`, `Loading.png`, `alpha-gradient.png` and `Themes.plist` come from the
same repository. Dopamine is MIT licensed (c) 2023-2024 Lars Fröder (opa334); the license text
is in `LICENSE.md`.

## Flow

1. Tap **Jailbreak** - the action menu hides, the header shifts up, the button expands into the
   lower two thirds of the screen exactly like Dopamine's `expandButton:`.
2. Log lines stream in at 0.09s intervals; each completed line gets a checkmark and dims.
3. After 4s every line completes, `Success` is appended as the final line.
4. One second later the app opens `livecontainer://` (Nyxian / Nyxian Clean).
5. Returning to the app rebuilds the interface.

## Build

No Mac required: clang cross-compiles to `arm64-apple-ios16.0` against an iPhoneOS SDK.

```
$env:CLANG   = "C:\path\to\clang.exe"
$env:IOS_SDK = "C:\path\to\iPhoneOS26.5.sdk"
powershell -ExecutionPolicy Bypass -File build.ps1
```

The IPA is unsigned - sign it with your own certificate.

## Limits

- There is no public jailbreak for iOS 27; this app opens the runtime, it does not unlock the system.
- Nyxian registers only the `livecontainer` scheme, so a specific app inside it cannot be launched directly.
