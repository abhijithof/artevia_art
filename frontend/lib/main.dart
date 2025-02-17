import 'package:flutter/material.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/home/screens/home_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'services/api_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/artworks/providers/artwork_provider.dart';
import 'features/artworks/services/artwork_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio(BaseOptions(
    baseUrl: ApiService.baseUrl,
    validateStatus: (status) => status! < 500,
    headers: {
      'Accept': 'application/json',
    },
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
          create: (_) => ArtworkProvider(ArtworkService(dio), dio),
          update: (_, auth, previous) => ArtworkProvider(
            ArtworkService(
              dio,
              authToken: auth.token,
            ),
            dio,
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
      debugShowCheckedModeBanner: false,
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

