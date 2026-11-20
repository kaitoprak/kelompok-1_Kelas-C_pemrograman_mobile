import 'package:flutter_test/flutter_test.dart';
import 'package:my_shelf/domain/social_models.dart';

void main() {
  group('SocialProfile username validation', () {
    test('accepts a lowercase handle with numbers and underscores', () {
      expect(SocialProfile.validateUsername('reader_2026'), isNull);
    });

    test('rejects short, long, or non-handle values', () {
      expect(SocialProfile.validateUsername('ab'), isNotNull);
      expect(SocialProfile.validateUsername('a' * 21), isNotNull);
      expect(SocialProfile.validateUsername('Reader Name'), isNotNull);
      expect(SocialProfile.validateUsername('_reader'), isNotNull);
    });
  });
}
