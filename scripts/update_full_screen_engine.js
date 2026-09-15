const fs = require('fs');
const path = require('path');

const targetBase = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib';

// 1. Update game_wall_bottom_sheet.dart
const gameWallPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'game_wall_bottom_sheet.dart');
if (fs.existsSync(gameWallPath)) {
  let content = fs.readFileSync(gameWallPath, 'utf8');

  // Replace Html5GameSheet and Html5GameFullScreenPage
  const html5Start = content.indexOf('class Html5GameSheet extends StatefulWidget {');
  if (html5Start !== -1) {
    const newHtml5Section = `class Html5GameFullScreenPage extends StatelessWidget {
  final String url;
  final String title;

  const Html5GameFullScreenPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A1C),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Html5GameSheet(url: url, title: title, isFullScreen: true),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.back();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Html5GameSheet extends StatefulWidget {
  final String url;
  final String title;
  final bool isFullScreen;

  const Html5GameSheet({
    super.key,
    required this.url,
    required this.title,
    this.isFullScreen = false,
  });

  static void show(
    BuildContext context, {
    required String url,
    required String title,
    bool isFullScreen = false,
    bool isInAudioRoom = false,
  }) {
    // 🎙️ STRICT: ONLY inside Voice Room will it show 70% Bottom Sheet!
    if (isInAudioRoom == true && isFullScreen == false) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.70, // Exact 70% screen height, top 30% empty!
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              color: const Color(0xFF030A1C),
              child: Column(
                children: [
                  // Top Drag Handle Bar & Close Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: const Color(0xFF070E24),
                    child: Row(
                      children: [
                        const SizedBox(width: 28),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white12,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white70, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Html5GameSheet(url: url, title: title, isFullScreen: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // 💳 Standalone / Wallet Screen Mode: 100% Full Screen Page!
      try {
        Get.to(
          () => Html5GameFullScreenPage(url: url, title: title),
          transition: Transition.rightToLeft,
        );
      } catch (_) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (ctx) => Html5GameFullScreenPage(url: url, title: title),
          ),
        );
      }
    }
  }

  @override
  State<Html5GameSheet> createState() => _Html5GameSheetState();
}

class _Html5GameSheetState extends State<Html5GameSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF030A1C))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJsMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJsMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
            final user = AuthController.instance.currentUser;
            String diamondIcon = '';
            try {
              if (Get.isRegistered<AppThemeService>()) {
                diamondIcon = Get.find<AppThemeService>().diamondIconUrl.value;
              }
            } catch (_) {}

            _controller.runJavaScript("""
              if (window.setUserProfile) {
                window.setUserProfile({
                  userId: '\${user.userId}',
                  uid: '\${user.userId}',
                  name: '\${user.fullname.replaceAll("'", "\\\\'")}',
                  avatar: '\${user.photoUrl}',
                  diamonds: \${user.diamonds},
                  coins: \${user.diamonds},
                  diamondIcon: '\$diamondIcon'
                });
              }
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _handleJsMessage(String msg) {
    if (!mounted) return;
    try {
      if (msg == 'CLOSE_GAME') {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Get.back();
        }
        return;
      }
      final data = jsonDecode(msg);
      if (data is Map) {
        final type = (data['type'] ?? data['action'] ?? '').toString();
        if (type == 'CLOSE_GAME' || type == 'close') {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Get.back();
          }
        } else if (type == 'OPEN_WALLET' || type == 'OPEN_RECHARGE' || type == 'wallet') {
          final user = AuthController.instance.currentUser;
          Get.to(() => UserWalletScreen(currentUser: user));
        }
      }
    } catch (_) {
      if (msg == 'CLOSE_GAME') {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Get.back();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          ),
      ],
    );
  }
}
`;
    content = content.substring(0, html5Start) + newHtml5Section;
    fs.writeFileSync(gameWallPath, content, 'utf8');
    console.log('game_wall_bottom_sheet.dart updated successfully!');
  }
}
