import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart'; 
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/user_dashboard.dart';
import 'screens/dashboard/librarian_dashboard.dart';
import 'services/auth_service.dart';

// import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://xvkgxnlorkyveceriooa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh2a2d4bmxvcmt5dmVjZXJpb29hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyNzMzMjUsImV4cCI6MjA2Nzg0OTMyNX0.khA3VKzru4MMwyzLCL9ICDqEorYr3FZpK0nrOj9w3QA',
    
  );

  //await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
  //await Supabase.instance.client.auth.signOut();
  print('signout on startup');
  
  print('Flutter App Starting...');
  runApp(const LibraryManagementApp());
}

class LibraryManagementApp extends StatelessWidget {
  const LibraryManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  // Session? _initialSession;

  @override
  void initState() {
    super.initState();
    // final _initialSession = Supabase.instance.client.auth.currentSession;
  }

  @override
  Widget build(BuildContext context) {
    print("waiting for auth stream...");
    print(Supabase.instance.client.auth.onAuthStateChange.runtimeType);
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print("Stream snapshot: ${snapshot.connectionState}");
        print("Session data: ${snapshot.data}");

        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        print('Final Session: $session');

        // if (snapshot.connectionState == ConnectionState.waiting && session == null) {
          // return const Scaffold(
           //  body: Center(child: CircularProgressIndicator()),
          // );
       // }

        if (session == null) {
          print("No session, redirecting to LoginScreen.");
          return const LoginScreen();
        }

        print("Session exists, getting profile...");
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserProfileWithRetry(session.user.id),
          builder: (context, profileSnapshot) {
            print("Profile snapshot state: ${profileSnapshot.connectionState}");
            print("Profile data: ${profileSnapshot.data}");

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              print("❌ No profile found after retry. Showing waiting screen");
              return const Scaffold(
                body: Center(child: Text("Setting up your profile, please wait...")),
              );
            }

            if (profile['user_type'] == 'librarian') {
              print("Librarian profile found, going to LibrarianDashboard.");
              return const LibrarianDashboard();
            } else {
              print("User profile found, going to UserDashboard.");
              return const UserDashboard();
            }
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfileWithRetry(String userId) async {
    Map<String, dynamic>? profile = await _authService.getUserProfile(userId);

    if (profile != null) return profile;

    // Retry after short delay
    await Future.delayed(const Duration(seconds: 1));
    profile = await _authService.getUserProfile(userId);
    return profile;
  }
}



