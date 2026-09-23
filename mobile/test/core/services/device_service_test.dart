import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:btc_blake2b_wallet/core/services/device_service.dart';
import 'package:uuid/uuid.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockUuid extends Mock implements Uuid {}

void main() {
  group('DeviceService', () {
    late MockFlutterSecureStorage mockFlutterSecureStorage;
    late MockUuid mockUuid;
    late DeviceService sut;

    setUp(() {
      mockFlutterSecureStorage = MockFlutterSecureStorage();
      mockUuid = MockUuid();
      sut = DeviceService(
        secureStorage: mockFlutterSecureStorage,
        uuid: mockUuid,
      );
    });

    test('should instantiate', () {
      expect(sut, isNotNull);
    });

    // TODO: Implementa test per i metodi pubblici
  });
}
