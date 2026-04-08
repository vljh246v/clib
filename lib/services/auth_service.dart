import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clib/models/article.dart';
import 'package:clib/models/label.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/services/firestore_service.dart';
import 'package:clib/services/sync_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static bool get isLoggedIn => currentUser != null;

  // Google 로그인
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // 사용자가 취소

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // Apple 로그인 — Firebase 네이티브 Apple 프로바이더 사용
  static Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    return await _auth.signInWithProvider(appleProvider);
  }

  // 로그아웃
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // 계정 삭제
  // 1. SyncService 리스너 중지 (삭제 중 스냅샷이 로컬 데이터 건드리는 것 방지)
  // 2. Firestore 데이터 영구 삭제
  // 3. Firebase Auth 계정 삭제
  // 4. 로컬 firestoreId 초기화 + lastLoginUid 제거
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    final uid = user.uid;

    // 1. 리스너 중지 — 삭제 중 스냅샷이 로컬 데이터를 건드리지 않도록
    SyncService.dispose();

    // 2. Firestore 데이터 영구 삭제
    await FirestoreService.deleteAllUserData(uid);

    // 3. Firebase Auth 계정 삭제
    await user.delete();

    // 4. 로컬 firestoreId 초기화 (클라우드 연결 해제, 로컬 데이터는 유지)
    final articleBox = Hive.box<Article>('articles');
    for (final article in articleBox.values) {
      if (article.firestoreId != null) {
        article.firestoreId = null;
        article.updatedAt = null;
        await article.save();
      }
    }
    final labelBox = Hive.box<Label>('labels');
    for (final label in labelBox.values) {
      if (label.firestoreId != null) {
        label.firestoreId = null;
        label.updatedAt = null;
        await label.save();
      }
    }

    // 5. lastLoginUid 제거
    await DatabaseService.saveLastLoginUid(null);
  }
}
