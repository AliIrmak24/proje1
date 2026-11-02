# -*- coding: utf-8 -*-
"""
SözEğitim sözlüğünü açık lisanslı kaynaklardan üretir (ayrıntılar: DATA_LICENSES.md).

Kullanım:
    python build_dictionary.py <kaynak_klasoru> [offline_words.json yolu]

Kaynak klasörü:
    cefrj/cefrj.csv         CEFR-J Wordlist 1.5 (olp-en-cefrj deposu)
    octanove/octanove.csv   Octanove Vocabulary Profile C1/C2 1.0
    wikt/en.jsonl           kaikki.org İngilizce Vikisözlük çıktısının kelime listesine süzülmüş hali
    wikt/tr.jsonl           kaikki.org Türkçe Vikisözlük çıktısının kelime listesine süzülmüş hali
    tatoeba/tur-eng.zip     manythings.org Türkçe-İngilizce Tatoeba cümle çiftleri
"""
import collections
import csv
import gzip
import io
import json
import re
import sys
import zipfile
from pathlib import Path

OUTPUT_FILE = Path(__file__).resolve().parent / "app" / "data" / "dictionary.jsonl.gz"

LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"]

POS_MAP = {
    "noun": "noun", "vern": "verb", "verb": "verb", "be-verb": "verb", "do-verb": "verb",
    "have-verb": "verb", "modal auxiliary": "verb", "adjective": "adj", "adverb": "adv",
    "pronoun": "pron", "preposition": "prep", "determiner": "det", "conjunction": "conj",
    "number": "num", "interjection": "intj",
}
POS_LABELS = {
    "noun": "isim", "verb": "fiil", "adj": "sıfat", "adv": "zarf", "pron": "zamir", "prep": "edat",
    "det": "belirteç", "conj": "bağlaç", "num": "sayı", "intj": "ünlem", "phrase": "deyim",
    "prep_phrase": "edat öbeği",
}
RELATED_POS = {"verb": ["verb"], "adj": ["adj"], "adv": ["adv", "prep_phrase"], "prep": ["prep", "prep_phrase"]}

SKIP_TAGS = {
    "obsolete", "archaic", "dated", "rare", "dialectal", "historical", "vulgar", "offensive",
    "derogatory", "slang", "nonstandard", "misspelling", "ethnic", "slur", "euphemistic",
}
BAD_GLOSS = re.compile(r"\d|bkz|çoğul|hâli|fiilinin|zamanı|biçimi|soyad|kısaltma|kadın adı|erkek adı|yer adı|ingilizce", re.IGNORECASE)
SENSITIVE = re.compile(
    r"\b(kill\w*|murder\w*|sex\w*|rape\w*|naked|gun|guns|drugs?|suicide|whore|bitch|fuck\w*|shit\w*|damn|porn\w*|nazi\w*|hitler|terroris\w*|bomb\w*|penis|vagina|breasts?|drunk|hate)\b",
    re.IGNORECASE,
)
BAD_DEFINITION = re.compile(r"letter of the|alphabet", re.IGNORECASE)
TOKEN = re.compile(r"[a-z]+(?:['-][a-z]+)*")
TURKISH_TOKEN = re.compile(r"[a-zçğıöşü]+")
SOFTENED = {"t": "d", "k": "ğ", "p": "b", "ç": "c"}
MAX_ALIGNMENT_SENTENCES = 300
MIN_ALIGNMENT_SHARE = 0.2

