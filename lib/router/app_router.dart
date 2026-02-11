import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../screens/marketplace/onboarding_screen.dart';
import '../screens/marketplace/role_selection_screen.dart';
import '../screens/marketplace/profile_create_screen.dart';
import '../screens/marketplace/creator_setup_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/marketplace/profile_detail_screen.dart';
import '../screens/marketplace/cart_screen.dart';
import '../screens/marketplace/checkout_calendar_screen.dart';
import '../screens/marketplace/dashboard_provider_screen.dart';
import '../screens/marketplace/dashboard_business_screen.dart';
import '../screens/marketplace/order_detail_screen.dart';
import '../screens/marketplace/delivery_upload_screen.dart';
import '../screens/marketplace/service_list_screen.dart';
import '../screens/marketplace/service_detail_screen.dart';
import '../screens/service/create_service_screen.dart';
import '../screens/provider/provider_setup_screen.dart';
import '../screens/orders/order_payment_screen.dart';
import '../screens/orders/order_workspace_screen.dart';
import '../screens/orders/delivery_upload_screen.dart';
import '../screens/orders/order_approve_screen.dart';
import '../screens/orders/order_list_screen.dart';
import '../screens/orders/hire_screen.dart';
import '../screens/orders/workspace_screen_mvp.dart';
import '../screens/orders/delivery_upload_screen_mvp.dart';
import '../screens/orders/approve_screen_mvp.dart';
import '../screens/orders/hire_confirm_screen.dart';
import '../screens/orders/workspace_screen.dart';
import '../screens/orders/delivery_screen.dart';
import '../screens/orders/approve_screen.dart';
import '../screens/business/business_home_screen.dart';
import '../screens/service/service_detail_screen.dart' as service_detail;
import '../screens/mvp/marketplace_screen.dart' as mvp;
import '../screens/mvp/service_detail_screen.dart' as mvp_detail;
import '../screens/hire/hire_service_screen.dart';
import '../data/mock/mock_models.dart';
import '../screens/orders/revision_request_screen.dart';
import '../screens/orders/order_dashboard_screen.dart';
import '../screens/hire/hire_confirm_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_manual_posts_screen.dart';
import '../screens/admin/admin_disputes_screen.dart';
import '../screens/admin/admin_payouts_screen.dart';
import '../screens/admin/admin_ban_screen.dart';
import '../features/dispute/dispute_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../services/onboarding_service.dart';
import '../services/marketplace/auth_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final onboardingService = OnboardingService();
      final authService = MarketplaceAuthService();
      final hasSeenOnboarding = onboardingService.hasSeenOnboarding();
      final isLoggedIn = authService.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isRole = state.matchedLocation == '/role';

      if (!hasSeenOnboarding && !isOnboarding) return '/onboarding';
      if (hasSeenOnboarding && !isLoggedIn && !isAuthRoute && !isOnboarding) return '/login';
      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/signup')) return '/role';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const _MarketplaceSplash()),
      GoRoute(path: '/onboarding', builder: (_, __) => const MarketplaceOnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/role', builder: (_, __) => const MarketplaceRoleSelectionScreen()),
      GoRoute(
        path: '/profile/create',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? state.extra as String?;
          return ProfileCreateScreen(role: role);
        },
      ),
      GoRoute(
        path: '/creator/setup/:profileId',
        builder: (context, state) {
          final id = state.pathParameters['profileId'] ?? '';
          return CreatorSetupScreen(profileId: id);
        },
      ),
      GoRoute(
        path: '/videographer/setup/:profileId',
        builder: (context, state) {
          final id = state.pathParameters['profileId'] ?? '';
          return CreatorSetupScreen(profileId: id);
        },
      ),
      GoRoute(
        path: '/freelancer/setup/:profileId',
        builder: (context, state) {
          final id = state.pathParameters['profileId'] ?? '';
          return CreatorSetupScreen(profileId: id);
        },
      ),
      GoRoute(path: '/marketplace', builder: (_, __) => const MarketplaceScreen()),
      GoRoute(path: '/mvp', builder: (_, __) => const mvp.MvpMarketplaceScreen()),
      GoRoute(
        path: '/mvp/service/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return mvp_detail.MvpServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(path: '/business', builder: (_, __) => const BusinessHomeScreen()),
      GoRoute(
        path: '/business/service/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return service_detail.ServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: '/hire',
        builder: (context, state) {
          final service = state.extra as MockServiceModel?;
          return BusinessHireConfirmScreen(service: service);
        },
      ),
      GoRoute(
        path: '/workspace/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrdersWorkspaceScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/delivery/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return DeliveryScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/approve/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return ApproveScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/mvp/workspace/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return WorkspaceScreenMvp(orderId: orderId, currentUserId: state.extra as String?);
        },
      ),
      GoRoute(
        path: '/mvp/delivery/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return DeliveryUploadScreenMvp(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/mvp/approve/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return ApproveScreenMvp(orderId: orderId);
        },
      ),
      GoRoute(path: '/services', builder: (_, __) => const ServiceListScreen()),
      GoRoute(
        path: '/provider/setup',
        builder: (context, state) {
          final profileId = state.uri.queryParameters['profileId'];
          final role = state.uri.queryParameters['role'];
          return ProviderSetupScreen(profileId: profileId, role: role);
        },
      ),
      GoRoute(
        path: '/service/create',
        builder: (_, __) => const CreateServiceScreen(),
      ),
      GoRoute(
        path: '/service/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ServiceDetailScreen(serviceId: id);
        },
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProfileDetailScreen(profileId: id);
        },
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/cart/checkout', builder: (_, __) => const CheckoutCalendarScreen()),
      GoRoute(
        path: '/hire/confirm/:serviceId',
        builder: (context, state) {
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return HireConfirmScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/hire/:serviceId',
        builder: (context, state) {
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return HireServiceScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return OrderListScreen(statusFilter: status);
        },
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/order/:id/dashboard',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDashboardScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/order/:id/payment',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderPaymentScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/order/:id/workspace',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderWorkspaceScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/order/:id/delivery',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDeliveryUploadScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/order/:id/approve',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderApproveScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/order/:id/revision',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RevisionRequestScreen(orderId: id);
        },
      ),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/manual-posts', builder: (_, __) => const AdminManualPostsScreen()),
      GoRoute(path: '/admin/disputes', builder: (_, __) => const AdminDisputesScreen()),
      GoRoute(path: '/admin/payouts', builder: (_, __) => const AdminPayoutsScreen()),
      GoRoute(path: '/admin/ban-users', builder: (_, __) => const AdminBanScreen()),
      GoRoute(
        path: '/dispute/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return DisputeScreen(orderId: orderId);
        },
      ),
      GoRoute(path: '/dashboard/provider', builder: (_, __) => const DashboardProviderScreen()),
      GoRoute(path: '/dashboard/business', builder: (_, __) => const DashboardBusinessScreen()),
    ],
  );
}

class _MarketplaceSplash extends StatefulWidget {
  const _MarketplaceSplash();

  @override
  State<_MarketplaceSplash> createState() => _MarketplaceSplashState();
}

class _MarketplaceSplashState extends State<_MarketplaceSplash> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final onboardingService = OnboardingService();
    final authService = MarketplaceAuthService();
    if (!onboardingService.hasSeenOnboarding()) {
      if (mounted) context.go('/onboarding');
      return;
    }
    if (!authService.isLoggedIn) {
      if (mounted) context.go('/login');
      return;
    }
    await authService.ensureUser();
    final roles = await authService.getMyRoles();
    final paidRoles = roles.where((r) => r.isPaid).map((r) => r.role).toSet();
    if (!mounted) return;
    if (paidRoles.isEmpty) {
      context.go('/role');
      return;
    }
    if (paidRoles.contains(AppConstants.roleBusinessOwner) && paidRoles.length == 1) {
      context.go('/marketplace');
      return;
    }
    if (paidRoles.contains(AppConstants.roleCreator) ||
        paidRoles.contains(AppConstants.roleVideographer) ||
        paidRoles.contains(AppConstants.roleFreelancer)) {
      context.go('/dashboard/provider');
      return;
    }
    context.go('/marketplace');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
