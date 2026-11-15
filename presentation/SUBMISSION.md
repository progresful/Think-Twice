# Submission blocks: Think Twice

Copy each block into its form field. Nothing here has been submitted.

## Name

```
Think Twice
```

## Punchline

```
Broke by Friday? Not this month. Chat with your money, spot the leaks, and climb to Financially Free, one cheeky reminder and one skipped snack at a time.
```

## Description

```markdown
## The problem: rest in peace, paycheck

30 % of people in the EU cannot face an unexpected expense (Eurostat, 2024). In Finland it is 1 household in 4 (Statistics Finland, 2021). The villain is rarely rent. It is lunch. One 25-year-old in S-Bank's dataset paid restaurants 10 times in August: 238,84 €, or 2 866 € a year. The statement tells you a month later. At the till, nobody says a word.

## The solution: a trainer with a sense of humour

Budgeting apps feel like homework, so people quit. Think Twice makes financial freedom a game you want to win, in three moves.

1. **Ask.** Chat with your own transactions in plain words. Your money answers back.
2. **Understand.** Every euro sits in one of three baskets: fixed costs, irregular costs, everyday spending. One number shows what is safe to spend this week.
3. **Act.** Pick the everyday spending to cut. Past your own monthly limit, the next payment brings a reminder: you want to be financially free. Still paying? Hold the button while the app heckles you: "This is a poor choice." "There is food at home." "Your savings just sighed." Or skip, keep the money and take the confetti.

Each skip is a step up a ladder of six levels, from "Broke by Friday" to "Financially Free". The reminder never blocks the card. It only makes you think twice.

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

- **Financial literacy.** The baskets teach where money goes. The reminder and the ladder turn the lesson into a habit, and the jokes make it stick.
- **AI integration.** Code computes every figure; the model only words it. So the coach can be funny and never wrong about your money. An answer is something you can drag, not only text to read.
- **Mobile experience.** One number on the dashboard, chat one tap away, four setup screens, and a game that fits a queue at the till.
- **Feasibility.** 22 unit tests pass on the money logic. The coach still answers when the model is offline.
- **S-mobiili.** Built on S-Bank's data structure as a feature for the bank's app. Approval happens on the bank's own page.

## Try it

- **Web:** thinktwice.pgf.lv. Set up, double-press to pay, get the reminder, get roasted.
- **iPhone:** a SwiftUI app. Runs in the simulator and installs on an iPhone 16.
- **Film:** 50 seconds, youtu.be/ZoQSPsUvayA.

## How it works

- Lookups, baskets, safe to spend, safe to save and what-if are computed from 593 transactions over 23 months.
- The computed answer goes to the model with the question. The model is told to use those figures as given.
- Basket rule: rent and bills are fixed; a category paid less than once a month is irregular; the rest is everyday.
- You set the strictness, from a weekly report only to a reminder on every payment. The pricier the payment, the longer the game.
- The coach declines investment, loan, tax and betting questions. It jokes about lunch, not about loans.

## Limits

- One synthetic customer. English only. No user testing.
- Bank approval, card, the reminder at the till and saved money are simulated.
- The basket rule is by frequency, so a trip counts as irregular even when it is a choice.
- The iPhone app sends this synthetic customer's figures to Google Gemini. A production version calls the bank's server.
- The web demo answers from figures on the page, without the live model.
- Double-press to pay is in the web demo. The iPhone app starts at the reminder notification.

## Next

Finnish, with Finnish jokes. A Statistics Finland benchmark for each basket. A pilot with a real card: the share of reminders that end in a skip.
```

Punchline: 154 of 200 characters. Description: 4247 of 5 000.

## Challenge

Personal Economic Trainer, by S-Pankki. One line on why: it lets a customer chat with their own transaction data, teaches the three baskets in every answer, and makes the road to financial freedom fun: a cheeky reminder at the moment of payment and a ladder to climb with every skip.

## Tech challenges

None claimed. The coach calls a language model (Google Gemini in our tests; an Anthropic key also works) to word answers whose figures are computed in the app.

## Links

| Link | Value | Status |
|---|---|---|
| Demo | https://thinktwice.pgf.lv | Live, with the 50-second film. Opened on desktop and at phone width; not opened in an incognito window on a real phone |
| Source | https://github.com/progresful/Think-Twice | Private. Make it public, or invite the judges, before it goes in the form |
| Video | https://youtu.be/ZoQSPsUvayA | 50.0 s on YouTube. Also plays on the demo page. Source file: `presentation/video/video.mp4` |
| Other | none | |

Each link must open in an incognito window on a phone before it goes in the form.
