import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'controllers/settings_controller.dart';
import 'routes/app_routes.dart';

import 'screens/welcome_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/phone_signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/home_shell.dart';
import 'screens/recharge_screen.dart';
import 'screens/conversion_screen.dart';
import 'screens/bundles_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/support_screen.dart';
import 'screens/reusable_confirmation_screen.dart';
import 'screens/reusable_result_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/payer_numbers_screen.dart';
import 'screens/bundle_detail_screen.dart';
import 'screens/legal_terms_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/about_screen.dart';
import 'screens/sms_bundles_screen.dart';
import 'screens/float_purchase_screen.dart';
import 'screens/bundle_subscription_screen.dart';
import 'screens/deposit_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/store_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/modern_login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
        final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
        return MaterialApp(
          title: 'Merecharge',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: colorScheme,
            scaffoldBackgroundColor: AppColors.white,
            useMaterial3: true,
          ),
          locale: settings.locale,
          supportedLocales: const [Locale('en'), Locale('fr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.welcome: (_) => const WelcomeScreen(),
            AppRoutes.signUp: (_) => const SignUpScreen(),
            AppRoutes.phoneSignUp: (_) => const PhoneSignUpScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.modernLogin: (_) => const ModernLoginScreen(),
            AppRoutes.otp: (_) => const OtpVerificationScreen(),
            AppRoutes.resetPassword: (_) => const PasswordResetScreen(),
            AppRoutes.newPassword: (_) => const NewPasswordScreen(),

            AppRoutes.home: (_) => const HomeShell(),
            AppRoutes.recharge: (_) => const CreditRechargeScreen(),
            AppRoutes.convert: (_) => const MobileMoneyConversionScreen(),
            AppRoutes.bundles: (_) => const BundlePurchaseScreen(),
            AppRoutes.history: (_) => const TransactionHistoryScreen(),
            AppRoutes.profile: (_) => const ProfileScreen(),
            AppRoutes.settings: (_) => const SettingsScreen(),
            AppRoutes.notifications: (_) => const NotificationsScreen(),
            AppRoutes.support: (_) => const SupportScreen(),

            // New flows
            AppRoutes.txConfirm: (_) => const ReusableConfirmationScreen(),
            AppRoutes.txResult: (_) => const ReusableResultScreen(),
            AppRoutes.txDetail: (_) => const TransactionDetailScreen(),
            AppRoutes.editProfile: (_) => const EditProfileScreen(),
            AppRoutes.changePassword: (_) => const ChangePasswordScreen(),
            AppRoutes.payerNumbers: (_) => const PayerNumbersScreen(),
            AppRoutes.bundleDetail: (_) => const BundleDetailScreen(),
            AppRoutes.legalTerms: (_) => const LegalTermsScreen(),
            AppRoutes.privacy: (_) => const PrivacyPolicyScreen(),
            AppRoutes.about: (_) => const AboutScreen(),
            AppRoutes.smsBundles: (_) => const SmsBundlesScreen(),
            AppRoutes.floatPurchase: (_) => const FloatPurchaseScreen(),
            AppRoutes.bundleSubscription: (_) => const BundleSubscriptionScreen(),
            AppRoutes.deposit: (_) => const DepositScreen(),
            AppRoutes.withdraw: (_) => const WithdrawScreen(),
            
            // Store routes
            AppRoutes.store: (_) => const StoreScreen(),
            
            // Admin routes
            AppRoutes.adminLogin: (_) => const AdminLoginScreen(),
            AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
            AppRoutes.adminUsers: (_) => const AdminUsersScreen(),
            AppRoutes.adminOrders: (_) => const AdminOrdersScreen(),
          },
          initialRoute: AppRoutes.splash,
        );
        },
      ),
    );
  }
}
