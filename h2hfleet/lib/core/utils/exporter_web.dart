// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

void downloadFile(String filename, String content, String mimeType) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

void printHtmlReport(String htmlContent) {
  // Inject auto-print script into HTML content
  final autoPrintHtml = htmlContent.replaceFirst(
    '</body>',
    '''
    <script>
      window.onload = function() {
        setTimeout(function() {
          window.print();
        }, 400);
      };
    </script>
    </body>
    ''',
  );

  final bytes = utf8.encode(autoPrintHtml);
  final blob = html.Blob([bytes], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}

void openExternalUrl(String url) {
  html.window.open(url, '_blank');
}
