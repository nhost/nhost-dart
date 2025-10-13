import 'package:http/http.dart' as http;

/// An HTTP request whose body is supplied via a [Stream].
class StreamWrappingRequest extends http.BaseRequest {
  StreamWrappingRequest(super.method, super.url, this.bodyStream);

  final Stream<List<int>> bodyStream;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(bodyStream);
  }
}
