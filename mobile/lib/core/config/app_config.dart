class AppConfig {
  static const String baseUrl = 'http://127.0.0.1:8000';
  // static const String baseUrl = 'https://cropdoctor.mrshakil.site';
  static const bool debugMode = true;
  
  // Production vs Dev toggles can go here
  static const String environment = 'production';
  
  /// Global API Key for production gateway (if required). 
  /// Fill this with the provided key from the backend administrator.
  static const String apiKey = ''; 
}
