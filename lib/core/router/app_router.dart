import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/language_select_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/farmer/presentation/screens/farmer_dashboard_screen.dart';
import '../../features/farmer/presentation/screens/add_product_screen.dart';
import '../../features/farmer/presentation/screens/farmer_orders_screen.dart';
import '../../features/farmer/presentation/screens/farmer_earnings_screen.dart';
import '../../features/farmer/presentation/screens/my_products_screen.dart';
import '../../features/consumer/presentation/screens/consumer_home_screen.dart';
import '../../features/consumer/presentation/screens/product_detail_screen.dart';
import '../../features/consumer/presentation/screens/cart_screen.dart';
import '../../features/consumer/presentation/screens/checkout_screen.dart';
import '../../features/consumer/presentation/screens/consumer_orders_screen.dart';
import '../../features/consumer/presentation/screens/order_tracking_screen.dart';
import '../../features/admin/presentation/screens/admin_verification_screen.dart';
import '../../features/crop_advisor/presentation/screens/crop_advisor_screen.dart';
import '../../features/crop_advisor/presentation/screens/crop_calendar_screen.dart';
import '../../features/disease_detection/presentation/screens/disease_detection_screen.dart';
import '../../features/krishi_sahayak/presentation/screens/krishi_sahayak_screen.dart';
import '../../features/marketplace/domain/models/product_model.dart';
import '../../features/marketplace/domain/models/order_model.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.languageSelect,
      builder: (context, state) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.verifyOtp,
      builder: (context, state) => const VerifyOtpScreen(),
    ),
    GoRoute(
      path: RouteNames.roleSelect,
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Farmer Routes
    GoRoute(
      path: RouteNames.farmerDashboard,
      builder: (context, state) => const FarmerDashboardScreen(),
    ),
    GoRoute(
      path: RouteNames.addProduct,
      builder: (context, state) => const AddProductScreen(),
    ),
    GoRoute(
      path: RouteNames.farmerOrders,
      builder: (context, state) => const FarmerOrdersScreen(),
    ),
    GoRoute(
      path: RouteNames.farmerEarnings,
      builder: (context, state) => const FarmerEarningsScreen(),
    ),
    GoRoute(
      path: RouteNames.myProducts,
      builder: (context, state) => const MyProductsScreen(),
    ),

    // Consumer Routes
    GoRoute(
      path: RouteNames.consumerHome,
      builder: (context, state) => const ConsumerHomeScreen(),
    ),
    GoRoute(
      path: RouteNames.productDetail,
      builder: (context, state) {
        final product = state.extra as ProductModel;
        return ProductDetailScreen(product: product);
      },
    ),
    GoRoute(
      path: RouteNames.cart,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: RouteNames.checkout,
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: RouteNames.consumerOrders,
      builder: (context, state) => const ConsumerOrdersScreen(),
    ),
    GoRoute(
      path: RouteNames.orderDetail,
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return OrderTrackingScreen(order: order);
      },
    ),

    // Admin Route
    GoRoute(
      path: RouteNames.admin,
      builder: (context, state) => const AdminVerificationScreen(),
    ),

    // Advisory & AI Features
    GoRoute(
      path: RouteNames.cropAdvisor,
      builder: (context, state) => const CropAdvisorScreen(),
    ),
    GoRoute(
      path: RouteNames.cropCalendar,
      builder: (context, state) => const CropCalendarScreen(),
    ),
    GoRoute(
      path: RouteNames.diseaseDetection,
      builder: (context, state) => const DiseaseDetectionScreen(),
    ),
    GoRoute(
      path: RouteNames.krishiSahayak,
      builder: (context, state) => const KrishiSahayakScreen(),
    ),
    GoRoute(
      path: RouteNames.machinery,
      builder: (context, state) => _placeholderScaffold('Machinery Rentals (Part 4)'),
    ),
    GoRoute(
      path: RouteNames.store,
      builder: (context, state) => _placeholderScaffold('Agri Store (Part 4)'),
    ),
  ],
);

Widget _placeholderScaffold(String title) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
