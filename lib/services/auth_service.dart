import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = supabase;

  Future<AuthResponse> signUp({
    
    required String email,
    required String password,
    required String fullName,
    required String userType,
    required String identificationNumber,
    String? phone,
    String? address,
    String? libraryId,
  }) async {
  print("📩 Attempting to register user with email: $email");

  try {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('User is null. Sign-up may have failed silently.');
    }

    await createUserProfile(
      fullName: fullName,
      userType: userType,
      identificationNumber: identificationNumber,
      phone: phone,
      address: address,
      libraryId: libraryId,
    );

    final profile = await waitForUserProfile(user.id);
    if (profile == null) {
      throw Exception('Profile not found after creation.');
    }

    print("✅ Profile created successfully: $profile");
    return response;

  } on AuthException catch (e) {
    print("❌ AuthException: ${e.message}");
    throw Exception(e.message);
  } catch (e) {
    print("❌ Unexpected error during registration: $e");
    throw Exception("Registration failed: $e");
  }
}

  Future<Map<String, dynamic>?> waitForUserProfile(String userId) async {
    const int maxAttempts = 10;
    const Duration delay = Duration(seconds: 2);
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        return profile;
      }
      await Future.delayed(delay);
    }
    
    print("❌ Failed to fetch user profile after $maxAttempts attempts.");
    return null;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createUserProfile({
  required String fullName,
  required String userType,
  required String identificationNumber,
  String? phone,
  String? address,
  String? libraryId,
}) async {
  final user = _supabase.auth.currentUser;
  if (user == null) {
    throw Exception("User is not authenticated.");
  }

  print("Inserting profile with id: ${user.id}");

  try{
   final response = await _supabase.from('user_profiles').insert({
     'id': user.id,
     'email': user.email,
     'full_name': fullName,
     'user_type': userType,
     'identification_number': identificationNumber,
     'phone': phone,
     'address': address,
     'library_id': libraryId,
   });
   print("Profile created successfully: $response");
  } on PostgrestException catch (e) {
    print("❌ PostgrestException: ${e.message}");
    throw Exception("Failed to create user profile: ${e.message}");  
  } catch (e) {
    print("❌ Error creating user profile: $e");
    throw Exception("Failed to create user profile");
  }
}

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      print("Fetched user profile: $response");    
      return response;
    } catch (e) {
      print("❌ Error fetching user profile: $e");
     return null;

    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _supabase
        .from('user_profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => 
      _supabase.auth.onAuthStateChange;
}
