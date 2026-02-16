import 'package:flutter/material.dart';
import 'package:unified_http_client/unified_http_client.dart';
import 'dart:convert';

/// This example demonstrates the complete refresh token flow
/// 
/// Setup:
/// 1. Configure refresh token endpoint and callbacks
/// 2. Make API calls normally
/// 3. Package automatically handles token refresh on 401
/// 4. User code receives response without any manual intervention

class TokenStorage {
  static String? _accessToken;
  static String? _refreshToken;
  
  static String? getAccessToken() => _accessToken;
  static String? getRefreshToken() => _refreshToken;
  
  static void saveTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  
  static void clear() {
    _accessToken = null;
    _refreshToken = null;
  }
}

void setupHttpClient(BuildContext context) {
  UnifiedHttpClient().init(
    usehttp: false, // Using Dio
    baseUrl: 'https://your-api.com',
    showLogs: true, // Enable to see refresh flow in console
    
    // === REFRESH TOKEN CONFIGURATION ===
    
    // Step 1: Specify the refresh token endpoint
    refreshTokenEndpoint: '/auth/refresh',
    
    // Step 2: (Optional) Whitelist specific endpoints
    // Only these endpoints will trigger token refresh on 401
    // If null or empty, ALL 401s will trigger refresh
    refreshWhitelist: [
      '/posts',
      '/user',
      '/profile',
      '/orders',
    ],
    
    // Step 3: Provide the refresh token in request body
    getRefreshTokenBody: () {
      final refreshToken = TokenStorage.getRefreshToken();
      
      debugPrint('[TokenRefresh] Providing refresh token: ${refreshToken?.substring(0, 10)}...');
      
      return {
        'refreshToken': refreshToken,
        // Add any other fields your backend requires
        // 'deviceId': DeviceInfo.getId(),
        // 'platform': 'mobile',
      };
    },
    
    // Step 4: Save new tokens when refresh succeeds
    onTokenRefreshed: (newTokens) async {
      debugPrint('[TokenRefresh] Received new tokens: ${newTokens.keys}');
      
      // Extract tokens - adjust field names based on your backend response
      final accessToken = newTokens['accessToken'] ?? newTokens['access_token'];
      final refreshToken = newTokens['refreshToken'] ?? newTokens['refresh_token'];
      
      // Save to storage (use SharedPreferences, Hive, etc. in real app)
      TokenStorage.saveTokens(accessToken, refreshToken);
      
      // IMPORTANT: Update the Authorization header with new token
      UnifiedHttpClient.setDefaultHeader(
        'Authorization',
        'Bearer $accessToken',
      );
      
      debugPrint('[TokenRefresh] Tokens saved and headers updated');
      
      // Optional: Save to persistent storage
      // await SharedPreferences.getInstance().then((prefs) {
      //   prefs.setString('access_token', accessToken);
      //   prefs.setString('refresh_token', refreshToken);
      // });
    },
    
    // Step 5: Handle logout when refresh fails
    onLogout: () {
      debugPrint('[TokenRefresh] Session expired - logging out');
      
      // Clear storage
      TokenStorage.clear();
      
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      
      // Show message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
    },
  );
  
  // Set initial authorization header if user is already logged in
  final accessToken = TokenStorage.getAccessToken();
  if (accessToken != null) {
    UnifiedHttpClient.setDefaultHeader('Authorization', 'Bearer $accessToken');
  }
}

/// Example: Login to get initial tokens
Future<bool> login(String email, String password) async {
  final result = await UnifiedHttpClient.post(
    '/auth/login',
    body: {
      'email': email,
      'password': password,
    },
  );
  
  return result.fold(
    (failure) {
      debugPrint('Login failed: ${failure.message}');
      return false;
    },
    (response) {
      final data = jsonDecode(response);
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      
      // Save tokens
      TokenStorage.saveTokens(accessToken, refreshToken);
      
      // Set authorization header
      UnifiedHttpClient.setDefaultHeader('Authorization', 'Bearer $accessToken');
      
      debugPrint('Login successful');
      return true;
    },
  );
}

