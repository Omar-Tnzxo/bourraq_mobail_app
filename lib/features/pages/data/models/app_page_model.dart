class AppPageModel {
  final String id;
  final String slug;
  final String titleAr;
  final String titleEn;
  final String contentAr;
  final String contentEn;
  final DateTime updatedAt;

  AppPageModel({
    required this.id,
    required this.slug,
    required this.titleAr,
    required this.titleEn,
    required this.contentAr,
    required this.contentEn,
    required this.updatedAt,
  });

  factory AppPageModel.fromJson(Map<String, dynamic> json) {
    return AppPageModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      contentAr: json['content_ar'] as String? ?? '',
      contentEn: json['content_en'] as String? ?? '',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
