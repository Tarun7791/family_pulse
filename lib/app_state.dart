import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'services/usage_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  FamilyMember? _currentUser;
  Family? _currentFamily;
  bool _isUsagePermissionGranted = false;
  int _dailyGoalMinutes = 120;
  Map<DateTime, bool> _streakHistory = {};
  String? _authError;
  
  StreamSubscription<DocumentSnapshot>? _familySubscription;
  StreamSubscription<QuerySnapshot>? _membersSubscription;
  StreamSubscription<User?>? _authSubscription;

  AppState() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    _checkPermission();
  }

  User? get firebaseUser => _firebaseUser;
  FamilyMember? get currentUser => _currentUser;
  Family? get currentFamily => _currentFamily;
  bool get isUsagePermissionGranted => _isUsagePermissionGranted;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  Map<DateTime, bool> get streakHistory => _streakHistory;
  String? get authError => _authError;

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    _authError = null;
    if (user != null) {
      try {
        // Fetch user data from Firestore
        // We use a timeout to avoid infinite buffering if offline
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 15));
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final roleString = data['role'] ?? 'UserRole.parent';
          
          _currentUser = FamilyMember(
            id: user.uid,
            name: data['name'] ?? 'User',
            role: UserRole.values.firstWhere(
              (e) => e.toString() == roleString,
              orElse: () => UserRole.parent,
            ),
            screenTimeMinutes: (data['todayUsage'] as num?)?.toInt() ?? 0,
          );
          
          _authError = null;
          final familyId = data.containsKey('familyId') ? data['familyId'] : null;
          if (familyId != null) {
            _listenToFamily(familyId);
          }
          
          // Trigger initial usage refresh as soon as we know who the user is
          refreshRealUsageData();
        } else {
          _authError = "Profile data not found in cloud.";
        }
      } catch (e) {
        _authError = "Connection Error: ${e.toString()}";
        debugPrint("Error loading user profile: $e");
      }
    } else {
      _currentUser = null;
      _currentFamily = null;
      _familySubscription?.cancel();
      _membersSubscription?.cancel();
    }
    notifyListeners();
  }

  void _listenToFamily(String familyId) {
    _familySubscription?.cancel();
    _familySubscription = _firestore.collection('families').doc(familyId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final name = data['name'] ?? 'Family';
        final joinCode = data['joinCode'] ?? '000000';
        _dailyGoalMinutes = (data['dailyGoal'] as num?)?.toInt() ?? 120;
        
        if (_currentFamily == null || _currentFamily!.id != familyId) {
          _currentFamily = Family(id: familyId, name: name, joinCode: joinCode, members: []);
        } else {
          _currentFamily = Family(id: familyId, name: name, joinCode: joinCode, members: _currentFamily!.members);
        }
        _loadStreak(familyId);
      }
      notifyListeners();
    });

    _membersSubscription?.cancel();
    _membersSubscription = _firestore
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .listen((snapshot) {
      final members = snapshot.docs.map((doc) {
        final data = doc.data();
        return FamilyMember(
          id: doc.id,
          name: data['name'] ?? 'User',
          role: UserRole.values.firstWhere(
            (e) => e.toString() == (data['role'] ?? 'UserRole.parent'),
            orElse: () => UserRole.parent,
          ),
          screenTimeMinutes: (data['todayUsage'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      if (_currentFamily != null) {
        _currentFamily = Family(
          id: _currentFamily!.id,
          name: _currentFamily!.name,
          joinCode: _currentFamily!.joinCode,
          members: members,
        );
      }
      notifyListeners();
    });
  }

  Future<void> _loadStreak(String familyId) async {
    final snapshot = await _firestore.collection('families').doc(familyId).collection('history').get();
    Map<DateTime, bool> history = {};
    for (var doc in snapshot.docs) {
      final date = (doc['date'] as Timestamp).toDate();
      history[DateTime(date.year, date.month, date.day)] = doc['success'];
    }
    _streakHistory = history;
    notifyListeners();
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'role': role.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Invalid email or password.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> createFamily(String name) async {
    if (_firebaseUser == null) return;
    
    final joinCode = (100000 + (DateTime.now().millisecond * 899999) ~/ 1000).toString();
    final familyDoc = await _firestore.collection('families').add({
      'name': name,
      'joinCode': joinCode,
      'hostId': _firebaseUser!.uid,
      'dailyGoal': 120,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'familyId': familyDoc.id,
    });
    
    _listenToFamily(familyDoc.id);
  }

  Future<bool> joinFamily(String code) async {
    if (_firebaseUser == null) return false;
    
    final query = await _firestore.collection('families').where('joinCode', isEqualTo: code).limit(1).get();
    if (query.docs.isEmpty) return false;
    
    final familyId = query.docs.first.id;
    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'familyId': familyId,
    });
    
    _listenToFamily(familyId);
    return true;
  }

  Future<void> setDailyGoal(int minutes) async {
    if (_currentFamily == null) return;
    await _firestore.collection('families').doc(_currentFamily!.id).update({
      'dailyGoal': minutes,
    });
  }

  Future<void> refreshRealUsageData() async {
    if (_firebaseUser == null) return;
    
    final minutes = await UsageService.getTodayScreenTime();
    debugPrint("FETCHED SCREEN TIME: $minutes min");
    
    await _firestore.collection('users').doc(_firebaseUser!.uid).update({
      'todayUsage': minutes,
      'lastActive': FieldValue.serverTimestamp(),
    });
    
    if (_currentFamily != null) {
      _updateStreakHistoryLocally(minutes);
    }
  }

  void _updateStreakHistoryLocally(int myMinutes) async {
    // This would ideally be a cloud function to be 100% accurate, 
    // but for now we'll do best-effort update when the parent/child refreshes.
    if (_currentFamily == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check all members
    bool allSuccess = true;
    for (var member in _currentFamily!.members) {
      if (member.id == _currentUser?.id) {
         if (myMinutes > _dailyGoalMinutes) {
           allSuccess = false;
           break;
         }
      } else if (member.screenTimeMinutes > _dailyGoalMinutes) {
        allSuccess = false;
        break;
      }
    }

    await _firestore.collection('families').doc(_currentFamily!.id).collection('history').doc(today.toIso8601String()).set({
      'date': today,
      'success': allSuccess,
    });
  }

  Future<void> _checkPermission() async {
    _isUsagePermissionGranted = await UsageService.isPermissionGranted();
    notifyListeners();
  }

  Future<void> requestUsagePermission() async {
    await UsageService.openSettings();
    _checkPermission();
  }

  void logout() {
    _auth.signOut();
    _familySubscription?.cancel();
    _membersSubscription?.cancel();
  }

  static String formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes min';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes min';
  }
}
