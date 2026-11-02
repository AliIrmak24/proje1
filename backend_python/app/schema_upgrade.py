# app/schema_upgrade.py
# create_all mevcut tablolara sütun ekleyemediği için eksik sütunları tamamlar

from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine

USER_COLUMNS = {
    "full_name": "VARCHAR",
    "phone_number": "VARCHAR",
    "avatar_url": "VARCHAR",
    "language": "VARCHAR DEFAULT 'tr'",
    "cefr_level": "VARCHAR",
    "token_version": "INTEGER NOT NULL DEFAULT 0",
}

def upgrade_schema(engine: Engine):
    existing = {column["name"] for column in inspect(engine).get_columns("users")}
    with engine.begin() as connection:
        for name, definition in USER_COLUMNS.items():
            if name not in existing:
                connection.execute(text(f"ALTER TABLE users ADD COLUMN {name} {definition}"))
