class Constants {
  static const String baseUrl = 'https://komikcast.bz';
  
  // API Endpoints
  static const String latestMangaEndpoint = '/daftar-komik/?orderby=update';
  static const String popularMangaEndpoint = '/daftar-komik/?status=&type=&orderby=popular';
  static const String searchEndpoint = '/?s=';
  
  // Shared Preferences Keys
  static const String keyFavorites = 'favorites';
  static const String keyHistory = 'history';
  static const String keySettings = 'settings';
  
  // Cache Duration
  static const int cacheDuration = 300; // 5 minutes in seconds
}