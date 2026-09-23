import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../game/domain/entities/psych_field.dart';
import '../../../onboarding/presentation/widgets/arena_tile.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

Future<void> showArenasSheet(BuildContext context, List<PsychField> fields) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<SettingsBloc>(),
      child: _ArenasSheet(fields: fields),
    ),
  );
}

class _ArenasSheet extends StatefulWidget {
  const _ArenasSheet({required this.fields});
  final List<PsychField> fields;

  @override
  State<_ArenasSheet> createState() => _ArenasSheetState();
}

class _ArenasSheetState extends State<_ArenasSheet> {
  late final List<String> _picked = List.of(context.read<SettingsBloc>().state.settings.pickedFields);

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your arenas', style: AppText.serif(32, color: c.ink)),
            const SizedBox(height: 6),
            Text('Cases from these arenas come first. Changes apply from the next drop.', style: AppText.sans(13.5, color: c.ink2, height: 1.45)),
            const SizedBox(height: 16),
            for (final f in widget.fields) ...[
              ArenaTile(
                field: f,
                selected: _picked.contains(f.id),
                onTap: () => setState(() => _picked.contains(f.id) ? _picked.remove(f.id) : _picked.add(f.id)),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            SolidButton(
              label: 'Save',
              enabled: _picked.isNotEmpty,
              onTap: () {
                context.read<SettingsBloc>().add(ArenasChanged(_picked));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showApiKeySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(value: context.read<SettingsBloc>(), child: const _ApiKeySheet()),
  );
}

class _ApiKeySheet extends StatefulWidget {
  const _ApiKeySheet();

  @override
  State<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<_ApiKeySheet> {
  late final _ctrl = TextEditingController(text: context.read<SettingsBloc>().state.settings.apiKey);
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final hasKey = context.select((SettingsBloc b) => b.state.settings.hasApiKey);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Analyzer engine', style: AppText.serif(32, color: c.ink)),
              const SizedBox(height: 6),
              Text(
                'Without a key, Motive uses its private offline engine for text. Add a Claude API key '
                '(console.anthropic.com) for deeper analysis that also reads screenshots. '
                'The key is stored only on this device.',
                style: AppText.sans(13.5, color: c.ink2, height: 1.45),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: c.glass,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.line),
                ),
                child: TextField(
                  controller: _ctrl,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: AppText.mono(13, color: c.ink, letterSpacing: 0),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintText: 'sk-ant-…',
                    hintStyle: AppText.mono(13, color: c.ink3, letterSpacing: 0),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: c.ink3, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (hasKey) ...[
                    Expanded(
                      child: GhostButton(
                        label: 'Remove key',
                        height: 52,
                        expand: true,
                        color: Palette.nope,
                        onTap: () {
                          context.read<SettingsBloc>().add(const ApiKeyChanged(''));
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SolidButton(
                      label: 'Save',
                      height: 52,
                      fontSize: 15,
                      onTap: () {
                        context.read<SettingsBloc>().add(ApiKeyChanged(_ctrl.text));
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showNameDialog(BuildContext context, String current) async {
  final ctrl = TextEditingController(text: current);
  final c = context.mc;
  final bloc = context.read<SettingsBloc>();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Your name', style: AppText.serif(28, color: c.ink)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 30,
        style: AppText.sans(16, color: c.ink),
        decoration: InputDecoration(hintText: 'What should we call you?', hintStyle: AppText.sans(16, color: c.ink3)),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: AppText.sans(14, color: c.ink2))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text('Save', style: AppText.sans(14, weight: FontWeight.w700, color: c.ink)),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (name != null) bloc.add(UserNameChanged(name));
}

Future<bool> confirmReset(BuildContext context) async {
  final c = context.mc;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Reset progress?', style: AppText.serif(28, color: c.ink)),
      content: Text(
        'All collected cards, XP, streak and today\'s answers will be erased. This cannot be undone.',
        style: AppText.sans(14, color: c.ink2, height: 1.45),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppText.sans(14, color: c.ink2))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Reset', style: AppText.sans(14, weight: FontWeight.w700, color: Palette.nope)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
