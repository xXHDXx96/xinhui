import 'package:flutter/material.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final List<Map<String, dynamic>> _devices = [
    {
      'id': '1',
      'name': '本机',
      'type': 'Android',
      'icon': Icons.smartphone,
      'location': '柬埔寨 · 金边',
      'lastActive': '当前在线',
      'current': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
      body: RefreshIndicator(
        color: const Color(0xFF00C853),
        backgroundColor: const Color(0xFF141414),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3))),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF00C853), size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  '如果发现陌生设备，请立即移除并修改密码。',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 20),
            Text('共 ${_devices.length} 台设备',
              style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
            const SizedBox(height: 12),
            ..._devices.map(_deviceCard),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(Map<String, dynamic> d) {
    final isCurrent = d['current'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
            ? const Color(0xFF00C853).withOpacity(0.4)
            : const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(d['icon'] as IconData,
                color: const Color(0xFF00C853), size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(d['name'] as String, style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4)),
                      child: const Text('当前设备',
                        style: TextStyle(color: Color(0xFF00C853), fontSize: 10))),
                  ],
                ]),
                const SizedBox(height: 4),
                Text('${d['type']} · ${d['location']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(d['lastActive'] as String,
                  style: TextStyle(
                    color: isCurrent ? const Color(0xFF00C853) : Colors.grey,
                    fontSize: 11.5)),
              ],
            )),
          ]),
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1F1F1F), height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _removeDevice(d),
                  icon: const Icon(Icons.logout, size: 16, color: Color(0xFFF44336)),
                  label: const Text('移除该设备',
                    style: TextStyle(color: Color(0xFFF44336), fontSize: 12.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _removeDevice(Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('移除设备', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('确认将 ${d['name']} 从账户中移除？',
          style: const TextStyle(color: Colors.grey, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _devices.remove(d));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设备已移除'),
                  behavior: SnackBarBehavior.floating));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('确认移除'),
          ),
        ],
      ),
    );
  }
}
