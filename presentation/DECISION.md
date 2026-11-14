# Decision sheet: Think Twice

| Question | Answer |
|---|---|
| Who is the first user? | A 25-year-old S-Pankki card customer who eats out about 10 times a month. This is customer CUST00849 in the challenge's synthetic dataset, not a real person. |
| What goes wrong today? | Banking stops at statements. Small payments stack up unnoticed (10 restaurant payments, 238,84 € in August), nobody explains where the money really goes, and nothing interrupts the eleventh tap of the card. |
| What do they do currently? | Nothing at the moment of payment. Budget apps and spending reports show the total afterwards. |
| What is our single promise? | Talk with your own money and see where it goes in three baskets; then, after your own limit, a locked payment costs a moment of effort and skipping it shows the money you kept. |
| What works now? | A native iPhone app, run in the simulator: a coach chat that answers lookups, safe to spend, safe to save and what-if from 23 months of the customer's transactions, a dashboard card with the three baskets, a what-if slider, plus the lock: strictness slider, real iOS notification, three unlock games, skip and paid results. Bank, card and decline are simulated. |
| What is the decisive demo moment? | The user asks "What if I cut eating out by 20%?", drags the slider, then taps "Next payment": the card is locked, and they press "Skip and save 33,18 €". |
| Why is our approach better? | A chat over transactions answers; this one also teaches the three baskets in every answer and acts at the payment. Figures are computed by code, so they can be tested. |
| What was difficult to build? | Making the lock arrive as a real iOS notification without a dead end: the alert is a system notification, with a drawn lock screen as fallback if it is missed or denied. Checked by running it; see LEDGER.md. |
| What evidence do we have? | 22 passing unit tests on the money logic, the four example questions from the brief run against the live model in the simulator, and a 109-second recording of the lock journey. No user testing yet. |
| Why does this fit the challenge? | It is a chat with your own transaction data on the S-Pankki dataset, built around the brief's three baskets, with safe-to-spend, safe-to-save and what-if, designed to sit inside the bank's app. |
| What is the largest unresolved weakness? | No one outside the team has tried it, and it runs only in the simulator on one synthetic customer. English only; the brief's optional open-data benchmark is not built. Next test: three to five people try the chat and the lock. |

Second weakness: nothing is real money yet. The decline, the card and the saving are simulated. The demo also sends the synthetic customer's figures to the model provider from the app; a real version would call the bank's server.
