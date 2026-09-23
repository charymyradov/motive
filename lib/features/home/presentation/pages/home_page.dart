import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analyzer/presentation/pages/analyzer_page.dart';
import '../../../game/presentation/bloc/game_bloc.dart';
import '../../../game/presentation/cubit/collection_cubit.dart';
import '../../../game/presentation/pages/collection_page.dart';
import '../../../game/presentation/pages/feed_page.dart';
import '../../../game/presentation/widgets/card_detail_overlay.dart';
import '../../../game/presentation/widgets/unlock_overlay.dart';
import '../../../profile/presentation/pages/me_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../cubit/home_cubit.dart';
import '../widgets/fade_indexed_stack.dart';
import '../widgets/tab_bar.dart';

/// Main shell: four tabs, the floating tab bar and the card spotlight.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A new day may have started while the app was in the background.
    if (state == AppLifecycleState.resumed) {
      final picked = context.read<SettingsBloc>().state.settings.pickedFields;
      context.read<GameBloc>().add(GameDayChecked(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final barBottom = math.max(media.padding.bottom, 12.0) + 10;
    final bottomInset = MotiveTabBar.height + barBottom + 16;
    final keyboardOpen = media.viewInsets.bottom > 0;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, home) {
        final cubit = context.read<HomeCubit>();
        return PopScope(
          canPop: home.spotlight == null && home.tab == HomeTab.feed,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (home.spotlight != null) {
              cubit.closeSpotlight();
            } else {
              cubit.selectTab(HomeTab.feed);
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: FadeIndexedStack(
                  index: home.tab.index,
                  children: [
                    FeedPage(bottomInset: bottomInset),
                    CollectionPage(bottomInset: bottomInset),
                    AnalyzerPage(bottomInset: bottomInset),
                    MePage(bottomInset: bottomInset),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 12,
                right: 12,
                bottom: keyboardOpen ? -MotiveTabBar.height - 40 : barBottom,
                child: MotiveTabBar(current: home.tab, onSelect: cubit.selectTab),
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (home.spotlight) {
                    null => const SizedBox.shrink(),
                    Spotlight(kind: SpotlightKind.unlock, :final cardId) => UnlockOverlay(
                        key: ValueKey('unlock-$cardId'),
                        cardId: cardId,
                        onClose: cubit.closeSpotlight,
                        onOpenCollection: () {
                          context.read<CollectionCubit>().showView(CollectionView.paths);
                          cubit.selectTab(HomeTab.cards);
                        },
                      ),
                    Spotlight(kind: SpotlightKind.detail, :final cardId) => CardDetailOverlay(
                        key: ValueKey('detail-$cardId'),
                        cardId: cardId,
                        onClose: cubit.closeSpotlight,
                      ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
