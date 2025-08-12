import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

class Guess {
  final String word;
  final int percent;
  Guess(this.word, this.percent);
}

class DictData {
  final Map<String, List<String>> categories;
  final Map<String, String> _indexToCategoryLoose = {};
  final List<String> _poolOriginal = [];
  final math.Random _rng = math.Random();

  int _poolIdx = 0;

  DictData(this.categories) {
    // DRY: бәрі JSON-нан. Дубликаттарды loose-нормализациямен сүземіз.
    final seen = <String>{};
    categories.forEach((cat, words) {
      for (final w in words) {
        final orig = w.toString().trim();
        final loose = normalizeLoose(orig);
        if (loose.isEmpty) continue;
        if (seen.add(loose)) {
          _poolOriginal.add(orig); // түпнұсқа форманы сақтаймыз
          _indexToCategoryLoose.putIfAbsent(loose, () => cat); // алғаш кездескен cat
        }
      }
    });
    _poolOriginal.shuffle(_rng);
  }

  static String normalizeStrict(String s) {
    var t = s.trim().toLowerCase();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  static String normalizeLoose(String s) {
    var t = s.trim().toLowerCase();
    const map = {'ё':'е','қ':'к','ғ':'г','ә':'а','ү':'у','ұ':'у','һ':'х','ө':'о','і':'и','ң':'н'};
    map.forEach((k,v){ t = t.replaceAll(k, v); });
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  String nextSecret() {
    if (_poolIdx >= _poolOriginal.length) {
      _poolOriginal.shuffle(_rng);
      _poolIdx = 0;
    }
    return _poolOriginal[_poolIdx++];
  }

  String categoryOf(String wordOriginal) {
    final loose = normalizeLoose(wordOriginal);
    return _indexToCategoryLoose[loose] ?? 'белгісіз';
  }

  int similarityPercent(String guessRaw, String secretOriginal) {
    final guessL = normalizeLoose(guessRaw);
    final secretL = normalizeLoose(secretOriginal);
    if (guessL.isEmpty) return 0;
    if (guessL == secretL) return 100;

    int score = 0;
    int catScore = 0;
    final gCat = _indexToCategoryLoose[guessL];
    final sCat = _indexToCategoryLoose[secretL];

    if (gCat != null && sCat != null) {
      if (gCat == sCat) {
        catScore = 30; // бір категорияда
        if (sCat == 'адам_денесі') catScore += 3; // ұсақ fine-tune
      } else {
        catScore = 18; // әртүрлі, бірақ екеуі де белгілі категория
      }
    } else if (gCat != null || sCat != null) {
      catScore = 10; // біреуі ғана белгілі
    }
    score += catScore;

    final sim = _bigramSim(guessL, secretL);
    score += (sim * 60).round();

    if (catScore >= 30 && score < 38) score = 38;
    if (catScore >= 18 && score < 25) score = 25;

    if (score > 99) score = 99;
    if (score < 0) score = 0;
    return score;
  }

  double _bigramSim(String a, String b) {
    List<String> bigrams(String s) {
      final cleaned = s.replaceAll(RegExp(r'\s+'), '');
      final out = <String>[];
      for (int i = 0; i < cleaned.length - 1; i++) {
        out.add(cleaned.substring(i, i + 2));
      }
      return out;
    }
    final aa = bigrams(a);
    final bb = bigrams(b);
    if (aa.isEmpty || bb.isEmpty) return 0;
    final mapA = <String, int>{};
    for (final x in aa) { mapA[x] = (mapA[x] ?? 0) + 1; }
    int inter = 0;
    for (final x in bb) {
      final c = mapA[x] ?? 0;
      if (c > 0) { inter += 1; mapA[x] = c - 1; }
    }
    final union = aa.length + bb.length - inter;
    return union == 0 ? 0 : inter / union;
  }

  static Future<DictData> load() async {
    final raw = await rootBundle.loadString('assets/data/words_kk.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final cats = (data['categories'] as Map).map((k, v) =>
      MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()));
    return DictData(cats);
  }
}
