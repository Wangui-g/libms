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

    return response;
  } on AuthException catch (e) {
    print("❌ AuthException: ${e.message}");
    throw Exception(e.message);
  } catch (e) {
    print("❌ Unexpected error during registration: $e");
    throw Exception("Registration failed: $e");
  }
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

  await _supabase.from('user_profiles').insert({
    'id': user.id,
    'email': user.email,
    'full_name': fullName,
    'user_type': userType,
    'identification_number': identificationNumber,
    'phone': phone,
    'address': address,
    'library_id': libraryId,
  });
}


  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return response;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _supabase
        .from('user_profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => 
      _supabase.auth.onAuthStateChange;
}
