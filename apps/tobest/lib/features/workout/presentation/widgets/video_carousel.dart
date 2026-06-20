// apps/tobest/lib/features/workout/presentation/widgets/video_carousel.dart

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/design/tokens.dart';
import 'package:shared/domain/entities/video_entity.dart';
import 'package:shared/infrastructure/video_service_drive.dart';
import 'package:video_player/video_player.dart';

part 'video_carousel.g.dart';

/// مزود metadata الفيديوهات لتمرين
@riverpod
Future<List<VideoMetadata>> exerciseVideos(
    Ref ref, String exerciseId) async {
  final service = await ref.watch(videoServiceProvider.future);
  return service.getVideosForExercise(exerciseId);
}

/// Carousel فيديوهات التمرين
///
/// ⚠️ URL الفيديو لا يُعرض في الـ UI أبداً — يُمرَّر مباشرة لـ VideoPlayerController
/// ⚠️ FLAG_SECURE على الشاشة — تمنع Screenshot لمحتوى الفيديو
/// عند عدم الاتصال + عدم وجود Cache: تظهر رسالة واضحة
class VideoCarousel extends ConsumerStatefulWidget {
  const VideoCarousel({
    super.key,
    required this.exerciseId,
    required this.videoIds,
  });

  final String exerciseId;
  final List<String> videoIds;

  @override
  ConsumerState<VideoCarousel> createState() => _VideoCarouselState();
}

class _VideoCarouselState extends ConsumerState<VideoCarousel> {
  int _currentPage = 0;
  VideoPlayerController? _controller;
  VideoPlayState _playState = VideoPlayState.idle;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(VideoMetadata meta) async {
    setState(() => _playState = VideoPlayState.loading);
    await _controller?.dispose();
    _controller = null;

    try {
      final service  = await ref.read(videoServiceProvider.future);
      final streamUrl = await service.getStreamUrl(meta.id);

      final ctrl = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await ctrl.initialize();

      if (!mounted) return;

      ctrl.addListener(() {
        if (!mounted) return;
        setState(() {
          if (ctrl.value.hasError) {
            _playState = VideoPlayState.error;
          } else if (ctrl.value.isPlaying) {
            _playState = VideoPlayState.playing;
          } else if (ctrl.value.isInitialized) {
            _playState = ctrl.value.position >= ctrl.value.duration
                ? VideoPlayState.ended
                : VideoPlayState.paused;
          }
        });
      });

      setState(() {
        _controller = ctrl;
        _playState  = VideoPlayState.paused;
      });
    } catch (e) {
      developer.log('Video load failed: $e', name: 'VideoCarousel');
      if (mounted) {
        setState(() => _playState = VideoPlayState.offlineUnavailable);
      }
    }
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      if (_playState == VideoPlayState.ended) {
        _controller!.seekTo(Duration.zero);
      }
      _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(exerciseVideosProvider(widget.exerciseId));

    return videosAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            // ── Carousel الفيديوهات ──────────────────────
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _loadVideo(videos[i]);
                },
                itemCount: videos.length,
                itemBuilder: (context, i) {
                  return _VideoPage(
                    meta:       videos[i],
                    controller: i == _currentPage ? _controller : null,
                    playState:  i == _currentPage
                        ? _playState
                        : VideoPlayState.idle,
                    onLoad:   () => _loadVideo(videos[i]),
                    onToggle: _togglePlay,
                  );
                },
              ),
            ),

            // ── مؤشر الصفحات ─────────────────────────────
            if (videos.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: videos.asMap().entries.map((e) {
                    return AnimatedContainer(
                      duration: AppDurations.fast,
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs / 2),
                      width:  _currentPage == e.key ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        color: _currentPage == e.key
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// صفحة فيديو واحدة في الـ Carousel
class _VideoPage extends StatelessWidget {
  const _VideoPage({
    required this.meta,
    required this.controller,
    required this.playState,
    required this.onLoad,
    required this.onToggle,
  });

  final VideoMetadata meta;
  final VideoPlayerController? controller;
  final VideoPlayState playState;
  final VoidCallback onLoad;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── خلفية داكنة / الفيديو ───────────────────────
          if (controller != null && controller!.value.isInitialized)
            FittedBox(
              fit:   BoxFit.cover,
              child: SizedBox(
                width:  controller!.value.size.width,
                height: controller!.value.size.height,
                child:  VideoPlayer(controller!),
              ),
            )
          else
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                child: _buildOverlay(context, isRtl),
              ),
            ),

          // ── Progress Bar ────────────────────────────────
          if (controller != null && controller!.value.isInitialized)
            Positioned(
              bottom: 0,
              left:   0,
              right:  0,
              child: VideoProgressIndicator(
                controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor:     theme.colorScheme.primary,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  bufferedColor:   Colors.white.withOpacity(0.5),
                ),
              ),
            ),

          // ── زر التشغيل/الإيقاف ──────────────────────────
          if (playState != VideoPlayState.loading &&
              playState != VideoPlayState.offlineUnavailable)
            Center(
              child: GestureDetector(
                onTap: playState == VideoPlayState.idle ? onLoad : onToggle,
                child: AnimatedOpacity(
                  duration: AppDurations.fast,
                  opacity:  playState == VideoPlayState.playing ? 0.0 : 1.0,
                  child: Container(
                    width:      56,
                    height:     56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Icon(
                      playState == VideoPlayState.ended
                          ? Icons.replay
                          : Icons.play_arrow,
                      color: Colors.white,
                      size:  32,
                    ),
                  ),
                ),
              ),
            ),

          // ── Loading Indicator ───────────────────────────
          if (playState == VideoPlayState.loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // ── Offline Message ─────────────────────────────
          if (playState == VideoPlayState.offlineUnavailable)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 36),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isRtl
                        ? 'الفيديو غير متاح بدون إنترنت'
                        : 'Video unavailable offline',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // ── العنوان ─────────────────────────────────────
          Positioned(
            top:   0,
            left:  0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical:   AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                meta.title,
                style: const TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, bool isRtl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_outline,
          size:  48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          meta.title,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          isRtl ? 'اضغط للتشغيل' : 'Tap to play',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
