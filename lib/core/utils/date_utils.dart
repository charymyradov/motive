/// Date helpers. A "day key" is a stable `yyyy-MM-dd` string in local time.
abstract final class DayKey {
  static String of(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String today([DateTime? now]) => of(now ?? DateTime.now());

  static DateTime parse(String key) {
    final p = key.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  /// Monday of the week that contains [d].
  static DateTime startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}

extension ThousandsFormat on int {
  /// 1240 -> "1,240"
  String get grouped {
    final s = abs().toString();
    final b = StringBuffer(this < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
