import 'package:blue_ribbon/login_page.dart';
import 'package:blue_ribbon/home_page.dart';
import 'package:blue_ribbon/bloc/auth/auth_bloc.dart';
import 'package:blue_ribbon/data/repositories/authentication_repository.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService();
  final authenticationRepository = AuthenticationRepository(
    apiService: apiService,
    prefs: prefs,
  );

  // Attempt auto-login on startup
  authenticationRepository.tryAutoLogin();

  runApp(App(authenticationRepository: authenticationRepository));
}

class App extends StatelessWidget {
  final AuthenticationRepository authenticationRepository;

  const App({super.key, required this.authenticationRepository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authenticationRepository,
      child: BlocProvider(
        create: (_) => AuthBloc(
          authenticationRepository: authenticationRepository,
        )..add(AuthSubscriptionRequested()),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blue Ribbon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SamsungOne',
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.black,
          secondary: Colors.blue,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
          displayMedium:
              TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
          displaySmall:
              TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
          headlineLarge:
              TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          headlineMedium:
              TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          headlineSmall:
              TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          titleLarge:
              TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          titleMedium:
              TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          titleSmall:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          bodyLarge:
              TextStyle(fontWeight: FontWeight.w400, color: Colors.black87),
          bodyMedium:
              TextStyle(fontWeight: FontWeight.w400, color: Colors.black87),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
      home: const AuthGuard(),
    );
  }
}

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthenticationStatus.authenticated:
            return const HomePage(title: "Home");
          case AuthenticationStatus.unauthenticated:
            return const LoginPage();
          case AuthenticationStatus.unknown:
          default:
            return const SplashScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
