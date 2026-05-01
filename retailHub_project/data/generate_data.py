"""
RetailX — Bulk Data Generator
==============================
Generates 1000+ additional realistic records using Faker.
Run after the base SQL inserts to scale up data.

Requirements:
    pip install faker mysql-connector-python

Usage:
    python generate_data.py
"""

import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker('en_IN')
random.seed(42)

# ── Config ────────────────────────────────────────────────
OUTPUT_FILE = "generated_data.sql"
NUM_CUSTOMERS = 300          # additional customers
NUM_ORDERS    = 800          # additional orders
CUSTOMER_ID_START = 201      # continue from existing 200
ORDER_ID_START    = 240      # continue from existing 239

# Reference data matching the schema
CITIES = [
    ('Mumbai','Maharashtra'), ('Delhi','Delhi'), ('Bengaluru','Karnataka'),
    ('Kolkata','West Bengal'), ('Chennai','Tamil Nadu'), ('Hyderabad','Telangana'),
    ('Pune','Maharashtra'), ('Ahmedabad','Gujarat'), ('Jaipur','Rajasthan'),
    ('Lucknow','UP'), ('Kochi','Kerala'), ('Coimbatore','Tamil Nadu'),
    ('Chandigarh','Punjab'), ('Indore','MP'), ('Patna','Bihar'),
    ('Bhopal','MP'), ('Surat','Gujarat'), ('Nagpur','Maharashtra'),
    ('Visakhapatnam','AP'), ('Vadodara','Gujarat'),
]
SEGMENTS   = ['Premium', 'Regular', 'Regular', 'Regular', 'New', 'New']
STORE_IDS  = [1, 2, 3, 4, 5]
STORE_WEIGHTS = [15, 15, 15, 10, 45]   # online gets more weight
CHANNELS   = ['In-Store', 'Online']
STATUSES   = ['Completed', 'Completed', 'Completed', 'Completed',
              'Completed', 'Completed', 'Completed',
              'Returned', 'Cancelled', 'Pending']
PAY_METHODS = ['UPI', 'UPI', 'UPI', 'Credit Card', 'Credit Card',
               'Debit Card', 'Net Banking', 'COD']
PAY_STATUS  = {
    'Completed': 'Success',
    'Returned':  'Refunded',
    'Cancelled': 'Failed',
    'Pending':   'Success',
}

# Products with realistic prices (product_id: selling_price)
PRODUCTS = {
    1: 134900, 2: 79900,   3: 129999, 4: 38999,   5: 64999,
    6: 59999,  7: 24999,   8: 44999,  9: 114900,  10: 169900,
    11: 109999, 12: 99990, 13: 112000, 14: 119990, 15: 49999,
    16: 44999,  17: 74990, 18: 149990, 19: 82990,  20: 28999,
    21: 31999,  22: 112900, 23: 59900, 24: 82999,  25: 34999,
    26: 3999,   27: 1999,  28: 1499,  29: 7999,   30: 1799,
    31: 2499,   32: 5499,  33: 4999,  34: 3999,   35: 3499,
    36: 9999,   37: 14999, 38: 5499,  39: 2499,   40: 4999,
    41: 5499,   42: 7999,  43: 3299,  44: 1499,   45: 1199,
    46: 14999,  47: 2799,  48: 22999, 49: 12499,  50: 8999,
}
PRODUCT_IDS = list(PRODUCTS.keys())

def rand_date(start_year=2022, end_year=2024):
    start = datetime(start_year, 1, 1)
    end   = datetime(end_year, 12, 31)
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days),
                             hours=random.randint(8, 21),
                             minutes=random.randint(0, 59))

def escape(s):
    if s is None:
        return 'NULL'
    return "'" + str(s).replace("'", "\\'") + "'"