# Otomatik seçimin yanlış çıktığı temel kelimeler ve işlev sözcükleri elle yazılmıştır
TRANSLATION_OVERRIDES = {
    "a": "bir", "an": "bir", "the": "belirli tanımlık (Türkçede karşılığı yok)",
    "of": "-in, -ın", "to": "-e, -a, -e doğru", "be": "olmak", "do": "yapmak, etmek",
    "have": "sahip olmak, -si olmak", "will": "-ecek, -acak", "would": "-erdi, -ardı",
    "can": "-ebilmek, teneke kutu", "may": "-ebilir, mayıs", "might": "-ebilir, güç",
    "must": "-meli, -malı", "are": "olmak", "is": "olmak", "no": "hayır, hiç",
    "you": "sen, siz", "they": "onlar", "them": "onları, onlara", "me": "beni, bana",
    "her": "onun, onu", "that": "şu, o, ki", "these": "bunlar, bu", "those": "şunlar, onlar",
    "than": "-den, -dan, göre", "too": "de, da, fazla", "so": "bu yüzden, çok, öyle",
    "some": "biraz, bazı", "other": "diğer, başka", "own": "kendi, sahip olmak",
    "or": "veya, ya da", "in": "içinde, -de", "on": "üzerinde, üstünde", "off": "kapalı, uzağa",
    "if": "eğer", "until": "-e kadar", "till": "-e kadar", "through": "içinden, boyunca",
    "without": "-sız, -siz, olmadan", "while": "-iken, süre", "although": "-e rağmen, gerçi",
    "besides": "ayrıca, dışında", "somebody": "birisi", "whatever": "her ne, her neyse",
    "there": "orada, oraya", "still": "hâlâ, yine de", "pretty": "güzel, oldukça",
    "o'clock": "saat (tam)", "a.m.": "öğleden önce", "p.m.": "öğleden sonra",
    "fine": "iyi, güzel, para cezası", "present": "hediye, şimdiki, sunmak", "kind": "tür, nazik",
    "fair": "adil, fuar", "store": "mağaza, depolamak", "bar": "bar, çubuk", "cop": "polis",
    "due": "vadesi gelmiş", "ideal": "ideal", "internet": "internet", "email": "e-posta",
    "video": "video", "atom": "atom", "id": "kimlik", "problem": "sorun, problem",
    "boy": "erkek çocuk, oğlan", "birthday": "doğum günü", "bee": "arı", "bean": "fasulye",
    "bone": "kemik", "bread": "ekmek", "bridge": "köprü", "game": "oyun", "hand": "el",
    "happen": "olmak, meydana gelmek", "hamburger": "hamburger", "love": "aşk, sevmek",
    "matter": "mesele, önemli olmak", "mind": "akıl, zihin, aldırmak", "photo": "fotoğraf",
    "film": "film, film çekmek", "plan": "plan, planlamak", "park": "park, park etmek",
    "practice": "pratik, alıştırma yapmak", "program": "program", "rabbit": "tavşan",
    "smoking": "sigara içme", "story": "hikâye, öykü", "test": "sınav, test",
    "tight": "sıkı, dar", "thursday": "perşembe", "toy": "oyuncak", "tomato": "domates",
    "turkey": "hindi", "turn": "dönmek, sıra", "wind": "rüzgâr", "world": "dünya",
    "exciting": "heyecan verici", "excuse": "mazeret, affetmek", "favorite": "favori, en sevilen",
    "floor": "kat, zemin", "football": "futbol", "form": "form, biçim", "get": "almak, elde etmek",
    "glasses": "gözlük", "good": "iyi", "grandmother": "büyükanne", "hello": "merhaba, selam",
    "history": "tarih", "ice cream": "dondurma", "imagine": "hayal etmek", "juice": "meyve suyu",
    "keep": "tutmak, saklamak, devam etmek", "jet": "jet", "leave": "ayrılmak, bırakmak, izin",
    "like": "sevmek, gibi", "look": "bakmak, görünmek", "man": "adam, erkek", "march": "mart, yürümek",
    "mine": "benimki, maden", "news": "haber, haberler", "newspaper": "gazete",
    "nothing": "hiçbir şey", "paragraph": "paragraf", "pardon": "pardon, affedersiniz",
    "parent": "ebeveyn", "pen": "tükenmez kalem, kalem", "pencil": "kurşun kalem", "pop": "pop müzik",
    "post": "gönderi, posta", "poster": "poster, afiş", "sale": "satış, indirim", "son": "oğul",
    "sorry": "üzgün, özür dilerim", "spot": "leke, nokta, yer", "thanks": "teşekkürler",
    "train": "tren, eğitmek", "up": "yukarı", "well": "iyi, kuyu", "wrong": "yanlış, hatalı",
    "yard": "avlu, bahçe", "achieve": "başarmak", "aisle": "koridor", "alarm": "alarm",
    "ankle": "ayak bileği", "badminton": "badminton", "badly": "kötü", "brilliant": "parlak, harika",
    "bulb": "ampul, soğan", "cab": "taksi", "capital": "başkent, sermaye", "car park": "otopark",
    "cereal": "tahıl, mısır gevreği", "clerk": "memur, kâtip", "contact": "iletişim, temas",
    "convenience": "kolaylık", "cooking": "yemek pişirme", "cost": "maliyet, mal olmak",
    "cross": "geçmek, çarpı", "custom": "gelenek", "cycling": "bisiklete binme",
    "dishonest": "dürüst olmayan", "display": "ekran, sergilemek", "dizzy": "başı dönen",
    "electric": "elektrikli", "ending": "son, bitiş", "establish": "kurmak",
    "express": "ifade etmek, ekspres", "fact": "gerçek", "fail": "başarısız olmak, sınıfta kalmak",
    "fancy": "süslü, hoşlanmak", "final": "son, final", "figure": "rakam, şekil", "float": "yüzmek, süzülmek",
    "handle": "sap, başa çıkmak", "human": "insan", "hunter": "avcı", "junior": "alt kademe, genç",
    "lead": "yönetmek, önderlik etmek, kurşun", "learner": "öğrenen", "least": "en az",
    "loudly": "yüksek sesle", "lyric": "şarkı sözü", "major": "ana, büyük, binbaşı", "mark": "not, işaret",
    "metal": "metal", "midday": "öğle", "mood": "ruh hâli", "model": "model, manken", "modern": "modern",
    "mosque": "cami", "noun": "isim", "normal": "normal", "organized": "düzenli", "original": "orijinal, özgün",
    "physically": "fiziksel olarak", "pile": "yığın", "pilot": "pilot", "pro": "profesyonel, lehine",
    "represent": "temsil etmek", "refer": "atıfta bulunmak, başvurmak", "rating": "değerlendirme",
    "roast": "kızartmak, kızarmış", "roll": "yuvarlamak, rulo", "romance": "romantik ilişki",
    "sake": "hatır, uğruna", "scale": "ölçek, terazi", "schedule": "program, takvim",
    "seriously": "ciddi şekilde", "shape": "şekil, biçim", "shot": "atış, iğne", "shoot": "ateş etmek, vurmak",
    "sadly": "ne yazık ki, üzgünce", "singular": "tekil", "sound": "ses, kulağa gelmek",
    "space": "uzay, boşluk, yer", "specific": "belirli, özel", "strike": "grev, vurmak",
    "tidy": "düzenli, derli toplu", "thunderstorm": "gök gürültülü fırtına", "track": "iz, pist",
    "unit": "birim, ünite", "used": "kullanılmış", "website": "web sitesi", "youth": "gençlik",
    "crisp": "gevrek, çıtır", "competent": "yetkin", "accidental": "kazara", "careless": "dikkatsiz",
    "remains": "kalıntılar", "box": "kutu",
    "able": "yapabilen, muktedir", "absent": "yok, devamsız", "advance": "ilerlemek, avans",
    "afford": "gücü yetmek", "amusing": "eğlenceli", "announce": "duyurmak", "anxiety": "kaygı, endişe",
    "arise": "ortaya çıkmak", "aside": "bir kenara", "aspirin": "aspirin", "blog": "blog",
    "bore": "sıkmak, sıkıcı kimse", "bound": "bağlı, -e mecbur", "cabbage": "lahana", "canal": "kanal",
    "capable": "yetenekli, muktedir", "chaos": "kaos", "charm": "çekicilik, cazibe", "contain": "içermek",
    "continuously": "sürekli olarak", "counter": "tezgâh, sayaç", "crop": "ürün, mahsul", "crush": "ezmek",
    "cucumber": "salatalık", "dating": "flört", "determination": "kararlılık", "disability": "engellilik",
    "disabled": "engelli", "disappoint": "hayal kırıklığına uğratmak", "drag": "sürüklemek",
    "eliminate": "ortadan kaldırmak, elemek", "embarrass": "utandırmak", "employment": "istihdam, iş",
    "evident": "açık, belli", "exact": "tam, kesin", "experiment": "deney", "extinct": "soyu tükenmiş",
    "extreme": "aşırı", "favorable": "elverişli, olumlu", "flow": "akış, akmak", "foundation": "temel, vakıf",
    "frequent": "sık", "frequently": "sık sık", "frustration": "hayal kırıklığı", "gesture": "jest, el kol hareketi",
    "grant": "vermek, burs", "gravy": "et suyu sosu", "helpless": "çaresiz", "imaginary": "hayalî",
    "immediate": "acil, anında", "injury": "yaralanma", "invasion": "işgal", "jogging": "koşu",
    "jungle": "orman, cangıl", "kitten": "kedi yavrusu", "launch": "başlatmak, fırlatmak", "legally": "yasal olarak",
    "locate": "yerini bulmak", "marine": "deniz, denizci", "marked": "belirgin", "mass": "kütle, kitle",
    "massive": "çok büyük", "mechanic": "tamirci, makinist", "medium": "orta, ortam", "mentally": "zihinsel olarak",
    "mess": "dağınıklık, karışıklık", "messy": "dağınık", "minor": "küçük, önemsiz", "misery": "sefalet, mutsuzluk",
    "mount": "tırmanmak, monte etmek", "neutral": "tarafsız, nötr", "noticeable": "fark edilir", "observe": "gözlemlemek",
    "overwork": "aşırı çalışmak", "paid": "ücretli", "palm": "avuç içi, palmiye", "pause": "duraklamak, duraklama",
    "permit": "izin vermek, izin belgesi", "policy": "politika, poliçe", "pound": "pound, sterlin", "qualified": "nitelikli",
    "reduction": "azalma, indirim", "regarding": "ile ilgili", "remedy": "çare, ilaç", "resident": "sakin, oturan",
    "resolve": "çözmek, karara varmak", "respond": "yanıt vermek", "rolling": "yuvarlanan", "routine": "rutin, alışkanlık",
    "sadness": "üzüntü", "seize": "ele geçirmek, el koymak", "selection": "seçim, seçki", "session": "oturum, seans",
    "setting": "ortam, ayar", "sheer": "tamamen, sarp", "shortage": "kıtlık, eksiklik", "sickness": "hastalık",
    "sort": "tür, sıralamak", "stable": "sabit, ahır", "strain": "gerginlik, zorlamak", "stunning": "çarpıcı",
    "suspect": "şüpheli, şüphelenmek", "symptom": "belirti", "tale": "masal, hikâye", "tire": "lastik, yormak",
    "toss": "atmak, fırlatmak", "transportation": "ulaşım", "unclear": "belirsiz", "unless": "-mezse, olmadıkça",
    "unlucky": "şanssız", "untidy": "dağınık", "variety": "çeşitlilik, çeşit", "warranty": "garanti",
    "wasteful": "savurgan", "wax": "mum, balmumu", "weakness": "zayıflık", "worth": "değer, değerinde",
    "anchor": "çapa, sunucu", "articulate": "açıkça ifade etmek", "assembly": "meclis, toplantı", "attached": "ekli, bağlı",
    "audition": "seçme", "backup": "yedek, yedekleme", "bid": "teklif, teklif vermek", "bolt": "cıvata, sürgü",
    "bum": "serseri, popo", "cast": "oyuncu kadrosu, atmak", "cease": "durmak, bitmek", "chaotic": "kaotik",
    "clarify": "açıklığa kavuşturmak", "comfortably": "rahatça", "constant": "sürekli, sabit", "convinced": "ikna olmuş",
    "core": "çekirdek, öz", "creek": "dere", "decade": "on yıl", "dental": "dişle ilgili", "digest": "sindirmek",
    "disappearance": "kaybolma", "domestic": "evcil, yurt içi", "donation": "bağış", "duplicate": "kopya, çoğaltmak",
    "economical": "ekonomik, tutumlu", "estate": "mülk, emlak", "external": "dış, harici", "fabulous": "muhteşem",
    "federal": "federal", "foul": "faul, pis", "found": "kurmak", "gangster": "gangster", "gum": "sakız, diş eti",
    "guts": "cesaret, bağırsaklar", "headquarters": "genel merkez", "honorable": "onurlu, saygıdeğer", "hunting": "avcılık, avlanma",
    "identification": "kimlik, tanımlama", "implication": "çıkarım, ima", "imply": "ima etmek", "impolite": "kaba, nezaketsiz",
    "import": "ithal etmek, ithalat", "impulsive": "dürtüsel", "incurable": "tedavi edilemez", "indispensable": "vazgeçilmez",
    "informal": "resmî olmayan, samimi", "institution": "kurum", "interpretation": "yorum", "interruption": "kesinti, sözünü kesme",
    "intersection": "kavşak", "lawn": "çimenlik", "liberal": "liberal, cömert", "litter": "çöp", "long-term": "uzun vadeli",
    "lousy": "berbat", "mango": "mango", "manufacturing": "imalat, üretim", "means": "araç, yol", "mixture": "karışım",
    "motivated": "motive olmuş", "neat": "düzenli, tertipli", "offense": "suç, gücenme", "outfit": "kıyafet",
    "outsider": "yabancı, dışarıdan biri", "persistent": "ısrarcı, kalıcı", "planning": "planlama", "privately": "özel olarak",
    "prospect": "olasılık, beklenti", "publicity": "tanıtım, reklam", "rack": "raf, askılık", "rash": "kızarıklık, aceleci",
    "reckon": "sanmak, hesaplamak", "reform": "reform", "relief": "rahatlama, yardım", "respected": "saygın",
    "reverse": "ters, geri almak", "rocky": "kayalık", "sack": "çuval, işten atmak", "satisfactory": "tatmin edici",
    "scooter": "skuter, scooter", "sensible": "mantıklı", "shaky": "titrek, sallantılı", "sketch": "taslak, eskiz",
    "sociable": "sosyal, arkadaş canlısı", "son-in-law": "damat", "span": "süre, karış", "spare": "yedek, ayırmak",
    "spite": "kin, inat", "spray": "sprey, püskürtmek", "stake": "pay, kazık", "steer": "yönlendirmek", "strictly": "kesinlikle, sıkı bir şekilde",
    "stroke": "felç, okşamak", "submit": "sunmak, teslim etmek", "subtle": "ince, belli belirsiz", "suffering": "acı, ıstırap",
    "tackle": "ele almak, üstesinden gelmek", "tame": "evcil, ehlileştirmek", "thoroughly": "tamamen, baştan sona", "tolerate": "hoş görmek, katlanmak",
    "trivial": "önemsiz", "truthful": "dürüst, doğru sözlü", "unimaginable": "hayal edilemez", "unto": "-e doğru", "vacant": "boş",
    "vital": "hayati, yaşamsal", "whip": "kırbaç, çırpmak", "wit": "zekâ, nükte", "zip": "fermuar", "bulk": "yığın, hacim",
    "clutch": "kavramak, debriyaj", "comply": "uymak", "eccentric": "eksantrik, tuhaf", "ego": "ego, benlik", "flask": "matara, şişe",
    "fuse": "sigorta, fitil", "immense": "çok büyük, engin", "ludicrous": "gülünç, saçma", "orchard": "meyve bahçesi",
    "perceptive": "algısı güçlü", "phenomenal": "olağanüstü", "premise": "öncül", "slack": "gevşek, ihmalkâr", "verdict": "karar, hüküm",
    "versatile": "çok yönlü", "voluntary": "gönüllü", "wicked": "kötü, ahlaksız", "wrench": "İngiliz anahtarı, burkmak",
    "hitch": "bağlamak, aksaklık", "rhetorical": "retorik", "standing": "ayakta, itibar",
}
HEADWORD_FIXES = {"IT": "it", "Miss": "miss", "Internet": "internet"}


