import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('both skins are Material 3 with distinct primaries', () {
    final mobile = AppThemes.playfulMobile;
    final web = AppThemes.professionalWeb;
    expect(mobile.useMaterial3, isTrue);
    expect(web.useMaterial3, isTrue);
    expect(mobile.colorScheme.primary, isNot(web.colorScheme.primary));
    expect(mobile.visualDensity, isNot(web.visualDensity));
  });
}
