import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de cifrado local para proteger datos clínicos sensibles en SQLite
/// Utiliza una clave maestra de 256 bits almacenada en el almacenamiento seguro
/// del sistema operativo (Keystore en Android / Keychain en iOS).
class EncryptionService {
  static final EncryptionService instance = EncryptionService._();
  EncryptionService._();

  static const _storageKey = 'priorix_sqlite_master_key_v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<int>? _masterKey;

  Future<void> init() async {
    String? storedKeyBase64 = await _secureStorage.read(key: _storageKey);
    if (storedKeyBase64 == null || storedKeyBase64.isEmpty) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      storedKeyBase64 = base64Encode(keyBytes);
      await _secureStorage.write(key: _storageKey, value: storedKeyBase64);
      _masterKey = keyBytes;
    } else {
      _masterKey = base64Decode(storedKeyBase64);
    }
  }

  /// Cifra una cadena de texto (ej. síntomas, signos vitales, notas clínicas)
  /// Retorna un string en Base64 con el IV, el ciphertext y el HMAC de autenticación.
  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) return plainText;
    if (_masterKey == null) await init();

    final random = Random.secure();
    final iv = List<int>.generate(16, (_) => random.nextInt(256));
    final plainBytes = utf8.encode(plainText);

    // Derivación de keystream usando HMAC-SHA256 en modo CTR
    final keyStream = _generateKeystream(_masterKey!, iv, plainBytes.length);
    final cipherBytes = List<int>.generate(plainBytes.length, (i) => plainBytes[i] ^ keyStream[i]);

    // HMAC para verificar integridad y autenticidad (Encrypt-then-MAC)
    final hmac = Hmac(sha256, _masterKey!);
    final mac = hmac.convert([...iv, ...cipherBytes]).bytes;

    final result = <int>[...iv, ...mac, ...cipherBytes];
    return 'ENC:${base64Encode(result)}';
  }

  /// Descifra una cadena previamente cifrada con [encrypt]. Si no está cifrada, la retorna tal cual.
  Future<String> decrypt(String cipherText) async {
    if (!cipherText.startsWith('ENC:')) {
      return cipherText; // Retorno de compatibilidad si el dato no estaba cifrado
    }
    if (_masterKey == null) await init();

    try {
      final raw = base64Decode(cipherText.substring(4));
      if (raw.length < 16 + 32) return cipherText;

      final iv = raw.sublist(0, 16);
      final receivedMac = raw.sublist(16, 48);
      final cipherBytes = raw.sublist(48);

      final hmac = Hmac(sha256, _masterKey!);
      final computedMac = hmac.convert([...iv, ...cipherBytes]).bytes;

      // Verificación de integridad en tiempo constante
      var macMatches = true;
      for (var i = 0; i < 32; i++) {
        if (receivedMac[i] != computedMac[i]) {
          macMatches = false;
        }
      }
      if (!macMatches) {
        throw Exception('Fallo de autenticación: los datos clínicos fueron alterados.');
      }

      final keyStream = _generateKeystream(_masterKey!, iv, cipherBytes.length);
      final plainBytes = List<int>.generate(cipherBytes.length, (i) => cipherBytes[i] ^ keyStream[i]);

      return utf8.decode(plainBytes);
    } catch (_) {
      return cipherText;
    }
  }

  List<int> _generateKeystream(List<int> key, List<int> iv, int length) {
    final stream = <int>[];
    var counter = 0;
    while (stream.length < length) {
      final counterBytes = Uint8List(4)..buffer.asByteData().setUint32(0, counter, Endian.big);
      final block = sha256.convert([...key, ...iv, ...counterBytes]).bytes;
      stream.addAll(block);
      counter++;
    }
    return stream.sublist(0, length);
  }
}
