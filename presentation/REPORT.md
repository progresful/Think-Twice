# Report: Think Twice

Date: 2026-11-14. Nothing has been submitted, posted or uploaded.

## Release gates

| # | Gate | Result | Basis |
|---|---|---|---|
| 1 | The core journey completes reliably over repeated runs | **Pass, simulator only** | Lock, game and result were run more than five times on the iPhone 18 Pro simulator. The coach (dashboard card, chat, what-if slider) was run several times on the iPhone Air simulator, live and on-device. Not run on a phone |
| 2 | A stranger can explain the product after a short viewing | **Fail: not run** | No communication test has been done. Script is in VALIDATION.md |
| 3 | Every important claim is in the ledger with support | **Pass** | 21 claims in LEDGER.md, each measured or observed; unsupported claims are listed as removed |
| 4 | The strongest technical contribution is visible | **Pass in the deck, fail in the video** | Deck slide 4: figures computed by code and handed to the model, 22 tests, on-device answers offline. The video predates the coach |
| 5 | The challenge fit is explicit | **Pass** | Official brief and criteria were read on 2026-11-14 (Personal Economic Trainer, five criteria at 20 %). The description maps the app to each criterion; the four example questions from the brief are answered |
| 6 | Demo and repository open for the evaluator: incognito, phone, no login | **Partly** | Demo is live at https://thinktwice.pgf.lv with no login. No public repository link exists. Not opened in an incognito window on a real phone |
| 7 | A recorded backup of the demo exists | **Pass** | `video/backup-demo.mp4`, 109 s, real speed |
| 8 | Name, promise and numbers consistent, no typos | **Pass for text and deck, fail for video** | Deck, submission text and ledger use the same figures. The video and its script still carry the old promise and "12 tests". Proofread by the agent only |
| 9 | The PDF is readable and within the limit | **Pass** | `deck/deck.pdf`: 7 pages, 3.2 MB (limit 20 MB). Slides 1, 2, 4, 6 and 7 were rendered and looked at after the restyle; 3 and 5 were not |
| 10 | Every field and link has been checked | **Fail** | Field lengths checked: name 11/30, punchline 121/200, description 4 005/5 000. There are no links to check |
| 11 | Final submission is confirmed | **Fail: team action** | Not submitted. The challenge page showed "Submissions are open" with about 29 hours left on 2026-11-14 |

Seven gates pass (two of them only partly, because the video is stale), four fail. The four failures need the team.

## What was made

| Asset | File | Note |
|---|---|---|
| Brief, decision sheet, demo journey, ledger, validation notes | `BRIEF.md`, `DECISION.md`, `DEMO.md`, `LEDGER.md`, `VALIDATION.md` | |
| Form text | `SUBMISSION.md` | Copy-paste blocks |
| Cover | `cover.png` (source `cover.html`) | 1920×1080, 6 words plus the name |
| Demo GIF | `demo.gif` | 13 s, 0.7 MB: notification, Hold on, skip, saved |
| Backup recording | `video/backup-demo.mp4` | 109 s |
| Video | `video/video.mp4` | 49.7 s, 1920×1080, H.264 and AAC, captions burnt in; `script.md`, `transcript.srt`, `transcript.md`, `voiceover.m4a` |
| Deck | `deck/index.html`, `deck/deck.pdf`, `deck/assets/` | Seven slides, restyled on 2026-11-14 to match the website and film: "Broke by Friday? Not this month.", stat tiles for Europe, Finland and the yearly leak, a setup slide, and a QR code to https://thinktwice.pgf.lv. Print mode with `?print` |
| App icon | `../ThinkTwice/Assets.xcassets` | Dark lock on lime; installed and seen on the simulator home screen |

`video/raw.mp4` (39 MB) is the unedited simulator recording that `video/build.py` cuts from. Delete it if the folder needs to be small.

## What works versus what is simulated

**Implemented and run today:** onboarding (bank picker optional), strictness slider with the saving computed from the customer's August payments, dashboard with level ladder and a card showing safe to spend a week and the three baskets, a coach chat that answers lookups, safe to spend, safe to save, what-if (with a slider card), saving questions and follow-ups from 23 months of transactions, live through Google Gemini and on-device without it, the model key remembered in the Keychain, real iOS notification for the lock with a drawn lock screen as fallback, three games, skip result with confetti, paid result with a roast line, skipped-payments list, no-no list. 22 unit tests pass.

**Simulated or planned:** bank connection and approval, card and Wallet, the decline, the 10-minute unlock, any movement of money, locks for groups other than Restaurants, a model choosing the game, Finnish text, an open-data benchmark, the multi-bank view, running on a phone.

## Open items

1. **Video.** `video/video.mp4` was rebuilt on 2026-11-14: 54.8 s, ten segments from recordings of the current app, voice Kokoro-82M (`af_heart`), captions burnt in. The voiceover was transcribed back by a speech-recognition model and matched the script word for word. No person has listened to it or watched it in motion. No music. `video/backup-demo.mp4` is still the old lock-only recording.
1a. **Model wording.** Figures are computed by code, but the live model has paraphrased them loosely (a six-month average called "last month"; weekend and evening counts merged). The prompt was tightened after that; only one reply was read afterwards.
1b. **Basket rule.** By frequency, so a car rental counts as an irregular cost although it is a choice.
1c. **Privacy.** The demo sends the synthetic customer's figures to the model provider from the app, with the key held on the device. A real version would call the bank's server.
1d. **Screenshots come from two simulators** (iPhone 18 Pro for the lock, iPhone Air for the coach), so the frames differ slightly.
2. **Voice.** The video uses the macOS fallback voice. The framework prefers a human recording.
3. **Music.** None added; no royalty-free track was available locally.
4. **Video not listened to.** Picture, timing and captions were checked from frames. The audio track exists but was not heard by anyone.
5. **Video length.** 49.7 s against a 60 s ceiling. Official limit unknown.
6. **README.** The project has none. The framework asks for setup in three commands, screenshots, limitations and a disclosure. Not written because outputs were limited to `presentation/`.
7. **Slide 6 has no demo link or QR code**, because no link exists.
8. **Not confirmed on screen:** tapping the notification banner itself (opening it from Notification Centre works), the notifications-denied path, sound and haptics.
9. **No population statistic** for the problem. A Statistics Finland or Eurostat figure would strengthen slide 2.

## Needed from team

1. Done: the track is "Personal Economic Trainer" by S-Pankki; brief and criteria were read on 2026-11-14.
2. Confirmation from the organizers of what "Status: Closed" means, the deadline, and the video and pitch limits.
3. Whether there is a popular vote. If yes, the booth and channel work in section 11 of the framework applies.
4. Done: the chat was built. Open decision: re-record the video with the coach, or keep the note that it predates it.
5. Team names, roles and photos. None are in any asset.
6. A product test with 3 to 5 people and a communication test with at least 3 people from other teams (scripts in VALIDATION.md).
7. A public source link, and a decision on the demo link: host the HTML demo, or link the video.
8. Upload of the video as unlisted, then the link.
9. A human voiceover, if wanted, to replace `video/voiceover.m4a`.
10. A run on a real iPhone (needs an Apple ID signed in to Xcode).
11. Any sponsor contact or endorsement. None is claimed.
12. The final Submit click.
