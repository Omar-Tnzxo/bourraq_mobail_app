import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Favorites service for managing favorite products
class FavoritesService {
  static const String _favoritesKey = 'favorites';
  final SharedPreferences _prefs;

  FavoritesService(this._prefs);

  /// Get all favorite product IDs
  List<String> getFavorites() {
    final String? favoritesJson = _prefs.getString(_favoritesKey);
    if (favoritesJson == null) return [];

    final List<dynamic> favoritesList = json.decode(favoritesJson);
    return favoritesList.cast<String>();
  }

  /// Check if product is favorite
  bool isFavorite(String productId) {
    final favorites = getFavorites();
    return favorites.contains(productId);
  }

  /// Add product to favorites
  Future<void> addToFavorites(String productId) async {
    final favorites = getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await _saveFavorites(favorites);
    }
  }

  /// Remove product from favorites
  Future<void> removeFromFavorites(String productId) async {
    final favorites = getFavorites();
    favorites.remove(productId);
    await _saveFavorites(favorites);
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String productId) async {
    if (isFavorite(productId)) {
      await removeFromFavorites(productId);
      return false;
    } else {
      await addToFavorites(productId);
      return true;
    }
  }

  /// Get favorites count
  int getFavoritesCount() {
    return getFavorites().length;
  }

  /// Save favorites to storage
  Future<void> _saveFavorites(List<String> favorites) async {
    final favoritesJson = json.encode(favorites);
    await _prefs.setString(_favoritesKey, favoritesJson);
  }
}
