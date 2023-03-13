import 'package:logging/logging.dart';

/// Logs package events
final log = Logger('nhost.dart');

/// When `true`, errors will be printed to the console via `Logger.root` (from
/// the `logging` package). When `false`, no logging will take place.
///
/// Nhost uses the `logging` package, which means that your application can be
/// configured to change what is logged, and where it is logged to. If you are
/// configuring logging yourself, it probably makes sense to set this flag to
/// `false`.
bool debugLogNhostErrorsToConsole = true;

/// Initializes logging if it hasn't already been.
void initializeLogging() {
  if (_loggingInitialized || !debugLogNhostErrorsToConsole) {
    return;
  }

  Logger.root.onRecord.listen((record) {
    if (debugLogNhostErrorsToConsole &&
        record.level >= Level.SEVERE &&
        record.loggerName.startsWith('nhost.')) {
      print('${record.time.toIso8601String()} [nhost] ${record.message}');
      if (record.error != null) print('${record.error}');
      if (record.stackTrace != null) print(record.stackTrace);
    }
  });
  _loggingInitialized = true;
}

/// `true` if we've created an error logger
bool _loggingInitialized = false;
