import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/haptics.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/motive_colors.dart';
import '../../../../core/widgets/buttons.dart';
import '../bloc/game_bloc.dart';
import 'collectible_card.dart';

/// Inspect a collected card: drag on it to tilt it and catch the foil.
class CardDetailOverlay extends StatefulWidget {
  const CardDetailOverlay({super.key, required this.cardId, required this.onClose});

  final String cardId;
  final VoidCallback onClose;

  @override
  State<CardDetailOverlay> createState() => _CardDetailOverlayState();
}

class _CardDetailOverlayState extends State<CardDetailOverlay> with SingleTickerProviderStateMixin {
  /// Pointer position over the card in 0..1, (0.5, 0.5) = resting.
  late final _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  Offset _p = const Offset(.5, .5);
  Offset _from = const Offset(.5, .5);
  bool _active = false;

  /// Captures the card as pixels for the share sheet.
  final _capture = GlobalKey();
  late final TextEditingController _note;
  late final GameBloc _bloc;
  bool _noteDirty = false;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<GameBloc>();
    _note = TextEditingController(text: _bloc.state.notes[widget.cardId]);
    _settle.addListener(() {
      final t = const Cubic(.2, 1, .3, 1).transform(_settle.value);
      setState(() => _p = Offset.lerp(_from, const Offset(.5, .5), t)!);
    });
  }

  @override
  void dispose() {
    if (_noteDirty) _flushNote();
    _note.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    _settle.stop();
    setState(() {
      _active = true;
      _p = Offset((local.dx / size.width).clamp(0, 1), (local.dy / size.height).clamp(0, 1));
    });
  }

  void _release() {
    _from = _p;
    setState(() => _active = false);
    _settle.forward(from: 0);
  }

  void _flushNote() {
    _noteDirty = false;
    _bloc.add(CardNoteSaved(cardId: widget.cardId, text: _note.text));
  }

  Future<void> _shareCard() async {
    final c = context.mc;
    final boundary = _capture.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final card = context.read<GameBloc>().state.catalog!.card(widget.cardId);
    final field = context.read<GameBloc>().state.catalog!.field(card.fieldId);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      image.dispose();
      if (bytes == null || !mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: '${card.id}.png')],
          text: '${card.force} · ${field.name}\nLearned with Motive.',
        ),
      );
      Haptics.celebrate();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share this card.', style: AppText.sans(14, color: c.ink))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.select((GameBloc b) => b.state.catalog)!;
    final card = catalog.card(widget.cardId);
    final field = catalog.field(card.fieldId);
    final screen = MediaQuery.sizeOf(context);
    final w = math.min(260.0, screen.height * .34);
    final size = Size(w, w * 1.4);

    final rx = (0.5 - _p.dy) * 20 * math.pi / 180;
    final ry = (_p.dx - 0.5) * 24 * math.pi / 180;
    final lit = _active || _settle.isAnimating;
    final scale = lit ? 1.03 : 1.0;

    final sheen = Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: lit ? 1 : 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(_p.dx * 2 - 1, _p.dy * 2 - 1),
                    radius: .9,
                    colors: const [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.6 + _p.dx * 1.2, -1.6 + _p.dy * 1.2),
                    end: Alignment(1.6 + _p.dx * 1.2, 1.6 + _p.dy * 1.2),
                    colors: const [
                      Color(0x00FFFFFF),
                      Color(0x38FFFFFF),
                      Color(0x2EA0DCFF),
                      Color(0x29FFA0E6),
                      Color(0x00FFFFFF),
                    ],
                    stops: const [.3, .45, .5, .55, .7],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: const ColoredBox(color: Color(0xBD05040C)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    onPanDown: (d) => _track(d.localPosition, size),
                    onPanUpdate: (d) => _track(d.localPosition, size),
                    onPanEnd: (_) => _release(),
                    onPanCancel: _release,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 1 / 900)
                        ..rotateX(rx)
                        ..rotateY(ry)
                        ..scaleByDouble(scale, scale, 1, 1),
                      child: RepaintBoundary(
                        key: _capture,
                        child: CollectibleCard(card: card, field: field, width: w, overlay: sheen),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const MonoLabel('DRAG TO TILT', color: Color(0x8CF4F2FB), spacing: .18),
                  const SizedBox(height: 12),
                  Text(
                    card.why,
                    textAlign: TextAlign.center,
                    style: AppText.sans(14.5, color: const Color(0xD1F4F2FB), height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  _NoteField(
                    controller: _note,
                    hint: 'Add a note about this card…',
                    onChanged: () => _noteDirty = true,
                    onEditingComplete: _flushNote,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GhostButton(label: 'Share card', onTap: _shareCard, height: 44),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Tap anywhere to close', style: AppText.sans(13, color: const Color(0x80F4F2FB))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-line personal note; saved on submit or when the overlay closes.
class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onEditingComplete,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final VoidCallback onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        onEditingComplete: onEditingComplete,
        onChanged: (_) => onChanged(),
        onSubmitted: (_) => onEditingComplete(),
        style: AppText.sans(14, color: const Color(0xE6F4F2FB)),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: AppText.sans(14, color: const Color(0x66F4F2FB)),
          filled: true,
          fillColor: const Color(0x2EFFFFFF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x24FFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x24FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x80FFFFFF)),
          ),
        ),
      ),
    );
  }
}
