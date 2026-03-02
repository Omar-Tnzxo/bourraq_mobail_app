class CategoryItem {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final String? imageUrlEn;
  final bool hideNameOnCard;

  const CategoryItem({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    this.imageUrlEn,
    this.hideNameOnCard = false,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      imageUrlEn: json['image_url_en'] as String?,
      hideNameOnCard: json['hide_name_on_card'] == true,
    );
  }

  /// Helper to get the correct image based on language
  String getImageUrl(String languageCode) {
    if (languageCode == 'en' && imageUrlEn != null && imageUrlEn!.isNotEmpty) {
      return imageUrlEn!;
    }
    return imageUrl;
  }
}
