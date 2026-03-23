import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseConfig {
  // Your Project URL from Supabase
  static const String supabaseUrl = 'https://uawxrfxbzczpadvhirjd.supabase.co';

  // Your Anon Public Key from Supabase (replace this!)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVhd3hyZnhiemN6cGFkdmhpcmpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1NjgwMTAsImV4cCI6MjA4NjE0NDAxMH0.HDhR_Cd5I7VuQVFhorvYPqSlGqttnVuep8Py9x29I8g';

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}