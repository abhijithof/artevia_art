import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/artworks/providers/artwork_provider.dart';
import 'features/artworks/services/artwork_service.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000',
    validateStatus: (status) => true,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  runApp(MyApp(dio: dio));
}

class MyApp extends StatelessWidget {
  final Dio dio;

  const MyApp({Key? key, required this.dio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ArtworkService>(
          update: (context, auth, previous) => 
            ArtworkService(dio, authToken: auth.token),
        ),
        ChangeNotifierProxyProvider<ArtworkService, ArtworkProvider>(
          create: (context) => ArtworkProvider(
            Provider.of<ArtworkService>(context, listen: false),
          ),
          update: (context, service, previous) => 
            previous ?? ArtworkProvider(service),
        ),
      ],
      child: MaterialApp(
        title: 'Artevia',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return authProvider.isAuthenticated 
              ? const HomeScreen() 
              : const LoginScreen();
          },
        ),
      ),
    );
  }
}