def load_word_list(source: Path) -> dict[str, dict]:
    words: dict[str, dict] = {}
    for rel in ("cefrj/cefrj.csv", "octanove/octanove.csv"):
        with open(source / rel, encoding="utf-8-sig", newline="") as handle:
            for row in csv.DictReader(handle):
                level = row["CEFR"].strip().upper()
                if level not in LEVELS:
                    continue
                pos = POS_MAP.get(row["pos"].strip().lower(), "noun")
                variants = [v.strip() for v in row["headword"].split("/") if v.strip()]
                key = variants[0].lower()
                if key not in words:
                    words[key] = {"word": variants[0], "level": level, "pos": [pos], "variants": variants}
                    continue
                item = words[key]
                if LEVELS.index(level) < LEVELS.index(item["level"]):
                    item["level"] = level
                    item["pos"].insert(0, pos)
                elif pos not in item["pos"]:
                    item["pos"].append(pos)
    return words


def load_entries(path: Path) -> dict[str, list[dict]]:
    entries: dict[str, list[dict]] = collections.defaultdict(list)
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            # "Apple" gibi özel adlar küçük harfli kelimenin önüne geçmemeli
            if entry.get("pos") != "name":
                entries[entry["word"].lower()].append(entry)
    return entries


def turkish_lower(text: str) -> str:
    return text.replace("İ", "i").replace("I", "ı").lower()


