## unified_http_client

**unified_http_client** is a Flutter/Dart package that gives you a single, simple API surface for making REST calls using either `http` or `dio` under the hood.

- **Unified API**: call `UnifiedHttpClient.get/post/delete/multipart` and switch between `http` and `dio` with a single flag.
- **Centralized headers**: configure common headers once in `init()`; they are automatically applied to all requests for both `http` and `dio`, with per-call overrides still possible.
- **Unified error model**: instead of throwing, requests return a `Result<Success, Failure>` with a rich `UnifiedHttpClientEnum` error type and messages.
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
    debugPrint('GET failed: ${failure.unifiedHttpClientEnum} - ${failure.message}');
  },
  (body) {
    debugPrint('GET body: $body');
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

## Example app

See the `example` folder (and its `README.md`) for a minimal working Flutter app that demonstrates:

- initializing the client once in `main.dart`
- switching between `http` and `dio`
- configuring headers globally and per-call
- using interceptors and logging
- handling `Success` / `Failure` results in the UI

