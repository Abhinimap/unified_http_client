A Flutter Package to provide smooth Api call with All Error and Exception handeled.<br>
-  while using package's api request call you don't have to worry about any exception which might occured including PlatformException , FormatException , SocketException.<br>
- Instead of Exception throw this package focus on returning Exxception as Custom Failure class.<br>
- you can use Enum to find out which exception has occured and along with it you get access to default message for those Exception and response body of the api in your UI.<br>

This package also ensure proper network checking before making any APi request for making process fast and improve user experience.<br><br>

## Android Configuration 
On Android, for correct working in release mode, you must add INTERNET & ACCESS_NETWORK_STATE permissions to AndroidManifest.xml, follow the next lines:
    

```
    <manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions for internet_connection_checker -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application
    
```

You can call `InternetConnectionChecker().hasConnection` to get bool Status of Internet Connection Availability, kindly note that this will only return Internet Status not Internet proivder device info like wifi, mobile,etc.



```
 if (!await InternetConnectionChecker().hasConnection) {
        CustomSnackbar().showNoInternetSnackbar();
      }     
```


 You can use this to show Alert Dialog or run some code 



 ## use of package for API Call

let's setup project to use HTTP and DIO REST API call

```dart

void main() async {
  // set whether to use http or Dio, by default it will use HTTP
  UnifiedHttpClient().init(usehttp: false);

  // setup DIO
  PackageDio.addInterceptors([]);
  PackageDio.setBaseOptions(
    // you can set more option inside it
    // but here i am setting base url to use for api calls
      baseUrl: 'https://66c45adfb026f3cc6ceefd10.mockapi.io'
  );
  
  // this will add base options and interceptors to dio client
  // must be called to setup dio 
  PackageDio.setUpDio();


  // setup HTTP
  // you can define your own http client (optional)
  PackageHttp.setupClient(client:http.Client() );
  // necessary to pass host (base url) to make http request
  PackageHttp.setup(host: '66c45adfb026f3cc6ceefd10.mockapi.io',prefix: '');

  runApp(const MyApp());
}

```

Initialize Snackbar after MaterialApp is configured.

 ```
  @override
  Widget build(BuildContext context) {
    
    // Make sure to call init function before using api call from UnifiedHttpClient class
    // context is needed to show No internet Snackbar,
    // Otherwise Snackbar will not appear when device is not connected to internet and api request is made
    CustomSnackbar().init(context);

    return Scaffold(
      appBar: AppBar(
```

Calling APi using UnifiedHttpClient class
use `UnifiedHttpClient().get(url)` to make GET request call
and get response as Result class, use Switch statement to iterate through Success or Failure

Below is sample code for how the request are made and how response are manipulated

```dart

  Future<void> callApi() async {
    clear();
    final Result response = await UnifiedHttpClient.get(
      '/data/postdata',
    );
    // await UnifiedHttpClient.post('/data/postdata', body: '');
    switch (response) {
      case Success(value: dynamic data):

        result.value = UnifiedHttpClient.useHttp
            ? (await json.decode(data.body)).toString()
            : data.data.toString();
        debugPrint('result  :$data');
        break;
      case Failure(error: ErrorResponse resp):
        debugPrint('the error occured : ${resp.UnifiedHttpClientEnum.name}');

        // Holds message regarding error
        defMesg.value = resp.errorResponseHolder.defaultMessage;
        customMesg.value = resp.errorResponseHolder.customMessage ?? '';
        
        // give error type 
        // such as badrequest , InternalServerError,etc..
        errorEnum.value = resp.UnifiedHttpClientEnum.name;
        
        // if error caught by package such as statusCode >300 
        // response body of that request is stored here
        responsebody.value = resp.errorResponseHolder.responseBody ?? '';
        
        // pass through enums of failure to customize uses according to failures
        switch (resp.UnifiedHttpClientEnum) {
          case UnifiedHttpClientEnum.badRequestError:
            debugPrint(
                'the status is 400 , Bad request from client side :resbody:${resp.errorResponseHolder.responseBody}\n mesg :${resp.errorResponseHolder.defaultMessage} ');
            break;
          case UnifiedHttpClientEnum.notFoundError:
            debugPrint('404 , Api endpoint not found');
            break;
          default:
            debugPrint(
                'Not matched in main cases : ${resp.UnifiedHttpClientEnum.name} ${resp.errorResponseHolder.defaultMessage}');
        }
        break;
      default:
        debugPrint('Api Response not matched with any cases ');
    }
  }
```# unified_http_client
# unified_http_client
