# Sonekk JB

Dopamine-style launcher for Nyxian Clean on non-jailbroken iOS.

One big **Jailbreak** button: it runs the short preparation sequence, fills the ring, and
deep-links into Nyxian Clean in about a second. The status card shows the device model,
iOS version and whether Nyxian is installed right now.

## What this is not

This is **not** a jailbreak. There is no public jailbreak for iOS 27, and no app can change
that. The button prepares the environment and opens Nyxian Clean — that is the whole flow,
and the screen says so.

It also cannot launch a specific app inside Nyxian: Nyxian registers only the `livecontainer`
URL scheme, with no bundle-id parameter.

## How it works

| Piece | Detail |
|---|---|
| Target | Nyxian / Nyxian Clean, `org.emexlabs.nyxian`, scheme `livecontainer://` |
| Detection | `canOpenURL:` with `LSApplicationQueriesSchemes` |
| Ring | `CAShapeLayer` + `strokeEnd` animation, 1.35 s, haptics at each stage |
| Failure | alert with the reason, ring drains back, no dead end |

## Build

No Mac needed: clang cross-compiles to `arm64-apple-ios16.0` against an iPhoneOS SDK.

```
$env:CLANG   = "C:\path\to\clang.exe"
$env:IOS_SDK = "C:\path\to\iPhoneOS26.5.sdk"
powershell -ExecutionPolicy Bypass -File build.ps1
```

Output `SonekkJB.ipa` is unsigned — sign it with your own certificate before installing.

## Layout

| File | Role |
|---|---|
| `src/main.m` | app delegate and entry point |
| `src/JBViewController.m` | UI, status card, ring animation, deep link |
| `src/Info.plist` | bundle metadata and queried schemes |
