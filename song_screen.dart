// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SongScreen extends StatefulWidget {
  final List<String> songPaths;
  final int currentIndex;
  final String title;

  const SongScreen(
      {Key? key,
      required this.songPaths,
      required this.currentIndex,
      required this.title})
      : super(key: key);

  @override
  _SongScreenState createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  late AudioPlayer _audioPlayer;
  late AudioSource _playlist;
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  int? _currentIndex;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentTitle = widget.title;
    _playlist = ConcatenatingAudioSource(
      children: widget.songPaths
          .map((path) => AudioSource.uri(Uri.parse(path)))
          .toList(),
    );
    _audioPlayer.setAudioSource(_playlist).then((_) {
      _audioPlayer.seek(Duration.zero, index: widget.currentIndex);
    });
    _audioPlayer.play();

    _audioPlayer.currentIndexStream.listen((currentIndex) {
      _currentIndex = currentIndex;
    });

    _audioPlayer.positionStream.listen((position) {
      if (_audioPlayer.duration != null && position < _audioPlayer.duration!) {
        positionNotifier.value = position;

        if (position >= _audioPlayer.duration! &&
            _currentIndex != null &&
            _audioPlayer.hasNext) {
          int nextIndex = (_currentIndex! + 1) % widget.songPaths.length;
          String nextTitle =
              Uri.parse(widget.songPaths[nextIndex]).pathSegments.last;
          _audioPlayer.stop();
          // Navigator.of(context).pop();
          positionNotifier.value = Duration.zero;
          _navigateToPage(nextIndex, nextTitle);
          // Check if the song is the last one
          // if (nextIndex == 0) {
          //   // If it is, set the position to the maximum
          //   positionNotifier.value = _audioPlayer.duration!;
          // } else {
          //   String nextTitle =
          //       Uri.parse(widget.songPaths[nextIndex]).pathSegments.last;
          //   _audioPlayer.stop();
          //   Navigator.of(context).pop();
          //   positionNotifier.value = Duration.zero;
          //   _navigateToPage(nextIndex, nextTitle);
          // }
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    positionNotifier.dispose();
    super.dispose();
  }

  void _navigateToPage(int index, String title) async {
    _currentTitle = title;
    final navigator = Navigator.of(context);
    await _audioPlayer.stop();
    navigator.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SongScreen(
          songPaths: widget.songPaths,
          currentIndex: index,
          title: title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.ease))),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle ?? ''),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _audioPlayer.stop();
              Navigator.of(context).popUntil((route) => route
                  .isFirst); // This will pop until the first route which is presumably SongsScreen
            }),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = _audioPlayer.playing;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fast_rewind),
                      onPressed: _audioPlayer.hasPrevious
                          ? () => _navigateToPage(
                                (widget.currentIndex -
                                        1 +
                                        widget.songPaths.length) %
                                    widget.songPaths.length,
                                Uri.parse(widget.songPaths[
                                        (widget.currentIndex -
                                                1 +
                                                widget.songPaths.length) %
                                            widget.songPaths.length])
                                    .pathSegments
                                    .last,
                              )
                          : null,
                    ),
                    IconButton(
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: processingState == ProcessingState.idle
                          ? _audioPlayer.play
                          : playing
                              ? _audioPlayer.pause
                              : _audioPlayer.play,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: processingState == ProcessingState.idle
                          ? null
                          : () async {
                              await _audioPlayer.seek(Duration.zero);
                              await _audioPlayer.stop();
                              positionNotifier.value = Duration.zero;
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.fast_forward),
                      onPressed: _audioPlayer.hasNext
                          ? () => _navigateToPage(
                                (widget.currentIndex + 1) %
                                    widget.songPaths.length,
                                Uri.parse(widget.songPaths[
                                        (widget.currentIndex + 1) %
                                            widget.songPaths.length])
                                    .pathSegments
                                    .last,
                              )
                          : null,
                    ),
                  ],
                );
              },
            ),
            StreamBuilder<Duration?>(
              stream: _audioPlayer.durationStream,
              builder: (context, durationSnapshot) {
                final duration = durationSnapshot.data ?? Duration.zero;
                return ValueListenableBuilder<Duration>(
                  valueListenable: positionNotifier,
                  builder: (context, value, child) {
                    double sliderValue = value.inMilliseconds.toDouble();
                    double max = duration.inMilliseconds.toDouble();

                    if (sliderValue > max) {
                      sliderValue = max;
                    }

                    return Slider(
                      value: sliderValue,
                      min: 0.0,
                      max: max,
                      onChanged: (value) {
                        _audioPlayer
                            .seek(Duration(milliseconds: value.round()));
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
