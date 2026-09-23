import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/motive_colors.dart';
import 'core/widgets/animated_blobs.dart';
import 'core/widgets/shake.dart';
import 'features/analyzer/presentation/bloc/analyzer_bloc.dart';
import 'features/game/presentation/bloc/game_bloc.dart';
import 'features/game/presentation/cubit/collection_cubit.dart';
import 'features/home/presentation/cubit/home_cubit.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'injection_container.dart';

class MotiveApp extends StatelessWidget {
  const MotiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ShakeController>.value(
      value: sl<ShakeController>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<SettingsBloc>()..add(const SettingsStarted())),
          BlocProvider(create: (_) => sl<GameBloc>()),
          BlocProvider(create: (_) => sl<AnalyzerBloc>()..add(const AnalyzerStarted())),
          BlocProvider(create: (_) => HomeCubit()),
          BlocProvider(create: (_) => CollectionCubit()),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (a, b) => a.settings.themeMode != b.settings.themeMode,
          builder: (context, state) {
            final dark = state.settings.themeMode == AppThemeMode.dark;
            return MaterialApp(
              title: 'Motive',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              themeAnimationDuration: const Duration(milliseconds: 400),
              home: const _Root(),
            );
          },
        ),
      ),
    );
  }
}

/// Background + onboarding/home switch + global listeners.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _gameStarted = false;

  void _maybeStartGame(SettingsState s) {
    if (_gameStarted || s.status != SettingsStatus.ready || !s.settings.onboarded) return;
    _gameStarted = true;
    context.read<GameBloc>().add(GameStarted(s.settings.pickedFields));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: c.bg,
        body: MultiBlocListener(
          listeners: [
            BlocListener<SettingsBloc, SettingsState>(
              listener: (context, s) => _maybeStartGame(s),
            ),
            BlocListener<SettingsBloc, SettingsState>(
              listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
              listener: (context, s) => _snack(context, s.notice!),
            ),
            BlocListener<SettingsBloc, SettingsState>(
              listenWhen: (a, b) => a.settings.onboarded && !b.settings.onboarded,
              listener: (context, s) => context.read<HomeCubit>().selectTab(HomeTab.feed),
            ),
            BlocListener<GameBloc, GameState>(
              listenWhen: (a, b) => b.error != null && a.error != b.error && b.status == GameStatus.ready,
              listener: (context, s) => _snack(context, s.error!),
            ),
          ],
          child: ShakeHost(
            controller: context.read<ShakeController>(),
            child: Stack(
              children: [
                const Positioned.fill(child: AnimatedBlobs()),
                Positioned.fill(
                  child: BlocBuilder<SettingsBloc, SettingsState>(
                    buildWhen: (a, b) => a.status != b.status || a.settings.onboarded != b.settings.onboarded,
                    builder: (context, s) {
                      final Widget child;
                      if (s.status == SettingsStatus.loading) {
                        child = const SizedBox.shrink(key: ValueKey('splash'));
                      } else if (!s.settings.onboarded) {
                        child = BlocProvider(
                          key: const ValueKey('onboarding'),
                          create: (_) => sl<OnboardingCubit>(param1: s.settings.pickedFields)..load(),
                          child: const OnboardingPage(),
                        );
                      } else {
                        child = const HomePage(key: ValueKey('home'));
                      }
                      return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: child);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), margin: const EdgeInsets.fromLTRB(16, 0, 16, 110)));
  }
}
