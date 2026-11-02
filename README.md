# SözEğitim

Türkçe konuşanlar için İngilizce kelime öğrenme uygulaması: A1–C2 sözlük, aralıklı tekrarlı kelime kartları,
quiz, seviye testi, eşleştirme, seviyeli okuma ve arkadaşlar.

- `backend_python/`: FastAPI sunucusu
- `sozegitim-frontend_temel-2/`: Flutter uygulaması

## Backend

```bash
python -m venv .venv
.venv/Scripts/python -m pip install -r backend_python/requirements.txt
```

`backend_python/.env.example` dosyasını `.env` olarak kopyalayıp `SECRET_KEY` değerini doldurun. `DATABASE_URL`
boş bırakılırsa SQLite kullanılır. Sunucu `sunuculari_baslat.bat` ile veya şu komutla açılır:

```bash
.venv/Scripts/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --app-dir backend_python
```

Testler:

```bash
.venv/Scripts/python -m pip install -r backend_python/requirements-dev.txt
.venv/Scripts/python -m pytest backend_python/tests
```

## Flutter

```bash
flutter pub get
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://sunucu-adresi
```

`API_BASE_URL` verilmezse uygulama yerel ağdaki sunucuyu arar; adres uygulamadaki **Sunucu IP** alanından da
girilebilir.

Mağaza sürümü için bir imza anahtarı oluşturup `android/key.properties` dosyasına `storeFile`, `storePassword`,
`keyAlias` ve `keyPassword` değerlerini yazın. Bu dosya git'e eklenmez; yoksa derleme debug anahtarıyla imzalanır.

## Sözlük verisi

Sözlük açık lisanslı kaynaklardan üretilir, ayrıntılar ve atıflar [DATA_LICENSES.md](DATA_LICENSES.md) dosyasındadır.
