import 'package:flutter_test/flutter_test.dart';
import 'package:astrotech_mobile/core/utils/logger.dart';

void main() {
  group('Logger Tests', () {
    test('debug should not throw exception', () {
      expect(() => Logger.debug('Test debug message'), returnsNormally);
    });

    test('debug with tag should not throw exception', () {
      expect(
        () => Logger.debug('Test debug message', 'TEST_TAG'),
        returnsNormally,
      );
    });

    test('info should not throw exception', () {
      expect(() => Logger.info('Test info message'), returnsNormally);
    });

    test('info with tag should not throw exception', () {
      expect(
        () => Logger.info('Test info message', 'TEST_TAG'),
        returnsNormally,
      );
    });

    test('warning should not throw exception', () {
      expect(() => Logger.warning('Test warning message'), returnsNormally);
    });

    test('warning with tag should not throw exception', () {
      expect(
        () => Logger.warning('Test warning message', 'TEST_TAG'),
        returnsNormally,
      );
    });

    test('error should not throw exception', () {
      expect(() => Logger.error('Test error message'), returnsNormally);
    });

    test('error with exception should not throw exception', () {
      expect(
        () => Logger.error(
          'Test error message',
          Exception('Test exception'),
          StackTrace.current,
          'TEST_TAG',
        ),
        returnsNormally,
      );
    });

    test('api should not throw exception', () {
      expect(() => Logger.api('Test API message'), returnsNormally);
    });

    test('workflow should not throw exception', () {
      expect(() => Logger.workflow('Test workflow message'), returnsNormally);
    });

    test('photo should not throw exception', () {
      expect(() => Logger.photo('Test photo message'), returnsNormally);
    });

    test('sync should not throw exception', () {
      expect(() => Logger.sync('Test sync message'), returnsNormally);
    });
  });
}
