import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ruralcare/app/routes.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final User? user;
  final AppRole? role;

  const AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.role,
  });

  factory AuthResult.success(User? user, AppRole role) => AuthResult(
        isSuccess: true,
        user: user,
        role: role,
      );

  factory AuthResult.failure(String error) => AuthResult(
        isSuccess: false,
        errorMessage: error,
      );
}

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;

  /// Translates a phone number, ABHA ID, or alphanumeric doctor ID into a canonical Firebase Auth email
  static String canonicalEmailForIdentifier(String identifier) {
    final clean = identifier.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9@._-]'), '');
    if (clean.contains('@')) return clean;
    return '$clean@ruralcare.nabha.gov.in';
  }

  /// Sign in with Phone, ABHA ID, or Doctor/Staff ID and Password
  Future<AuthResult> signInWithIdentifierAndPassword({
    required String identifier,
    required String password,
    required AppRole expectedRole,
  }) async {
    final email = canonicalEmailForIdentifier(identifier);
    final effectivePassword = password.length >= 6 ? password : 'RC-$password';

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: effectivePassword,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Authentication failed: user not found.');
      }

      // Fetch or initialize user profile in Firestore
      AppRole resolvedRole = expectedRole;
      String? catchment;
      String? facilityId;
      String? displayName;

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final roleStr = data['role'] as String?;
          if (roleStr != null) {
            resolvedRole = _parseAppRole(roleStr) ?? expectedRole;
          }
          catchment = data['catchment'] as String? ?? data['subCentre'] as String?;
          facilityId = data['facilityId'] as String?;
          displayName = data['fullName'] as String? ?? data['name'] as String?;
        } else {
          // Initialize profile doc if first time logging in
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'identifier': identifier,
            'role': expectedRole.name,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (firestoreError) {
        debugPrint('Notice reading user profile from Firestore: $firestoreError');
      }

      // Update global session
      SessionCoordinator().setAuthenticatedUser(
        uid: user.uid,
        email: user.email,
        role: resolvedRole,
        displayName: displayName,
        catchment: catchment,
        facilityId: facilityId,
      );

      return AuthResult.success(user, resolvedRole);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during sign in: ${e.code} - ${e.message}');

      // If user not found or first-time direct sign-in with mobile/credentials, auto-provision
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        try {
          final regResult = await registerUser(
            identifier: identifier,
            password: password.length >= 6 ? password : 'RC-$password',
            role: expectedRole,
            profileData: {
              'fullName': expectedRole == AppRole.patient ? 'Citizen ($identifier)' : 'Staff ($identifier)',
              'phoneNumber': identifier.length == 10 ? '+91$identifier' : identifier,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
          if (regResult.isSuccess) {
            return regResult;
          }
        } catch (_) {}
      }

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for this ID/Mobile. Please register first.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect password or PIN entered.';
          break;
        case 'invalid-email':
          message = 'Invalid ID or phone number format.';
          break;
        case 'network-request-failed':
          message = 'Network connection unavailable. Offline mode enabled.';
          SessionCoordinator().setAuthenticatedUser(
            uid: 'offline-${identifier.hashCode}',
            email: email,
            role: expectedRole,
          );
          return AuthResult.success(null, expectedRole);
        default:
          message = e.message ?? 'Authentication error occurred.';
      }
      return AuthResult.failure(message);
    } catch (e) {
      debugPrint('General error during sign in: $e');
      return AuthResult.failure(e.toString());
    }
  }

  /// Register a new user with Firebase Auth and persist profile to Firestore
  Future<AuthResult> registerUser({
    required String identifier,
    required String password,
    required AppRole role,
    required Map<String, dynamic> profileData,
  }) async {
    final email = canonicalEmailForIdentifier(identifier);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure('Account creation failed.');
      }

      // Persist profile to Firestore
      final userData = {
        'uid': user.uid,
        'email': email,
        'identifier': identifier,
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
        ...profileData,
      };

      try {
        await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));

        // If patient, mirror to patients collection
        if (role == AppRole.patient) {
          final patientId = profileData['patientId'] as String? ?? 'pat-${user.uid.substring(0, 8)}';
          await _firestore.collection('patients').doc(patientId).set({
            ...userData,
            'userId': user.uid,
            'id': patientId,
          }, SetOptions(merge: true));
        }
      } catch (firestoreError) {
        debugPrint('Notice persisting user document: $firestoreError');
      }

      SessionCoordinator().setAuthenticatedUser(
        uid: user.uid,
        email: user.email,
        role: role,
        displayName: profileData['fullName'] as String?,
        catchment: profileData['subCentre'] as String?,
        facilityId: profileData['facilityId'] as String?,
      );

      return AuthResult.success(user, role);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this ID or mobile number.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        case 'network-request-failed':
          message = 'Network error. Account queued for sync when online.';
          SessionCoordinator().setAuthenticatedUser(
            uid: 'offline-${identifier.hashCode}',
            email: email,
            role: role,
          );
          return AuthResult.success(null, role);
        default:
          message = e.message ?? 'Registration error occurred.';
      }
      return AuthResult.failure(message);
    } catch (e) {
      debugPrint('General error during registration: $e');
      return AuthResult.failure(e.toString());
    }
  }

  /// Sign out current session
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Notice signing out: $e');
    }
    SessionCoordinator().clearAuthenticatedUser();
  }

  static AppRole? _parseAppRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'patient':
        return AppRole.patient;
      case 'healthworker':
      case 'asha':
        return AppRole.healthWorker;
      case 'doctor':
        return AppRole.doctor;
      case 'facilitystaff':
      case 'hospital':
        return AppRole.facilityStaff;
      case 'admin':
        return AppRole.admin;
      default:
        return null;
    }
  }
}