def load_sentences(source: Path) -> tuple[dict, dict]:
    """Örnek cümle dizini ile kelime başına Türkçe çeviri sözcüklerini döndürür."""
    index: dict[str, list[tuple[str, str, str]]] = collections.defaultdict(list)
    aligned: dict[str, list[frozenset[str]]] = collections.defaultdict(list)
    archive = zipfile.ZipFile(source / "tatoeba" / "tur-eng.zip")
    with archive.open("tur.txt") as raw:
        seen = set()
        for line in io.TextIOWrapper(raw, encoding="utf-8"):
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 3:
                continue
            english, turkish, attribution = parts
            tokens = TOKEN.findall(english.lower())
            turkish_tokens = frozenset(TURKISH_TOKEN.findall(turkish_lower(turkish)))
            for token in set(tokens):
                if len(aligned[token]) < MAX_ALIGNMENT_SENTENCES:
                    aligned[token].append(turkish_tokens)
            if english in seen or not 4 <= len(tokens) <= 12 or SENSITIVE.search(english) or english.count('"'):
                continue
            seen.add(english)
            match = re.search(r"#(\d+) \(([^)]*)\) & #(\d+) \(([^)]*)\)", attribution)
            source_note = f"Tatoeba #{match[1]} ({match[2]}), #{match[3]} ({match[4]})" if match else "Tatoeba"
            sentence = (english, turkish, source_note)
            for token in set(tokens):
                index[token].append(sentence)
            for size in (2, 3):
                for i in range(len(tokens) - size + 1):
                    index[" ".join(tokens[i:i + size])].append(sentence)
    return index, aligned


