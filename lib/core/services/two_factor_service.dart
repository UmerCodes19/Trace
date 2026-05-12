import 'dart:math';
import 'package:base32/base32.dart';
import 'package:otp/otp.dart';

class TwoFactorService {
  /// Generate a deterministic random 160-bit secret key for TOTP, base32 encoded.
  static String generateSecret() {
    final rand = Random.secure();
    final List<int> bytes = List<int>.generate(20, (i) => rand.nextInt(256));
    // Standard Authenticator apps expect uppercase Base32 without padding
    return base32.encodeHexString(bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()).toUpperCase().replaceAll('=', '');
  }

  /// Constructs the universal protocol standard otpauth URI scanned by Google/Apple Authenticator
  static String generateQrUri({
    required String email,
    required String secret,
    String issuer = 'Trace',
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedEmail = Uri.encodeComponent(email);
    // Structure: otpauth://totp/Issuer:Label?secret=SECRET&issuer=Issuer
    return 'otpauth://totp/$encodedIssuer:$encodedEmail?secret=$secret&issuer=$encodedIssuer';
  }

  /// Validates that a given 6-digit input code matches the generated TOTP for the secret AT THIS MOMENT.
  static bool verifyCode(String secret, String inputCode) {
    try {
      // Base32 package expects valid padding if strict, but otp handles raw secret sometimes.
      // Let's ensure code is exactly 6 characters.
      if (inputCode.trim().length != 6) return false;

      final int now = DateTime.now().millisecondsSinceEpoch;
      
      // Verify against current time window, but allow tolerance of previous window to account for clock drift (typical 2FA standard)
      final String currentCode = OTP.generateTOTPCodeString(
        secret, 
        now, 
        algorithm: Algorithm.SHA1, 
        isGoogle: true
      );
      
      final String prevCode = OTP.generateTOTPCodeString(
        secret, 
        now - 30000, 
        algorithm: Algorithm.SHA1, 
        isGoogle: true
      );

      return inputCode.trim() == currentCode || inputCode.trim() == prevCode;
    } catch (e) {
      return false;
    }
  }
}
