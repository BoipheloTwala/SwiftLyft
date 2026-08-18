import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Cache manager for data caching, image optimization, and lazy loading
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache configuration
  static const int _maxMemoryCacheSize = 100; // Maximum items in memory cache
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  static const Duration _imageCacheExpiry = Duration(days: 7);

  /// Initialize cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanupExpiredCache();
  }

  /// Cache data with expiration
  Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final expiryTime = DateTime.now().add(expiry ?? _defaultCacheExpiry);
      final cacheEntry = {
        'data': data,
        'expiry': expiryTime.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Store in memory cache
      _memoryCache[key] = cacheEntry;
      _cacheTimestamps[key] = DateTime.now();

      // Store in persistent cache
      await _prefs?.setString('cache_$key', jsonEncode(cacheEntry));

      // Cleanup if memory cache is full
      if (_memoryCache.length > _maxMemoryCacheSize) {
        _cleanupMemoryCache();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cache data for key $key: $e');
      }
    }
  }

  /// Retrieve cached data
  Future<T?> getCachedData<T>(String key) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final entry = _memoryCache[key] as Map<String, dynamic>;
        final expiry = DateTime.parse(entry['expiry']);
        
        if (DateTime.now().isBefore(expiry)) {
          return entry['data'] as T;
        } else {
          // Remove expired entry
          _memoryCache.remove(key);
          _cacheTimestamps.remove(key);
        }
      }

      // Check persistent cache
      final cachedString = _prefs?.getString('cache_$key');
      if (cachedString != null) {
        final entry = jsonDecode(cachedString) as Map<String, dynamic>;
        final expiry = DateTime.parse(entry['expiry']);
        
        if (DateTime.now().isBefore(expiry)) {
          // Add to memory cache
          _memoryCache[key] = entry;
          _cacheTimestamps[key] = DateTime.now();
          return entry['data'] as T;
        } else {
          // Remove expired entry
          await _prefs?.remove('cache_$key');
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to retrieve cached data for key $key: $e');
      }
      return null;
    }
  }

  /// Cache image data
  Future<void> cacheImage(String key, Uint8List imageData) async {
    await cacheData(
      'image_$key',
      base64Encode(imageData),
      expiry: _imageCacheExpiry,
    );
  }

  /// Get cached image
  Future<Uint8List?> getCachedImage(String key) async {
    final cachedString = await getCachedData<String>('image_$key');
    if (cachedString != null) {
      try {
        return base64Decode(cachedString);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to decode cached image for key $key: $e');
        }
      }
    }
    return null;
  }

  /// Cache API response
  Future<void> cacheApiResponse(String endpoint, Map<String, dynamic> response) async {
    final key = 'api_${_generateHash(endpoint)}';
    await cacheData(key, response);
  }

  /// Get cached API response
  Future<Map<String, dynamic>?> getCachedApiResponse(String endpoint) async {
    final key = 'api_${_generateHash(endpoint)}';
    return await getCachedData<Map<String, dynamic>>(key);
  }

  /// Cache user preferences
  Future<void> cacheUserPreferences(Map<String, dynamic> preferences) async {
    await cacheData('user_preferences', preferences);
  }

  /// Get cached user preferences
  Future<Map<String, dynamic>?> getCachedUserPreferences() async {
    return await getCachedData<Map<String, dynamic>>('user_preferences');
  }

  /// Cache search results
  Future<void> cacheSearchResults(String query, List<dynamic> results) async {
    final key = 'search_${_generateHash(query)}';
    await cacheData(key, results, expiry: const Duration(hours: 1));
  }

  /// Get cached search results
  Future<List<dynamic>?> getCachedSearchResults(String query) async {
    final key = 'search_${_generateHash(query)}';
    return await getCachedData<List<dynamic>>(key);
  }

  /// Clear specific cache entry
  Future<void> clearCache(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    await _prefs?.remove('cache_$key');
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    
    final keys = _prefs?.getKeys() ?? {};
    final cacheKeys = keys.where((key) => key.startsWith('cache_'));
    for (final key in cacheKeys) {
      await _prefs?.remove(key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'maxMemoryCacheSize': _maxMemoryCacheSize,
      'cacheKeys': _memoryCache.keys.toList(),
      'oldestEntry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
      'newestEntry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  /// Cleanup expired cache entries
  Future<void> _cleanupExpiredCache() async {
    try {
      final keys = _prefs?.getKeys() ?? {};
      final cacheKeys = keys.where((key) => key.startsWith('cache_'));
      
      for (final key in cacheKeys) {
        final cachedString = _prefs?.getString(key);
        if (cachedString != null) {
          try {
            final entry = jsonDecode(cachedString) as Map<String, dynamic>;
            final expiry = DateTime.parse(entry['expiry']);
            
            if (DateTime.now().isAfter(expiry)) {
              await _prefs?.remove(key);
            }
          } catch (e) {
            // Remove invalid cache entries
            await _prefs?.remove(key);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup expired cache: $e');
      }
    }
  }

  /// Cleanup memory cache (remove oldest entries)
  void _cleanupMemoryCache() {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;

    // Sort by timestamp and remove oldest entries
    final sortedKeys = _cacheTimestamps.keys.toList()
      ..sort((a, b) => _cacheTimestamps[a]!.compareTo(_cacheTimestamps[b]!));

    final keysToRemove = sortedKeys.take(_memoryCache.length - _maxMemoryCacheSize);
    
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Generate hash for cache keys
  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = bytes.fold<int>(0, (hash, byte) => ((hash << 5) - hash + byte) & 0xFFFFFFFF);
    return digest.toRadixString(16);
  }
}

/// Lazy loading manager for pagination and progressive loading
class LazyLoadingManager {
  static final LazyLoadingManager _instance = LazyLoadingManager._internal();
  factory LazyLoadingManager() => _instance;
  LazyLoadingManager._internal();

  final Map<String, List<dynamic>> _loadedData = {};
  final Map<String, int> _currentPages = {};
  final Map<String, bool> _hasMoreData = {};
  final Map<String, bool> _isLoading = {};

  /// Load data with pagination
  Future<List<dynamic>> loadDataWithPagination({
    required String key,
    required Future<List<dynamic>> Function(int page, int pageSize) dataLoader,
    int pageSize = AppConstants.defaultPageSize,
    bool refresh = false,
  }) async {
    if (_isLoading[key] == true) {
      return _loadedData[key] ?? [];
    }

    if (refresh) {
      _loadedData[key] = [];
      _currentPages[key] = 0;
      _hasMoreData[key] = true;
    }

    if (_hasMoreData[key] != true) {
      return _loadedData[key] ?? [];
    }

    _isLoading[key] = true;

    try {
      final currentPage = (_currentPages[key] ?? 0) + 1;
      final newData = await dataLoader(currentPage, pageSize);

      if (newData.isEmpty) {
        _hasMoreData[key] = false;
      } else {
        _loadedData[key] = [...(_loadedData[key] ?? []), ...newData];
        _currentPages[key] = currentPage;
        _hasMoreData[key] = newData.length >= pageSize;
      }

      return _loadedData[key] ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load data for key $key: $e');
      }
      return _loadedData[key] ?? [];
    } finally {
      _isLoading[key] = false;
    }
  }

  /// Check if more data is available
  bool hasMoreData(String key) {
    return _hasMoreData[key] ?? false;
  }

  /// Check if currently loading
  bool isLoading(String key) {
    return _isLoading[key] ?? false;
  }

  /// Get current data
  List<dynamic> getCurrentData(String key) {
    return _loadedData[key] ?? [];
  }

  /// Clear data for specific key
  void clearData(String key) {
    _loadedData.remove(key);
    _currentPages.remove(key);
    _hasMoreData.remove(key);
    _isLoading.remove(key);
  }

  /// Clear all data
  void clearAllData() {
    _loadedData.clear();
    _currentPages.clear();
    _hasMoreData.clear();
    _isLoading.clear();
  }
}

/// Image optimization utilities
class ImageOptimizer {
  /// Optimize image for web display
  static Future<Uint8List> optimizeImageForWeb(
    Uint8List imageData, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    // In a real app, use image processing library like image package
    // For now, return original data
    return imageData;
  }

  /// Generate responsive image URLs
  static String getResponsiveImageUrl(String baseUrl, {int? width, int? height}) {
    if (width != null && height != null) {
      return '$baseUrl?w=$width&h=$height&fit=crop';
    } else if (width != null) {
      return '$baseUrl?w=$width&fit=scale';
    } else if (height != null) {
      return '$baseUrl?h=$height&fit=scale';
    }
    return baseUrl;
  }

  /// Get image placeholder
  static String getImagePlaceholder({int width = 300, int height = 200}) {
    return 'https://via.placeholder.com/$width x $height/f0f0f0/cccccc?text=Image+Loading';
  }

  /// Preload images
  static Future<void> preloadImages(List<String> imageUrls) async {
    // In a real app, implement image preloading
    for (final url in imageUrls) {
      try {
        // Preload image logic here
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        if (kDebugMode) {
          print('Failed to preload image $url: $e');
        }
      }
    }
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _measurements = {};

  /// Start performance measurement
  static void startMeasurement(String name) {
    _startTimes[name] = DateTime.now();
  }

  /// End performance measurement
  static void endMeasurement(String name) {
    final startTime = _startTimes[name];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _measurements.putIfAbsent(name, () => []).add(duration);
      _startTimes.remove(name);
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _measurements.entries) {
      final measurements = entry.value;
      if (measurements.isNotEmpty) {
        final avgDuration = measurements.fold<Duration>(
          Duration.zero,
          (sum, duration) => sum + duration,
        ) ~/ measurements.length;
        
        final minDuration = measurements.reduce((a, b) => a < b ? a : b);
        final maxDuration = measurements.reduce((a, b) => a > b ? a : b);
        
        stats[entry.key] = {
          'count': measurements.length,
          'average': avgDuration.inMilliseconds,
          'min': minDuration.inMilliseconds,
          'max': maxDuration.inMilliseconds,
          'last': measurements.last.inMilliseconds,
        };
      }
    }
    
    return stats;
  }

  /// Clear performance measurements
  static void clearMeasurements() {
    _startTimes.clear();
    _measurements.clear();
  }
} 