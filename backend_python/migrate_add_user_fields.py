import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'sozegitim.db')
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

columns_to_add = [
    ("full_name", "TEXT"),
    ("phone_number", "TEXT"),
    ("avatar_url", "TEXT"),
    ("language", "TEXT DEFAULT 'tr'"),
]

for col_name, col_type in columns_to_add:
    try:
        cursor.execute(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
        print(f"Added column: {col_name}")
    except sqlite3.OperationalError as e:
        if "duplicate column" in str(e).lower():
            print(f"Column already exists: {col_name}")
        else:
            print(f"Error adding {col_name}: {e}")

conn.commit()
conn.close()
print("Migration complete!")
