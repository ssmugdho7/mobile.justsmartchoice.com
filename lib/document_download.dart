import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'navigation_policy.dart';

class SavedDocument {
  const SavedDocument(this.uri, this.name, this.mimeType);
  final String uri, name, mimeType;
}

class DocumentDownload {
  DocumentDownload({
    HttpClient Function()? clientFactory,
    Future<Directory> Function()? temporaryDirectory,
  }) : _clientFactory = clientFactory ?? HttpClient.new,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;
  final HttpClient Function() _clientFactory;
  final Future<Directory> Function() _temporaryDirectory;
  static const channel = MethodChannel('com.justsmartchoice.mobile/documents');
  static const maxBytes = 100 * 1024 * 1024;
  Future<SavedDocument> savePdfBytes(Uint8List bytes, String name) async {
    if (bytes.length < 5 ||
        bytes.length > 10 * 1024 * 1024 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('Invalid PDF document.');
    }
    final directory = await _temporaryDirectory();
    final file = File(
      '${directory.path}/crm-${DateTime.now().microsecondsSinceEpoch}.download',
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
      final safe = safeName(name, 'application/pdf');
      final uri = await channel.invokeMethod<String>('saveDownload', {
        'path': file.path,
        'name': safe,
        'mime': 'application/pdf',
      });
      if (uri == null) throw const FormatException('Unable to save PDF.');
      return SavedDocument(uri, safe, 'application/pdf');
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  static String safeName(String? suggested, String mime) {
    final name = (suggested ?? '')
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'), '_')
        .trim();
    if (name.isNotEmpty && name != '.' && name != '..') {
      return name.length > 120 ? name.substring(name.length - 120) : name;
    }
    return mime == 'application/pdf' ? 'CRM-document.pdf' : 'CRM-document';
  }

  Future<SavedDocument> save(
    Uri uri, {
    required String cookie,
    required String userAgent,
    String? filename,
  }) async {
    if (!NavigationPolicy.isCrm(uri)) {
      throw const FormatException('Only mobile CRM documents can be saved.');
    }
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 20);
    File? file;
    IOSink? sink;
    try {
      var current = uri;
      HttpClientResponse? response;
      for (var redirects = 0; redirects <= 5; redirects++) {
        final request = await client.getUrl(current);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.cookieHeader, cookie);
        request.headers.set(HttpHeaders.userAgentHeader, userAgent);
        response = await request.close().timeout(const Duration(seconds: 30));
        if (!response.isRedirect) break;
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null) {
          throw const FormatException('Invalid document redirect.');
        }
        current = current.resolve(location);
        if (!NavigationPolicy.isCrm(current)) {
          throw const FormatException('Document left the mobile CRM.');
        }
        response = null;
      }
      if (response == null || response.statusCode != HttpStatus.ok) {
        throw const FormatException('Document unavailable.');
      }
      final mime =
          response.headers.contentType?.mimeType ?? 'application/octet-stream';
      if (mime == 'text/html' || mime == 'application/json') {
        throw const FormatException('Sign in again before downloading.');
      }
      if (response.contentLength > maxBytes) {
        throw const FormatException('Document is too large.');
      }
      final name = safeName(filename, mime);
      final temporary = await _temporaryDirectory();
      file = File(
        '${temporary.path}/crm-${DateTime.now().microsecondsSinceEpoch}.download',
      );
      sink = file.openWrite();
      var bytes = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        bytes += chunk.length;
        if (bytes > maxBytes) {
          throw const FormatException('Document size limit exceeded.');
        }
        sink.add(chunk);
      }
      if (bytes == 0) throw const FormatException('The document is empty.');
      await sink.flush();
      await sink.close();
      sink = null;
      final result = await channel.invokeMethod<String>('saveDownload', {
        'path': file.path,
        'name': name,
        'mime': mime,
      });
      if (result == null) {
        throw const FormatException('Unable to save document.');
      }
      return SavedDocument(result, name, mime);
    } finally {
      client.close(force: true);
      await sink?.close();
      if (file != null && await file.exists()) await file.delete();
    }
  }

  Future<void> open(SavedDocument document) => channel.invokeMethod<void>(
    'openDownload',
    {'uri': document.uri, 'mime': document.mimeType},
  );
}
