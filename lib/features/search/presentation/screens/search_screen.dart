import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
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
  CartService? _cartService;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use maybeOf pattern to avoid ProviderNotFoundException
    try {
      _cartService = Provider.of<CartService>(context, listen: false);
    } catch (_) {
      _cartService = null;
    }
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
      if (state.status == SearchStatus.searching) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.darkGreen),
        );
      }
      return SearchResultsGrid(
        results: state.searchResults,
        query: state.query,
        cartService: _cartService,
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
        ),
      ],
    );
  }
}
