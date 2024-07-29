import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '条码扫描器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Set<String> scannedData = {};
  final TextEditingController _controller = TextEditingController();
  bool scanning = false;
  String feedbackMessage = '';

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // 启用屏幕常亮
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    _controller.dispose();
    WakelockPlus.disable(); // 关闭屏幕常亮
    super.dispose();
  }

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!scanning) return;
      if (scannedData.contains(scanData.code)) {
        _showDialog('扫描成功', '内容匹配！\n扫描结果：${scanData.code}');
        // 暂停扫描
        controller.pauseCamera();
      } else {
        setState(() {
          feedbackMessage = '扫描失败，内容不匹配，扫描结果：${scanData.code}';
        });
      }
    });
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击对话框外部区域关闭对话框
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: Text(content, style: TextStyle(fontSize: 16, color: Colors.black87)),
        actions: [
          TextButton(
            child: Text('确定', style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pop(context);
              // 继续扫描
              setState(() {
                scanning = true;
                controller?.resumeCamera();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('条码扫描器'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: '输入条形码',
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (text) {
                    setState(() {
                      feedbackMessage = '';
                    });
                  },
                  onSubmitted: (text) {
                    if (text.isNotEmpty) {
                      setState(() {
                        scannedData.add(text);
                        _controller.clear(); // 清空输入框
                        feedbackMessage = '';
                      });
                    }
                  },
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: scannedData.map((data) {
                    return Chip(
                      label: Text(data),
                      onDeleted: () {
                        setState(() {
                          scannedData.remove(data);
                        });
                      },
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      deleteIconColor: Colors.blueAccent,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        scanning = !scanning;
                        feedbackMessage = ''; // 清空提示信息
                        if (scanning) {
                          controller?.resumeCamera();
                        } else {
                          controller?.pauseCamera();
                        }
                      });
                    },
                    child: Text(scanning ? '停止扫描' : '开始扫描'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scanning ? Colors.red : Colors.blueAccent,
                      minimumSize: Size(double.infinity, 48), // 使按钮宽度与屏幕边距相等
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        scannedData.clear(); // 清空所有 Tag
                        feedbackMessage = ''; // 清空提示信息
                      });
                    },
                    child: Text('清空条形码'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      minimumSize: Size(double.infinity, 48), // 使按钮宽度与屏幕边距相等
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: onQRViewCreated,
                ),
                if (feedbackMessage.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        feedbackMessage,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