def translation_stems(candidate: str) -> tuple[str, ...]:
    word = turkish_lower(candidate).split()[0].strip("-")
    word = re.sub(r"m[ae]k$", "", word)
    stems = {word if len(word) <= 3 else word[:-1]}
    if word[-1:] in SOFTENED:
        stems.add(word[:-1] + SOFTENED[word[-1]])
    return tuple(stems)


def rank_translations(word: str, candidates: list[str], aligned: dict) -> list[str]:
    """Adayları, kelimenin geçtiği Tatoeba cümlelerinin Türkçe karşılıklarındaki sıklığa göre dizer."""
    normalized: dict[str, str] = {}
    for candidate in candidates:
        key = turkish_lower(candidate)
        if key not in normalized or candidate == key:
            normalized[key] = candidate
    unique = [c for c in normalized.values() if c.lower() != word.lower() and not c.startswith("-")]
    unique = unique or list(normalized.values())
    pairs = aligned.get(word.lower(), [])
    if len(pairs) < 10 or len(unique) < 2:
        return unique

    scores = {}
    for candidate in unique:
        stems = translation_stems(candidate)
        scores[candidate] = sum(any(t.startswith(stems) for t in tokens) for tokens in pairs) / len(pairs)

    best = max(scores.values())
    if best == 0:
        return unique
    return sorted(
        (c for c in unique if scores[c] >= best * MIN_ALIGNMENT_SHARE),
        key=lambda c: -scores[c],
    )


