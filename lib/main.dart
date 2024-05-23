import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    String m3uFilePath = await _downloadM3UFile();
    List<String> videoUrls = await _parseM3UFile(m3uFilePath);
    if (videoUrls.isNotEmpty) {
      _controller = VideoPlayerController.network(videoUrls[0]);
      await _controller.initialize();
      _controller.play();
    }
  }

  Future<String> _downloadM3UFile() async {
    var ipdata;
    final response = await http.get(Uri.parse("https://iptv.macvision.global/$ipdata"));
    if (response.statusCode == 200) {
      String m3uFileUrl = jsonDecode(response.body)['data']['ipdata'];
      final fileResponse = await http.get(Uri.parse(m3uFileUrl));
      if (fileResponse.statusCode == 200) {
        Directory directory = await getApplicationDocumentsDirectory();
        String filePath = '${directory.path}/playlist.m3u';
        File file = File(filePath);
        await file.writeAsBytes(fileResponse.bodyBytes);
        return filePath;
      } else {
        throw Exception('Failed to download m3u file');
      }
    } else {
      throw Exception('Failed to load m3u file location');
    }
  }

  Future<List<String>> _parseM3UFile(String filePath) async {
    File file = File(filePath);
    List<String> lines = await file.readAsLines();
    List<String> videoUrls = [];
    for (String line in lines) {
      if (line.startsWith('http')) {
        videoUrls.add(line);
      }
    }
    return videoUrls;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
