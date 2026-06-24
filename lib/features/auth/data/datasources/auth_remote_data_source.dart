import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String role,
  });
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credentials = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credentials.user;
      if (user == null) {
        throw const AuthException('User is null after signing in.');
      }

      // Fetch user profile from Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        data['id'] = user.uid;
        return UserModel.fromJson(data);
      } else {
        // If Firestore document doesn't exist, build from Firebase Auth credentials (useful for testing/fallback)
        final fallbackUser = UserModel(
          id: user.uid,
          fullName: user.displayName ?? email.split('@').first,
          email: user.email ?? email,
          contactNumber: user.phoneNumber ?? '',
          role: 'technician', // Default role
        );
        
        // Save user details to firestore for future login
        await firestore.collection('users').doc(user.uid).set(fallbackUser.toJson());
        
        return fallbackUser;
      }
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String contactNumber,
    required String role,
  }) async {
    try {
      final credentials = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credentials.user;
      if (user == null) {
        throw const AuthException('User registration failed.');
      }

      final userModel = UserModel(
        id: user.uid,
        fullName: fullName,
        email: email,
        contactNumber: contactNumber,
        role: role,
      );

      // Save user details to firestore
      await firestore.collection('users').doc(user.uid).set(userModel.toJson());

      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration error occurred.');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
