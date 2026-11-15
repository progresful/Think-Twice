# Submission blocks: Think Twice

Copy each block into its form field. Nothing here has been submitted.

## Name

```
Think Twice
```

## Punchline

```
Broke by Friday? Not this month. Ask your own money anything, see the three baskets it falls into, and lock the spending that leaks.
```

## Description

```markdown
## Problem

30 % of people in the EU cannot face an unexpected expense (Eurostat, 2024). In Finland it is 1 household in 4 (Statistics Finland, 2021). The cause is rarely rent. One 25-year-old in S-Bank's dataset paid restaurants 10 times in August: 238,84 €, or 2 866 € a year. A statement shows that afterwards. Nothing happens at the till.

## Solution

Think Twice is a personal economic trainer in three steps.

1. **Ask.** Chat with your own transactions in plain words, from lookups to reasoning.
2. **Understand.** Every euro sits in one of three baskets: fixed costs, irregular costs, everyday spending. One number shows what is safe to spend this week.
3. **Act.** Choose the everyday spending to cut. Past your own monthly limit the card locks. Unlock with a short game scaled to the price, or skip and keep the money. Each skip moves you up a ladder of six levels, from "Broke by Friday" to "Financially Free".

## The brief, point by point

| The brief asks for | Think Twice |
|---|---|
| Lookup: "How much did I spend on taxis last month?" | 31,98 €, one payment, everyday basket |
| "What is safe for me to spend this week?" | 225,94 €, with the sum shown |
| What-if: "What if I cut eating out by 20%?" | 44,99 € a month, 539,86 € a year, on a slider you can drag |
| Reasoning: "Why do I need to save?" | Answered from this customer's own irregular costs and buffer |
| The three baskets | 687,22 € fixed, 416,19 € irregular, 999,00 € everyday, named in every answer |
| Mobile app or embeddable web app | Both: a native iPhone app and a web demo |
| Optional: open-data benchmark, multi-bank view | Not built |

## Judging criteria

- **Financial literacy.** The baskets teach where money goes. The lock turns the lesson into a habit at the moment of paying.
- **AI integration.** Code computes every figure; the model only words it. An answer is something you can drag, not only text to read.
- **Mobile experience.** One number on the dashboard, chat one tap away, four setup screens.
- **Feasibility.** 22 unit tests pass on the money logic. The coach still answers when the model is offline.
- **S-mobiili.** Built on S-Bank's data structure as a feature for the bank's app. Approval happens on the bank's own page.

## Try it

- **Web:** thinktwice.pgf.lv. Set up, double-press to pay, see the decline, play the game.
- **iPhone:** a SwiftUI app. Runs in the simulator and installs on an iPhone 16.
- **Film:** 46 seconds, on the demo page.

## How it works

- Lookups, baskets, safe to spend, safe to save and what-if are computed from 593 transactions over 23 months.
- The computed answer goes to the model with the question. The model is told to use those figures as given.
- Basket rule: rent and bills are fixed; a category paid less than once a month is irregular; the rest is everyday.
- The coach declines investment, loan, tax and betting questions.

## Limits

- One synthetic customer. English only. No user testing.
- Bank approval, card, decline and saved money are simulated.
- The basket rule is by frequency, so a trip counts as irregular even when it is a choice.
- The iPhone app sends this synthetic customer's figures to Google Gemini. A production version calls the bank's server.
- The web demo answers from figures on the page, without the live model.
- Double-press to pay and the decline are in the web demo. The iPhone app starts at the lock notification.

## Next

Finnish, a Statistics Finland benchmark for each basket, and a pilot with a real card: the share of locked payments that end in a skip.
```

Punchline: 132 of 200 characters. Description: 3552 of 5 000.

## Challenge fit

- **Financial literacy:** the three baskets from the brief are the backbone of every screen and answer.
- **Originality of AI:** answers you can manipulate (the slider), and a coach connected to a lock that acts at the moment of paying.
- **Mobile UX:** one number on the dashboard, chat one tap away, native iOS.
- **Feasibility:** figures are computed by code and tested; the model only words them.
- **S-mobiili:** built as a feature inside the bank's app, on the bank's own data structure.

## Limitations

- One synthetic customer. Simulator only, not run on a phone.
- The basket rule is by frequency, so a trip counts as an irregular cost even when it is a choice.
- The live model was tested with Google Gemini. The demo sends this synthetic customer's figures to the model provider from the app; a real version would call the bank's own server.
- The model can still phrase a figure loosely, for example calling a six-month average "last month".
- Bank approval, the card, the decline and the saved money are simulated. English only.
- The video predates the coach and shows only the lock.

## Next

Finnish, a Statistics Finland benchmark for each basket, and a pilot with a real card: the share of locked payments that end in "Skip and save".
```

Description length: 4005 of 5 000 characters.

## Challenge

Personal Economic Trainer, by S-Pankki. One line on why: it lets a customer chat with their own transaction data, teaches the three baskets in every answer, and adds a lock that acts on everyday leakage at the moment of payment.

## Tech challenges

None claimed. The coach calls a language model (Google Gemini in our tests; an Anthropic key also works) to word answers whose figures are computed in the app.

## Links

| Link | Value | Status |
|---|---|---|
| Demo | https://thinktwice.pgf.lv | Live, with the 46-second film. Opened on desktop and at phone width; not opened in an incognito window on a real phone |
| Source | https://github.com/progresful/Think-Twice | Private. Make it public, or invite the judges, before it goes in the form |
| Video | `presentation/video/video.mp4` | 46.3 s, built from the storyboard, ElevenLabs voice and sound effects. Also plays on the demo page. Team to upload as unlisted if the form needs a video link |
| Other | none | |

Each link must open in an incognito window on a phone before it goes in the form.
