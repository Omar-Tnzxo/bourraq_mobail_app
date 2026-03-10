import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/account/presentation/cubit/faqs_cubit.dart';
import 'package:bourraq/features/account/data/repositories/account_content_repository.dart';
import 'package:bourraq/features/account/data/models/faq_model.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FaqsCubit(context.read<AccountContentRepository>())..loadFaqs(),
      child: const _FaqsView(),
    );
  }
}

class _FaqsView extends StatefulWidget {
  const _FaqsView();

  @override
  State<_FaqsView> createState() => _FaqsViewState();
}

class _FaqsViewState extends State<_FaqsView> {
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, isArabic),
          Expanded(
            child: BlocBuilder<FaqsCubit, FaqsState>(
              builder: (context, state) {
                if (state is FaqsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                if (state is FaqsError) {
                  return _buildErrorState(context);
                }

                if (state is FaqsLoaded) {
                  if (state.faqs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: state.faqs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _FaqTile(faq: state.faqs[index]);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return BourraqHeader(
      padding: const EdgeInsets.only(top: 16, bottom: 48, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Padding(
              padding: EdgeInsets.only(
                right: isArabic ? 0 : 12,
                left: isArabic ? 12 : 0,
              ),
              child: Icon(
                isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                color: AppColors.accentYellow,
                size: 28,
              ),
            ),
          ),

          // Title
          Text(
            'account.faqs'.tr(),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.accentYellow,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.wifi,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'common.error'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: () => context.read<FaqsCubit>().loadFaqs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('common.retry'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.search,
              size: 64,
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'search.no_results'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded
              ? AppColors.primaryGreen.withValues(alpha: 0.3)
              : AppColors.border,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          if (_isExpanded)
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
              if (expanded) HapticFeedback.lightImpact();
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isExpanded
                    ? AppColors.accentYellow.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.circleQuestionMark,
                size: 20,
                color: _isExpanded
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
            ),
            title: Text(
              widget.faq.getQuestion(context.locale.languageCode),
              style: TextStyle(
                fontSize: 15,
                fontWeight: _isExpanded ? FontWeight.w800 : FontWeight.w600,
                color: _isExpanded
                    ? AppColors.primaryGreen
                    : AppColors.textPrimary,
              ),
            ),
            trailing: Icon(
              _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 20,
              color: _isExpanded
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  widget.faq.getAnswer(context.locale.languageCode),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
