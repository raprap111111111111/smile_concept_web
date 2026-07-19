import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';

class AuthenticatedImage extends ConsumerStatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget Function(BuildContext, VoidCallback retry)? errorBuilder;
  final BorderRadius? borderRadius; // ✅ THIS MUST EXIST
  final Duration timeout;
  final bool useCache;

  const AuthenticatedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorBuilder,
    this.borderRadius, // ✅ AND HERE
    this.timeout = const Duration(seconds: 30),
    this.useCache = true,
  });

  static void clearCache() => _AuthenticatedImageCache.clear();
  static void evict(String url) => _AuthenticatedImageCache.evict(url);

  @override
  ConsumerState<AuthenticatedImage> createState() => _AuthenticatedImageState();
}

class _AuthenticatedImageState extends ConsumerState<AuthenticatedImage> {
  Uint8List? _bytes;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.useCache) {
      final cached = _AuthenticatedImageCache.get(widget.url);
      if (cached != null) {
        setState(() {
          _bytes = cached;
          _loading = false;
          _error = null;
        });
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<List<int>>(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: widget.timeout,
          headers: {'Accept': '*/*'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'HTTP ${response.statusCode}',
        );
      }

      final bytes = Uint8List.fromList(response.data!);

      if (widget.useCache) {
        _AuthenticatedImageCache.put(widget.url, bytes);
      }

      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ AuthenticatedImage failed: ${widget.url}\n$e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Widget _wrapWithBorder(Widget child) {
    if (widget.borderRadius == null) return child;
    return ClipRRect(borderRadius: widget.borderRadius!, child: child);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _wrapWithBorder(
          widget.placeholder ??
              Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
        ),
      );
    }

    if (_error != null || _bytes == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: _wrapWithBorder(
          widget.errorBuilder?.call(context, _load) ??
              _DefaultErrorWidget(onRetry: _load, error: _error),
        ),
      );
    }

    return _wrapWithBorder(
      Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _DefaultErrorWidget(onRetry: _load, error: error),
      ),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final Object? error;

  const _DefaultErrorWidget({required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    final isForbidden = error is DioException &&
        (error as DioException).response?.statusCode == 403;
    final isNotFound = error is DioException &&
        (error as DioException).response?.statusCode == 404;

    String message = 'Failed to load image';
    IconData icon = Icons.broken_image_outlined;

    if (isForbidden) {
      message = 'Access denied';
      icon = Icons.lock_outline;
    } else if (isNotFound) {
      message = 'Image not found';
      icon = Icons.image_not_supported_outlined;
    }

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          if (!isForbidden) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthenticatedImageCache {
  static const int _maxEntries = 50;
  static const int _maxTotalBytes = 50 * 1024 * 1024; // 50 MB

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static int _currentBytes = 0;

  static Uint8List? get(String url) {
    final bytes = _cache.remove(url);
    if (bytes != null) {
      _cache[url] = bytes;
    }
    return bytes;
  }

  static void put(String url, Uint8List bytes) {
    if (_cache.containsKey(url)) {
      _currentBytes -= _cache[url]!.lengthInBytes;
      _cache.remove(url);
    }

    _cache[url] = bytes;
    _currentBytes += bytes.lengthInBytes;

    while (_cache.length > _maxEntries || _currentBytes > _maxTotalBytes) {
      if (_cache.isEmpty) break;
      final oldest = _cache.keys.first;
      _currentBytes -= _cache[oldest]!.lengthInBytes;
      _cache.remove(oldest);
    }
  }

  static void evict(String url) {
    final bytes = _cache.remove(url);
    if (bytes != null) _currentBytes -= bytes.lengthInBytes;
  }

  static void clear() {
    _cache.clear();
    _currentBytes = 0;
  }
}