import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Convert YouTube URL to embeddable format
    String embedUrl = _getYouTubeEmbedUrl(widget.videoUrl);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  String _getYouTubeEmbedUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return url;

      String? videoId;

      if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }

      if (videoId != null && videoId.isNotEmpty) {
        videoId = videoId.split('&')[0].split('?')[0];
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1';
      }
    } catch (e) {
      debugPrint('Error converting to embed URL: $e');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.videoTitle,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
