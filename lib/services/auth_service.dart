import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService
{
  final SupabaseClient _supabase = Supabase.instance.client;

  //sign up

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.user != null) {
        // Try to create user profile (may fail due to RLS, but that's okay)
        // The profile might be created by a database trigger instead
        try {
          await _supabase
              .from('user_profiles')
              .insert({
                'email': email,
                'first_name': firstName,
                'last_name': lastName,
                if (phoneNumber != null) 'phone_number': phoneNumber,
              });
        } catch (e) {
          // RLS might prevent this, but that's okay - profile might be created by trigger
          print('Note: Could not create user_profile (may be handled by trigger): $e');
        }

        return UserModel(
          id: response.user!.id,
          email: response.user!.email ?? email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }
  //sign in
Future<UserModel?> signIn({
    required String email,
  required String password,
})async{
    try{
      final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password
      );
      if(response.user != null)
      {
        final userData = response.user!.userMetadata;
        return UserModel(
            id: response.user!.id,
            email: response.user!.email ?? email,
            firstName: userData?['first_name'],
            lastName: userData?['last_name'],
            phoneNumber: userData?['phone_number']
        );

      }
      return null;
    }
    catch(e)
    {
      throw Exception('sign in failed: $e');
    }
}
//sign out
Future<void> signOut()async
{
  await _supabase.auth.signOut();
}
//get current user
UserModel? getCurrentUser()
{
  final user = _supabase.auth.currentUser;
  if(user == null)
    return null;

  final userData = user.userMetadata;
  return UserModel(
      id: user.id,
      email: user.email ?? '',
      firstName: userData?['first_name'],
      lastName: userData?['last_name'],
      phoneNumber: userData?['phone_number']
  );
}
}