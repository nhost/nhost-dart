import 'dart:async';

/// Used to suppress irrelevant prints from the GraphQL library
FutureOr<void> Function() silencePrints(FutureOr<void> Function() testFn) {
  return () {
    return Zone.current
        .fork(specification: ZoneSpecification(print: (_, __, ___, ____) {}))
        .run(() => testFn());
  };
}
