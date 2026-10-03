import 'package:flutter/material.dart';

class WithdrawHistoryPage extends StatelessWidget {
  const WithdrawHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提现记录')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
              size: 56, color: Colors.grey[700]),
            const SizedBox(height: 12),
            const Text('暂无提现记录',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('提现功能即将上线',
              style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
