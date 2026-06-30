import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box _clientsBox;
  late Box _jobsBox;
  late Box _paymentsBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _clientsBox = await Hive.openBox('clients');
    _jobsBox = await Hive.openBox('jobs');
    _paymentsBox = await Hive.openBox('payments');
    _settingsBox = await Hive.openBox('settings');
  }

  // --- Settings ---
  String getLanguage() => _settingsBox.get('language', defaultValue: 'ar');
  Future<void> setLanguage(String code) => _settingsBox.put('language', code);

  String getThemeMode() => _settingsBox.get('themeMode', defaultValue: 'light');
  Future<void> setThemeMode(String mode) => _settingsBox.put('themeMode', mode);

  // --- Clients Caching ---
  List<Map<String, dynamic>> getClients() {
    return _clientsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> saveClients(List<Map<String, dynamic>> clients) async {
    await _clientsBox.clear();
    for (var client in clients) {
      if (client['id'] != null) {
        await _clientsBox.put(client['id'], client);
      }
    }
  }

  Future<void> saveClient(Map<String, dynamic> client) async {
    if (client['id'] != null) {
      await _clientsBox.put(client['id'], client);
    }
  }

  Future<void> deleteClient(String id) async {
    await _clientsBox.delete(id);
  }

  // --- Jobs Caching ---
  List<Map<String, dynamic>> getJobs(String clientId) {
    return _jobsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((job) => job['clientId'] == clientId)
        .toList();
  }

  Future<void> saveJobs(List<Map<String, dynamic>> jobs) async {
    for (var job in jobs) {
      if (job['id'] != null) {
        await _jobsBox.put(job['id'], job);
      }
    }
  }

  Future<void> saveJob(Map<String, dynamic> job) async {
    if (job['id'] != null) {
      await _jobsBox.put(job['id'], job);
    }
  }

  // --- Payments Caching ---
  List<Map<String, dynamic>> getPayments(String clientId) {
    return _paymentsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((pay) => pay['clientId'] == clientId)
        .toList();
  }

  Future<void> savePayments(List<Map<String, dynamic>> payments) async {
    for (var pay in payments) {
      if (pay['id'] != null) {
        await _paymentsBox.put(pay['id'], pay);
      }
    }
  }

  Future<void> savePayment(Map<String, dynamic> payment) async {
    if (payment['id'] != null) {
      await _paymentsBox.put(payment['id'], payment);
    }
  }

  Future<void> clearAll() async {
    await _clientsBox.clear();
    await _jobsBox.clear();
    await _paymentsBox.clear();
  }

  // --- Saved Credentials ---
  String? getSavedEmail() => _settingsBox.get('saved_email');
  String? getSavedPassword() => _settingsBox.get('saved_password');

  Future<void> saveCredentials(String email, String password) async {
    await _settingsBox.put('saved_email', email);
    await _settingsBox.put('saved_password', password);
  }

  Future<void> clearCredentials() async {
    await _settingsBox.delete('saved_email');
    await _settingsBox.delete('saved_password');
  }
}
