/// Home Section Model - Dynamic section configuration from Supabase
class HomeSection {
  final String id;
  final String sectionType; // 'banners', 'categories', 'products'
  final String? titleAr;
  final String? titleEn;
  final int displayOrder;
  final bool isActive;
  final HomeSectionConfig config;

  const HomeSection({
    required this.id,
    required this.sectionType,
    this.titleAr,
    this.titleEn,
    this.displayOrder = 0,
    this.isActive = true,
    required this.config,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id: json['id'] as String,
      sectionType: json['section_type'] as String,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      config: HomeSectionConfig.fromJson(
        json['config'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  String getTitle(String languageCode) {
    if (languageCode == 'ar') {
      return titleAr ?? titleEn ?? '';
    }
    return titleEn ?? titleAr ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_type': sectionType,
      'title_ar': titleAr,
      'title_en': titleEn,
      'display_order': displayOrder,
      'is_active': isActive,
      'config': config.toJson(),
    };
  }
}

/// Section configuration - flexible JSONB config
class HomeSectionConfig {
  // Common
  final int? limit;
  final bool showTitle;
  final bool showSeeAll;
  final String? seeAllRoute;

  // Banners specific
  final bool autoScroll;
  final int scrollIntervalMs;
  final String? placement; // NEW

  // Products specific
  final String? source; // 'best_sellers', 'newest', 'offers', 'category'
  final String? categoryId;

  const HomeSectionConfig({
    this.limit,
    this.showTitle = true,
    this.showSeeAll = true,
    this.seeAllRoute,
    this.autoScroll = true,
    this.scrollIntervalMs = 4000,
    this.placement,
    this.source,
    this.categoryId,
  });

  factory HomeSectionConfig.fromJson(Map<String, dynamic> json) {
    return HomeSectionConfig(
      limit: json['limit'] as int?,
      showTitle: json['show_title'] as bool? ?? true,
      showSeeAll: json['show_see_all'] as bool? ?? true,
      seeAllRoute: json['see_all_route'] as String?,
      autoScroll: json['auto_scroll'] as bool? ?? true,
      scrollIntervalMs: json['scroll_interval_ms'] as int? ?? 4000,
      placement: json['placement'] as String?,
      source: json['source'] as String?,
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limit': limit,
      'show_title': showTitle,
      'show_see_all': showSeeAll,
      'see_all_route': seeAllRoute,
      'auto_scroll': autoScroll,
      'scroll_interval_ms': scrollIntervalMs,
      'placement': placement,
      'source': source,
      'category_id': categoryId,
    };
  }
}
