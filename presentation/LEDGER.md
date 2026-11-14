# Claim-and-evidence ledger: Think Twice

Date of every check: 2026-11-14. "Run" means seen in the iOS simulator: rows 1 to 12 on the iPhone 18 Pro (recording `video/backup-demo.mp4`), rows 13 to 21 on the iPhone Air.

| # | Claim | Label | Support | Used in |
|---|---|---|---|---|
| 1 | The dataset customer made 10 restaurant payments in August, 238,84 € | measured | Computed from the S-Pankki synthetic dataset (customer CUST00849); unit test `testCategoriesForTheNoNoList`; shown on the strictness screen | Description, deck 2, video |
| 2 | The same customer made 10 restaurant payments in September, 315,23 € | measured | Sum of the 10 bundled September payments in `demo-data.json` | Description, deck 2 |
| 3 | At the default setting (lock after 5 payments) the lock would have caught 106,44 € in August; at the strictest, 238,84 € | measured | Unit test `testCouldSaveForSixTiers`; strictness screen in the recording | Description, deck 3 |
| 4 | Every one of the six strictness stops locks at least one payment | measured | Unit test `testEveryTierLocksSomething` | Ledger only |
| 5 | The lock arrives as a real iOS notification with the payment, the count and the month's total | observed | Run: banner seen in the app and on the home screen; opening it from Notification Centre opened the game. Tapping the banner itself was not confirmed | Description, deck 4, video |
| 6 | Three unlock games scale with the price: 1 tap per 10 cents, 1 second per 2 € (at least 20), or typing a sentence | measured | Unit test `testEffortAndSentence`; Tap it out and Hold on played to "Unlocked" in the simulator. "Say it" was not completed on screen (prefix matching and the typo stop were seen) | Description, deck 3 |
| 7 | Skipping shows the money kept and moves the user up a level | observed | Recording: "33,18 € saved", "New level: Treats Myself Daily", saved tile on the dashboard | Description, deck 3, video |
| 8 | Paying anyway unlocks the card for 10 minutes and shows one line built from the user's numbers | observed | Recording: "Open until" time on the game, "Paid 20,45 €" with the line. The 10-minute window is displayed only; no card exists | Description |
| 9 | Figures are computed by code; the model only words them | measured | `Money.swift` computes lookups, baskets, safe to spend and what-if; the computed answer is attached to each question sent to the model; 22 unit tests pass. The model can still paraphrase a figure loosely (seen: a six-month average called "last month") | Description, deck 4 |
| 10 | Switching off a place type on the no-no list stops those payments being locked | measured | Unit test `testNoNoListSwitchesOffAPlaceType`; run: Fast food off gave 8 paid instead of 5 | Description |
| 11 | 22 unit tests pass | measured | `xcodebuild test` on the iPhone Air simulator, 22 executed, 0 failures | Description, deck 4 |
| 12 | Bank approval, the card, the decline and the saving are simulated | measured | Source and on-screen notes ("Demo: no bank is contacted.", "Demo: no card is issued.") | Description, deck 6 |
| 13 | The customer spent 31,98 € on taxis in August, one payment | measured | Computed from the dataset (CUST00849); run: live model reply quoted 31,98 € and one payment | Description, deck 3 |
| 14 | Typical month: income 2 082,48 €, fixed costs 687,22 €, irregular costs 416,19 €, everyday spending 999,00 € | measured | `Money.swift`, six-month averages (irregular: twelve months); shown on the dashboard card | Description, deck 3 |
| 15 | Safe to spend is 225,94 € a week; everyday spending runs 19,93 € a month over | measured | Income minus fixed costs minus the irregular reserve, times 12/52; unit test `testSafeToSpendAndSave` covers the formula; run: dashboard card and chat | Description, deck 3 |
| 16 | Cutting eating out by 20 % keeps 44,99 € a month and 539,86 € a year, leaving 25,06 € safe to save | measured | Unit test `testLookupsAndWhatIf` covers the formula; run: live reply and slider card | Description, deck 1 and 3 |
| 17 | The what-if slider recomputes as it is dragged | observed | Run: dragged from 20 % to 50 %, figures changed to 112,47 € and 1 349,66 € | Description |
| 18 | The coach answers without the model | observed | Run with no key: taxi lookup, safe to spend, what-if, "why do I need to save", "why am i sad" all answered on-device | Description, deck 4 |
| 19 | Follow-ups keep their subject ("how to cut by 10%", "and in July?") | measured | Unit test `testQuestionsAreUnderstood`; run: "how to cut by 10%" answered for restaurants, live and on-device | Description |
| 20 | The live model answers with the app's figures | observed | Run with a Google Gemini key: header "Live model, grounded in your payments"; five replies read on screen. Not run with an Anthropic key | Description |
| 21 | Baskets follow a stated rule: rent and bills fixed, under one payment a month irregular, the rest everyday | measured | Unit test `testBasketsFollowTheRule` | Description |

## Claims removed or not made

| Claim | Why it is out |
|---|---|
| "People overspend on eating out" as a population statistic | No source collected. Add only with a Statistics Finland or Eurostat figure |
| "Users want it", any feedback or quote | No one outside the team has tried it |
| Any saving for real users, revenue or market size | No data and no method |
| "S-Pankki supports us" | No endorsement on record |
| "AI picks the game" | Planned only. Today the game is chosen by a price rule |
| "The model never gets a number wrong" | Not true: figures are computed by code, but the model can paraphrase them loosely |
| Finnish language, Statistics Finland benchmark, multi-bank view | Not built |
| Tested on a phone | Not done |
