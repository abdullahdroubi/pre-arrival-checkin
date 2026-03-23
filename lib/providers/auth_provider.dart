import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier
{
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider()
  {
    //check if user is already logged
    _user = _authService.getCurrentUser();
  }
  Future<bool> signUp({

    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
}) async{
    _isLoading = true;
    notifyListeners();

    try{
      _user = await _authService.signUp(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    }
    catch(e)
    {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async
  {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}