## unified_http_client

**unified_http_client** is a Flutter/Dart package that gives you a single, simple API surface for making REST calls using either `http` or `dio` under the hood.

- **Unified API**: call `UnifiedHttpClient.get/post/delete/multipart` and switch between `http` and `dio` with a single flag.
- **Centralized headers**: configure common headers once in `init()`; they are automatically applied to all requests for both `http` and `dio`, with per-call overrides still possible.
- **Unified error model**: instead of throwing, requests return a `Result<Success, Failure>` with a rich `UnifiedHttpClientEnum` error type and messages.
- **Automatic token refresh**: built-in support for refreshing expired tokens on 401 errors, with automatic retry—zero user interaction required.
- **Network checking & snackbar**: optional internet availability check with a built-in "no internet" snackbar helper.
- **Interceptors**: plug in `UnifiedInterceptor`s once and have them applied consistently for both `http` and `dio`.

---



## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  unified_http_client: ^latest
```

Then run:

```bash
flutter pub get
```

---

## Android configuration

On Android, for correct working in release mode, you must add `INTERNET` and `ACCESS_NETWORK_STATE` permissions to `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <!-- Permissions for internet_connection_checker -->
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

  <application
      android:name="..."
      ... >
  </application>
</manifest>
```

You can use the built-in internet checker and snackbar like this:

```dart
if (!await InternetConnectionChecker().hasConnection) {
  CustomSnackbar().showNoInternetSnackbar();
}
```

Initialize the snackbar after `MaterialApp` is built:

```dart
@override
Widget build(BuildContext context) {
  // Needed to show the "no internet" snackbar.
  CustomSnackbar().init(context);

  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Unified HTTP Client')),
      body: const MyHomePage(),
    ),
  );
}
```

---

## Initialization (headers + client selection)

Call `UnifiedHttpClient().init()` once, early in your app (e.g. in `main()`), to configure:

- whether to use `http` or `dio`
- base URL and timeouts (for `dio`)
- global headers (used by **both** `http` and `dio`)
- interceptors and logging

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UnifiedHttpClient().init(
    usehttp: false, // false => use dio, true => use http (default is true)
    baseUrl: 'https://66c45adfb026f3cc6ceefd10.mockapi.io',
    showLogs: true,
    // headers configured here are applied to ALL requests by default
    headers: {
      'Authorization': 'Bearer <token>',
      'X-App-Version': '1.0.0',
    },
    interceptors: [
      ApiInterceptor(
        // Example: override headers or log extra info
        onRequestOverride: (req) {
          req.headers['X-Demo-Header'] = 'demo';
          return req;
        },
      ),
    ],
  );

  runApp(const MyApp());
}
```

> **Note:** You no longer need to call `PackageDio.setBaseOptions` / `setUpDio()` or `PackageHttp.setup()` directly in your app. The `init()` method wires everything up for you.

---

## Making API calls

Use the static helpers from `UnifiedHttpClient` anywhere in your code.  
All methods return a `Result<String>` which will be either `Success` or `Failure`.

### GET

```dart
final result = await UnifiedHttpClient.get(
  '/data/postdata',
  // optional per-call headers (merged with init headers, override by key)
  headers: {
    'X-Request-Id': '123',
  },
  queryPara: {
    'page': 1,
  },
);

result.fold(
  (failure) {
    PackageLogger.error('GET failed: ${failure.unifiedHttpClientEnum} - ${failure.message}');
  },
  (body) {
    PackageLogger.green('GET body: $body');
  },
);
```

### POST

```dart
final result = await UnifiedHttpClient.post(
  '/data/postdata',
  body: {
    'name': 'John',
    'age': 30,
  },
  headers: {
    // overrides/extends init headers for this call only
    'X-Request-Id': '456',
  },
);

result.fold(
  (failure) {
    // handle error
  },
  (body) {
    // handle success
  },
);
```

### DELETE

```dart
final result = await UnifiedHttpClient.delete(
  '/data/postdata/1',
);
```

### Multipart (file upload)

```dart
final result = await UnifiedHttpClient.multipart(
  '/upload',
  files: {
    'image': {
      'path': '/path/to/image.jpg',
      'filename': 'image.jpg',
    },
  },
  fields: {
    'title': 'My Image',
    'description': 'Image description',
  },
);
```

---

## Header behavior (important)

- **Init-level headers** (`init(headers: ...)`):
  - Stored once and automatically applied to **every** request (for both `http` and `dio`).
  - Example: global `Authorization` token, `Accept-Language`, app version, etc.

- **Per-call headers** (e.g. `get(..., headers: {...})`):
  - Optional and still supported.
  - These are **merged** with init headers; when a key exists in both, the per-call value wins.
  - This works consistently for `get`, `post`, `delete`, and `multipart`.

This lets you configure your main headers once, while still having the flexibility to tweak/override them for individual calls.

You can also update global headers **later at runtime** from anywhere in your app:

```dart
// e.g. after a successful login
final loginResult = await UnifiedHttpClient.post('/auth/login', body: {...});

loginResult.fold(
  (failure) {
    // handle login error
  },
  (body) {
    final token = extractTokenFrom(body);
    UnifiedHttpClient.setDefaultHeader('Authorization', 'Bearer $token');
  },
);

// or replace/merge multiple defaults at once
UnifiedHttpClient.setDefaultHeaders({
  'Authorization': 'Bearer $token',
  'X-Session-Id': sessionId,
});
```

