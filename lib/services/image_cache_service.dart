import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  late Directory _cacheDir;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/image_cache');
    
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    
    _isInitialized = true;
  }

  // Check if device is connected to the internet
  Future<bool> get isConnected async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  // Get cached image path
  String _getCachedImagePath(String imageUrl) {
    final fileName = imageUrl.split('/').last.split('?').first;
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
    return '${_cacheDir.path}/$sanitizedFileName';
  }

  // Cache image from URL
  Future<String?> cacheImage(String imageUrl) async {
    if (!_isInitialized) await init();
    
    try {
      final cachedPath = _getCachedImagePath(imageUrl);
      final cachedFile = File(cachedPath);
      
      // If already cached, return the path
      if (await cachedFile.exists()) {
        return cachedPath;
      }
      
      // Only download if online
      if (!(await isConnected)) {
        return null;
      }

      if (kIsWeb) {
        // Web implementation
        try {
          final response = await html.HttpRequest.request(
            imageUrl,
            responseType: 'blob',
          );
          
          if (response.status == 200) {
            // For web, we'll store in memory cache instead of file system
            return imageUrl; // Return original URL for web
          }
        } catch (e) {
          debugPrint('Error caching image on web: $e');
          return null;
        }
      } else {
        // Mobile implementation
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(imageUrl));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          await cachedFile.writeAsBytes(bytes);
          return cachedPath;
        }
        
        httpClient.close();
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
    }
    
    return null;
  }

  // Get cached image or return null if not available
  Future<String?> getCachedImagePath(String imageUrl) async {
    if (!_isInitialized) await init();
    
    if (kIsWeb) {
      // For web, check if we can access the URL
      if (await isConnected) {
        return imageUrl;
      }
      return null;
    }
    
    final cachedPath = _getCachedImagePath(imageUrl);
    final cachedFile = File(cachedPath);
    
    if (await cachedFile.exists()) {
      return cachedPath;
    }
    
    return null;
  }

  // Get ImageProvider for cached or network image
  Future<ImageProvider?> getImageProvider(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    
    if (kIsWeb) {
      // For web, always use NetworkImage when online
      if (await isConnected) {
        return NetworkImage(imageUrl);
      }
      return null;
    }
    
    // Try to get cached image first
    final cachedPath = await getCachedImagePath(imageUrl);
    if (cachedPath != null) {
      return FileImage(File(cachedPath));
    }
    
    // If online, cache the image and return NetworkImage
    if (await isConnected) {
      // Start caching in background
      cacheImage(imageUrl);
      return NetworkImage(imageUrl);
    }
    
    return null;
  }

  // Clear all cached images
  Future<void> clearCache() async {
    if (!_isInitialized) await init();
    
    if (kIsWeb) return; // No file cache on web
    
    try {
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  // Get cache size
  Future<int> getCacheSize() async {
    if (!_isInitialized) await init();
    
    if (kIsWeb) return 0; // No file cache on web
    
    try {
      if (!await _cacheDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in _cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }
}