import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/artworks/providers/artwork_provider.dart';
import 'features/artworks/services/artwork_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/profile/screens/profile_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000',  // Changed from 10.0.2.2 for web
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    validateStatus: (status) => status! < 500,
  ));

  // Add logging interceptor
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(dio)),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ArtworkProvider>(
          create: (_) => ArtworkProvider(ArtworkService(dio)),
          update: (_, auth, previous) => ArtworkProvider(
            ArtworkService(dio, authToken: auth.token),
          ),
        ),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const MyApp({
    required this.navigatorKey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Artevia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
