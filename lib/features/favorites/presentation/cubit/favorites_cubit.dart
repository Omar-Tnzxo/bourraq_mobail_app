import 'package:bloc/bloc.dart';
import 'package:bourraq/core/utils/error_handler.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:equatable/equatable.dart';

// States
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<Product> favorites;
  // Keep track of processing IDs to show spinners on specific items
  final Set<String> processingIds;

  const FavoritesLoaded(this.favorites, {this.processingIds = const {}});

  @override
  List<Object?> get props => [favorites, processingIds];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesCubit(this._repository) : super(FavoritesInitial());

  Future<void> loadFavorites({String? areaId}) async {
    emit(FavoritesLoading());
    try {
      final favorites = await _repository.getFavorites(areaId: areaId);
      emit(FavoritesLoaded(favorites));
    } catch (e) {
      emit(FavoritesError(ErrorHandler.getErrorKey(e)));
    }
  }

  Future<void> removeFavorite(String productId) async {
    final currentState = state;
    if (currentState is FavoritesLoaded) {
      // Optimistic update possibility, but for now let's just use processing state
      // or remove immediately from UI then sync.
      // Let's allow UI to show removal animation or similar.

      // Update state to include this ID in processing
      final newProcessing = Set<String>.from(currentState.processingIds)
        ..add(productId);
      emit(
        FavoritesLoaded(currentState.favorites, processingIds: newProcessing),
      );

      try {
        await _repository.removeFromFavorites(productId);

        // Remove from list
        final updatedList = currentState.favorites
            .where((p) => p.id != productId)
            .toList();

        // Update state with new list and remove from processing
        final processingDone = Set<String>.from(newProcessing)
          ..remove(productId);
        emit(FavoritesLoaded(updatedList, processingIds: processingDone));
      } catch (e) {
        // Revert on error
        final processingDone = Set<String>.from(newProcessing)
          ..remove(productId);
        emit(
          FavoritesLoaded(
            currentState.favorites,
            processingIds: processingDone,
          ),
        );
        // Optionally emit error or toast event
      }
    }
  }

  // Method to refresh silently (e.g. after navigating back)
  Future<void> refreshFavorites({String? areaId}) async {
    try {
      final favorites = await _repository.getFavorites(areaId: areaId);
      emit(FavoritesLoaded(favorites));
    } catch (e) {
      // Silent error or keep previous state
    }
  }
}
