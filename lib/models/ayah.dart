class Ayah {
  final int id;
  final String text;
  final String translation;

  Ayah({required this.id, required this.text, required this.translation});

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      id: json['id'] as int,
      text: json['text'] as String,
      translation: json['translation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'translation': translation};
  }
}
