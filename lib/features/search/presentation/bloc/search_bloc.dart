import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/core/utils/error_handler.dart';
import '../../data/models/search_history_item.dart';
import '../../data/models/popular_search_item.dart';
import '../../data/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

/// Search BLoC
/// Handles search logic with debouncing and state management
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository;
  Timer? _debounceTimer;

  SearchBloc({SearchRepository? repository})
    : _repository = repository ?? SearchRepository(),
      super(const SearchState()) {
    on<SearchInitialized>(_onInitialized);
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchFromSuggestion>(_onFromSuggestion);
    on<SearchCleared>(_onCleared);
    on<SearchHistoryItemDeleted>(_onHistoryItemDeleted);
    on<SearchHistoryCleared>(_onHistoryCleared);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  /// Initialize: load history and popular searches
  Future<void> _onInitialized(
    SearchInitialized event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(status: SearchStatus.loading));

    try {
      // Load all data in parallel
      final historyFuture = _repository.getSearchHistory();
      final popularSearchesFuture = _repository.getPopularSearches();
      final popularProductsFuture = _repository.getPopularProducts(limit: 6);

      final history = await historyFuture;
      final popularSearches = await popularSearchesFuture;
      final popularProducts = await popularProductsFuture;

      emit(
        state.copyWith(
          status: SearchStatus.loaded,
          searchHistory: history,
          popularSearches: popularSearches,
          popularProducts: popularProducts,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.error,
          errorMessage: ErrorHandler.getErrorKey(e),
        ),
      );
    }
  }

  /// Handle query input with debouncing
  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();

    if (event.query.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          searchResults: [],
          status: SearchStatus.loaded,
        ),
      );
      return;
    }

    emit(state.copyWith(query: event.query, status: SearchStatus.searching));

    // Debounce search (300ms)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      add(SearchSubmitted(event.query));
    });
  }

  /// Perform search
  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) return;

    emit(state.copyWith(status: SearchStatus.searching));

    try {
      final results = await _repository.searchProducts(event.query);

      // Add to history (don't await, do it in background)
      _repository.addToSearchHistory(event.query);

      // Track search analytics
      if (results.isEmpty) {
        AnalyticsService().trackSearchNoResults(searchTerm: event.query);
      } else {
        AnalyticsService().trackSearch(
          searchTerm: event.query,
          resultsCount: results.length,
        );
      }

      emit(
        state.copyWith(
          status: SearchStatus.loaded,
          query: event.query,
          searchResults: results,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.error,
          errorMessage: ErrorHandler.getErrorKey(e),
        ),
      );
    }
  }

  /// Search from suggestion tap
  Future<void> _onFromSuggestion(
    SearchFromSuggestion event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(query: event.query, status: SearchStatus.searching));

    try {
      final results = await _repository.searchProducts(event.query);

      // Add to history
      _repository.addToSearchHistory(event.query);

      emit(state.copyWith(status: SearchStatus.loaded, searchResults: results));
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.error,
          errorMessage: ErrorHandler.getErrorKey(e),
        ),
      );
    }
  }

  /// Clear search
  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    emit(
      state.copyWith(query: '', searchResults: [], status: SearchStatus.loaded),
    );
  }

  /// Delete single history item
  Future<void> _onHistoryItemDeleted(
    SearchHistoryItemDeleted event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _repository.deleteSearchHistoryItem(event.id);

      final updatedHistory = state.searchHistory
          .where((item) => item.id != event.id)
          .toList();

      emit(state.copyWith(searchHistory: updatedHistory));
    } catch (e) {
      // Silently fail for history deletion
    }
  }

  /// Clear all history
  Future<void> _onHistoryCleared(
    SearchHistoryCleared event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await _repository.clearSearchHistory();
      emit(state.copyWith(searchHistory: []));
    } catch (e) {
      // Silently fail for history clearing
    }
  }
}
