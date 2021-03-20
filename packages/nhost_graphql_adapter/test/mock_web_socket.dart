import 'dart:async';

import 'package:async/async.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocket extends Mock implements WebSocketChannel {
  MockWebSocket.connect() : controller = StreamController<String>.broadcast() {
    controller.stream.listen((event) {
      payloads.add(event);
    });
  }

  final StreamController controller;
  final List<String> payloads = [];

  @override
  Stream get stream => controller.stream;

  @override
  WebSocketSink get sink => _sink ??= MockWebSocketSink(controller.sink);
  MockWebSocketSink _sink;

  void tearDown() {
    controller.close();
  }

  @override
  void pipe(StreamChannel other) {}
}

class MockWebSocketSink extends DelegatingStreamSink implements WebSocketSink {
  final StreamSink sink;

  MockWebSocketSink(this.sink) : super(sink);

  @override
  Future close([int closeCode, String closeReason]) {
    return super.close();
  }
}
