import 'package:http/http.dart' as http;

/// An HTTP request whose body is supplied via a [Stream].
class StreamWrappingRequest extends http.BaseRequest {
  StreamWrappingRequest(String method, Uri url, this.bodyStream)
      : super(method, url);

  final Stream<List<int>> bodyStream;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(bodyStream);
  }
}
