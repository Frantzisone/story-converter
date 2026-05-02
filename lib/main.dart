import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE1306C)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _inputFolder = '';
  bool _isRunning = false;
  List<String> _logs = [];
  int _done = 0;
  int _total = 0;

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Επέλεξε φάκελο με Stories',
    );
    if (result != null) setState(() => _inputFolder = result);
  }

  void _log(String msg) => setState(() => _logs.add(msg));

  Future<void> _start() async {
    if (_inputFolder.isEmpty) { _log('❌ Επέλεξε φάκελο!'); return; }
    setState(() { _isRunning = true; _logs = []; _done = 0; });

    final output = Directory('/sdcard/Download/youtube_output');
    output.createSync(recursive: true);

    final files = Directory(_inputFolder)
        .listSync()
        .where((f) => f.path.toLowerCase().endsWith('.mp4'))
        .toList();

    setState(() => _total = files.length);
    if (files.isEmpty) {
      _log('❌ Δεν βρέθηκαν MP4!');
      setState(() => _isRunning = false);
      return;
    }

    _log('📁 ${files.length} βίντεο βρέθηκαν...');

    for (final file in files) {
      final name = file.path.split('/').last;
      _log('🔄 Επεξεργασία: $name');
      final outputPath = '${output.path}/youtube_$name';
      final result = await Process.run('ffmpeg', [
        '-i', file.path,
        '-filter_complex',
        '[0:v]scale=606:1080[fg];[0:v]scale=1920:1080,boxblur=40:40[bg];[bg][fg]overlay=(W-w)/2:(H-h)/2',
        '-c:v', 'libx264', '-crf', '23', '-preset', 'fast',
        '-c:a', 'aac', '-y', outputPath,
      ]);
      if (result.exitCode == 0) {
        setState(() => _done++);
        _log('✅ Έτοιμο: $name');
      } else {
        _log('❌ Σφάλμα: $name');
      }
    }

    _log('🎉 Τελείωσε! $_done/$_total στο ${output.path}');
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story → YouTube'),
        backgroundColor: const Color(0xFFE1306C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(child: ListTile(
              leading: const Icon(Icons.folder, color: Color(0xFFE1306C)),
              title: const Text('Φάκελος Stories'),
              subtitle: Text(_inputFolder.isEmpty ? 'Δεν επιλέχθηκε' : _inputFolder),
              trailing: ElevatedButton(
                onPressed: _isRunning ? null : _pickFolder,
                child: const Text('Επιλογή'),
              ),
            )),
            const SizedBox(height: 16),
            if (_isRunning) ...[
              LinearProgressIndicator(value: _total > 0 ? _done / _total : null, color: const Color(0xFFE1306C)),
              const SizedBox(height: 8),
              Text('$_done / $_total', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _start,
              icon: _isRunning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Επεξεργασία...' : 'Εκκίνηση'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Text(_logs[i], style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