def clean_translation(text: str) -> str | None:
    text = re.sub(r"\s+", " ", text).strip(" .;")
    if not text or len(text) > 32 or len(text.split()) > 3 or re.search(r"[()\[\]/\d=]", text):
        return None
    return text


def english_translations(entries: list[dict]) -> list[str]:
    results: list[str] = []
    for entry in entries:
        scored = []
        for order, sense in enumerate(entry.get("senses", [])):
            scored += [(order, t) for t in sense.get("translations", [])]
        scored += [(len(entry.get("senses", [])), t) for t in entry.get("translations", [])]
        for _, item in sorted(scored, key=lambda pair: pair[0]):
            if item.get("code") != "tr" or SKIP_TAGS & set(item.get("tags", [])):
                continue
            text = clean_translation(item.get("word", ""))
            if text:
                results.append(text)
    return results


def turkish_glosses(entries: list[dict]) -> list[str]:
    """Türkçe Vikisözlük tanımlarından kısa karşılıkları çıkarır."""
    short = []
    for entry in entries:
        for sense in entry.get("senses", []):
            if SKIP_TAGS & set(sense.get("tags", [])):
                continue
            for gloss in sense.get("glosses", [])[-1:]:
                if BAD_GLOSS.search(gloss):
                    continue
                parts = [clean_translation(part) for part in re.split(r"[,;]", gloss)]
                if all(parts) and len(parts) <= 4:
                    short += parts
    return short


