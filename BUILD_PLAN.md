# Think Twice iOS: build plan

Native SwiftUI app with screen-by-screen parity to the HTML demo. The HTML is the source of truth for layout, copy, numbers and behaviour.

## Decisions already made (do not reopen)

| Topic | Decision |
|---|---|
| Source of truth | `../think-twice/index.html` (read it in full before writing code) |
| Run target | iPhone 18 Pro simulator on this Mac (Xcode 27.2). No device signing |
| Bank, card, decline | Simulated, exactly as in the HTML |
| Lock alert | A real iOS local notification, with the HTML's drawn lock screen as fallback |
| Data | The same S-Pankki demo customer, bundled as JSON |
| Style | Black and lime, dark only |
| Copy | Verbatim from the HTML, jokes included. No new strings without need; no emoji, no exclamation marks |

## Project setup

- Folder: `junction/think-twice-ios/`. Do not modify `../think-twice/` or `../koutsi/`; read only.
- Generate the Xcode project with XcodeGen (`/opt/homebrew/bin/xcodegen`) from a `project.yml`. Do not hand-write a `.pbxproj`.
- App target `ThinkTwice`, bundle id `app.thinktwice.demo`, iPhone only, portrait only, deployment target iOS 17.0, SwiftUI lifecycle, no third-party packages.
- Unit test target `ThinkTwiceTests` for the logic.
- Force dark appearance (`.preferredColorScheme(.dark)`), status bar light.
- The folder is not a git repository. Do not run `git init`, commit or push.

## Data

Extract the JSON object from the `/*DATA*/window.DATA=...;/*END*/` block in `../think-twice/index.html` into `ThinkTwice/Resources/demo-data.json`. Fields: `customer, age, month, beforeMonth, type, usual, read, before[], payments[]` (`buffer` is unused). Each payment is `[label, longDate, time, amount, openUntil, shortDate]`. Decode into a `Payment` struct. Never hardcode a figure that the JSON or a computation provides.

## Logic (port 1:1 from the HTML's script)

| HTML | Swift |
|---|---|
| `TIERS` (name, pct, len, games) | `Tier` array, same six entries and order |
| `LEVELS = [0,1,2,3,5,8]` | skips needed for each rung |
| `limitOf`, `limitText`, `couldSave` | same rules; `limitOf` rounds half up (`10 × 0.75 → 8`, `10 × 0.25 → 3`) |
| `start()` | session: first `limit` payments of the month are already Paid, the rest are the queue |
| `pick(amount)` | under 20 € tap, 20 to under 40 € hold, 40 € and over type |
| `GAMES[...].goal` × `tier.len` ÷ ease | taps = amount × 10; hold seconds = amount ÷ 2; rounded, minimum 1 |
| Say-it sentence | `This is my {nth} {label lowercased} payment this month` + ` and I still want it` when `tier.len > 1`, then `.` |
| `DISS` | the five roast lines, rotating by queue index |
| `eur()` | Finnish format: `19,70 €`, `106,44 €`, `222 €` (no decimals when whole) |
| `nth()` | 1st, 2nd, 3rd, 4th, 11th, 12th, 13th, 21st |

Keep state in one `@Observable` model (`AppModel`): onboarding step, chosen bank, tier index, session (saved, skipped, log, queue index, last effort).

## Screens (same order, same copy)

