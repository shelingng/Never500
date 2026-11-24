// SCRUM-38: student category values, labels and rate eligibility.
import 'package:flutter_test/flutter_test.dart';
import 'package:krp_play/models/facility.dart';
import 'package:krp_play/models/student_category.dart';

void main() {
  group('stored values map to labels and rates', () {
    test('krp and non_krp are the stored values', () {
      expect(StudentCategory.krp.value, 'krp');
      expect(StudentCategory.nonKrp.value, 'non_krp');
      expect(StudentCategory.krp.label, 'KRP Student');
      expect(StudentCategory.nonKrp.label, 'Non-KRP Student');
      expect(StudentCategory.krp.priceColumn, 'krp_price');
      expect(StudentCategory.nonKrp.priceColumn, 'non_krp_price');
    });

    test('stored values and old labels are all understood', () {
      for (final raw in ['krp', 'KRP', ' KRP Student ', 'krp_student']) {
        expect(StudentCategory.parse(raw), StudentCategory.krp, reason: raw);
      }
      for (final raw in ['non_krp', 'Non-KRP Student', 'non krp', 'NON-KRP']) {
        expect(StudentCategory.parse(raw), StudentCategory.nonKrp, reason: raw);
      }
    });

    test('missing or unknown values are "not set", never KRP', () {
      for (final raw in [null, '', '   ', 'Student', 'Public', 'krpp']) {
        expect(StudentCategory.parse(raw), isNull, reason: '$raw');
        expect(StudentCategory.labelFor(raw), 'Category not set');
      }
    });
  });

  group('KRP is charged correctly and the discount is protected', () {
    const badminton = Facility(
      name: 'Badminton Court 1',
      type: 'Badminton',
      krpPrice: 6,
      nonKrpPrice: 8,
      unit: 'hour',
    );

    test('KRP pays the KRP rate, whether stored value or old label', () {
      expect(badminton.priceFor('krp'), 6);
      expect(badminton.priceFor('KRP Student'), 6);
    });

    test('non-KRP and unknown categories pay the non-KRP rate', () {
      expect(badminton.priceFor('non_krp'), 8);
      expect(badminton.priceFor(''), 8);
      expect(badminton.priceFor('Student'), 8);
    });
  });

  test('the sign-up list is exactly the two stored values', () {
    // login_screen.dart builds its DropdownButtonFormField<StudentCategory>
    // from StudentCategory.values, so no other value can be selected.
    expect(StudentCategory.values.map((c) => c.value), ['krp', 'non_krp']);
  });
}
