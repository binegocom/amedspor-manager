class BadWordsFilter {
  static const List<String> _badWords = [
    'küfür1',
    'küfür2',
    'aptal',
    'salak',
    'gerizekalı',
    'şerefsiz',
    'amk',
    'aq',
    // ... add more as needed
  ];

  static bool containsBadWords(String text) {
    if (text.isEmpty) return false;
    final lowerText = text.toLowerCase();
    
    for (final word in _badWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
