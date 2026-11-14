# Demo journey: Think Twice

> A user's restaurant payments have passed their monthly limit. They tap their card (in the demo: "Next payment"). Think Twice locks the payment and sends a notification. They either play a short game scaled to the price to unlock the card for 10 minutes, or press "Skip and save". They see the money they kept and move up a level. We show it with a recording of the running app and the customer's real dataset numbers.

## Steps (as recorded in `video/backup-demo.mp4`)

| Time | Step | What to look for |
|---|---|---|
| 0:00 | Approve at S-Pankki, bank sheet | Simulated consent: "Demo: no bank is contacted." |
| 0:08 | Strictness slider | The saving follows the slider: 106,44 € at "Thinks Twice", 238,84 € at "Financially Free" |
| 0:17 | Add your card, dashboard | "Demo: no card is issued." Ladder starts at "Broke by Friday" |
| 0:22 | Next payment | "Payment sent", then a real iOS notification: "Card locked. Fast food, 33,18 €. 1st this month, 0 € so far." |
| 0:34 | Hold on | 25 seconds to unlock; the line above the ring changes while holding; letting go restarts |
| 0:46 | Skip and save 33,18 € | Confetti, "33,18 € saved", "New level: Treats Myself Daily" |
| 0:53 | Dashboard, saved tile | "Saved by skipping 33,18 €"; tapping it lists the skipped payment |
| 1:00 | Second payment, 20,45 € | Held for the full 20 seconds, "Unlocked", "Pay 20,45 €" appears |
| 1:41 | Paid result | "Paid 20,45 €" with a roast line and "Card locked again." |
| 1:47 | No-no list | Five spending groups from the August data; Restaurants is on |

The recording runs at real speed with no rehearsal switch. Waiting for the notification takes about 10 seconds each time because the simulator was driven by an agent.

## Coach steps (not in the recording; run in the iPhone Air simulator)

| Step | What to look for |
|---|---|
| Dashboard, scroll below the ladder | "Safe to spend a week 225,94 €" and the three baskets: 687,22 €, 416,19 €, 999,00 € |
| Tap the Ask field | The coach writes first, from the customer's payments. Header: "Live model, grounded in your payments" |
| Chip "What if I cut eating out by 20%" | 44,99 € a month, 539,86 € a year; drag the slider and the figures follow |
| Type "How much did I spend on taxis last month?" | 31,98 €, one payment, everyday basket |
| Type "why do I need to save" | A direct answer from the irregular costs and the buffer |

The model key is remembered in the simulator's Keychain after one launch with it, so restarts need nothing. Without a key or network the same figures are answered on-device. Live replies take roughly 5 to 15 seconds.

## Priority split

**Must work** (all run today in the simulator): strictness and saving figure, dashboard, lock notification with fallback, one game to the end, skip result, paid result, saved total.

**Must prove:** the numbers come from the dataset by code (unit tests); the lock arrives as a real system notification; effort scales with the price.

**Optional:** bank picker (`-bank`), confetti, changing lines in Hold on, no-no list for groups other than Restaurants (switches are saved but lock nothing), level ladder.

## Demo resilience

| Item | Status |
|---|---|
| Seeded demo data | Yes: one dataset customer bundled as JSON (593 transactions). Only the coach uses the network |
| Guest mode, no login | Yes: no account; bank approval is simulated |
| Tested on a phone | **No.** Simulator only (iPhone 18 Pro, iOS 27.2). No code-signing identity on this Mac |
| Rate limits and API costs | The coach calls a language model (tested with Google Gemini). If the call fails, the on-device answer is shown and the header says why |
| Recorded backup | Yes: `video/backup-demo.mp4`, 109 seconds |
| Rehearsal switches | `-fast` divides game effort by 10; `-dash` opens the dashboard; `-bank` adds the bank picker |

Known rough edges for a live demo: the first game at the default setting is 197 taps; Hold on is at least 20 seconds; "Say it" rejects pasted text.
