import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paraver/data/dlive_client.dart';

DliveClient _clientReturning(List<int> bytes, String contentType) {
  return DliveClient(
    client: MockClient((_) async {
      return http.Response.bytes(
        Uint8List.fromList(bytes),
        200,
        headers: {'content-type': contentType},
      );
    }),
  );
}

void main() {
  test('decodes UTF-8 pages', () async {
    final client = _clientReturning([
      0xC3,
      0xB1,
      0x41,
    ], 'text/html; charset=UTF-8');
    expect(await client.fetchText('https://example.com'), 'ñA');
  });

  test('decodes ISO-8859-1 pages', () async {
    final client = _clientReturning([
      0xF1,
      0x41,
    ], 'text/html; charset=iso-8859-1');
    expect(await client.fetchText('https://example.com'), 'ñA');
  });

  test('falls back to replacement characters for malformed UTF-8', () async {
    final client = _clientReturning([
      0x41,
      0xFF,
      0x42,
    ], 'text/html; charset=UTF-8');
    final text = await client.fetchText('https://example.com');
    expect(text, startsWith('A'));
    expect(text, endsWith('B'));
    expect(text, contains('\uFFFD'));
  });
}
