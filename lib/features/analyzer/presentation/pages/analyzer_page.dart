import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/shake.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/analysis.dart';
import '../bloc/analyzer_bloc.dart';
import '../widgets/analyzer_widgets.dart';

abstract final class _Samples {
  static const politician =
      "Only I can stop the chaos. Every single day, hardworking families like yours are losing everything while the elites laugh at you. The other side wants you afraid and silent. Don't let them win. Share this before it gets taken down.";
  static const influencer =
      "I was broke 12 months ago. Now I make \$30K a month from my phone. Only 50 spots left in my FREE masterclass, and 4,000 people already joined. If you're still scrolling, you're choosing to stay broke.";
}

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key, required this.bottomInset});
  final double bottomInset;

  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  late final _text = TextEditingController(text: context.read<AnalyzerBloc>().state.text);
  final _scroll = ScrollController();
  final _resultKey = GlobalKey();

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _setText(String value) {
    _text.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
    context.read<AnalyzerBloc>().add(AnalyzerTextChanged(value));
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final mime = file.mimeType ??
          (name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
                  ? 'image/webp'
                  : name.endsWith('.gif')
                      ? 'image/gif'
                      : 'image/jpeg');
      if (mounted) context.read<AnalyzerBloc>().add(AnalyzerImageAttached(bytes, mime));
      GetIt.instance<SoundService>().playImageAttached();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open that image.')));
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<AnalyzerBloc>().add(const AnalyzerSubmitted());
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, alignment: .05);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final top = MediaQuery.paddingOf(context).top;
    final hasKey = context.select((SettingsBloc b) => b.state.settings.hasApiKey);

    return BlocConsumer<AnalyzerBloc, AnalyzerState>(
      listenWhen: (a, b) => a.status != b.status || a.result != b.result,
      listener: (context, state) {
        if (state.status == AnalyzerStatus.loading) _scrollToResult();
        if (state.status == AnalyzerStatus.success && state.result != null) {
          _scrollToResult();
          GetIt.instance<SoundService>().playScanComplete();
          context.read<ShakeController>().shake(haptic: false);
        }
      },
      builder: (context, state) {
        return ListView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(18, top + 16, 18, widget.bottomInset + 24),
          children: [
            const MonoLabel('ANALYZER', size: 11, spacing: .2),
            const SizedBox(height: 8),
            Text("Who's pulling the strings?", style: AppText.serif(40, color: c.ink)),
            const SizedBox(height: 10),
            Text(
              "Paste a post from a politician, influencer or brand. Motive shows you the levers they're pulling.",
              style: AppText.sans(14.5, color: c.ink2, height: 1.5),
            ),
            const SizedBox(height: 18),
            _InputBox(
              controller: _text,
              state: state,
              onChanged: (v) => context.read<AnalyzerBloc>().add(AnalyzerTextChanged(v)),
              onPickImage: _pickImage,
              onSubmit: _submit,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const MonoLabel('TRY', size: 11, weight: FontWeight.w500, spacing: 0),
                _Chip(label: 'Politician post', onTap: () => _setText(_Samples.politician)),
                _Chip(label: 'Influencer promo', onTap: () => _setText(_Samples.influencer)),
                if (state.text.isNotEmpty || state.image != null || state.result != null)
                  _Chip(
                    label: 'Clear',
                    onTap: () {
                      _text.clear();
                      context.read<AnalyzerBloc>().add(const AnalyzerReset());
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: hasKey ? null : () => context.read<HomeCubit>().selectTab(HomeTab.me),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: hasKey ? Palette.accent : c.ink3, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasKey
                          ? 'Claude engine · reads text and screenshots'
                          : 'Offline engine · add a Claude key in Me for deeper, screenshot-ready analysis',
                      style: AppText.sans(12, color: c.ink3),
                    ),
                  ),
                ],
              ),
            ),
            KeyedSubtree(
              key: _resultKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: const Cubic(.2, 1, .3, 1),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(a), child: child),
                ),
                child: switch (state.status) {
                  AnalyzerStatus.loading => const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.only(top: 18),
                      child: ScannerPanel(),
                    ),
                  AnalyzerStatus.failure => Container(
                      key: const ValueKey('error'),
                      margin: const EdgeInsets.only(top: 18),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Palette.nope.withValues(alpha: .4)),
                      ),
                      child: Text(state.error ?? '', style: AppText.sans(13.5, color: Palette.nopeSoft, height: 1.5)),
                    ),
                  AnalyzerStatus.success when state.result != null => Padding(
                      key: ValueKey(state.result!.id),
                      padding: const EdgeInsets.only(top: 18),
                      child: AnalysisResultView(analysis: state.result!),
                    ),
                  _ => const SizedBox.shrink(key: ValueKey('idle')),
                },
              ),
            ),
            if (state.history.isNotEmpty) ...[
              const SizedBox(height: 26),
              const MonoLabel('RECENT', spacing: .18),
              const SizedBox(height: 10),
              for (final a in state.history.take(10)) _HistoryTile(analysis: a, selected: a.id == state.result?.id),
            ],
          ],
        );
      },
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.state,
    required this.onChanged,
    required this.onPickImage,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final AnalyzerState state;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final loading = state.status == AnalyzerStatus.loading;
    return Glass(
      radius: 26,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              style: AppText.sans(15, color: c.ink, height: 1.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                hintText: 'Paste the post here…',
                hintStyle: AppText.sans(15, color: c.ink3, height: 1.5),
              ),
            ),
          ),
          if (state.image != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: c.glass2, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.memory(state.image!.bytes, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Screenshot attached', style: AppText.sans(12.5, color: c.ink2))),
                  TextButton(
                    onPressed: () => context.read<AnalyzerBloc>().add(const AnalyzerImageCleared()),
                    child: Text('Remove', style: AppText.sans(12, weight: FontWeight.w600, color: c.ink3)),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
            child: Row(
              children: [
                Pressable(
                  onTap: onPickImage,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.line),
                    ),
                    child: Text('+ Screenshot', style: AppText.sans(12.5, weight: FontWeight.w600, color: c.ink)),
                  ),
                ),
                const Spacer(),
                SolidButton(
                  label: loading ? 'Scanning…' : 'Expose it',
                  onTap: onSubmit,
                  enabled: state.canSubmit,
                  height: 40,
                  fontSize: 13.5,
                  expand: false,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Text(label, style: AppText.sans(12.5, weight: FontWeight.w600, color: c.ink2)),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.analysis, required this.selected});
  final Analysis analysis;
  final bool selected;

  String _when(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}.${d.month}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final p = analysis.pressure;
    final color = p > 60
        ? Palette.nope
        : p > 30
            ? Palette.warn
            : Palette.holds;
    final snippet = analysis.text.isNotEmpty ? analysis.text : 'Screenshot';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(analysis.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          GetIt.instance<SoundService>().playAnalysisDelete();
          context.read<AnalyzerBloc>().add(AnalyzerHistoryDeleted(analysis.id));
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Text('Delete', style: AppText.sans(13, weight: FontWeight.w700, color: Palette.nope)),
        ),
        child: Pressable(
          scale: .98,
          onTap: () => context.read<AnalyzerBloc>().add(AnalyzerHistoryOpened(analysis)),
          child: Glass(
            radius: 20,
            color: selected ? c.glass2 : null,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text('$p', style: AppText.serif(30, color: color, height: 1)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(13.5, weight: FontWeight.w600, color: c.ink),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${analysis.label} · ${_when(analysis.createdAt)}',
                        style: AppText.sans(11.5, color: c.ink3),
                      ),
                    ],
                  ),
                ),
                Text('›', style: AppText.sans(18, color: c.ink3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
