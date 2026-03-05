import 'package:equatable/equatable.dart';

import '../../data/models/search_history_item.dart';
import '../../data/models/popular_search_item.dart';

/// Search States
enum SearchStatus { initial, loading, loaded, searching, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final String query;
  final List<Map<String, dynamic>> searchResults;
  final List<SearchHistoryItem> searchHistory;
  final List<PopularSearchItem> popularSearches;
  final List<Map<String, dynamic>> popularProducts;
  final String? errorMessage;
  final bool hasReachedMax;
  final int currentPage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.searchResults = const [],
    this.searchHistory = const [],
    this.popularSearches = const [],
    this.popularProducts = const [],
    this.errorMessage,
    this.hasReachedMax = false,
    this.currentPage = 0,
  });

  /// Check if actively searching
  bool get isSearching => query.isNotEmpty;

  /// Check if showing suggestions (history + popular)
  bool get showSuggestions => !isSearching && status != SearchStatus.loading;

  /// Check if showing results
  bool get showResults => isSearching && status == SearchStatus.loaded;

  /// Check if searching more pages
  bool get isLoadingMore =>
      isSearching &&
      status == SearchStatus.searching &&
      searchResults.isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Map<String, dynamic>>? searchResults,
    List<SearchHistoryItem>? searchHistory,
    List<PopularSearchItem>? popularSearches,
    List<Map<String, dynamic>>? popularProducts,
    String? errorMessage,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      searchResults: searchResults ?? this.searchResults,
      searchHistory: searchHistory ?? this.searchHistory,
      popularSearches: popularSearches ?? this.popularSearches,
      popularProducts: popularProducts ?? this.popularProducts,
      errorMessage: errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    searchResults,
    searchHistory,
    popularSearches,
    popularProducts,
    errorMessage,
    hasReachedMax,
    currentPage,
  ];
}
