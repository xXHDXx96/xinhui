import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});
  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selected = 'zh_CN';

  final _langs = [
    {'code': 'zh_CN', 'name': '中文（简体）', 'native': 'Chinese (Simplified)'},
    {'code': 'zh_TW', 'name': '中文（繁體）', 'native': 'Chinese (Traditional)'},
    {'code': 'en_US', 'name': 'English', 'native': 'English'},
    {'code': 'ja_JP', 'name': '日本語', 'native': 'Japanese'},
    {'code': 'ko_KR', 'name': '한국어', 'native': 'Korean'},
    {'code': 'vi_VN', 'name': 'Tiếng Việt', 'native': 'Vietnamese'},
    {'code': 'th_TH', 'name': 'ภาษาไทย', 'native': 'Thai'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语言')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _langs.map((l) {
          final sel = _selected == l['code'];
          return GestureDetector(
            onTap: () => setState(() => _selected = l['code']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? const Color(0xFF00C853) : const Color(0xFF1F1F1F),
                  width: sel ? 1.5 : 1)),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l['name']!, style: const TextStyle(
                      color: Colors.white, fontSize: 14.5,
                      fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(l['native']!, style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
                  ],
                )),
                if (sel)
                  const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 22)
                else
                  const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}
