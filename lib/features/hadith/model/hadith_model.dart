class HadithModel {
  final String text;
  final String textBengali;
  final String book;
  final int number;

  const HadithModel({
    required this.text,
    required this.textBengali,
    required this.book,
    required this.number,
  });

  String get bookDisplayName {
    const names = {
      'bukhari': 'সহীহ বুখারী',
      'muslim': 'সহীহ মুসলিম',
      'abu-daud': 'আবু দাউদ',
      'tirmidzi': 'তিরমিজি',
      'nasai': 'নাসাঈ',
    };
    return names[book] ?? book;
  }

  /// Full version of Hadith (Bengali if available, otherwise original text)
  String get fullText => textBengali.isNotEmpty ? textBengali : text;

  /// Compatible getter returning full text
  String get shortText => fullText;

  Map<String, dynamic> toJson() => {
        'text': text,
        'textBengali': textBengali,
        'book': book,
        'number': number,
      };

  factory HadithModel.fromJson(Map<String, dynamic> json) => HadithModel(
        text: json['text'] ?? '',
        textBengali: json['textBengali'] ?? '',
        book: json['book'] ?? '',
        number: json['number'] ?? 0,
      );
}
