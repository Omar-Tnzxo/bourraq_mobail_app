/// Onboarding Screen Model
/// Represents a single onboarding page from the database
class OnboardingScreenModel {
  final String id;
  final String imageUrl;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final int displayOrder;
  final bool isActive;

  const OnboardingScreenModel({
    required this.id,
    required this.imageUrl,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.displayOrder,
    this.isActive = true,
  });

  factory OnboardingScreenModel.fromJson(Map<String, dynamic> json) {
    return OnboardingScreenModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      titleAr: json['title_ar'] as String,
      titleEn: json['title_en'] as String,
      descriptionAr: json['description_ar'] as String,
      descriptionEn: json['description_en'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Get title based on current locale
  String getTitle(String languageCode) {
    return languageCode == 'ar' ? titleAr : titleEn;
  }

  /// Get description based on current locale
  String getDescription(String languageCode) {
    return languageCode == 'ar' ? descriptionAr : descriptionEn;
  }
}
