// M-19: _gas._dio استُبدل بـ _gas.dio (getter عام)
// M-20: LRU Eviction مُحسَّن

import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/config/app_config.dart';
import 'package:shared/domain/entities/video_entity.dart';
import 'package:shared/infrastructure/gas_client.dart';
import 'package:shared/infrastructure/video_service.dart';

part 'video_service_drive.g.dart';

class VideoServiceDrive implements VideoService {
  VideoServiceDrive({required GasClient gasClient, required String cacheDir})
      : _gas = gasClient,
        _cacheDir = cacheDir,
        _cache = {};

  final GasClient _gas;
  final Map<String, String> _cache;
  final String _cacheDir;

  @override
  Future<List<VideoMetadata>> getVideosForExercise(String exerciseId) async {
    try {
      final resp = await _gas.get<Map<String, dynamic>>('/video/exercise/$exerciseId');
      final data = resp.data?['videos'] as List<dynamic>? ?? [];
      return data.map((v) => _parseMeta(v as Map<String, dynamic>)).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      developer.log('getVideos failed: $e', name: 'VideoServiceDrive');
      return [];
    }
  }

  @override
  Future<String> getStreamUrl(String videoId) async {
    if (_cache.containsKey(videoId)) {
      if (File(_cache[videoId]!).existsSync()) return _cache[videoId]!;
      _cache.remove(videoId);
    }
    final resp = await _gas.get<Map<String, dynamic>>('/video/stream/$videoId');
    final url  = resp.data?['streamUrl'] as String?;
    if (url == null || url.isEmpty) throw Exception('Empty stream URL: $videoId');
    return url;
  }

  @override
  Future<void> prefetchVideo(String videoId) async {
    if (await isVideoCached(videoId)) return;

    final cacheSize = await getVideoCacheSizeBytes();
    if (cacheSize >= AppConfig.videoCacheMaxBytes) await _evictLRU();

    try {
      final streamUrl  = await getStreamUrl(videoId);
      final localPath  = '$_cacheDir/$videoId.mp4';
      // M-19: استخدام _gas.dio العام بدل _gas._dio الخاص
      await _gas.dio.download(streamUrl, localPath);
      _cache[videoId] = localPath;
    } catch (e) {
      developer.log('Prefetch failed: $videoId — $e', name: 'VideoServiceDrive');
    }
  }

  @override
  Future<bool> isVideoCached(String videoId) async {
    if (_cache.containsKey(videoId) && File(_cache[videoId]!).existsSync()) return true;
    final path = '$_cacheDir/$videoId.mp4';
    if (File(path).existsSync()) { _cache[videoId] = path; return true; }
    return false;
  }

  @override
  Future<void> clearVideoCache() async {
    final dir = Directory(_cacheDir);
    if (dir.existsSync()) {
      for (final f in dir.listSync().whereType<File>()) {
        if (f.path.endsWith('.mp4')) f.deleteSync();
      }
    }
    _cache.clear();
  }

  @override
  Future<int> getVideoCacheSizeBytes() async {
    final dir = Directory(_cacheDir);
    if (!dir.existsSync()) return 0;
    return dir.listSync().whereType<File>()
        .where((f) => f.path.endsWith('.mp4'))
        .fold(0, (s, f) => s + f.lengthSync());
  }

  Future<void> _evictLRU() async {
    final dir = Directory(_cacheDir);
    if (!dir.existsSync()) return;
    final files = dir.listSync().whereType<File>()
        .where((f) => f.path.endsWith('.mp4')).toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    final toDelete = (files.length * 0.2).ceil();
    for (int i = 0; i < toDelete && i < files.length; i++) {
      final id = files[i].path.split('/').last.replaceAll('.mp4', '');
      files[i].deleteSync();
      _cache.remove(id);
    }
  }

  VideoMetadata _parseMeta(Map<String, dynamic> d) => VideoMetadata(
    id:              d['id'] as String? ?? '',
    exerciseId:      d['exerciseId'] as String? ?? '',
    title:           d['title'] as String? ?? '',
    durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 0,
    order:           (d['order'] as num?)?.toInt() ?? 0,
    thumbnailUrl:    d['thumbnailUrl'] as String?,
  );
}

@riverpod
Future<VideoService> videoService(Ref ref) async {
  final gas     = await ref.watch(gasClientProvider.future);
  final appDir  = await getApplicationDocumentsDirectory();
  final cacheDir = Directory('${appDir.path}/video_cache');
  if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);
  return VideoServiceDrive(gasClient: gas, cacheDir: cacheDir.path);
}
