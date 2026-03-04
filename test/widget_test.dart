import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grade value converts correctly for the five-point scale', () {
    String toDisplayGrade(double percent) {
      if (percent >= 90) return '5';
      if (percent >= 75) return '4';
      if (percent >= 60) return '3';
      return '2';
    }

    expect(toDisplayGrade(95), '5');
    expect(toDisplayGrade(80), '4');
    expect(toDisplayGrade(65), '3');
    expect(toDisplayGrade(50), '2');
  });
}