/// Example: Fetch posts - token refresh is automatic!
Future<List<dynamic>> fetchPosts() async {
  debugPrint('[API] Fetching posts...');
  
  final result = await UnifiedHttpClient.get('/posts');
  
  return result.fold(
    (failure) {
      debugPrint('[API] Failed to fetch posts: ${failure.message}');
      return [];
    },
    (response) {
      debugPrint('[API] Posts fetched successfully');
      final data = jsonDecode(response);
      return data['posts'] ?? [];
    },
  );
}

/// Example: Complete flow demonstration
class RefreshTokenExample extends StatefulWidget {
  const RefreshTokenExample({super.key});

  @override
  State<RefreshTokenExample> createState() => _RefreshTokenExampleState();
}

class _RefreshTokenExampleState extends State<RefreshTokenExample> {
  String status = 'Not logged in';
  
  @override
  void initState() {
    super.initState();
    setupHttpClient(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refresh Token Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $status'),
            const SizedBox(height: 20),
            
            // Step 1: Login
            ElevatedButton(
              onPressed: () async {
                setState(() => status = 'Logging in...');
                final success = await login('test@example.com', 'password');
                setState(() => status = success ? 'Logged in' : 'Login failed');
              },
              child: const Text('1. Login'),
            ),
            
            // Step 2: Fetch posts (with valid token)
            ElevatedButton(
              onPressed: () async {
                setState(() => status = 'Fetching posts...');
                final posts = await fetchPosts();
                setState(() => status = 'Fetched ${posts.length} posts');
              },
              child: const Text('2. Fetch Posts (Valid Token)'),
            ),
            
            // Step 3: Simulate token expiry and fetch again
            ElevatedButton(
              onPressed: () async {
                setState(() => status = 'Simulating expired token...');
                
                // Simulate expired token by setting an invalid one
                UnifiedHttpClient.setDefaultHeader('Authorization', 'Bearer expired_token');
                
                setState(() => status = 'Fetching with expired token...');
                
                // This will:
                // 1. Get 401 from server
                // 2. Package detects 401
                // 3. Package calls getRefreshTokenBody()
                // 4. Package calls /auth/refresh
                // 5. Package calls onTokenRefreshed()
                // 6. Package retries original request
                // 7. Returns data!
                final posts = await fetchPosts();
                
                setState(() => status = 'Auto-refreshed! Fetched ${posts.length} posts');
              },
              child: const Text('3. Fetch Posts (Expired Token - Auto Refresh)'),
            ),
            
            const SizedBox(height: 20),
            const Text(
              'What happens when token expires:\n'
              '1. API returns 401\n'
              '2. Package calls refresh endpoint\n'
              '3. Package saves new tokens\n'
              '4. Package retries original request\n'
              '5. You get the data!\n\n'
              'No manual intervention needed!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expected console output when token refresh happens:
/// 
/// ```
/// [API] Fetching posts...
/// [UnifiedHttpClient] → GET https://your-api.com/posts
/// [UnifiedHttpClient] ✕ error: 401 Unauthorized
/// 401 detected - checking whitelist
/// Endpoint /posts is in whitelist
/// [TokenRefresh] Providing refresh token: eyJhbGciOi...
/// [UnifiedHttpClient] → POST https://your-api.com/auth/refresh
/// [UnifiedHttpClient] ← status 200
/// Token refresh successful
/// [TokenRefresh] Received new tokens: [accessToken, refreshToken]
/// [TokenRefresh] Tokens saved and headers updated
/// Retrying original request after token refresh
/// [UnifiedHttpClient] → GET https://your-api.com/posts
/// [UnifiedHttpClient] ← status 200
/// [API] Posts fetched successfully
/// ```
