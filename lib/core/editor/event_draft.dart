import '../time/time_value.dart';

/// 草稿保存使用者輸入，不將模糊時間補成日期。
class DraftSection {
  DraftSection({
    this.id,
    this.title = '',
    this.content = '',
    this.suggestionKey,
  });
  String? id;
  String title;
  String content;
  String? suggestionKey;
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'suggestionKey': suggestionKey,
  };
  factory DraftSection.fromJson(Map<String, dynamic> json) => DraftSection(
    id: json['id'] as String?,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    suggestionKey: json['suggestionKey'] as String?,
  );
}

class EventDraft {
  EventDraft({
    this.eventId,
    this.creationId,
    this.title = '',
    TimeValue? time,
    this.category = '',
    this.place = '',
    this.latitude,
    this.longitude,
    this.radiusM,
    this.privacy = 'normal',
    List<DraftSection>? sections,
    List<String>? people,
    List<String>? tags,
    List<String>? relatedIds,
    List<Map<String, String>>? attachments,
  }) : time = time ?? const UnknownTime(),
       sections = sections ?? [DraftSection()],
       people = people ?? [],
       tags = tags ?? [],
       relatedIds = relatedIds ?? [],
       attachments = attachments ?? [];
  String? eventId;
  String? creationId;
  String title;
  TimeValue time;
  String category;
  String place;
  double? latitude, longitude, radiusM;
  String privacy;
  List<DraftSection> sections;
  List<String> people;
  List<String> tags;
  List<String> relatedIds;
  List<Map<String, String>> attachments;
  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'creationId': creationId,
    'title': title,
    'time': time.toJson(),
    'category': category,
    'place': place,
    'latitude': latitude,
    'longitude': longitude,
    'radius_m': radiusM,
    'privacy': privacy,
    'sections': sections.map((section) => section.toJson()).toList(),
    'people': people,
    'tags': tags,
    'relatedIds': relatedIds,
    'attachments': attachments,
  };
  factory EventDraft.fromJson(Map<String, dynamic> json) => EventDraft(
    eventId: json['eventId'] as String?,
    creationId: json['creationId'] as String?,
    title: json['title'] as String? ?? '',
    time: TimeValue.fromJson(Map<String, Object?>.from(json['time'] as Map)),
    category: json['category'] as String? ?? '',
    place: json['place'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    radiusM: (json['radius_m'] as num?)?.toDouble(),
    privacy: json['privacy'] as String? ?? 'normal',
    sections: (json['sections'] as List)
        .map(
          (value) =>
              DraftSection.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(),
    people: List<String>.from(json['people'] as List? ?? []),
    tags: List<String>.from(json['tags'] as List? ?? []),
    relatedIds: List<String>.from(json['relatedIds'] as List? ?? []),
    attachments: (json['attachments'] as List? ?? [])
        .map((value) => Map<String, String>.from(value as Map))
        .toList(),
  );
}