lines = []
lines.append("-- ============================================================")
lines.append("-- RetailX — Auto-Generated Bulk Data")
lines.append(f"-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
lines.append("-- ============================================================")
lines.append("USE retailx_db;")
lines.append("")

# ── CUSTOMERS ────────────────────────────────────────────
lines.append("-- Additional Customers")
lines.append("INSERT INTO customers")
lines.append("  (full_name, email, phone, city, state, pincode, segment, loyalty_pts, created_at)")
lines.append("VALUES")

cust_rows = []
used_emails = set()
cid = CUSTOMER_ID_START

for _ in range(NUM_CUSTOMERS):
    city, state = random.choice(CITIES)
    segment     = random.choice(SEGMENTS)
    pts         = random.randint(0, 8000) if segment == 'Premium' else \
                  random.randint(0, 1500) if segment == 'Regular' else \
                  random.randint(0, 200)
    name  = fake.name()
    email = fake.email()
    while email in used_emails:
        email = fake.email()
    used_emails.add(email)
    phone   = fake.phone_number()[:15] if random.random() > 0.15 else None
    pincode = str(random.randint(100000, 999999))
    created = rand_date(2022, 2024)

    cust_rows.append(
        f"  ({escape(name)},{escape(email)},{escape(phone)},"
        f"{escape(city)},{escape(state)},{escape(pincode)},"
        f"{escape(segment)},{pts},{escape(created.strftime('%Y-%m-%d %H:%M:%S'))})"
    )
    cid += 1

lines.append(",\n".join(cust_rows) + ";")
lines.append("")

# ── ORDERS + ORDER_ITEMS + PAYMENTS ──────────────────────
all_customer_ids = list(range(1, CUSTOMER_ID_START + NUM_CUSTOMERS))

order_lines   = []
item_lines    = []
payment_lines = []

oid = ORDER_ID_START
for i in range(NUM_ORDERS):
    customer_id = random.choice(all_customer_ids)
    store_id    = random.choices(STORE_IDS, weights=STORE_WEIGHTS)[0]
    order_dt    = rand_date(2022, 2024)
    status      = random.choice(STATUSES)
    channel     = 'Online' if store_id == 5 else random.choice(CHANNELS)

    # pick 1-3 products
    num_items   = random.choices([1, 2, 3], weights=[70, 20, 10])[0]
    items       = random.sample(PRODUCT_IDS, num_items)
    total       = 0
    item_rows   = []
    for pid in items:
        qty       = random.choices([1, 2, 3], weights=[75, 20, 5])[0]
        price     = PRODUCTS[pid]
        discount  = random.choices([0, 5, 10, 15], weights=[60, 20, 15, 5])[0]
        line_total = round(qty * price * (1 - discount / 100), 2)
        total     += line_total
        item_rows.append(
            f"  ({oid},{pid},{qty},{price},{discount})"
        )
    total = round(total, 2)

    # order
    order_lines.append(
        f"  ({customer_id},{store_id},"
        f"{escape(order_dt.strftime('%Y-%m-%d %H:%M:%S'))},"
        f"{escape(status)},{total},{escape(channel)})"
    )

    # order items
    item_lines.extend(item_rows)

    # payment
    pay_method = random.choice(PAY_METHODS)
    pay_status = PAY_STATUS.get(status, 'Success')
    if pay_status in ('Success', 'Refunded'):
        paid_at = (order_dt + timedelta(minutes=random.randint(3, 15))).strftime('%Y-%m-%d %H:%M:%S')
        txn_ref = f"'TXN-GEN-{oid:05d}'"
    else:
        paid_at = 'NULL'
        txn_ref = 'NULL'

    payment_lines.append(
        f"  ({oid},{escape(pay_method)},{total},"
        f"{escape(pay_status)},{txn_ref},"
        f"{'NULL' if paid_at == 'NULL' else escape(paid_at)})"
    )

    oid += 1

# Write orders
lines.append("-- Additional Orders")
lines.append("INSERT INTO orders (customer_id, store_id, order_date, status, total_amount, channel) VALUES")
lines.append(",\n".join(order_lines) + ";")
lines.append("")

# Write order items in chunks
lines.append("-- Additional Order Items")
chunk_size = 100
for start in range(0, len(item_lines), chunk_size):
    chunk = item_lines[start:start+chunk_size]
    lines.append("INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES")
    lines.append(",\n".join(chunk) + ";")
lines.append("")

# Write payments
lines.append("-- Additional Payments")
lines.append("INSERT INTO payments (order_id, payment_method, amount, status, transaction_ref, paid_at) VALUES")
lines.append(",\n".join(payment_lines) + ";")
lines.append("")

lines.append("-- Done!")
lines.append(f"SELECT 'Generated {NUM_CUSTOMERS} customers, {NUM_ORDERS} orders' AS status;")

# ── Output ────────────────────────────────────────────────
sql_output = "\n".join(lines)
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write(sql_output)

print(f"✅  Generated {OUTPUT_FILE}")
print(f"    Customers : {NUM_CUSTOMERS}")
print(f"    Orders    : {NUM_ORDERS}")
print(f"    Items     : {len(item_lines)}")
print(f"    Payments  : {len(payment_lines)}")
print(f"\nRun: mysql -u root -p retailx_db < {OUTPUT_FILE}")
