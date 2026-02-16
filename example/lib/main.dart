import 'package:example/controller.dart';
import 'package:example/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unified_http_client/unified_http_client.dart';
import 'package:unified_http_client/unified_interceptor.dart';

void main() async {
  /// Single entry point: pick http/dio, base url, logging and extra interceptors
  UnifiedHttpClient().init(
      usehttp: false, // set true to use the http package instead of dio
      baseUrl: 'https://69de-103-143-8-45.ngrok-free.app',
      showLogs: true,
      interceptors: [
        // optional extra interceptor to inject headers or inspect payloads
        ApiInterceptor(
          onRequestOverride: (req) {
            req.headers['X-Demo-Header'] = 'demo';
            return req;
          },
        ),
      ],
      onLogout: () {
        debugPrint("Logout callback triggered - User session expired");
        // TODO: Clear local storage, navigate to login screen
      },
      refreshWhitelist: ['posts'], // Only refresh token for these endpoints
      refreshTokenEndpoint: '/auth/refresh',
      
      // Callback to provide refresh token body
      getRefreshTokenBody: () {
        // TODO: Get refresh token from local storage
        final refreshToken = "your_refresh_token_from_storage";
        return {
          'refreshToken': refreshToken,
        };
      },
      
      // Callback when new tokens are received after refresh
      onTokenRefreshed: (newTokens) async {
        debugPrint("New tokens received: $newTokens");
        
        // Extract and save new tokens
        final newAccessToken = newTokens['accessToken'];
        // final newRefreshToken = newTokens['refreshToken'];
        
        // TODO: Save to local storage (SharedPreferences, Hive, etc.)
        // await storage.write('access_token', newAccessToken);
        // await storage.write('refresh_token', newRefreshToken);
        
        // Update the default headers with new access token
        if (newAccessToken != null) {
          UnifiedHttpClient.setDefaultHeader('Authorization', 'Bearer $newAccessToken');
        }
        
        debugPrint("Tokens saved successfully");
      });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isConnected = false;

  // enter your own url to test
  // String url = 'https://mocki.io/v1/cbde42ba-5b27-4530-8fc5-2d3aa669ccbd';
  String url = 'https://69de-103-143-8-45.ngrok-free.app/posts';

  final cont = Get.put(ApiController());
  @override
  Widget build(BuildContext context) {
    // Make sure to call init function before using api call from ErrorHandelerFlutter class
    // context is needed to show No internet Snackbar
    CustomSnackbar().init(context);

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Internet Connection: ${isConnected ? 'Connected' : 'Not Connected'}',
              ),
              if (cont.errorEnum.isNotEmpty)
                Obx(
                  () => Text(
                    cont.errorEnum.value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              Obx(
                () => cont.defMesg.isNotEmpty
                    ? Text(
                        cont.defMesg.value,
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => cont.customMesg.isNotEmpty
                    ? Text(
                        cont.customMesg.value,
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => cont.responsebody.isNotEmpty
                    ? Text(
                        cont.responsebody.value,
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => cont.result.isNotEmpty
                    ? Text(
                        cont.result.value,
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(
                height: 30,
              ),
              ElevatedButton(
                  onPressed: () async {
                    await cont.callApi();
                  },
                  child: const Text('Call Api'))
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final connected = await InternetConnectionChecker().hasConnection;
          setState(() {
            isConnected = connected;
          });
        },
        tooltip: 'Internet Connection',
        child: const Icon(Icons.wifi),
      ),
    );
  }
}
