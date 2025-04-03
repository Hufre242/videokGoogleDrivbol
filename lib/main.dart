import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stress-Pass Video Drive',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: DriveVideoList(),
    );
  }
}

class DriveVideoList extends StatefulWidget {
  @override
  _DriveVideoListState createState() => _DriveVideoListState();
}

class _DriveVideoListState extends State<DriveVideoList> {
  final String folderId = "1HeOneOTCTcdgyjSO-DaWb4-Zuu9pKlQV";
  final String apiKey = "AIzaSyAzN8SS2ubglIV-6_pcHnEClYfBm79_lMM";
  List<Map<String, String>> videos = [];

  @override
  void initState() {
    super.initState();
    fetchDriveVideos();
  }

  Future<void> fetchDriveVideos() async {
    final url =
        'https://www.googleapis.com/drive/v3/files?q=\'$folderId\'+in+parents&key=$apiKey&fields=files(id,name,mimeType)';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    final files = data['files'] as List;
    print("LEKÉRÉS VÁLASZ: ${response.body}");
    setState(() {
      videos = files
          .where((file) => file['mimeType'].toString().contains('video'))
          .map((file) => {
        'id': file['id'].toString(),
        'name': file['name'].toString(),
      })
          .toList();
    });
  }

  Future<String> downloadFile(String fileId, String name) async {
    final url = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  void openVideo(String id, String name) async {
    final path = await downloadFile(id, name);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Drive videók")),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return ListTile(
            title: Text(video['name'] ?? ''),
            trailing: Icon(Icons.play_arrow),
            onTap: () => openVideo(video['id']!, video['name']!),
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  VideoPlayerScreen({required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Videólejátszó")),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}
