# app/services/dictionary_loader.py
# Paketlenen sözlük dosyasını veritabanıyla eşitler (bkz. build_dictionary.py)

import gzip
import hashlib
import json
from pathlib import Path
from sqlalchemy.orm import Session
from app.models.dictionary import AppMeta, DictionaryWord

DICTIONARY_FILE = Path(__file__).resolve().parents[1] / "data" / "dictionary.jsonl.gz"
VERSION_KEY = "dictionary_version"

def sync_dictionary(db: Session):
    raw = DICTIONARY_FILE.read_bytes()
    version = hashlib.sha256(raw).hexdigest()
    meta = db.get(AppMeta, VERSION_KEY)
    if meta and meta.value == version:
        return

    entries = {}
    for line in gzip.decompress(raw).decode("utf-8").splitlines():
        entry = json.loads(line)
        entries[entry["word"].lower()] = entry

    # Mevcut satırlar güncellenir ki kullanıcı ilerlemesi kelime id'sine bağlı kalsın
    for row in db.query(DictionaryWord).all():
        entry = entries.pop(row.word.lower(), None)
        if entry is None:
            db.delete(row)
            continue
        row.word = entry["word"]
        row.translation = entry["translation"]
        row.level = entry["level"]
        row.phonetic = entry.get("phonetic")
        row.meanings = entry["meanings"]

    db.flush()
    db.add_all(
        DictionaryWord(
            word=entry["word"],
            translation=entry["translation"],
            level=entry["level"],
            phonetic=entry.get("phonetic"),
            meanings=entry["meanings"],
        )
        for entry in entries.values()
    )

    if meta:
        meta.value = version
    else:
        db.add(AppMeta(key=VERSION_KEY, value=version))
    db.commit()
