"""Add the no-no list groups to demo-data.json: this customer's purchases in the month onboarding analyses,
grouped by category and then by place type (from the merchant category code; the dataset has no merchant names).
Usage: python3 -I categories.py <dataset_dir> <demo-data.json>"""
import csv, sys, json
from datetime import datetime
D, OUT = sys.argv[1], sys.argv[2]
data = json.load(open(OUT, encoding='utf-8'))
MCC = {'5812': 'Restaurant', '5813': 'Bar', '5814': 'Fast food', '5411': 'Supermarket', '5422': 'Butcher',
       '5499': 'Convenience store', '5541': 'Fuel station', '5542': 'Fuel pump', '7523': 'Parking', '4121': 'Taxi',
       '7999': 'Recreation', '7996': 'Amusement park', '7922': 'Theatre', '7832': 'Cinema', '5912': 'Pharmacy'}
rows, seen = [], False
with open(D + '/tx_junction_transactions.csv', encoding='utf-8-sig') as fh:
    for r in csv.DictReader(fh):
        if r['customer_id'] == data['customer']:
            seen = True
            t = datetime.strptime(r['tx_timestamp'], '%d%b%y:%H:%M:%S')
            if r['transaction_type'] == 'purchase' and t.strftime('%B') == data['beforeMonth'] and t.year == 2026:
                rows.append(r)
        elif seen: break
cats = {}
for r in rows:
    other = 'Restaurant' if r['category'] == data['type'] else 'Other'      # same rule as the HTML build
    it = cats.setdefault(r['category'], {}).setdefault(MCC.get(r['mcc_code'], other), [0, 0.0])
    it[0] += 1; it[1] += -float(r['tx_amount_eur'])
tot = lambda c: sum(v[1] for v in cats[c].values())
data['categories'] = [{'name': c, 'items': [{'label': k, 'count': v[0], 'total': round(v[1], 2)}
                       for k, v in sorted(cats[c].items(), key=lambda x: -x[1][1])]}
                      for c in sorted(cats, key=lambda c: (c != data['type'], -tot(c)))]
json.dump(data, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(json.dumps(data['categories']))
