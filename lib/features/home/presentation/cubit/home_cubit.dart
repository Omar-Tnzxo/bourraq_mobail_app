import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bourraq/core/services/session_manager.dart';
import 'package:bourraq/core/utils/error_handler.dart';
import 'package:bourraq/features/home/data/models/home_section_model.dart';
import 'package:bourraq/features/home/data/repositories/home_repository.dart';
import 'package:bourraq/features/home/presentation/widgets/home_banners_carousel.dart';
import 'package:bourraq/features/categories/data/models/category_model.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/products/data/repositories/branch_product_repository.dart';
import 'package:bourraq/features/products/data/models/branch_product_model.dart';

part 'home_state.dart';

/// HomeCubit - Manages home screen state with dynamic sections
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final BranchProductRepository _branchProductRepo;
  final SessionManager _sessionManager = SessionManager();

  /// Current area ID for branch-filtered product fetching
  String? _areaId;

  HomeCubit({
    HomeRepository? repository,
    BranchProductRepository? branchProductRepository,
  }) : _repository = repository ?? HomeRepository(),
       _branchProductRepo =
           branchProductRepository ?? BranchProductRepository(),
       super(HomeInitial());

  /// Load all home screen data with cache-first strategy
  ///
  /// 1. Immediately emit cached data if available (fast UI response)
  /// 2. Fetch fresh data from network in background
  /// 3. Update UI when fresh data arrives
  Future<void> loadHomeData({String? areaId}) async {
    if (isClosed) return;
    _areaId = areaId ?? _areaId;

    // Step 1: Try to load from cache first for instant UI
    final hasCachedData = await _tryLoadFromCache();

    // Only show loading spinner if no cached data
    if (!hasCachedData && !isClosed) {
      emit(HomeLoading());
    }

    // Step 2: Fetch fresh data from network
    try {
      await _fetchAndEmitFreshData();
    } catch (e) {
      if (isClosed) return;

      // Handle JWT errors
      final wasJwtError = await _sessionManager.handleSupabaseError(e);
      if (wasJwtError) {
        if (_sessionManager.isSessionValid) {
          return loadHomeData();
        }
      }

      // If home_sections table doesn't exist, fall back to defaults
      if (e.toString().contains('home_sections')) {
        await _loadDefaultSections();
        return;
      }

      // If we have cached data, keep showing it with stale indicator
      if (hasCachedData) {
        // Keep current state but mark as stale if needed
        return;
      }

      if (!isClosed) {
        debugPrint('❌ [HomeCubit] Error loading fresh data: $e');
        if (e is PostgrestException) {
          debugPrint(
            '❌ [HomeCubit] PG Error: ${e.message} (Code: ${e.code}, Details: ${e.details})',
          );
        }
        emit(HomeError(message: ErrorHandler.getErrorKey(e)));
      }
    }
  }

  /// Try to load data from cache
  Future<bool> _tryLoadFromCache() async {
    if (!_repository.hasHomeCache()) return false;

    try {
      final cachedBanners = _repository.getCachedBanners(stale: true);
      final cachedCategories = _repository.getCachedCategories(stale: true);
      final cachedProducts = _repository.getCachedProducts(stale: true);

      if (cachedBanners == null &&
          cachedCategories == null &&
          cachedProducts == null) {
        return false;
      }

      final cacheAge = _repository.getHomeCacheAge();

      // Create default sections for cached data
      final defaultSections = _buildDefaultSections();
      final sectionData = {
        'default_banners': _mapBanners(
          cachedBanners ?? [],
          const HomeSectionConfig(),
        ),
        'default_categories': _mapCategories(cachedCategories ?? []),
        'default_products': _mapProducts(cachedProducts ?? []),
      };

      if (!isClosed) {
        emit(
          HomeLoadedFromCache(
            sections: defaultSections,
            sectionData: sectionData,
            isStale: true,
            cacheAgeMinutes: cacheAge,
            isRefreshing: true, // Will fetch fresh data
          ),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch fresh data from network and emit
  Future<void> _fetchAndEmitFreshData() async {
    // Fetch sections configuration
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

    if (!isClosed) {
      emit(HomeLoaded(sections: sections, sectionData: sectionData));
    }
  }

  /// Build default sections structure
  List<HomeSection> _buildDefaultSections() {
    return const [
      HomeSection(
        id: 'default_banners',
        sectionType: 'banners',
        displayOrder: 1,
        config: HomeSectionConfig(placement: 'main_carousel'),
      ),
      HomeSection(
        id: 'default_categories',
        sectionType: 'categories',
        titleAr: 'التصنيفات',
        titleEn: 'Categories',
        displayOrder: 2,
        config: HomeSectionConfig(),
      ),
      HomeSection(
        id: 'spotlight_banners',
        sectionType: 'banners',
        displayOrder: 3,
        config: HomeSectionConfig(placement: 'spotlight', limit: 1),
      ),
      HomeSection(
        id: 'default_products',
        sectionType: 'products',
        titleAr: 'الأكثر مبيعاً',
        titleEn: 'Best Sellers',
        displayOrder: 4,
        config: HomeSectionConfig(source: 'best_sellers', showSeeAll: false),
      ),
    ];
  }

  /// Load data for a specific section based on its type and config
  Future<dynamic> _loadSectionData(HomeSection section) async {
    final config = section.config;
    final limit = config.limit;

    switch (section.sectionType) {
      case 'banners':
        final data = await _repository.getBanners(
          limit: limit,
          placement: config.placement,
        );
        return _mapBanners(data, config);

      case 'categories':
        final data = await _repository.getCategories(limit: limit);
        return _mapCategories(data);

      case 'products':
        return _loadBranchProducts(
          source: config.source ?? 'best_sellers',
          categoryId: config.categoryId,
          limit: limit ?? 10,
        );

      default:
        return [];
    }
  }

  Future<List<ProductItem>> _loadBranchProducts({
    required String source,
    String? categoryId,
    int limit = 10,
  }) async {
    final areaId = _areaId;
    List<BranchProduct> branchProducts;

    switch (source) {
      case 'best_sellers':
        branchProducts = await _branchProductRepo.getBestSellersForArea(
          areaId: areaId,
          limit: areaId == null ? limit * 2 : limit,
        );
        break;
      case 'newest':
        branchProducts = await _branchProductRepo.getNewestForArea(
          areaId: areaId,
          limit: areaId == null ? limit * 2 : limit,
        );
        break;
      case 'offers':
        branchProducts = await _branchProductRepo.getOffersForArea(
          areaId: areaId,
          limit: areaId == null ? limit * 2 : limit,
        );
        break;
      case 'category':
        branchProducts = await _branchProductRepo.getBranchProductsByArea(
          areaId: areaId,
          categoryId: categoryId,
          limit: areaId == null ? limit * 2 : limit,
        );
        break;
      default:
        branchProducts = await _branchProductRepo.getBranchProductsByArea(
          areaId: areaId,
          limit: areaId == null ? limit * 2 : limit,
        );
    }

    if (areaId == null) {
      final seenIds = <String>{};
      final uniqueProducts = <BranchProduct>[];
      for (var sp in branchProducts) {
        if (!seenIds.contains(sp.productId) && uniqueProducts.length < limit) {
          seenIds.add(sp.productId);
          uniqueProducts.add(sp);
        }
      }
      branchProducts = uniqueProducts;
    }

    return branchProducts
        .map((sp) => ProductItem.fromBranchProduct(sp))
        .toList();
  }

  /// Fallback to default sections if home_sections table not configured
  Future<void> _loadDefaultSections() async {
    try {
      // Fetch categories from HomeRepository
      final bannersFuture = _repository.getBanners();
      final categoriesFuture = _repository.getCategories();

      // Fetch products from branch-aware repo if areaId available
      final productsFuture = _loadBranchProducts(
        source: 'best_sellers',
        limit: 10,
      );

      final results = await Future.wait([
        bannersFuture,
        categoriesFuture,
        productsFuture,
      ]);

      final banners = results[0] as List<Map<String, dynamic>>;
      final categories = results[1] as List<Map<String, dynamic>>;
      final products = results[2] as List<ProductItem>;

      // Cache the raw data for offline access (banners + categories only)
      await _repository.cacheHomeData(
        banners: banners,
        categories: categories,
        products: const [],
      );

      // Create default sections using the reusable builder
      final defaultSections = _buildDefaultSections();

      final sectionData = {
        'default_banners': _mapBanners(banners, const HomeSectionConfig()),
        'default_categories': _mapCategories(categories),
        'default_products': products,
      };

      if (!isClosed) {
        emit(HomeLoaded(sections: defaultSections, sectionData: sectionData));
      }
    } catch (e) {
      if (!isClosed) {
        emit(HomeError(message: ErrorHandler.getErrorKey(e)));
      }
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
        placement: json['placement'] as String? ?? 'main_carousel',
        isAutoScroll: json['is_auto_scroll'] as bool? ?? true,
        scrollIntervalSeconds: json['scroll_interval_seconds'] as int? ?? 5,
      );
    }).toList();
  }

  /// Map raw category data to CategoryItem
  List<CategoryItem> _mapCategories(List<Map<String, dynamic>> data) {
    return data
        .map<CategoryItem>((json) => CategoryItem.fromJson(json))
        .toList();
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
