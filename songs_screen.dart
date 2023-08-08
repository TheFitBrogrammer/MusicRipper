// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_ripper/song_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({
    Key? key,
  }) : super(key: key);

  @override
  _SongsScreenState createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  AudioPlayer audioPlayer = AudioPlayer();
  List<String> songs = [];

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  void loadSongs() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Stream<FileSystemEntity> fileStream = appDir.list();

    await for (final file in fileStream) {
      if (file is File) {
        final String filePath = file.path;
        if (filePath.endsWith('.mp3')) {
          songs.add(filePath);
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        String songTitle = Uri.parse(songs[index])
            .pathSegments
            .last
            .substring(0, Uri.parse(songs[index]).pathSegments.last.length - 4);
        return ListTile(
          title: Text(songTitle),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongScreen(
                    songPaths: songs, currentIndex: index, title: songTitle),
              ),
            );

            // try {
            //   if (audioPlayer.playing) {
            //     await audioPlayer.stop();
            //   } else {
            //     await audioPlayer.setAudioSource(
            //       AudioSource.uri(
            //         Uri.parse(songs[index]),
            //       ),
            //     );
            //     await audioPlayer.play();
            //   }
            // } catch (e) {
            //   log('Error playing audio: $e');
            // }
          },
          onLongPress: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            await File(songs[index]).delete();

            loadSongs();
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("Song deleted from storage"),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
        );
      },
    );
  }
}
