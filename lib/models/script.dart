class ScriptSegment {
  String title;
  String content;
  List<String> emotions;

  ScriptSegment({
    required this.title,
    required this.content,
    required this.emotions,
  });

  ScriptSegment copyWith({
    String? title,
    String? content,
    List<String>? emotions,
  }) {
    return ScriptSegment(
      title: title ?? this.title,
      content: content ?? this.content,
      emotions: emotions ?? this.emotions,
    );
  }
}

class TeleprompterScript {
  final String id;
  String title;
  List<ScriptSegment> segments;

  TeleprompterScript({
    required this.id,
    required this.title,
    required this.segments,
  });

  int get wordCount {
    int count = 0;
    for (var seg in segments) {
      count += seg.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    }
    return count;
  }

  int get estimatedSeconds {
    return (wordCount / 2.5).round();
  }

  String get durationString {
    int seconds = estimatedSeconds;
    if (seconds < 60) return '$seconds sec';
    int min = seconds ~/ 60;
    return '$min min';
  }

  String get fullContent {
    return segments.map((s) => s.content).join("\n\n");
  }

  TeleprompterScript copyWith({
    String? title,
    List<ScriptSegment>? segments,
  }) {
    return TeleprompterScript(
      id: id,
      title: title ?? this.title,
      segments: segments ?? this.segments.map((s) => s.copyWith()).toList(),
    );
  }
}
