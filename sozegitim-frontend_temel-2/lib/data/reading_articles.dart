class ReadingArticle {
  final String id;
  final String title;
  final String turkishTitle;
  final String level;
  final String category;
  final int readingTimeMinutes;
  final String englishContent;
  final String turkishSummary;
  final List<Map<String, String>> keyVocabulary;
  final List<ReadingQuestion> questions;

  ReadingArticle({
    required this.id,
    required this.title,
    required this.turkishTitle,
    required this.level,
    required this.category,
    required this.readingTimeMinutes,
    required this.englishContent,
    required this.turkishSummary,
    required this.keyVocabulary,
    this.questions = const [],
  });
}

class ReadingQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const ReadingQuestion(this.question, this.options, this.correctIndex);
}

final List<ReadingArticle> readingArticles = [
  ReadingArticle(
    id: '1',
    title: 'The Magic of Morning Walks',
    turkishTitle: 'Sabah Yürüyüşlerinin Sihri',
    level: 'A1-A2',
    category: 'Sağlık & Yaşam',
    readingTimeMinutes: 2,
    englishContent: '''Walking in the morning is one of the simplest habits for a healthy life. When you wake up early and step outside, the fresh air gives you energy. The city is still quiet, and the sun rises gently in the sky.

Scientists say that walking twenty minutes every day makes your heart stronger and improves your mood. You can listen to gentle music, watch birds in the trees, or simply enjoy the peaceful silence.

Start your tomorrow with a short walk. You will feel energized, positive, and ready for all challenges of the day!''',
    turkishSummary: 'Sabahları erken saatte yapılan kısa yürüyüşler hem kalp sağlığını güçlendirir hem de güne zinde ve pozitif başlamanızı sağlar. Sessiz sokaklar ve temiz hava gün boyu odaklanmanıza yardımcı olur.',
    keyVocabulary: [
      {'word': 'Habit', 'translation': 'Alışkanlık', 'level': 'A2'},
      {'word': 'Peaceful', 'translation': 'Huzurlu, sakin', 'level': 'A2'},
      {'word': 'Improve', 'translation': 'Geliştirmek, iyileştirmek', 'level': 'A2'},
      {'word': 'Challenge', 'translation': 'Zorluk, meydan okuma', 'level': 'B1'},
    ],
    questions: const [
      ReadingQuestion('How long should you walk every day, according to scientists?', ['Twenty minutes', 'One hour', 'Five minutes'], 0),
      ReadingQuestion('What does walking improve?', ['Your cooking', 'Your heart and your mood', 'Your handwriting'], 1),
    ],
  ),
  ReadingArticle(
    id: '2',
    title: 'Coffee Culture Around the World',
    turkishTitle: 'Dünya Genelinde Kahve Kültürü',
    level: 'A1-A2',
    category: 'Kültür & Seyahat',
    readingTimeMinutes: 2,
    englishContent: '''Coffee is much more than a hot drink; it is a global tradition that connects millions of people every day. In Italy, people drink a quick espresso at the bar counter before heading to work. In Turkey, Turkish coffee is served with water and sweet delight, celebrated for deep conversations and hospitality.

In modern Scandinavian countries, the concept of "Fika" means taking a dedicated break with colleagues to drink coffee and eat cinnamon buns. Wherever you travel in the world, sharing a cup of coffee opens doors to new friendships.''',
    turkishSummary: 'Kahve sadece bir içecek değil, insanları bir araya getiren evrensel bir gelenektir. İtalya\'daki hızlı espresso kültüründen Türkiye\'deki dostluk kahvesine ve İskandinav "Fika" molasına kadar her kültür kahveye özel bir anlam yükler.',
    keyVocabulary: [
      {'word': 'Tradition', 'translation': 'Gelenek, anane', 'level': 'A2'},
      {'word': 'Hospitality', 'translation': 'Misafirperverlik', 'level': 'B1'},
      {'word': 'Connect', 'translation': 'Bağlamak, birleştirmek', 'level': 'A2'},
      {'word': 'Colleague', 'translation': 'İş arkadaşı, meslektaş', 'level': 'B1'},
    ],
    questions: const [
      ReadingQuestion('Where do people drink a quick espresso at the bar?', ['Turkey', 'Sweden', 'Italy'], 2),
      ReadingQuestion('What does "Fika" mean?', ['A break with coffee and colleagues', 'A type of cinnamon', 'A morning walk'], 0),
    ],
  ),
  ReadingArticle(
    id: '3',
    title: 'Artificial Intelligence and Future Jobs',
    turkishTitle: 'Yapay Zeka ve Geleceğin Meslekleri',
    level: 'B1-B2',
    category: 'Teknoloji & Bilim Haberi',
    readingTimeMinutes: 3,
    englishContent: '''Artificial intelligence is transforming industries at an extraordinary pace. From healthcare and education to software development and automated finance, intelligent systems can analyze vast amounts of data in seconds.

While routine and repetitive tasks are increasingly automated, experts emphasize that human creativity, critical thinking, and emotional empathy can never be replaced by algorithms. The professionals of tomorrow will not compete against AI; instead, they will collaborate with intelligent tools to solve complex global challenges.

Lifelong learning and adaptability have therefore become the most vital skills of the modern economic era.''',
    turkishSummary: 'Yapay zeka teknolojileri rutin işleri otomatikleştirirken; yaratıcılık, empati ve eleştirel düşünme insanı vazgeçilmez kılmaya devam ediyor. Geleceğin başarılı çalışanları yapay zekayla rekabet etmek yerine onunla işbirliği yapabilen ve sürekli öğrenen bireyler olacaktır.',
    keyVocabulary: [
      {'word': 'Transform', 'translation': 'Dönüştürmek, başkalaştırmak', 'level': 'B2'},
      {'word': 'Extraordinary', 'translation': 'Olağanüstü, fevkalade', 'level': 'B1'},
      {'word': 'Collaborate', 'translation': 'İşbirliği yapmak', 'level': 'B2'},
      {'word': 'Adaptability', 'translation': 'Uyum yeteneği, esneklik', 'level': 'B2'},
    ],
    questions: const [
      ReadingQuestion('Which skills cannot be replaced by algorithms?', ['Repetitive tasks', 'Data analysis', 'Creativity and empathy'], 2),
      ReadingQuestion('How will future professionals work with AI?', ['They will compete against it', 'They will collaborate with it', 'They will avoid it'], 1),
    ],
  ),
  ReadingArticle(
    id: '4',
    title: 'Renewable Energy: The Solar Revolution',
    turkishTitle: 'Yenilenebilir Enerji: Güneş Devrimi',
    level: 'B1-B2',
    category: 'Çevre & Dünya Haberi',
    readingTimeMinutes: 3,
    englishContent: '''As global climate concerns intensify, renewable energy has evolved from an alternative idea into the cornerstone of global infrastructure. Over the past decade, the cost of manufacturing solar photovoltaic panels has plummeted by more than eighty percent.

Nations across Europe and Asia are constructing massive solar parks that power millions of homes without generating greenhouse gases. Breakthroughs in battery storage technology are addressing the intermittency problem, ensuring electricity remains available even when clouds gather.

The transition toward green energy represents the greatest industrial transformation of our century, fostering economic growth while preserving the biosphere for posterity.''',
    turkishSummary: 'Güneş panellerinin maliyetlerindeki büyük düşüş ve batarya teknolojilerindeki devrimler, yenilenebilir enerjiyi küresel enerjinin temeli haline getiriyor. Bu yeşil dönüşüm hem ekonomik kalkınma sağlıyor hem de gezegenimizi koruyor.',
    keyVocabulary: [
      {'word': 'Infrastructure', 'translation': 'Altyapı', 'level': 'B2'},
      {'word': 'Plummet', 'translation': 'Hızla düşmek, çakılmak', 'level': 'B2'},
      {'word': 'Intermittent', 'translation': 'Aralıklı, kesintili', 'level': 'B2'},
      {'word': 'Posterity', 'translation': 'Gelecek nesiller, ahfad', 'level': 'C1'},
    ],
    questions: const [
      ReadingQuestion('How much has the cost of solar panels fallen?', ['More than eighty percent', 'About ten percent', 'It has risen'], 0),
      ReadingQuestion('What does battery storage help with?', ['Building panels', 'Electricity when clouds gather', 'Reducing colleagues'], 1),
    ],
  ),
  ReadingArticle(
    id: '5',
    title: 'The Cognitive Architecture of Memory',
    turkishTitle: 'Hafızanın Bilişsel Mimarisi',
    level: 'C1-C2',
    category: 'Bilim & Psikoloji',
    readingTimeMinutes: 4,
    englishContent: '''Human memory is not a passive archive storing pristine records of the past; rather, it is a dynamic, reconstructive cognitive apparatus shaped by neuroplasticity. Contemporary neuroscience demonstrates that every act of recollection subtly recalibrates the underlying synaptic configuration.

Through the mechanism of long-term potentiation, neurons forge robust conduits in response to repeated intellectual stimulation. When learners engage in active recall and spaced repetition, knowledge transcends ephemeral working memory and crystallizes into semantic frameworks within the cerebral cortex.

Understanding these neurobiological principles empowers language learners to orchestrate highly efficacious study paradigms, overcoming the inevitable decay of forgotten information.''',
    turkishSummary: 'Hafıza pasif bir kayıt deposu değil, her hatırlamada yeniden inşa edilen dinamik bir sinirsel ağdır. Aktif hatırlama ve aralıklı tekrar yöntemleri, bilgiyi geçici hafızadan kalıcı serebral korteks yapılarına aktararak kusursuz bir dil öğrenme verimliliği sağlar.',
    keyVocabulary: [
      {'word': 'Neuroplasticity', 'translation': 'Beyin esnekliği, nöroplastisite', 'level': 'C2'},
      {'word': 'Recalibrate', 'translation': 'Yeniden ayarlamak', 'level': 'C1'},
      {'word': 'Ephemeral', 'translation': 'Geçici, uçucu', 'level': 'C2'},
      {'word': 'Efficacious', 'translation': 'Son derece etkili, yararlı', 'level': 'C1'},
    ],
    questions: const [
      ReadingQuestion('According to the text, human memory is...', ['a passive archive', 'a perfect record', 'dynamic and reconstructive'], 2),
      ReadingQuestion('Which methods help knowledge last?', ['Active recall and spaced repetition', 'Reading once', 'Avoiding revision'], 0),
    ],
  ),
  ReadingArticle(
    id: '6',
    title: 'Philosophy of Resilience in the Digital Era',
    turkishTitle: 'Dijital Çağda Dirayet ve Felsefe',
    level: 'C1-C2',
    category: 'Felsefe & Kültür',
    readingTimeMinutes: 4,
    englishContent: '''In an era characterized by relentless notifications and hyper-connectivity, cultivating philosophical fortitude has become an indispensable imperative. The ancient Stoics posited that tranquility is derived not from controlling extraneous circumstances, but from mastering one's internal cognitive interpretations.

Modern psychological research vindicates this venerable axiom. Individuals endowed with cognitive equanimity navigate algorithmic noise without relinquishing their moral agency. By prioritizing deliberateness over frantic reactivity, one develops an unassailable sanctuary of mental peace.

True intellectual maturity lies in the discernment between the mutable ephemeral and the transcendent eternal.''',
    turkishSummary: 'Sürekli bildirim ve uyaran bombardımanı altında geçen dijital çağda zihinsel dirayet vazgeçilmez bir erdemdir. Stoacı felsefe ve modern psikoloji, huzurun dış dünyayı değil kendi içsel tepkilerimizi yönetmekten geçtiğini doğrulamaktadır.',
    keyVocabulary: [
      {'word': 'Fortitude', 'translation': 'Metanet, ruh gücü, dirayet', 'level': 'C1'},
      {'word': 'Extraneous', 'translation': 'Dışsal, konu dışı', 'level': 'C1'},
      {'word': 'Equanimity', 'translation': 'Sükunet, soğukkanlılık', 'level': 'C2'},
      {'word': 'Discernment', 'translation': 'Basiret, ince kavrayış, sezgi', 'level': 'C2'},
    ],
    questions: const [
      ReadingQuestion('Where does tranquility come from, according to the Stoics?', ['Controlling circumstances', 'Mastering inner interpretations', 'Avoiding technology'], 1),
      ReadingQuestion('What should be prioritized over frantic reactivity?', ['Notifications', 'Speed', 'Deliberateness'], 2),
    ],
  ),
];
