import 'package:equatable/equatable.dart';

/// An "arena" of everyday life where psychological forces act on us.
class PsychField extends Equatable {
  const PsychField({
    required this.id,
    required this.name,
    required this.short,
    required this.description,
  });

  final String id;

  /// Title earned when the field is mastered, e.g. "Money Mind".
  final String name;

  /// Short filter label, e.g. "Money".
  final String short;
  final String description;

  @override
  List<Object?> get props => [id];
}
