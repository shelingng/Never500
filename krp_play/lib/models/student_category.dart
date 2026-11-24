// SCRUM-38: the one place that knows the student category values.
//
// Stored (canonical) values in profiles.student_category and
// bookings.customer_category are only `krp` and `non_krp`. The UI shows
// "KRP Student" / "Non-KRP Student". Anything else (null, empty, old labels
// such as "KRP Student", typos) is parsed here, and an unknown category never
// gets the KRP discount.

enum StudentCategory {
  krp('krp', 'KRP Student', 'krp_price'),
  nonKrp('non_krp', 'Non-KRP Student', 'non_krp_price');

  /// Value stored in the database.
  final String value;

  /// Text shown to users.
  final String label;

  /// Column in `facilities` that holds this category's hourly rate.
  final String priceColumn;

  const StudentCategory(this.value, this.label, this.priceColumn);

  /// Reads a stored value or an old UI label. Returns null when the category
  /// is missing or not recognised.
  static StudentCategory? parse(Object? raw) {
    final text = (raw?.toString() ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      ' ',
    );
    return switch (text) {
      'krp' || 'krp student' => StudentCategory.krp,
      'non krp' || 'non krp student' || 'nonkrp' => StudentCategory.nonKrp,
      _ => null,
    };
  }

  /// Label for any raw value, including missing ones.
  static String labelFor(Object? raw) => parse(raw)?.label ?? notSetLabel;

  static const String notSetLabel = 'Category not set';

  /// Shown when a profile has no valid category.
  static const String notSetHelp =
      'Your student category is not set. Please contact the KRP office before booking.';
}
