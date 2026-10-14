# Wick

Your menu bar slowly changes color as your battery drains: green, then amber, then red.

Wick gives you a signal in the corner of your eye, so you don't have to remember to look at the battery icon. It's useful if you never check the icon, or if you hide it with a menu bar organiser like Bartender or Thaw.

| Battery | Menu bar |
| --- | --- |
| 70–100% | untouched, exactly as macOS draws it (or green, if you turn that on) |
| 70% → 45% | amber slowly fades in |
| ~25% | orange |
| 10% and below | red |

The colors blend smoothly between those points. While the battery is healthy, Wick stays out of sight. It only shows up once you're actually draining. When you plug in, the tint fades away (you can change this).

## Privacy and security

Wick is built to be boring from a security point of view:

- **It reads one thing:** the internal battery's charge level and whether it's plugged in, through Apple's public IOKit power-source API. It reads no files, windows, other apps, location, or anything else.
- **No network, in or out.** The App Sandbox is on and grants no network entitlement, so macOS blocks any connection even if the code tried to make one. There is no telemetry, no update checker and no crash reporter.
- **Nothing can look into it.** No AppleScript, no URL schemes, no XPC services and no shared files. The hardened runtime blocks debuggers and code injection.
- **No dependencies.** It uses only Apple's system frameworks. There are no packages and no third-party code.
- **Stores only your four preferences** (intensity, placement, show green when healthy, show while plugged in), in its own sandbox container.
- **You build it yourself.** No prebuilt binaries are distributed. You compile the source you can read.
- **No image files.** Even the app icon is drawn from code (`Sources/Flame.swift` and `scripts/icon/`), so there's nothing opaque in the repo.

Don't take my word for it. After building, run:

```sh
./scripts/audit.sh
```

This prints the app's entitlements, signing flags and linked libraries. It also scans the source for networking, file or scripting APIs, and checks the binary for local paths.

## Install

To build, you need Xcode 16 or later, or just the Command Line Tools (`xcode-select --install`), which needs macOS 14.5 or later. The finished app runs on macOS 13 or later, on Apple silicon Macs only. Intel Macs aren't supported.

```sh
git clone https://github.com/andreasaez/wick.git
cd wick
./build.sh --install
```

This builds `Wick.app`, copies it to `/Applications` and launches it. It will only replace an existing `/Applications/Wick.app` if that app is Wick. To build without installing, run `./build.sh`. The app ends up in `build/Wick.app`.

The app is ad-hoc signed on your own machine, so you don't need an Apple developer account. Because you built it locally, Gatekeeper won't quarantine it.

Don't share a built `Wick.app` as a download. macOS will block an ad-hoc-signed app that came from the internet, and people should build it from source anyway.

## Using it

Wick adds a small flame to the menu bar, filled with the current battery color. Click it for these options:

- **Intensity:** Subtle, Medium or Strong.
- **Placement:**
  - *Behind Menu Bar Text* keeps text and icons crisp. This is the default on macOS 26 and later, where the menu bar is transparent.
  - *Over Menu Bar* lays a translucent wash on top. This works on every version. Pick it if you can't see the tint.
- **Show Green When Healthy (70%+)** tints the menu bar green while the battery is healthy, instead of leaving it alone.
- **Show While Plugged In**
- **Launch at Login**
- **Quit**

You can hide the flame with Bartender or Thaw. The tint keeps working.

If your menu bar is set to auto-hide, Wick stays out of the way. It also doesn't draw over full-screen apps. On Macs without a battery it does nothing.

## Uninstall

If you turned on Launch at Login, turn it off first. Then quit Wick from its menu and run:

```sh
rm -rf /Applications/Wick.app
rm -rf ~/Library/Containers/dev.wick.Wick
```

## Forking

Everything lives in `Sources/` (about 300 lines of Swift). The colors are in `Sources/Palette.swift`. The flame shape is in `Sources/Flame.swift`. The bundle identifier is in `Resources/Info.plist`.

## License

MIT
