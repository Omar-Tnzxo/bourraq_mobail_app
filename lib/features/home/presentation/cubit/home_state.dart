part of 'home_cubit.dart';

/// Home screen states
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {}

/// Loading state
class HomeLoading extends HomeState {}

/// Loaded state with dynamic sections and their data
class HomeLoaded extends HomeState {
  /// Dynamic sections configuration
  final List<HomeSection> sections;

  /// Data for each section (keyed by section ID)
  final Map<String, dynamic> sectionData;

  const HomeLoaded({required this.sections, required this.sectionData});

  @override
  List<Object?> get props => [sections, sectionData];

  /// Get banners data for a section
  List<BannerItem> getBanners(String sectionId) {
    return (sectionData[sectionId] as List<BannerItem>?) ?? [];
  }

  /// Get categories data for a section
  List<CategoryItem> getCategories(String sectionId) {
    return (sectionData[sectionId] as List<CategoryItem>?) ?? [];
  }

  /// Get products data for a section
  List<ProductItem> getProducts(String sectionId) {
    return (sectionData[sectionId] as List<ProductItem>?) ?? [];
  }
}

/// Loaded from cache state - shows data is from cache (may be stale)
class HomeLoadedFromCache extends HomeLoaded {
  /// Whether the cache is stale (expired but still usable)
  final bool isStale;

  /// How old the cache is in minutes
  final int? cacheAgeMinutes;

  /// Whether background refresh is in progress
  final bool isRefreshing;

  const HomeLoadedFromCache({
    required super.sections,
    required super.sectionData,
    this.isStale = false,
    this.cacheAgeMinutes,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    sections,
    sectionData,
    isStale,
    cacheAgeMinutes,
    isRefreshing,
  ];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
