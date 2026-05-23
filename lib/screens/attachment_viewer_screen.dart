import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachmentViewerScreen extends StatelessWidget {
  final String url;
  final String? label;

  const AttachmentViewerScreen({super.key, required this.url, this.label});

  static bool isImage(String url) {
    final u = url.toLowerCase();
    if (u.contains('/image/upload/')) return true;
    return u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.gif') ||
        u.endsWith('.webp') ||
        u.endsWith('.bmp') ||
        u.endsWith('.heic');
  }

  static bool isVideo(String url) {
    final u = url.toLowerCase();
    if (u.contains('/video/upload/')) return true;
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.avi') ||
        u.endsWith('.mkv') ||
        u.endsWith('.webm');
  }

  Future<void> _launchUrl(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showError(context, 'Invalid URL');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) _showError(context, 'Could not open file');
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isImage(url)) {
      return _ImageViewer(url: url, label: label);
    }
    // Videos and all other files — open externally
    return _ExternalFileViewer(
      url: url,
      label: label,
      isVideo: isVideo(url),
      onLaunch: () => _launchUrl(context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen image viewer with pinch-to-zoom
// ─────────────────────────────────────────────────────────────────────────────
class _ImageViewer extends StatelessWidget {
  final String url;
  final String? label;

  const _ImageViewer({required this.url, this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: label != null
            ? Text(
                label!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const Text(
                'Attachment',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white),
              ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
            onPressed: () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
          ),
        ),
        errorBuilder: (_, __, ___) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 56, color: Colors.white54),
              SizedBox(height: 12),
              Text(
                'Could not load image',
                style: TextStyle(fontFamily: 'Inter', color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Launcher screen for videos and other file types
// ─────────────────────────────────────────────────────────────────────────────
class _ExternalFileViewer extends StatefulWidget {
  final String url;
  final String? label;
  final bool isVideo;
  final Future<void> Function() onLaunch;

  const _ExternalFileViewer({
    required this.url,
    required this.label,
    required this.isVideo,
    required this.onLaunch,
  });

  @override
  State<_ExternalFileViewer> createState() => _ExternalFileViewerState();
}

class _ExternalFileViewerState extends State<_ExternalFileViewer> {
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    // Auto-launch on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
  }

  Future<void> _launch() async {
    setState(() => _launching = true);
    await widget.onLaunch();
    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isVideo
        ? Icons.play_circle_outline_rounded
        : Icons.insert_drive_file_outlined;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.white54),
            const SizedBox(height: 20),
            Text(
              widget.label ?? (widget.isVideo ? 'Video' : 'File'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Opening with your device\'s default app…',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            if (_launching)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1BA3A1)),
              )
            else
              ElevatedButton.icon(
                onPressed: _launch,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text(
                  'Open again',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1BA3A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
