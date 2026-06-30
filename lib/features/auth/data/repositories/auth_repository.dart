import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Key for local user caching
  static const String _userCacheKey = 'cached_user_profile';

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userCacheKey);
    if (userJson != null) {
      try {
        final Map<String, dynamic> userMap = json.decode(userJson);
        return UserModel.fromMap(userMap, userMap['uid']);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userMap = user.toMap();
    userMap['uid'] = user.uid;
    await prefs.setString(_userCacheKey, json.encode(userMap));
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
  }

  Future<UserModel?> getCurrentUser() async {
    final User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      await _clearCache();
      return null;
    }

    // Try cache first for instant load
    final cached = await getCachedUser();
    if (cached != null && cached.uid == firebaseUser.uid) {
      // Async refresh in the background
      _refreshUserFromServer(firebaseUser.uid);
      return cached;
    }

    // Fallback to server if no cache
    return await _fetchUserFromServer(firebaseUser.uid, firebaseUser.email ?? '');
  }

  Future<UserModel?> _fetchUserFromServer(String uid, String email) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!, uid);
        await _cacheUser(user);
        return user;
      } else {
        // Create user document if it doesn't exist (e.g. first admin)
        final usersCount = await _firestore.collection('users').limit(1).get();
        final isFirst = usersCount.docs.isEmpty;
        final newUser = UserModel(
          uid: uid,
          email: email,
          name: email.split('@')[0],
          role: isFirst ? 'admin' : 'employee',
          isActive: true,
        );
        await _firestore.collection('users').doc(uid).set(newUser.toMap());
        await _cacheUser(newUser);
        return newUser;
      }
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> _refreshUserFromServer(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!, uid);
        await _cacheUser(user);
      }
    } catch (_) {}
  }

  Future<UserModel?> login(String email, String password) async {
    final UserCredential cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      return await _fetchUserFromServer(cred.user!.uid, email);
    }
    return null;
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _clearCache();
  }

  // Admin User Management Operations
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> addEmployeeUser(String email, String password, String name) async {
    // Create new credentials in Firebase Auth without logging out the current admin
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempRegisterApp',
      options: Firebase.app().options,
    );

    try {
      UserCredential creds = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      
      if (creds.user != null) {
        final newUser = UserModel(
          uid: creds.user!.uid,
          email: email,
          name: name,
          role: 'employee',
          isActive: true,
        );
        // Write user details to the main Firestore using main Firebase credentials
        await _firestore.collection('users').doc(creds.user!.uid).set(newUser.toMap());
      }
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
