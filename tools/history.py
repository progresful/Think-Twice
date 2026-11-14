"""Write history.json: the demo customer's full transaction history up to the end of the month onboarding analyses.
Each row: [date, category, kind of place (from the merchant category code), euros out (negative = money in), balance after].
Usage: python3 -I history.py <dataset_dir> <demo-data.json> <history.json>"""
import csv, sys, json
from datetime import datetime
D, DEMO, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(DEMO, encoding='utf-8'))
MCC = {'5812': 'Restaurant', '5813': 'Bar', '5814': 'Fast food', '5411': 'Supermarket', '5422': 'Butcher',
       '5499': 'Convenience store', '5541': 'Fuel', '5542': 'Fuel', '7523': 'Parking', '4121': 'Taxi',
       '4111': 'Public transport', '4131': 'Bus', '4112': 'Train', '7999': 'Recreation', '7996': 'Amusement park',
       '7922': 'Theatre', '7832': 'Cinema', '7841': 'Streaming', '5912': 'Pharmacy', '8011': 'Doctor', '8021': 'Dentist',
       '5200': 'Home improvement', '5732': 'Electronics', '5712': 'Furniture', '5722': 'Appliances', '7512': 'Car rental',
       '7011': 'Hotel', '4511': 'Flights', '3000': 'Flights', '5651': 'Clothing', '5691': 'Clothing', '5941': 'Sports',
       '7230': 'Hairdresser', '5977': 'Cosmetics', '7997': 'Gym', '5942': 'Books', '5816': 'Digital games'}
TYPE = {'housing_payment': 'Rent', 'utilities_payment': 'Utility bill', 'salary': 'Salary'}
end = datetime.strptime(data['beforeMonth'] + ' 2026', '%B %Y')
rows, seen, unknown = [], False, {}
with open(D + '/tx_junction_transactions.csv', encoding='utf-8-sig') as fh:
    for r in csv.DictReader(fh):
        if r['customer_id'] == data['customer']:
            seen = True
            if (r['tx_date'][:7]) > end.strftime('%Y-%m'): continue
            label = TYPE.get(r['transaction_type']) or MCC.get(r['mcc_code'])
            if not label: unknown[r['mcc_code']] = unknown.get(r['mcc_code'], 0) + 1; label = r['category']
            rows.append([r['tx_date'], r['category'], label, round(-float(r['tx_amount_eur']), 2), round(float(r['balance_after_eur']), 2)])
        elif seen: break
json.dump(rows, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print(len(rows), 'rows', rows[0][0], rows[-1][0], 'unmapped codes', unknown)
