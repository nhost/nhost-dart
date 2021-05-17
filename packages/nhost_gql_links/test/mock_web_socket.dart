import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockWebSocket extends Mock implements WebSocketChannel {
  MockWebSocket.connect() : _responseController = StreamController.broadcast() {
    _requestController = StreamController<String>.broadcast();
    _requestSink = MockWebSocketSink(_requestController, onClose: () async {
      await _responseController.close();
    });
    _requestController.stream.listen((event) {
      payloads.add(event);

      final message = jsonDecode(event);
      if (message['type'] == 'connection_init') {
        _responseController.add('{"type": "connection_ack"}');
      } else {
        _responseController.add(
            '{"id": "${message['id']}", "type": "data", "payload": {"data": {}}}');
      }
    });
  }

  final StreamController _responseController;
  late final StreamController _requestController;
  late final MockWebSocketSink _requestSink;

  final List<String> payloads = [];

  @override
  Stream get stream => _responseController.stream;

  @override
  WebSocketSink get sink => _requestSink;

  void tearDown() {
    _requestController.close();
  }

  @override
  void pipe(StreamChannel other) {}
}

class MockWebSocketSink extends DelegatingStreamSink implements WebSocketSink {
  MockWebSocketSink(this.sink, {required this.onClose}) : super(sink);
  final StreamSink sink;
  final Future<void> Function() onClose;
  var isClosed = false;

  @override
  Future close([int? closeCode, String? closeReason]) {
    return super.close().then((res) async {
      await onClose();
      return res;
    });
  }
}
