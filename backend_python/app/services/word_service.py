import requests
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.schemas.word_schema import WordResponse, Meaning
from app.models.dictionary import DictionaryWord
from deep_translator import GoogleTranslator

class WordService:
    def __init__(self):
        self.translator = GoogleTranslator(source='en', target='tr')

    # KÜÇÜK AI MOTORU: Kelime zorluğunu tahmin eden algoritma
    def _predict_cefr_level(self, word: str) -> str:
        word = word.lower().strip()
        length = len(word)
        
        # Basit kural tabanlı bir tahmin: Kısa ve yaygın kelimeler A1/A2, uzunlar B/C seviyesidir.
        if length <= 4:
            return "A1"
        elif length <= 6:
            return "A2"
        elif length <= 8:
            return "B1"
        elif length <= 10:
            return "B2"
        elif length <= 12:
            return "C1"
        else:
            return "C2"

    def search_word(self, db: Session, word: str) -> WordResponse:
        word = word.lower().strip()
        
        db_word = db.query(DictionaryWord).filter(DictionaryWord.word == word).first()
        
        if db_word:
            meanings_list = [Meaning(**m) for m in db_word.meanings]
            return WordResponse(
                word=db_word.word,
                translation=db_word.translation,
                phonetic=db_word.phonetic,
                level=db_word.level,
                meanings=meanings_list,
            )

        url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
        response = requests.get(url)
        
        if response.status_code != 200:
            raise HTTPException(status_code=404, detail="Kelime bulunamadı")
            
        data = response.json()[0]
        meanings_list = []
        
        for meaning in data.get("meanings", []):
            part_of_speech = meaning.get("partOfSpeech", "")
            pos_tr = {"noun": "isim", "verb": "fiil", "adjective": "sıfat", "adverb": "zarf"}.get(part_of_speech, part_of_speech)
            definitions = meaning.get("definitions", [])
            
            if definitions:
                first_def = definitions[0]
                tr_definition = self.translator.translate(first_def.get("definition", "")) if first_def.get("definition") else ""
                meanings_list.append(Meaning(part_of_speech=pos_tr, definition=tr_definition, example=first_def.get("example")))
                
        original_word = data.get("word", word)
        translated_word = self.translator.translate(original_word)
        predicted_level = self._predict_cefr_level(original_word)
        meanings_json = [m.model_dump() for m in meanings_list]
        
        new_dictionary_word = DictionaryWord(
            word=original_word,
            translation=translated_word,
            level=predicted_level,
            phonetic=data.get("phonetic"),
            meanings=meanings_json,
        )
        db.add(new_dictionary_word)
        db.commit()
        db.refresh(new_dictionary_word)
        
        return WordResponse(
            word=original_word,
            translation=translated_word,
            phonetic=data.get("phonetic"),
            level=predicted_level,
            meanings=meanings_list,
        )