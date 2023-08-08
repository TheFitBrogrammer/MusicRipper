// ignore_for_file: library_private_types_in_public_api

// import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  _DownloadScreenState createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final YoutubeExplode yt = YoutubeExplode();
  final TextEditingController urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'YouTube Video URL',
            ),
          ),
          ElevatedButton(
            child: const Text('Download'),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text("Download started..."),
                  duration: Duration(milliseconds: 1500),
                ),
              );
              try {
                var video = await yt.videos.get(urlController.text);
                var manifest =
                    await yt.videos.streamsClient.getManifest(video.id);
                var audioOnly = manifest.audioOnly.withHighestBitrate();
                // ignore: unnecessary_null_comparison
                if (audioOnly != null) {
                  var dir = await getApplicationDocumentsDirectory();
                  var filePath = '${dir.path}/${video.title}.mp3';
                  var dio = Dio();
                  await dio.download(audioOnly.url.toString(), filePath);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("Download finished."),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("ERROR: No audio stream available."),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    yt.close();
    urlController.dispose();
    super.dispose();
  }
}
