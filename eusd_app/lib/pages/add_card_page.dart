import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});
  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _holder = TextEditingController(text: 'ZHANG WEI');
  String _type = 'virtual';
  String _brand = 'VISA';
  bool _submitting = false;

  @override
  void dispose() {
    _holder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final r = await context.read<CardProvider>().createCard(
          holderName: _holder.text.trim().toUpperCase(),
          brand: _brand,
          cardType: _type,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    final ok = r['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r['message']?.toString() ?? (ok ? '创建成功' : '创建失败'))),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加卡片')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('卡片类型', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'virtual', label: Text('虚拟卡'), icon: Icon(Icons.phone_android)),
              ButtonSegment(value: 'physical', label: Text('实体卡'), icon: Icon(Icons.credit_card)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 24),
          const Text('卡组织', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'VISA', label: Text('VISA')),
              ButtonSegment(value: 'MasterCard', label: Text('MasterCard')),
            ],
            selected: {_brand},
            onSelectionChanged: (s) => setState(() => _brand = s.first),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _holder,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '持卡人姓名（拼音）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_submitting ? '提交中...' : '提交申请'),
          ),
        ],
      ),
    );
  }
}
