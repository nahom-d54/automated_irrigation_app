import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irrigation_app/presentation/pages/auth_wrapper.dart';
import 'package:irrigation_app/presentation/pages/welcome_page.dart';
import 'package:irrigation_app/service_locator.dart';
import 'package:irrigation_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:irrigation_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'presentation/blocs/sensor_data/sensor_data_bloc.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  // Initialize service locator
  final serviceLocator = ServiceLocator();
  serviceLocator.initialize();
  // Check if this is the first time opening the app
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('first_time') ?? true;
  
  runApp(MyApp(
    serviceLocator: serviceLocator,
    isFirstTime: isFirstTime,
  ));
}

class MyApp extends StatefulWidget {
  final ServiceLocator serviceLocator;
  final bool isFirstTime;
  
  const MyApp({
    super.key, 
    required this.serviceLocator,
    required this.isFirstTime,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Check authentication status on app start
    widget.serviceLocator.authBloc.add(AuthCheckRequested());
    // Initialize notifications
    widget.serviceLocator.notificationBloc.add(NotificationInitialize());
    
    // Mark that the app has been opened
    if (widget.isFirstTime) {
      _markFirstTimeComplete();
    }
  }

  Future<void> _markFirstTimeComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
  }

  @override
  void dispose() {
    widget.serviceLocator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => widget.serviceLocator.authBloc,
        ),
        BlocProvider<SensorDataBloc>(
          create: (context) => widget.serviceLocator.sensorDataBloc,
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => widget.serviceLocator.notificationBloc,
        ),
      ],
      child: MaterialApp(
        title: 'Irrigation Monitor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.green,
            elevation: 0,
          ),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.green,
            accentColor: Colors.greenAccent,
            brightness: Brightness.light,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        home: widget.isFirstTime ? const WelcomePage() : const AuthWrapper(),
      ),
    );
  }
}
