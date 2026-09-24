import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../game/domain/entities/game_catalog.dart';
import '../../../game/domain/entities/player_progress.dart';
import '../../../game/presentation/bloc/game_bloc.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../widgets/profile_sheets.dart';

class MePage extends StatelessWidget {
  const MePage({super.key, required this.bottomInset});
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final top = MediaQuery.paddingOf(context).top;
    final settings = context.select((SettingsBloc b) => b.state.settings);
    final game = context.watch<GameBloc>().state;
    final catalog = game.catalog;
    if (catalog == null) return const Center(child: CircularProgressIndicator.adaptive());
    final progress = game.progress;

    return ListView(
      padding: EdgeInsets.fromLTRB(18, top + 16, 18, bottomInset + 24),
      children: [
        _Identity(settings: settings, title: _title(progress, catalog)),
        const SizedBox(height: 20),
        _StreakCard(progress: progress),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Stat(value: '${progress.collectedCount}', label: 'Cards')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(value: progress.accuracy == null ? '—' : '${progress.accuracy}%', label: 'Accuracy')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(value: progress.xp.grouped, label: 'XP')),
          ],
        ),
        const SizedBox(height: 22),
        const MonoLabel('SETTINGS', spacing: .18),
        const SizedBox(height: 10),
        Glass(
          radius: 22,
          child: Column(
            children: [
              _Row(
                title: 'Appearance',
                trailing: _ThemeToggle(mode: settings.themeMode),
              ),
              const _Divider(),
              _Row(
                title: 'Daily drop reminder',
                subtitle: '${AppConstants.reminderHour}:00, when new cases land',
                onTap: () => context.read<SettingsBloc>().add(ReminderToggled(!settings.reminderEnabled)),
                trailing: _Switch(on: settings.reminderEnabled),
              ),
              const _Divider(),
              _Row(
                title: 'Your arenas',
                subtitle: settings.pickedFields.map((id) => catalog.field(id).short).join(', '),
                onTap: () => showArenasSheet(context, catalog.fields),
                trailing: const _Chevron(),
              ),
              const _Divider(),
              _Row(
                title: 'Analyzer engine',
                subtitle: settings.hasApiKey ? 'Claude · connected' : 'Offline · add a Claude API key',
                onTap: () => showApiKeySheet(context),
                trailing: const _Chevron(),
              ),
              const _Divider(),
              _Row(
                title: 'Replay onboarding',
                onTap: () => context.read<SettingsBloc>().add(const OnboardingReplayRequested()),
                trailing: const _Chevron(),
              ),
              const _Divider(),
              _Row(
                title: 'Reset progress',
                danger: true,
                onTap: () async {
                  if (await confirmReset(context) && context.mounted) {
                    context.read<GameBloc>().add(GameResetRequested(settings.pickedFields));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(child: Text('Motive 1.0', style: AppText.mono(10, color: c.ink3, letterSpacing: .1))),
      ],
    );
  }

  String _title(PlayerProgress progress, GameCatalog catalog) {
    if (progress.collectedCount == 0) return 'Novice · just getting started';
    final paths = catalog.fields.map((f) => progress.masteryOf(f, catalog.cards)).toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));
    final top = paths.first;
    return '${top.field.name} · ${top.rank.label}';
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.settings, required this.title});
  final AppSettings settings;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final name = settings.userName.isEmpty ? 'Add your name' : settings.userName;
    final initial = settings.userName.isEmpty ? 'M' : settings.userName.characters.first.toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showNameDialog(context, settings.userName),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-.4, -.4),
                colors: [Color(0xFFC77DFF), Color(0xFF5B2BFF), Color(0xFF0A0A2A)],
                stops: [0, .55, 1],
              ),
              boxShadow: [
                BoxShadow(color: c.bg, spreadRadius: 2),
                const BoxShadow(color: Palette.accent, spreadRadius: 3.5),
                const BoxShadow(color: Palette.accent, blurRadius: 30, spreadRadius: -4),
              ],
            ),
            child: Text(initial, style: AppText.serif(28, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.serif(30, color: settings.userName.isEmpty ? c.ink3 : c.ink),
                ),
                const SizedBox(height: 4),
                Text(title, style: AppText.sans(13, color: c.ink2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.progress});
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final now = DateTime.now();
    final streak = progress.streak(now);
    final todayDone = progress.isActiveOn(now);
    final monday = DayKey.startOfWeek(now);
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Glass(
      radius: 26,
      padding: const EdgeInsets.all(20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 210,
              height: 210,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x40FF7A00), Color(0x00FF7A00)]),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$streak', style: AppText.serif(64, color: c.ink, height: .85)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('day streak', style: AppText.sans(15, weight: FontWeight.w700, color: c.ink)),
                          const SizedBox(height: 2),
                          Text(
                            todayDone
                                ? "You're safe for today. See you tomorrow."
                                : streak > 0
                                    ? 'Answer one case today to keep it.'
                                    : 'Answer one case to start a streak.',
                            style: AppText.sans(12.5, color: c.ink2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Builder(builder: (context) {
                        final day = monday.add(Duration(days: i));
                        final active = progress.isActiveOn(day);
                        final isToday = DayKey.of(day) == DayKey.of(now);
                        return Column(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: active ? Palette.flame : null,
                                border: Border.all(color: isToday ? c.ink2 : c.line, width: isToday ? 1.5 : 1),
                                boxShadow: active
                                    ? const [BoxShadow(color: Color(0xCCFF8C00), blurRadius: 14, spreadRadius: -2)]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(letters[i], style: AppText.mono(10, color: isToday ? c.ink : c.ink3, letterSpacing: 0)),
                          ],
                        );
                      }),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Glass(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppText.serif(32, color: c.ink)),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppText.sans(12, color: c.ink2)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.trailing, this.onTap, this.danger = false});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, subtitle == null ? 15 : 13, 14, subtitle == null ? 15 : 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.sans(14.5, weight: FontWeight.w600, color: danger ? Palette.nope : c.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.sans(12, color: c.ink3)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(left: 18), child: Container(height: 1, color: context.mc.line));
}

class _Chevron extends StatelessWidget {
  const _Chevron();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text('›', style: AppText.sans(18, color: context.mc.ink3)),
      );
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 50,
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: on ? Palette.holds : c.line, borderRadius: BorderRadius.circular(15)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        curve: const Cubic(.3, 1.5, .5, 1),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => GetIt.instance<SoundService>().playToggleClick(),
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x4D000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.mode});
  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    Widget seg(String label, AppThemeMode m) {
      final on = mode == m;
      return GestureDetector(
        onTap: () {
          GetIt.instance<SoundService>().playToggleClick();
          context.read<SettingsBloc>().add(ThemeModeChanged(m));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? c.solid : Colors.transparent, borderRadius: BorderRadius.circular(11)),
          child: Text(label, style: AppText.sans(12.5, weight: FontWeight.w700, color: on ? c.onSolid : c.ink2)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.glass2, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('Dark', AppThemeMode.dark), seg('Light', AppThemeMode.light)]),
    );
  }
}
