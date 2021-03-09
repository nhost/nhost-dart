void debugPrint(Object message) => print('$message');
void warnPrint(Object message) => print('WARN $message');

/// `true` if the nhost.io SDK should print out HTTP request and responses to
/// aid with debugging.
bool debugPrintApiCalls = false;