1. **Welcome**: lime lock badge, "Think Twice", "A moment before you pay.", the one-sentence explanation, button "Start".
2. **Pick your bank**: search field, the eleven banks, empty state "No bank found. Check the spelling."
3. **Approve at {bank}**: three facts, button "Continue to bank". Opens the light-coloured simulated bank sheet ("Share payment data", Approve, Decline, "Demo: no bank is contacted.").
4. **Reading**: spinner and a counter running to `read` ("payments read", then "payments sorted"), auto-advance.
5. **Could save + How hard to pay?** (one screen): big lime figure that follows the slider, context line, tier name, slider with six stops, end labels, limit line, button "Save".
6. **Add your card**: lime card, "Add to Wallet", "Demo: no card is issued."
7. **Dashboard**: header with month pill; hint ("N more skips to move up." / "Top level reached."); ladder with the current rung large and lime plus "You", skips on every other rung, "Goal" on the top rung; lime "Saved by skipping" tile only after the first skip; "Locked" row; month list newest first; pinned "Next payment" button with the caption, or "Start over" at the end.
8. **Lock alert**: see next section.
9. **Game**: "Card locked", amount, label, running-total line, the game, game name and rule, "Skip and save {amount}" always visible, "Pay {amount}" only after unlocking, hint "Tap your card again. Open until {time}."
10. **Result**: "{amount} saved" with "Stays in your account. No action needed.", or "Paid {amount}" with a roast line and "Card locked again."; "New level: {name}" pill when a rung is crossed; button "Done".

Progress dots (5) and a back button on onboarding steps 2 to 6, as in the HTML (no back on Reading; back from step 5 goes to Approve).

## Lock alert: real notification

- Ask for notification permission when the user presses "Add to Wallet" (after the tap, before showing the dashboard).
- "Next payment" schedules a local notification 4 seconds later: title "Card locked", body `{label}, {amount}. {nth} this month, {total} so far.`
- Meanwhile show a waiting screen: title "Payment sent", body "The alert arrives in 4 seconds. Lock the phone to see it on the Lock Screen."
- Show the banner in the foreground too (`UNUserNotificationCenterDelegate.willPresent` returning `.banner, .sound`).
- Tapping the notification, or the fallback, opens the Game for that payment.
- If permission is denied, show the HTML's drawn lock screen (date, large time, tappable alert) instead.
- These two waiting-screen strings are the only new copy; keep them as written.

## Games

- **Tap it out**: large circular button with a progress ring and the remaining count; each touch-down decrements; light haptic per tap.
- **Hold on**: same ring; counts down while pressed; releasing before zero resets to full.
- **Say it**: the sentence with the matched prefix in lime, a text field below; match is case-insensitive prefix; a typo stops progress; reject any change that adds more than one character at once (paste); unlock when the whole sentence matches.

## Visual parity

- Take colours, corner radii, spacing and type sizes from the HTML's CSS (CSS px map to points). Key colours: background `#000000`, card `#1C1C1E`, lime `#9BF05C`, lime ink `#06140A`, secondary text white 55%, track white 14%, game background `#0B0B0D`.
- System font; amounts use the rounded design with monospaced digits and bold weight.
- Sheets and layers slide up; onboarding steps slide in from the right; the alert drops in.

## Rehearsal switches

Launch arguments: `-fast` divides game effort and the reading animation by 10; `-dash` skips onboarding and opens the dashboard at the default tier.

## Tests (must pass)

- `couldSave` for the six tiers: 0, 0, 54.61, 106.44, 152.36, 238.84.
- Limits: none, 10, 8, 5, 3, 0.
- Default tier: queue is 19.70, 15.06, 40.29, 21.66, 40.94; games are tap, tap, type, hold, type.
- First alert body: `Restaurant, 19,70 €. 6th this month, 177,58 € so far.`
- Formatting and ordinals as listed under Logic.
- Level thresholds: 0, 1, 2, 3, 5, 8 skips.

## Build, launch, verify

1. `xcodegen generate`, then build for the iPhone 18 Pro simulator with `xcodebuild` into a local derived-data folder.
2. Run the unit tests.
3. Boot the simulator, install and launch (the iOS Simulator tool can attach, launch, tap and screenshot).
4. Walk the whole flow once with screenshots: all six onboarding steps, dashboard, alert, each of the three games, a skip result, a paid result with a roast, the end-of-month state.
5. Compare each screenshot with the same state in the HTML and fix differences in copy, numbers or structure.

## Done means

- The app builds without warnings that matter, tests pass, and it launches in the simulator.
- Every screen above exists with the HTML's copy and numbers.
- The final report lists what was verified by screenshot, what was not, and any deviation from the HTML with the reason.

## Out of scope

Real bank connection, real card or decline, Screen Time app lock, a physical iPhone, App Store submission, Android.