You can also update global headers **later at runtime** from anywhere in your app:

```dart
// e.g. after a successful login
result.fold(
  (failure) {
    // handle login error
  },
  (body) {
    final token = extractTokenFrom(body);
    UnifiedHttpClient.setDefaultHeader('Authorization', 'Bearer $token');
  },
);

// or replace/merge multiple defaults at once
UnifiedHttpClient.setDefaultHeaders({
  'Authorization': 'Bearer $token',
  'X-Session-Id': sessionId,
});
```

---

## Error handling

All helpers (`get/post/delete/multipart`) return a `Result<String>`:

- **Success**: wraps the response body as a `String`.
- **Failure**: wraps:
  - a `UnifiedHttpClientEnum` describing the error category (e.g. `badRequestError`, `internalServerError`, `noInternetError`, etc.),
  - a default message,
  - and (where applicable) the raw response body from the server.

You can pattern-match on the enum to customize your UI and flows:

```dart
result.fold(
  (failure) {
    switch (failure.unifiedHttpClientEnum) {
      case UnifiedHttpClientEnum.badRequestError:
        // 400
        break;
      case UnifiedHttpClientEnum.notFoundError:
        // 404
        break;
      default:
        // generic handling
    }
  },
  (body) {
    // handle success
  },
);
```

---

## Network log viewer screen

This package also includes a ready‑made **network inspector** screen, powered by a unified interceptor that records all `http` and `dio` traffic.

- Logs are stored in-memory inside the package (via `NetworkLogStorage`).
- The widget is exposed as `NetworkLogScreen` and can be used in any Flutter app.

### Usage in your Flutter project

1. **Import the package (and screen)**

```dart
import 'package:flutter/material.dart';
import 'package:unified_http_client/unified_http_client.dart'; // exports NetworkLogScreen
```

2. **Navigate to the screen from anywhere**

```dart
IconButton(
  icon: const Icon(Icons.network_check),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NetworkLogScreen(),
      ),
    );
  },
);
```

3. **Or use it as a standalone page**

```dart
class DebugNetworkPage extends StatelessWidget {
  const DebugNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const NetworkLogScreen();
  }
}
```

As long as your app is using `UnifiedHttpClient` (and calling `UnifiedHttpClient().init(...)`), all requests made through the package (both `http` and `dio`) will be recorded and displayed in this screen—no extra setup or external state management required.

---

## Automatic token refresh (401 handling)

This package includes **built-in support** for automatically refreshing expired access tokens when your API returns a 401 (Unauthorized) status. The entire flow—detecting 401, calling your refresh endpoint, saving new tokens, and retrying the original request—happens automatically without any user interaction.

### How it works

```
User calls API → 401 response → Package calls refresh endpoint →
Saves new tokens → Retries original request → Returns data
```

**Your user code simply receives the data—as if nothing happened!**

### Quick setup

```dart
UnifiedHttpClient().init(
  baseUrl: 'https://api.example.com',
  
  // 1. Specify your refresh token endpoint
  refreshTokenEndpoint: '/auth/refresh',
  
  // 2. (Optional) Only refresh for specific endpoints
  refreshWhitelist: ['/posts', '/user', '/profile'],
  
  // 3. Provide refresh token for the refresh request
  getRefreshTokenBody: () {
    final refreshToken = storage.read('refresh_token');
    return {'refreshToken': refreshToken};
  },
  
  // 4. Save new tokens when refresh succeeds
  onTokenRefreshed: (newTokens) async {
    await storage.write('access_token', newTokens['accessToken']);
    await storage.write('refresh_token', newTokens['refreshToken']);
    
    // Update authorization header with new token
    UnifiedHttpClient.setDefaultHeader(
      'Authorization',
      'Bearer ${newTokens['accessToken']}',
    );
  },
  
  // 5. Handle session expiry when refresh fails
  onLogout: () {
    storage.clear();
    Navigator.pushReplacementNamed(context, '/login');
  },
);
```

### Using it in your code

```dart
// Just make the API call—token refresh is automatic!
final result = await UnifiedHttpClient.get('/posts');

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (response) => print('Success: $response'),
);

// Even if the access token expired:
// 1. Package detects 401
// 2. Calls /auth/refresh automatically
// 3. Saves new tokens via onTokenRefreshed callback
// 4. Retries /posts with new token
// 5. Returns the data!
```

### Features

- ✅ **Zero user interaction**: completely automatic
- ✅ **Infinite loop prevention**: won't refresh if refresh endpoint returns 401
- ✅ **Whitelist support**: only refresh for specific endpoints (optional)
- ✅ **Token save callback**: receive new tokens to save to storage
- ✅ **Automatic retry**: original request retried with new token
- ✅ **Logout callback**: handle session expiry gracefully

### Documentation

For a complete guide with advanced examples, see:
- **[REFRESH_TOKEN_GUIDE.md](REFRESH_TOKEN_GUIDE.md)** - Comprehensive usage guide
- **[example/lib/refresh_token_example.dart](example/lib/refresh_token_example.dart)** - Working demo

---

## Example app

See the `example` folder (and its `README.md`) for a minimal working Flutter app that demonstrates:

- initializing the client once in `main.dart`
- switching between `http` and `dio`
- configuring headers globally and per-call
- using interceptors and logging
- handling `Success` / `Failure` results in the UI

