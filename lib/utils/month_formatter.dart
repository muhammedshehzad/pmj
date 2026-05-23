class MonthFormatter {
  static const List<String> _monthNames = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  static String formatMonthList(List<String> months, String year, {bool includeYear = true}) {
    if (months.isEmpty) return "N/A";
    if (months.length == 1) return includeYear ? "${months.first} $year" : months.first;

    // Sort months based on chronological order
    final sortedMonths = List<String>.from(months)..sort((a, b) {
      return _monthNames.indexOf(a).compareTo(_monthNames.indexOf(b));
    });

    // Check if contiguous
    bool isContiguous = true;
    for (int i = 0; i < sortedMonths.length - 1; i++) {
      int currentIdx = _monthNames.indexOf(sortedMonths[i]);
      int nextIdx = _monthNames.indexOf(sortedMonths[i + 1]);
      if (nextIdx != currentIdx + 1) {
        isContiguous = false;
        break;
      }
    }

    if (isContiguous) {
      String range = "${sortedMonths.first.substring(0, 3)} - ${sortedMonths.last.substring(0, 3)}";
      return includeYear ? "$range $year" : range;
    } else {
      String list = sortedMonths.map((m) => m.substring(0, 3)).join(', ');
      return includeYear ? "$list $year" : list;
    }
  }

  static String formatMonthLong(List<String> months, String year, {bool includeYear = true}) {
    if (months.isEmpty) return "N/A";
    if (months.length == 1) return includeYear ? "${months.first} $year" : months.first;

    // Sort months based on chronological order
    final sortedMonths = List<String>.from(months)..sort((a, b) {
      return _monthNames.indexOf(a).compareTo(_monthNames.indexOf(b));
    });

    // Check if contiguous
    bool isContiguous = true;
    for (int i = 0; i < sortedMonths.length - 1; i++) {
      int currentIdx = _monthNames.indexOf(sortedMonths[i]);
      int nextIdx = _monthNames.indexOf(sortedMonths[i + 1]);
      if (nextIdx != currentIdx + 1) {
        isContiguous = false;
        break;
      }
    }

    if (isContiguous) {
      String range = "${sortedMonths.first} - ${sortedMonths.last}";
      return includeYear ? "$range $year" : range;
    } else {
      String list = sortedMonths.join(', ');
      return includeYear ? "$list $year" : list;
    }
  }
}
