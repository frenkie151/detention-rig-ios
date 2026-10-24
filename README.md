# Detention Rig for iOS

A native SwiftUI app for iOS 27 that tracks truck detention. It shows a live clock at the receiver, works out what to bill, writes the broker email for you, and lets you flip automations on and off. While the truck waits, a Live Activity keeps the clock on the Lock Screen and in the Dynamic Island.

All company, load and broker data is fictional demo data.

## Screens

- **Today:** a live detention card, tiles for Detention, Lumpers and Alerts, and a "Needs you" list. Swipe a card to dismiss it.
- **Detention:** a ticking clock, a timeline (arrived, free time up, now), and "How it was figured" (2 free hours, then $75/hr in 15-minute steps, with a countdown to the next step). "Truck left" asks you to confirm, then stops the clock.
- **Detention request:** the broker email, already written. Edit it, send it through Mail or any app with the share sheet, copy it, and mark it as sent.
- **Loads:** this week's loads with a filter and status pills.
- **Automations:** arrival and departure updates, detention heads-up, POD send, overdue follow-ups and automatic invoicing.
- **Live Activity:** elapsed time counts up on its own. The dollar amount refreshes while the app is open, and after the next 15-minute step the activity shows as out of date.

## iOS 27 details

- Liquid Glass throughout. The tab bar and toolbars pick it up automatically. Actions use `.glass` and `.glassProminent` button styles, and the toast uses `glassEffect`.
- `ToolbarOverflowMenu` holds the detention screen's secondary actions, and `topBarPinnedTrailing` keeps the dispatcher badge in place.
- `swipeActionsContainer()` turns on swipe-to-dismiss for the "Needs you" cards, which sit outside a `List`.
- `safeAreaBar` for the bottom action bar, `navigationSubtitle`, numeric content transitions, symbol effects and sensory feedback.
- Layout uses size classes and flexible frames, never device idiom, so it holds up now that iPhone apps can be resized.

The iOS 27 APIs were checked against Apple's WWDC26 "What's new in SwiftUI" session and SwiftUI guide. Signatures from the beta can still change, so check the final SDK if Xcode flags any of them.

## Build

You need Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen            # writes DetentionRig.xcodeproj from project.yml
open DetentionRig.xcodeproj
```

Pick your team under Signing & Capabilities for both targets. Then run the **DetentionRig** scheme on an iOS 27 simulator or device. To see the Live Activity, lock the simulator with ⌘L.

## Layout

| Path | What it is |
| --- | --- |
| `Packages/DetentionCore` | Detention math, formatting, the email text and demo data. Foundation only. |
| `DetentionRig/` | The app: `App/` holds the entry point and `AppModel`, and `Views/` holds one file per screen. |
| `DetentionRigWidgets/` | The widget extension with the Live Activity. |
| `Shared/` | `DetentionActivityAttributes`, used by both the app and the extension. |
| `project.yml` | XcodeGen spec. The `.xcodeproj` is generated, not committed. |

## Tests

The billing math and email text are covered by Swift Testing tests in `DetentionCore`. They run anywhere Swift 6 does, including Linux CI:

```bash
cd Packages/DetentionCore && swift test
```
