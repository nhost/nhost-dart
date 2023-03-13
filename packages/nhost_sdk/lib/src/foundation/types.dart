import 'package:http/http.dart' as http;

/// Signature for callbacks that respond to token changes.
///
/// Registered via [HasuraAuthClient.addTokenChangedCallback].
typedef TokenChangedCallback = void Function();

/// Signature for callbacks that respond to authentication changes.
///
/// Registered via [HasuraAuthClient.addAuthStateChangedCallback].
typedef AuthStateChangedCallback = void Function(
  AuthenticationState authenticationState,
);

/// Signature for callbacks that respond to session refresh failures.
///
/// Registered via [HasuraAuthClient.addSessionRefreshFailedCallback].
typedef SessionRefreshFailedCallback = void Function(
    Exception error, StackTrace stackTrace);

/// Signature for functions that remove their associated callback when called.
typedef UnsubscribeDelegate = void Function();

/// Identifies the refresh token in the [HasuraAuthClient]'s [AuthStore] instance.
const refreshTokenClientStorageKey = 'nhostRefreshToken';

/// The query parameter name for the refresh token provided during OAuth
/// provider-based sign-ins.
const refreshTokenQueryParamName = 'refreshToken';

/// Signature for callbacks that receive the upload progress of
/// [ApiClient.postMultipart] requests.
typedef UploadProgressCallback = void Function(
  http.MultipartRequest request,
  int bytesUploaded,
  int bytesTotal,
);

enum AuthenticationState {
  inProgress,
  signedIn,
  signedOut,
}
