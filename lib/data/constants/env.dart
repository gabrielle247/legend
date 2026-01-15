class AppEnv {
  //Secrets Cannot be implemented on a project that is not working yet.
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String powerSyncUrl =
      "https://6943ea857e2a07e6df7daa4e.powersync.journeyapps.com";
  static const String supabaseUrl = "https://hcxvsygvihhdkkyynqzw.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjeHZzeWd2aWhoZGtreXlucXp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MTA3OTEsImV4cCI6MjA3ODQ4Njc5MX0.Tn1vzaNWHW9bV6FchGU_du-HQ9QDDXphxWJL1cM75qY";
}