def english_definitions(entries: list[dict], limit: int) -> list[str]:
    results = []
    for entry in entries:
        for sense in entry.get("senses", []):
            if sense.get("form_of") or sense.get("alt_of") or SKIP_TAGS & set(sense.get("tags", [])):
                continue
            glosses = sense.get("glosses") or []
            if glosses and 3 <= len(glosses[-1]) <= 180 and not BAD_DEFINITION.search(glosses[-1]):
                results.append(glosses[-1])
            if len(results) == limit:
                return results
    return results


def phonetic_of(entries: list[dict]) -> str | None:
    fallback = None
    for entry in entries:
        for sound in entry.get("sounds", []):
            ipa = sound.get("ipa")
            if not ipa or not ipa.startswith("/"):
                continue
            if "US" in sound.get("tags", []) or "General-American" in sound.get("tags", []):
                return ipa
            fallback = fallback or ipa
    return fallback


def wiktionary_example(entries: list[dict]) -> str | None:
    for entry in entries:
        for sense in entry.get("senses", []):
            for example in sense.get("examples", []):
                text = example.get("text", "")
                if not example.get("ref") and 15 <= len(text) <= 90 and not SENSITIVE.search(text):
                    return text
    return None


def pick_sentence(word: str, sentences: dict) -> tuple[str, str, str] | None:
    options = sentences.get(word.lower())
    if not options:
        return None
    return min(options, key=lambda s: (len(s[0].split()) < 5, len(s[0]), s[0]))


