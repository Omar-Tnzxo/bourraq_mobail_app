import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:bourraq/core/services/session_manager.dart';
import 'package:bourraq/features/home/data/models/home_section_model.dart';
import 'package:bourraq/features/home/data/repositories/home_repository.dart';
import 'package:bourraq/features/home/presentation/widgets/home_banners_carousel.dart';
import 'package:bourraq/features/home/presentation/widgets/home_categories_section.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';

part 'home_state.dart';

/// HomeCubit - Manages home screen state with dynamic sections
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final SessionManager _sessionManager = SessionManager();

  HomeCubit({HomeRepository? repository})
    : _repository = repository ?? HomeRepository(),
      super(HomeInitial());

  /// Load all home screen data dynamically based on sections config
  Future<void> loadHomeData() async {
    if (isClosed) return;
    emit(HomeLoading());

    try {
      // First, fetch the sections configuration
      final sections = await _repository.getHomeSections();
      if (isClosed) return;

      // If no sections configured, use defaults
      if (sections.isEmpty) {
        await _loadDefaultSections();
        return;
      }

      // Load data for each active section
      final Map<String, dynamic> sectionData = {};

      for (final section in sections) {
        if (isClosed) return;
        final data = await _loadSectionData(section);
        sectionData[section.id] = data;
      }

      if (isClosed) return;
      emit(HomeLoaded(sections: sections, sectionData: sectionData));
    } catch (e) {
      if (isClosed) return;

      // Check if it's a JWT error - try refresh first
      final wasJwtError = await _sessionManager.handleSupabaseError(e);
      if (wasJwtError) {
        if (_sessionManager.isSessionValid) {
          return loadHomeData();
        }
        return loadHomeData();
      }

      // If home_sections table doesn't exist, fall back to defaults
      if (e.toString().contains('home_sections')) {
        await _loadDefaultSections();
        return;
      }

      if (isClosed) return;
      emit(HomeError(message: e.toString()));
    }
  }

  /// Load data for a specific section based on its type and config
  Future<dynamic> _loadSectionData(HomeSection section) async {
    final config = section.config;
    final limit = config.limit;

    switch (section.sectionType) {
      case 'banners':
        final data = await _repository.getBanners(limit: limit);
        return _mapBanners(data, config);

      case 'categories':
        final data = await _repository.getCategories(limit: limit);
        return _mapCategories(data);

      case 'products':
        final source = config.source ?? 'best_sellers';
        final data = await _repository.getProductsBySource(
          source: source,
          categoryId: config.categoryId,
          limit: limit ?? 10,
        );
        return _mapProducts(data);

      default:
        return [];
    }
  }

  /// Fallback to default sections if home_sections table not configured
  Future<void> _loadDefaultSections() async {
    try {
      final results = await Future.wait([
        _repository.getBanners(),
        _repository.getCategories(),
        _repository.getBestSellers(),
      ]);

      // Create default sections
      final defaultSections = [
        const HomeSection(
          id: 'default_banners',
          sectionType: 'banners',
          displayOrder: 1,
          config: HomeSectionConfig(),
        ),
        const HomeSection(
          id: 'default_categories',
          sectionType: 'categories',
          titleAr: 'التصنيفات',
          titleEn: 'Categories',
          displayOrder: 2,
          config: HomeSectionConfig(),
        ),
        const HomeSection(
          id: 'default_products',
          sectionType: 'products',
          titleAr: 'الأكثر مبيعاً',
          titleEn: 'Best Sellers',
          displayOrder: 3,
          config: HomeSectionConfig(
            source: 'best_sellers',
            showSeeAll: false, // TODO: Enable when /products route is created
          ),
        ),
      ];

      final sectionData = {
        'default_banners': _mapBanners(results[0], const HomeSectionConfig()),
        'default_categories': _mapCategories(results[1]),
        'default_products': _mapProducts(results[2]),
      };

      emit(HomeLoaded(sections: defaultSections, sectionData: sectionData));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  /// Refresh home data
  Future<void> refresh() async {
    await loadHomeData();
  }

  /// Map raw banner data to BannerItem
  List<BannerItem> _mapBanners(
    List<Map<String, dynamic>> data,
    HomeSectionConfig config,
  ) {
    return data.map((json) {
      return BannerItem(
        id: json['id'] as String,
        imageUrl: json['image_url_ar'] as String? ?? '',
        imageUrlEn: json['image_url_en'] as String?,
        actionUrl: json['action_url'] as String?,
        isExternal: json['is_external'] as bool? ?? false,
      );
    }).toList();
  }

  /// Map raw category data to CategoryItem
  List<CategoryItem> _mapCategories(List<Map<String, dynamic>> data) {
    return data.map((json) {
      return CategoryItem(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
      );
    }).toList();
  }

  /// Map raw product data to ProductItem
  List<ProductItem> _mapProducts(List<Map<String, dynamic>> data) {
    return data.map((json) {
      return ProductItem(
        id: json['id'] as String,
        nameAr: json['name_ar'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        oldPrice: (json['old_price'] as num?)?.toDouble(),
        imageUrl: json['image_url'] as String? ?? '',
        isAvailable: json['is_active'] as bool? ?? true,
      );
    }).toList();
  }
}
