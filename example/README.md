# Unified HTTP Client Example

This sample shows how to initialize the unified client once and use the same API surface for both `dio` and `http` under the hood.

Key steps:

1) Call `UnifiedHttpClient().init(...)` early in `main.dart`
```
UnifiedHttpClient().init(
  usehttp: false, // switch to true to use the http client instead of dio
  baseUrl: 'https://66c45adfb026f3cc6ceefd10.mockapi.io',
  showLogs: true,
  interceptors: [
    ApiInterceptor(
      onRequestOverride: (req) {
        req.headers['X-Demo-Header'] = 'demo';
        return req;
      },
    ),
  ],
);
```

2) Use the static helpers from `UnifiedHttpClient` anywhere in the app:
```
final result = await UnifiedHttpClient.get('/data/postdata');
```

No direct `dio` or `http` imports are needed in your app code—only the unified package. The default `ApiInterceptor` can log traffic, and you can add more interceptors to customize requests/responses/errors.
