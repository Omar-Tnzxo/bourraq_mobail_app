import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/pages/data/repositories/pages_repository.dart';
import 'package:bourraq/features/pages/presentation/cubit/pages_cubit.dart';

class StaticPageScreen extends StatelessWidget {
  final String slug;

  const StaticPageScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PagesCubit(PagesRepository())..loadPage(slug),
      child: const _StaticPageView(),
    );
  }
}

class _StaticPageView extends StatelessWidget {
  const _StaticPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: BlocBuilder<PagesCubit, PagesState>(
          builder: (context, state) {
            if (state is PagesLoaded) {
              final isAr = context.locale.languageCode == 'ar';
              return Text(
                isAr ? state.page.titleAr : state.page.titleEn,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: BlocBuilder<PagesCubit, PagesState>(
        builder: (context, state) {
          if (state is PagesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PagesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.circleAlert,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'common.error_occurred'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry logic could be added here if slug is available in state or context
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                    ),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          } else if (state is PagesLoaded) {
            final isAr = context.locale.languageCode == 'ar';
            final content = isAr ? state.page.contentAr : state.page.contentEn;
            final updatedAt = DateFormat.yMMMMd(
              context.locale.toString(),
            ).format(state.page.updatedAt);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${'common.last_update'.tr()}: $updatedAt',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        HtmlWidget(
                          content,
                          textStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                          onTapUrl: (url) async {
                            // Handle URL taps if needed
                            return true;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
