/// Popular Search Item Model
/// Represents an admin-managed popular search keyword
class PopularSearchItem {
  final String id;
  final String keywordAr;
  final String keywordEn;
  final int displayOrder;
  final bool isActive;

  const PopularSearchItem({
    required this.id,
    required this.keywordAr,
    required this.keywordEn,
    required this.displayOrder,
    required this.isActive,
  });

  factory PopularSearchItem.fromMap(Map<String, dynamic> map) {
    return PopularSearchItem(
      id: map['id'] as String,
      keywordAr: map['keyword_ar'] as String,
      keywordEn: map['keyword_en'] as String,
      displayOrder: map['display_order'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  /// Get keyword based on locale
  String getKeyword(bool isArabic) => isArabic ? keywordAr : keywordEn;
}
