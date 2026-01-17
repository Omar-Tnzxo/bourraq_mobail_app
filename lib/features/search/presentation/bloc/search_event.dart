import 'package:equatable/equatable.dart';

/// Search Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load - fetch history and popular searches
class SearchInitialized extends SearchEvent {
  const SearchInitialized();
}

/// User typed in search box (debounced)
class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// User submitted search (pressed enter or search button)
class SearchSubmitted extends SearchEvent {
  final String query;

  const SearchSubmitted(this.query);

  @override
  List<Object?> get props => [query];
}

/// User tapped a history item or popular search
class SearchFromSuggestion extends SearchEvent {
  final String query;

  const SearchFromSuggestion(this.query);

  @override
  List<Object?> get props => [query];
}

/// User cleared the search input
class SearchCleared extends SearchEvent {
  const SearchCleared();
}

/// User deleted a single history item
class SearchHistoryItemDeleted extends SearchEvent {
  final String id;

  const SearchHistoryItemDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

/// User cleared all history
class SearchHistoryCleared extends SearchEvent {
  const SearchHistoryCleared();
}
