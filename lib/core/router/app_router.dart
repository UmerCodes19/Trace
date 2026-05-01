import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/simple_post_model.dart';

import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/auth/cms_webview_login.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/debug/debug_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/map/map_screen.dart';
import '../../presentation/screens/map/isometric_campus_screen.dart';
import '../../presentation/screens/notifications/notification_list_screen.dart';
import '../../presentation/screens/post/create_post_screen.dart';
import '../../presentation/screens/post/post_detail_screen.dart';
import '../../presentation/screens/post/claim_request_screen.dart';
import '../../presentation/screens/post/claim_review_list_screen.dart';
import '../../presentation/screens/post/handover_qr_screen.dart';
import '../../presentation/screens/post/handover_scanner_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/qr_code_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';
import '../../presentation/screens/shell/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, state) => _fadePage(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, state) => _fadePage(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => _fadePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: '/login/cms',
        pageBuilder: (ctx, state) => _fadePage(const CMSWebViewLogin(), state),
      ),
      GoRoute(
        path: '/debug',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const DebugScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (ctx, state) => _slidePage(const HomeScreen(), state),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (ctx, state) => _slidePage(const MapScreen(), state),
          ),
          GoRoute(
            path: '/create',
            pageBuilder: (ctx, state) =>
                _slidePage(const CreatePostScreen(), state),
          ),
          GoRoute(
            path: '/chats',
            pageBuilder: (ctx, state) =>
                _slidePage(const ChatListScreen(), state),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (ctx, state) =>
                _slidePage(const ProfileScreen(), state),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (ctx, state) =>
                _slidePage(const AdminDashboardScreen(), state),
          ),
        ],
      ),
      GoRoute(
        path: '/post/:id',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) =>
            PostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/:id/claim',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) {
          final post = state.extra as SimplePostModel;
          return ClaimRequestScreen(post: post);
        },
      ),
      GoRoute(
        path: '/post/:id/claims',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) =>
            ClaimReviewListScreen(
              postId: state.pathParameters['id']!,
              postTitle: state.uri.queryParameters['title'] ?? 'Item',
            ),
      ),
      GoRoute(
        path: '/chat/:chatId',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) =>
            ChatScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: '/post/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) {
          final post = state.extra as SimplePostModel;
          return CreatePostScreen(postToEdit: post);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/view/:uid',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => ProfileScreen(viewUid: state.pathParameters['uid']),
      ),
      GoRoute(
        path: '/handover/qr',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) {
          final args = state.extra as Map<String, dynamic>;
          return HandoverQrScreen(
            claimId: args['claimId'],
            itemTitle: args['itemTitle'],
            claimerName: args['claimerName'],
          );
        },
      ),
      GoRoute(
        path: '/map/isometric',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const IsometricCampusScreen(),
      ),
      GoRoute(
        path: '/handover/scan',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const HandoverScannerScreen(),
      ),
      GoRoute(
        path: '/profile/qr',
        parentNavigatorKey: _rootKey,
        builder: (ctx, state) => const QrCodeScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const NotificationListScreen(),
      ),
    ],
    redirect: (ctx, state) => null,
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page not found: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ctx.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

CustomTransitionPage _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(
            Tween(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}

CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 600),
  );
}
