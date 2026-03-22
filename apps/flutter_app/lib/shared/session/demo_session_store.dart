import 'package:shared_preferences/shared_preferences.dart';

class DemoSessionRecord {
  const DemoSessionRecord({required this.phoneNumber});

  final String phoneNumber;
}

abstract class DemoSessionStore {
  Future<DemoSessionRecord?> readSession();

  Future<void> writeSession(DemoSessionRecord session);

  Future<void> clearSession();
}

class SharedPreferencesDemoSessionStore implements DemoSessionStore {
  static const String _phoneNumberKey = 'telegram_demo.phone_number';

  @override
  Future<DemoSessionRecord?> readSession() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? phoneNumber = preferences.getString(_phoneNumberKey);
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null;
    }
    return DemoSessionRecord(phoneNumber: phoneNumber);
  }

  @override
  Future<void> writeSession(DemoSessionRecord session) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_phoneNumberKey, session.phoneNumber);
  }

  @override
  Future<void> clearSession() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_phoneNumberKey);
  }
}
