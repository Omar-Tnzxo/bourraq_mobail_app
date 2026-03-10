import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/home/presentation/widgets/address_picker_bottom_sheet.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/popular_searches_section.dart';
import '../widgets/search_history_section.dart';
import '../widgets/search_results_grid.dart';
import '../widgets/popular_items_section.dart';

/// Search Screen
/// Full-featured search with history, popular searches, and results
/// Reference: Rabbit app search page
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AddressService _addressService = AddressService();
  late FavoritesRepository _favoritesRepository;
  final Set<String> _favoriteIds = {};
  CartService? _cartService;
  Address? _defaultAddress;

  @override
  void initState() {
    super.initState();
    _favoritesRepository = FavoritesRepository(Supabase.instance.client);
    _searchController.addListener(_onSearchTextChanged);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadDefaultAddress();
    await _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final favorites = await _favoritesRepository.getFavorites(
        areaId: _defaultAddress?.areaId,
      );
      if (mounted) {
        setState(() {
          _favoriteIds.clear();
          _favoriteIds.addAll(favorites.map((p) => p.id));
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(ProductItem product) async {
    final wasFavorite = _favoriteIds.contains(product.id);
    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id);
      }
    });

    try {
      if (wasFavorite) {
        await _favoritesRepository.removeFromFavorites(product.id);
      } else {
        await _favoritesRepository.addToFavorites(
          product.id,
          branchId: product.branchId,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (wasFavorite) {
            _favoriteIds.add(product.id);
          } else {
            _favoriteIds.remove(product.id);
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use maybeOf pattern to avoid ProviderNotFoundException
    if (_cartService == null) {
      try {
        _cartService = Provider.of<CartService>(context, listen: false);
      } catch (_) {
        try {
          _cartService = CartService.instance;
        } catch (_) {
          _cartService = null;
        }
      }
      _loadDefaultAddress();
    }
  }

  Future<void> _loadDefaultAddress() async {
    final address = await _addressService.getDefaultAddress();
    if (mounted) {
      setState(() {
        _defaultAddress = address;
      });
    }
  }

  void _showLocationPrompt() {
    AddressPickerBottomSheet.show(
      context: context,
      currentAddress: _defaultAddress,
      onAddressSelected: (address) async {
        final success = await _addressService.setDefaultAddress(address.id);
        if (success && mounted) {
          setState(() {
            _defaultAddress = address;
          });
        }
      },
    ).then((_) {
      // Re-load default address to be sure
      _loadDefaultAddress();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    // Trigger search on text change
    if (mounted) {
      setState(() {}); // Update UI for clear button
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc()..add(const SearchInitialized()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            return Column(
              children: [
                // Premium Curved Search Header
                BourraqHeader(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: SearchBarWidget(
                    controller: _searchController,
                    focusNode: _focusNode,
                    hintText: 'search.hint'.tr(),
                    showCancelButton: state.isSearching,
                    onChanged: (query) {
                      context.read<SearchBloc>().add(SearchQueryChanged(query));
                    },
                    onSubmitted: (query) {
                      context.read<SearchBloc>().add(SearchSubmitted(query));
                    },
                    onClear: () {
                      context.read<SearchBloc>().add(const SearchCleared());
                    },
                    onCancel: () {
                      _searchController.clear();
                      _focusNode.unfocus();
                      context.read<SearchBloc>().add(const SearchCleared());
                    },
                  ),
                ),

                // Content
                Expanded(child: _buildContent(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SearchState state) {
    // Show loading
    if (state.status == SearchStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkGreen),
      );
    }

    // Show results if searching
    if (state.isSearching) {
      if (state.status == SearchStatus.searching &&
          state.searchResults.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.darkGreen),
        );
      }
      return SearchResultsGrid(
        results: state.searchResults,
        query: state.query,
        cartService: _cartService,
        hasAddress: _defaultAddress != null,
        onLocationRequired: _showLocationPrompt,
        isLoadingMore: state.isLoadingMore,
        favoriteIds: _favoriteIds,
        onFavoriteToggle: _toggleFavorite,
        onLoadMore: () {
          context.read<SearchBloc>().add(const SearchLoadMore());
        },
      );
    }

    // Show suggestions (history + popular + popular items)
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      children: [
        // Popular Searches
        PopularSearchesSection(
          popularSearches: state.popularSearches,
          onSearchTap: (keyword) {
            _searchController.text = keyword;
            context.read<SearchBloc>().add(SearchFromSuggestion(keyword));
          },
        ),

        const SizedBox(height: 24),

        // Search History
        SearchHistorySection(
          history: state.searchHistory,
          onHistoryTap: (query) {
            _searchController.text = query;
            context.read<SearchBloc>().add(SearchFromSuggestion(query));
          },
          onDeleteItem: (id) {
            context.read<SearchBloc>().add(SearchHistoryItemDeleted(id));
          },
          onClearAll: () {
            context.read<SearchBloc>().add(const SearchHistoryCleared());
          },
        ),

        const SizedBox(height: 24),

        // Popular Items in Area
        PopularItemsSection(
          products: state.popularProducts,
          cartService: _cartService,
          hasAddress: _defaultAddress != null,
          onLocationRequired: _showLocationPrompt,
          favoriteIds: _favoriteIds,
          onFavoriteToggle: _toggleFavorite,
        ),
      ],
    );
  }
}