def by_pos(entries: list[dict], pos_list: list[str]) -> list[dict]:
    ordered = []
    for pos in pos_list:
        wanted = RELATED_POS.get(pos, [pos])
        ordered += [e for e in entries if e.get("pos") in wanted]
    return ordered


def build_entry(item: dict, english: dict, turkish: dict, sentences: dict, aligned: dict) -> dict | None:
    keys = [v.lower() for v in item["variants"]]
    en_all = [e for k in keys for e in english.get(k, [])]
    tr_all = [e for k in keys for e in turkish.get(k, [])]
    en_pos = by_pos(en_all, item["pos"]) or en_all
    tr_pos = by_pos(tr_all, item["pos"])

    candidates = english_translations(en_pos) + turkish_glosses(tr_pos)
    if not candidates:
        candidates = english_translations(en_all)
    override = TRANSLATION_OVERRIDES.get(item["word"].lower())
    ranked = rank_translations(item["word"], candidates, aligned)
    if not override and not ranked:
        return None
    translation = override or ", ".join(ranked[:3])

    definitions = english_definitions(en_pos, 2) or [translation]

    label = POS_LABELS.get(item["pos"][0], "isim")
    meanings = [{"part_of_speech": label, "definition": text} for text in definitions]

    sentence = pick_sentence(item["word"], sentences)
    if sentence:
        meanings[0].update(example=sentence[0], example_translation=sentence[1], example_source=sentence[2])
    else:
        example = wiktionary_example(en_pos)
        if example:
            meanings[0]["example"] = example

    return {
        "word": HEADWORD_FIXES.get(item["word"], item["word"]),
        "translation": translation,
        "level": item["level"],
        "phonetic": phonetic_of(en_pos) or phonetic_of(en_all),
        "meanings": meanings,
    }


def main():
    source = Path(sys.argv[1])
    words = load_word_list(source)
    english = load_entries(source / "wikt" / "en.jsonl")
    turkish = load_entries(source / "wikt" / "tr.jsonl")
    sentences, aligned = load_sentences(source)

    entries = []
    dropped = []
    for key in sorted(words, key=lambda k: (LEVELS.index(words[k]["level"]), k)):
        entry = build_entry(words[key], english, turkish, sentences, aligned)
        if entry:
            entries.append(entry)
        else:
            dropped.append(key)

    OUTPUT_FILE.parent.mkdir(exist_ok=True)
    payload = "\n".join(json.dumps(e, ensure_ascii=False, sort_keys=True) for e in entries).encode("utf-8")
    OUTPUT_FILE.write_bytes(gzip.compress(payload, mtime=0))

    print(f"{len(entries)} kelime yazıldı, {len(dropped)} kelime çeviri bulunamadığı için elendi")
    print(collections.Counter(e["level"] for e in entries))

    if len(sys.argv) > 2:
        offline = [
            e for e in entries
            if e["level"] in ("A1", "A2") and " " not in e["word"] and e["meanings"][0].get("example_translation")
        ][:400]
        Path(sys.argv[2]).write_text(json.dumps(offline, ensure_ascii=False, sort_keys=True), encoding="utf-8")
        print(f"{len(offline)} çevrimdışı kelime yazıldı")


if __name__ == "__main__":
    main()
