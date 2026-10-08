import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_choice_mobile/document_download.dart';

class Headers implements HttpHeaders {
  Headers({String? mime, String? location})
    : contentType = mime == null ? null : ContentType.parse(mime) {
    if (location != null) values['location'] = location;
  }
  final values = <String, String>{};
  @override
  ContentType? contentType;
  @override
  String? value(String name) => values[name.toLowerCase()];
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      values[name.toLowerCase()] = value.toString();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Response extends Stream<List<int>> implements HttpClientResponse {
  Response(
    this.statusCode,
    this.headers, {
    this.body = const [37, 80, 68, 70],
    int? length,
  }) : contentLength = length ?? body.length;
  final List<int> body;
  @override
  final int statusCode;
  @override
  final Headers headers;
  @override
  final int contentLength;
  @override
  bool get isRedirect => [301, 302, 303, 307, 308].contains(statusCode);
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(body).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Request implements HttpClientRequest {
  Request(this.response);
  final Response response;
  @override
  final Headers headers = Headers();
  @override
  bool followRedirects = true;
  @override
  Future<HttpClientResponse> close() async => response;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Client implements HttpClient {
  Client(this.responses);
  final List<Response> responses;
  final requests = <Request>[];
  final urls = <Uri>[];
  bool closed = false;
  @override
  Duration? connectionTimeout;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    urls.add(url);
    final request = Request(responses[requests.length]);
    requests.add(request);
    return request;
  }

  @override
  void close({bool force = false}) => closed = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  final exports = <Map<Object?, Object?>>[];
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('sc-download-test-');
    exports.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DocumentDownload.channel, (
          MethodCall call,
        ) async {
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          expect(await File(args['path'] as String).readAsBytes(), [
            37,
            80,
            68,
            70,
          ]);
          exports.add(args);
          return 'content://media/external/downloads/123';
        });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DocumentDownload.channel, null);
    await temporary.delete(recursive: true);
  });
  Future<SavedDocument> save(Client client) =>
      DocumentDownload(
        clientFactory: () => client,
        temporaryDirectory: () async => temporary,
      ).save(
        Uri.parse('https://mobile.justsmartchoice.com/download/contract'),
        cookie: 'session=test-fixture',
        userAgent: 'TestWebView',
      );

  test('Authenticated PDF exports successfully and removes its private temporary file', () async {
    final client = Client([Response(200, Headers(mime: 'application/pdf'))]);
    final result = await save(client);
    expect(result.name, 'CRM-document.pdf');
    expect(result.uri, startsWith('content://media/'));
    expect(
      client.requests.single.headers.value('cookie'),
      'session=test-fixture',
    );
    expect(client.requests.single.followRedirects, isFalse);
    expect(exports, hasLength(1));
    expect(await temporary.list().toList(), isEmpty);
    expect(client.closed, isTrue);
  });
  test('Cross-host redirect is refused before another request can transmit cookies', () async {
    final client = Client([
      Response(
        302,
        Headers(location: 'https://crm.justsmartchoice.com/download/pdf'),
      ),
    ]);
    await expectLater(save(client), throwsFormatException);
    expect(client.urls, hasLength(1));
    expect(exports, isEmpty);
    expect(client.closed, isTrue);
  });
  test(
    'Same-origin redirects retain auth without automatic redirect forwarding',
    () async {
      final client = Client([
        Response(302, Headers(location: '/download/ready')),
        Response(200, Headers(mime: 'application/pdf')),
      ]);
      await save(client);
      expect(client.urls.last.path, '/download/ready');
      expect(client.requests.every((r) => !r.followRedirects), isTrue);
      expect(
        client.requests.last.headers.value('cookie'),
        'session=test-fixture',
      );
    },
  );
  test('Login HTML, server failures, empty and oversized responses are not exported', () async {
    for (final response in [
      Response(200, Headers(mime: 'text/html')),
      Response(500, Headers()),
      Response(200, Headers(mime: 'application/pdf'), body: []),
      Response(
        200,
        Headers(mime: 'application/pdf'),
        length: DocumentDownload.maxBytes + 1,
      ),
    ]) {
      await expectLater(save(Client([response])), throwsFormatException);
      expect(exports, isEmpty);
      expect(await temporary.list().toList(), isEmpty);
    }
  });
}
