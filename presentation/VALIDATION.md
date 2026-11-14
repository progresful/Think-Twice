# Validation: Think Twice

## Product test: not run

No one outside the team has tried the app. This needs people, so it is on the "Needed from team" list in REPORT.md.

Script for each tester (aim for 3 to 5 people, 3 minutes each):

1. Hand over the phone or simulator at the Welcome screen. Say only: "Set it up and make a payment."
2. Note where they hesitate, and whether they reach a result screen without help.
3. After the first lock, ask: "What just happened, and what are your options?"
4. Ask: "Would this have changed what you did at the till?"

Record for each person: finished or not, where they struggled, their answer to question 4 in their own words. Report the sample size with the result.

## Communication test: not run

Show `cover.png` and the punchline for about 5 seconds to at least 3 people from other teams, then ask:

1. What does it do?
2. Who is it for?
3. Why would someone use it?
4. What do you believe actually works?

Our own answers, to compare against:

1. You can ask it about your own money (where it goes, what is safe to spend, what a cut would save), and it locks a type of everyday spending after a monthly limit; you unlock with a short game or skip and keep the money.
2. Bank card customers whose small payments stack up.
3. To stop and think at the moment of paying.
4. The chat, the figures and the app flow work; the bank, card and decline are simulated.

If two punchlines are tested, keep the one people repeat back. Variant B: "Screen Time for your spending: a moment before you pay."

## What was checked without people

Everything in LEDGER.md: 22 unit tests, a recorded run of the lock journey in the simulator, and unrecorded runs of the coach (dashboard card, chat, what-if slider) live and on-device.
