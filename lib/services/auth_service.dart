import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  static Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');

    try {
      return await _auth.signInWithProvider(appleProvider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'web-context-cancelled') {
        return null; // 사용자 취소
      }
      rethrow;
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // 계정 삭제
  // 각 단계가 실패해도 SyncService 리스너를 복원하고 에러를 전파한다.
  // UI 계층은 rethrow된 예외를 받아 "재인증 후 재시도" 안내를 표시한다.
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    await performDeleteAccount(
      uid: user.uid,
      // 1. SyncService 리스너 중지
      syncDispose: SyncService.dispose,
      // 2. Firestore 데이터 영구 삭제
      deleteRemote: FirestoreService.deleteAllUserData,
      // 3. Firebase Auth 계정 삭제
      authDelete: user.delete,
      // 실패 복원용: 현재 로그인된 유저로 리스너를 재초기화
      // user.delete() 성공 후에는 currentUser가 null이 되므로 재초기화가 no-op
      syncReinit: () async {
        final u = _auth.currentUser;
        if (u != null) await SyncService.init(u);
      },
      // 4. 로컬 firestoreId 초기화 + lastLoginUid 제거
      localCleanup: _clearLocalFirestoreState,
    );
  }

  // 로컬 Hive 데이터에서 firestoreId를 초기화하고 lastLoginUid를 제거한다.
  // deleteAccount의 마지막 단계(step 4)로 user.delete() 성공 후에만 호출된다.
  static Future<void> _clearLocalFirestoreState() async {
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

    await articleBox.flush();
    await labelBox.flush();

    // lastLoginUid 제거
    await DatabaseService.saveLastLoginUid(null);
  }

  /// deleteAccount 오케스트레이션 핵심 로직 (테스트 가능 형태로 분리).
  ///
  /// 각 단계가 throw하면:
  /// - step 2(deleteRemote) 실패: syncReinit 후 rethrow. authDelete·localCleanup 미실행.
  /// - step 3(authDelete) 실패: syncReinit 후 rethrow. localCleanup 미실행.
  /// - step 4(localCleanup) 실패: 계정은 이미 삭제됨. syncReinit은 호출하지 않음
  ///   (currentUser가 null이라 리스너가 무의미). rethrow.
  ///
  /// syncReinit 자체가 throw해도 원래 예외는 이미 rethrow 경로에 있으므로
  /// syncReinit의 오류가 원래 오류를 덮어쓴다 (단순성 우선).
  @visibleForTesting
  static Future<void> performDeleteAccount({
    required FutureOr<void> Function() syncDispose,
    required Future<void> Function(String uid) deleteRemote,
    required Future<void> Function() authDelete,
    required Future<void> Function() syncReinit,
    required Future<void> Function() localCleanup,
    required String uid,
  }) async {
    // 1단계: SyncService 리스너 중지
    // 삭제 진행 중 Firestore 스냅샷이 로컬 데이터를 건드리지 않도록 리스너를 먼저 중지
    await syncDispose();

    // 2단계: Firestore 원격 데이터 영구 삭제
    try {
      await deleteRemote(uid);
    } catch (_) {
      // deleteRemote 실패 → SyncService 복원 후 rethrow
      // 계정은 아직 살아있으므로 리스너를 재초기화해 동기화 상태를 복원한다
      await syncReinit();
      rethrow;
    }

    // 3단계: Firebase Auth 계정 삭제 (requires-recent-login 등으로 실패 가능)
    try {
      await authDelete();
    } catch (_) {
      // authDelete 실패 → Firestore 데이터는 이미 비워졌지만 계정은 살아있음
      // SyncService를 재초기화해 리스너를 복원한다 (Firestore가 비었으므로 첫 스냅샷은 빈 리스트)
      await syncReinit();
      rethrow;
    }

    // 4단계: 로컬 firestoreId 초기화 + lastLoginUid 제거
    // 계정 삭제 성공 후에만 실행. 실패해도 syncReinit은 불필요 (계정이 없으므로 리스너 복원 불가)
    try {
      await localCleanup();
    } catch (_) {
      rethrow;
    }
  }
}
