import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../core/constants/api_constants.dart';

class GtfsCacheManager {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'gtfs_cache',
      stalePeriod: ApiConstants.staticGtfsCacheDuration,
      maxNrOfCacheObjects: 10,
    ),
  );

  /// Get cached file
  Future<File?> getCachedFile(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download and cache file
  Future<File> downloadAndCache(String url) async {
    return await _cacheManager.getSingleFile(url);
  }

  /// Check if file is cached
  Future<bool> isCached(String url) async {
    final file = await getCachedFile(url);
    return file != null;
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Remove specific cached file
  Future<void> removeCachedFile(String url) async {
    await _cacheManager.removeFile(url);
  }
}

