import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/mqtt_cloud_service.dart';
import 'services/schedule_executor_service.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/add_home/add_home_flow_screen.dart';
import 'screens/device/device_screen.dart';
import 'screens/devices/devices_screen.dart';
import 'screens/control/control_center_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/debug/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initializing Brightify Cloud-First Architecture...');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️ Failed to load .env file: $e');
    print('   Continuing with default configuration...');
  }
  
  // Initialize Firebase
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized');
  
  // Initialize Cloud Services
  print('☁️ Initializing Cloud Services...');
  await ApiService.initialize();
  
  // Initialize MQTT Cloud Service
  print('📡 Initializing MQTT Cloud Service...');
  try {
    await MqttCloudService.initialize();
    print('✅ MQTT Cloud Service ready');
  } catch (e) {
    print('⚠️ MQTT initialization failed: $e');
    print('   Device control may be limited');
  }
  
  // Initialize Schedule Executor Service
  print('⏰ Initializing Schedule Executor...');
  try {
    ScheduleExecutorService().startExecutor();
    print('✅ Schedule Executor started');
  } catch (e) {
    print('⚠️ Schedule Executor initialization failed: $e');
    print('   Automatic schedules may not work');
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const BrightifyApp());
}

class BrightifyApp extends StatelessWidget {
  const BrightifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Brightify',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/add-home': (context) => const AddHomeFlowScreen(),
          '/devices': (context) => const DevicesScreen(),
          '/control-center': (context) => const ControlCenterScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/schedule': (context) => const ScheduleScreen(),
          '/debug': (context) => const DebugScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle dynamic routes with parameters
          if (settings.name != null && settings.name!.startsWith('/device/')) {
            final uri = Uri.parse(settings.name!);
            final segments = uri.pathSegments;
            if (segments.length >= 3) {
              final deviceId = segments[1];
              final roomName = segments[2];
              return MaterialPageRoute(
                builder: (context) => DeviceScreen(
                  deviceId: deviceId,
                  roomName: Uri.decodeComponent(roomName),
                ),
              );
            }
          }
          // Return null if route not found
          return null;
        },
          );
        },
      ),
    );
  }
}
