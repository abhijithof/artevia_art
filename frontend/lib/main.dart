import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/artworks/providers/artwork_provider.dart';
import 'features/artworks/services/artwork_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/discovery/providers/location_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000',
    validateStatus: (status) => true,
  ));

  final artworkService = ArtworkService(dio);

  runApp(MyApp(
    dio: dio,
    artworkService: artworkService,
  ));
}

class MyApp extends StatelessWidget {
  final Dio dio;
  final ArtworkService artworkService;

  const MyApp({
    super.key,
    required this.dio,
    required this.artworkService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ArtworkProvider(artworkService),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Artevia',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
