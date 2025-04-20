// In auth_controller.dart or a new security_service.dart
import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  // Generate a secure key (in production, this should be stored securely)
  final _key = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);

  String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.encrypt(data, iv: _iv).base64;
  }

  String decryptData(String encryptedData) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.decrypt64(encryptedData, iv: _iv);
  }
}
