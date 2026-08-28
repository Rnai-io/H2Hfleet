import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

void downloadFile(String filename, String content, String mimeType) {
  // Mobile / Desktop fallback
}

void printHtmlReport(String htmlContent) {
  // Mobile / Desktop fallback
}

void openExternalUrl(String url) {
  try {
    final uri = Uri.parse(url);
    launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) {
      debugPrint('Error launching url $url: $e');
      return false;
    });
  } catch (e) {
    debugPrint('Could not parse/launch url $url: $e');
  }
}
