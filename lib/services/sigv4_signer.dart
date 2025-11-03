import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class SigV4Signer {
  static String generateSignedUrl({
    required String accessKey,
    required String secretKey,
    required String region,
    required String endpoint,
    String? sessionToken,
  }) {
    final now = DateTime.now().toUtc();
    final amzDate =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}Z';
    final dateStamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    const service = 'iotdevicegateway';
    const algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/$service/aws4_request';

    final canonicalUri = '/mqtt';
    final canonicalQuerystring =
        'X-Amz-Algorithm=$algorithm&X-Amz-Credential=${Uri.encodeComponent('$accessKey/$credentialScope')}&X-Amz-Date=$amzDate&X-Amz-SignedHeaders=host';

    final canonicalHeaders = 'host:$endpoint\n';
    final payloadHash = sha256.convert(utf8.encode('')).toString();
    final canonicalRequest =
        'GET\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeaders\nhost\n$payloadHash';

    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, service);
    final signature =
    Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    var requestUrl =
        'wss://$endpoint/mqtt?$canonicalQuerystring&X-Amz-Signature=$signature';
    if (sessionToken != null && sessionToken.isNotEmpty) {
      requestUrl += '&X-Amz-Security-Token=${Uri.encodeComponent(sessionToken)}';
    }
    return requestUrl;
  }

  static Uint8List _getSignatureKey(
      String key, String dateStamp, String region, String service) {
    final kDate =
    Hmac(sha256, utf8.encode('AWS4$key')).convert(utf8.encode(dateStamp));
    final kRegion =
    Hmac(sha256, kDate.bytes).convert(utf8.encode(region));
    final kService =
    Hmac(sha256, kRegion.bytes).convert(utf8.encode(service));
    final kSigning =
    Hmac(sha256, kService.bytes).convert(utf8.encode('aws4_request'));
    return Uint8List.fromList(kSigning.bytes);
  }
}
