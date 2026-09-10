import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  DeviceService({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  static const String _deviceIdKey = 'device_id_v1';

  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _uuid.v4();
    await _secureStorage.write(key: _deviceIdKey, value: created);
    return created;
  }
}
