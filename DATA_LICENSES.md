# Sözlük Veri Kaynakları ve Lisanslar

`backend_python/app/data/dictionary.jsonl.gz` ve `sozegitim-frontend_temel-2/assets/offline_words.json`
dosyaları aşağıdaki açık kaynaklardan `backend_python/build_dictionary.py` ile üretilir.

Sözlük verisi, kaynaklarının gerektirdiği şekilde **CC BY-SA 4.0** ile paylaşılır.
Bu lisans yalnızca sözlük verisini kapsar; uygulamanın kaynak koduna yayılmaz.

| Veri | Kaynak | Lisans / Koşul |
|---|---|---|
| A1–B2 kelime listesi ve seviyeler | [CEFR-J Wordlist 1.5](https://github.com/openlanguageprofiles/olp-en-cefrj), Yukio Tono, Tokyo University of Foreign Studies | Atıf koşuluyla araştırma ve ticari kullanım ücretsiz; telif hakkı Tono Laboratory, TUFS |
| C1–C2 kelime listesi ve seviyeler | [Octanove Vocabulary Profile C1/C2 1.0](https://github.com/openlanguageprofiles/olp-en-cefrj), Octanove Labs | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) |
| Türkçe çeviriler, tanımlar, telaffuz | [İngilizce](https://en.wiktionary.org) ve [Türkçe](https://tr.wiktionary.org) Vikisözlük katılımcıları, [kaikki.org / Wiktextract](https://kaikki.org) ile çıkarıldı (T. Ylonen) | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) ve GFDL |
| Örnek cümleler ve Türkçe çevirileri | [Tatoeba](https://tatoeba.org) katılımcıları, [manythings.org/anki](https://www.manythings.org/anki/) aracılığıyla | [CC BY 2.0 FR](https://creativecommons.org/licenses/by/2.0/fr/); cümle numarası ve yazar her kayıtta `example_source` alanında |

## Yapılan değişiklikler

Kaynak veriler değiştirilerek kullanılmıştır: kelimeler CEFR listesine göre süzülmüş, çeviri adayları
Tatoeba cümle çiftlerindeki sıklığa göre sıralanmış, eski/nadir/argo anlamlar elenmiş, biçim
sadeleştirilmiştir. İşlev sözcükleri (`a`, `the`, `of` vb.) ve otomatik seçimi yanlış çıkan yaklaşık 500 kelimenin
karşılıkları elle yazılmıştır (`TRANSLATION_OVERRIDES`).

## Atıf

The CEFR-J Wordlist Version 1.5. Compiled by Yukio Tono, Tokyo University of Foreign Studies.

Uygulama içinde atıflar **Ayarlar > Hakkımızda** ekranında ve kelime kartlarında gösterilir.

## Sözlüğü yeniden üretmek

Kaynak dosyaların beklenen yerleşimi `backend_python/build_dictionary.py` dosyasının başında yazılıdır.

```bash
python backend_python/build_dictionary.py <kaynak_klasoru> sozegitim-frontend_temel-2/assets/offline_words.json
```

Sunucu açılışta sözlük dosyasının değiştiğini algılar ve veritabanını günceller.
