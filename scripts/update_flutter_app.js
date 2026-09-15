const fs = require('fs');
const path = require('path');

const targetBase = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib';

// 1. Update game_wall_bottom_sheet.dart
const gameWallPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'game_wall_bottom_sheet.dart');
if (fs.existsSync(gameWallPath)) {
  let content = fs.readFileSync(gameWallPath, 'utf8');

  // Add imports if missing
  if (!content.includes("import 'dart:convert';")) {
    content = "import 'dart:convert';\n" + content;
  }
  if (!content.includes("import 'package:chat_messenger/screens/room/wallet_screen.dart';")) {
    content = "import 'package:chat_messenger/screens/room/wallet_screen.dart';\nimport 'package:chat_messenger/screens/audio_rooms_v2/minimized_room_controller.dart';\n" + content;
  }

  // Update GameWallBottomSheet definition
  content = content.replace(
    /class GameWallBottomSheet extends StatelessWidget {[\s\S]*?static void show\(BuildContext context, \{AudioRoomV2\? room\}\) \{[\s\S]*?builder: \(context\) => GameWallBottomSheet\(room: room\),[\s\S]*?\}\.then\(\(_\) \{[\s\S]*?WidgetsBinding\.instance\.scheduleFrame\(\);[\s\S]*?\}\);[\s\S]*?\}/,
    `class GameWallBottomSheet extends StatelessWidget {
  final AudioRoomV2? room;
  final String? roomId;
  final bool isInAudioRoom;

  const GameWallBottomSheet({
    super.key,
    this.room,
    this.roomId,
    this.isInAudioRoom = false,
  });

  static void show(
    BuildContext context, {
    AudioRoomV2? room,
    String? roomId,
    bool? isInAudioRoom,
  }) {
    final bool effectiveInRoom = isInAudioRoom ?? (
      room != null ||
      roomId != null ||
      (Get.isRegistered<MinimizedRoomController>() &&
          (Get.find<MinimizedRoomController>().hasMinimizedRoom ||
           Get.find<MinimizedRoomController>().currentRoom != null))
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GameWallBottomSheet(
        room: room,
        roomId: roomId,
        isInAudioRoom: effectiveInRoom,
      ),
    ).then((_) {
      WidgetsBinding.instance.scheduleFrame();
    });
  }`
  );

  // Update Game card onTap handler
  content = content.replace(
    /onTap: \(\) async \{[\s\S]*?Navigator\.pop\(context\);[\s\S]*?final gameType = \(data\['gameType'\] \?\? ''\)\.toString\(\)\.toLowerCase\(\);[\s\S]*?if \(gameUrl\.isNotEmpty \|\| gameCode\.contains\('html5'\) \|\| gameCode\.contains\('market'\) \|\| gameType == 'html5'\) \{[\s\S]*?Html5GameSheet\.show\([\s\S]*?isFullScreen: false,[\s\S]*?\);[\s\S]*?return;[\s\S]*?\}[\s\S]*?if \(gameType == 'carrom'\) \{[\s\S]*?\} else \{[\s\S]*?GreadyGameSheet\.show\(context\);[\s\S]*?\}[\s\S]*?\},/,
    `onTap: () async {
                          Navigator.pop(context);
                          final gameType = (data['gameType'] ?? '').toString().toLowerCase();
                          String gameUrl = (data['gameUrl'] ?? data['url'] ?? data['link'] ?? data['webViewUrl'] ?? '').toString().trim();
                          final gameCode = (data['gameCode'] ?? data['gameId'] ?? doc.id).toString().toLowerCase();

                          final bool effectiveInRoom = isInAudioRoom ||
                              room != null ||
                              roomId != null ||
                              (Get.isRegistered<MinimizedRoomController>() &&
                                  (Get.find<MinimizedRoomController>().hasMinimizedRoom ||
                                   Get.find<MinimizedRoomController>().currentRoom != null));

                          // 1. Direct In-App WebView / HTML5 Game Opening (No external browser!)
                          if (gameUrl.isNotEmpty || gameCode.contains('html5') || gameCode.contains('market') || gameCode.contains('delicious') || gameType == 'html5') {
                            if (gameUrl.isEmpty) {
                              gameUrl = 'https://greedy-market-game.web.app';
                            }

                            final user = AuthController.instance.currentUser;
                            final currentUserId = user.userId.isNotEmpty
                                ? user.userId
                                : (FirebaseAuth.instance.currentUser?.uid ?? '');
                            final userName = user.fullname.isNotEmpty ? user.fullname : 'Player';
                            final userAvatar = user.photoUrl;
                            final userDiamonds = user.diamonds;

                            String diamondIconUrl = '';
                            try {
                              if (Get.isRegistered<AppThemeService>()) {
                                diamondIconUrl = Get.find<AppThemeService>().diamondIconUrl.value;
                              }
                            } catch (_) {}

                            final uri = Uri.parse(gameUrl);
                            final Map<String, String> queryParams = Map.from(uri.queryParameters);
                            queryParams['userId'] = currentUserId;
                            queryParams['uid'] = currentUserId;
                            queryParams['name'] = userName;
                            queryParams['avatar'] = userAvatar;
                            queryParams['diamonds'] = userDiamonds.toString();
                            queryParams['coins'] = userDiamonds.toString();
                            if (diamondIconUrl.isNotEmpty) {
                              queryParams['diamondIcon'] = diamondIconUrl;
                            }
                            final effectiveRoomId = room?.id ?? roomId ?? '';
                            if (effectiveRoomId.isNotEmpty) {
                              queryParams['roomId'] = effectiveRoomId;
                            }

                            final finalUrl = uri.replace(queryParameters: queryParams).toString();

                            Html5GameSheet.show(
                              context,
                              url: finalUrl,
                              title: name,
                              isFullScreen: !effectiveInRoom,
                              isInAudioRoom: effectiveInRoom,
                            );
                            return;
                          }

                          if (gameType == 'carrom') {
                            if (room != null) {
                              CarromSetupBottomSheet.show(context, room!);
                            } else {
                              GreadyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
                            }
                          } else if (gameType == 'ludo') {
                            if (room != null) {
                              LudoSetupBottomSheet.show(context, room!);
                            } else {
                              GreadyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
                            }
                          } else if (gameType == 'food_spin' || gameType == 'foodspin') {
                            FoodSpinGameSheet.show(context, isInAudioRoom: effectiveInRoom);
                          } else if (gameType == 'pink_greedy' || gameType == 'pinkgreedy') {
                            PinkGreedyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
                          } else if (gameType == 'fruit_wheel' || gameType == 'fruitwheel') {
                            showFruitWheelSheet(context);
                          } else if (gameType == 'greedy' || gameType == 'gready') {
                            GreadyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
                          } else {
                            GreadyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
                          }
                        },`
  );

  // Replace entire Html5GameSheet class at bottom
  const html5ClassStart = content.indexOf('class Html5GameSheet extends StatefulWidget {');
  if (html5ClassStart !== -1) {
    const updatedHtml5Class = `class Html5GameSheet extends StatefulWidget {
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
    bool isInAudioRoom = true,
  }) {
    if (isFullScreen || !isInAudioRoom) {
      // 1. Standalone / Outside Voice Room: Full Screen Mode (100% height)
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF030A1C),
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Html5GameSheet(url: url, title: title, isFullScreen: true),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // 2. Audio Room Mode: Exactly 70% height with top 30% empty/visible!
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
        Navigator.of(context).pop();
        return;
      }
      final data = jsonDecode(msg);
      if (data is Map) {
        final type = (data['type'] ?? data['action'] ?? '').toString();
        if (type == 'CLOSE_GAME' || type == 'close') {
          Navigator.of(context).pop();
        } else if (type == 'OPEN_WALLET' || type == 'OPEN_RECHARGE' || type == 'wallet') {
          final user = AuthController.instance.currentUser;
          Get.to(() => UserWalletScreen(currentUser: user));
        }
      }
    } catch (_) {
      if (msg == 'CLOSE_GAME') {
        Navigator.of(context).pop();
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
    content = content.substring(0, html5ClassStart) + updatedHtml5Class;
  }

  fs.writeFileSync(gameWallPath, content, 'utf8');
  console.log('Successfully updated game_wall_bottom_sheet.dart');
}

// 2. Update gready_game_sheet.dart
const greadyPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'gready_game_sheet.dart');
if (fs.existsSync(greadyPath)) {
  let content = fs.readFileSync(greadyPath, 'utf8');
  content = content.replace(
    /class GreadyGameSheet extends StatefulWidget {[\s\S]*?const GreadyGameSheet\(\{super\.key\}\);[\s\S]*?static void show\(BuildContext context\) \{[\s\S]*?builder: \(context\) => const GreadyGameSheet\(\),[\s\S]*?\}\.then\(\(_\) \{[\s\S]*?WidgetsBinding\.instance\.scheduleFrame\(\);[\s\S]*?\}\);[\s\S]*?\}/,
    `class GreadyGameSheet extends StatefulWidget {
  final bool isInAudioRoom;
  const GreadyGameSheet({super.key, this.isInAudioRoom = true});

  static void show(BuildContext context, {bool isInAudioRoom = true}) {
    if (!isInAudioRoom) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF4A0000),
            body: SafeArea(
              child: Stack(
                children: [
                  const GreadyGameSheet(isInAudioRoom: false),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (context) => const GreadyGameSheet(isInAudioRoom: true),
      ).then((_) {
        WidgetsBinding.instance.scheduleFrame();
      });
    }
  }`
  );
  // Update height
  content = content.replace(
    /height: MediaQuery\.of\(context\)\.size\.height \* 0\.9,/,
    'height: MediaQuery.of(context).size.height * (widget.isInAudioRoom ? 0.70 : 1.0),'
  );
  fs.writeFileSync(greadyPath, content, 'utf8');
  console.log('Successfully updated gready_game_sheet.dart');
}

// 3. Update pink_greedy_game_sheet.dart
const pinkPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'pink_greedy_game_sheet.dart');
if (fs.existsSync(pinkPath)) {
  let content = fs.readFileSync(pinkPath, 'utf8');
  content = content.replace(
    /class PinkGreedyGameSheet extends StatefulWidget {[\s\S]*?const PinkGreedyGameSheet\(\{super\.key\}\);[\s\S]*?static void show\(BuildContext context\) \{[\s\S]*?builder: \(context\) => const PinkGreedyGameSheet\(\),[\s\S]*?\}\.then\(\(_\) \{[\s\S]*?WidgetsBinding\.instance\.scheduleFrame\(\);[\s\S]*?\}\);[\s\S]*?\}/,
    `class PinkGreedyGameSheet extends StatefulWidget {
  final bool isInAudioRoom;
  const PinkGreedyGameSheet({super.key, this.isInAudioRoom = true});

  static void show(BuildContext context, {bool isInAudioRoom = true}) {
    if (!isInAudioRoom) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF3B0B3C),
            body: SafeArea(
              child: Stack(
                children: [
                  const PinkGreedyGameSheet(isInAudioRoom: false),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (context) => const PinkGreedyGameSheet(isInAudioRoom: true),
      ).then((_) {
        WidgetsBinding.instance.scheduleFrame();
      });
    }
  }`
  );
  // Update height
  content = content.replace(
    /final double sheetHeight = MediaQuery\.of\(context\)\.size\.height \* 0\.9;/,
    'final double sheetHeight = MediaQuery.of(context).size.height * (widget.isInAudioRoom ? 0.70 : 1.0);'
  );
  fs.writeFileSync(pinkPath, content, 'utf8');
  console.log('Successfully updated pink_greedy_game_sheet.dart');
}

// 4. Update food_spin_game_sheet.dart
const foodSpinPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'food_spin_game_sheet.dart');
if (fs.existsSync(foodSpinPath)) {
  let content = fs.readFileSync(foodSpinPath, 'utf8');
  content = content.replace(
    /class FoodSpinGameSheet extends StatefulWidget {[\s\S]*?const FoodSpinGameSheet\(\{super\.key\}\);[\s\S]*?static void show\(BuildContext context\) \{[\s\S]*?builder: \(context\) => const FoodSpinGameSheet\(\),[\s\S]*?\}\.then\(\(_\) \{[\s\S]*?WidgetsBinding\.instance\.scheduleFrame\(\);[\s\S]*?\}\);[\s\S]*?\}/,
    `class FoodSpinGameSheet extends StatefulWidget {
  final bool isInAudioRoom;
  const FoodSpinGameSheet({super.key, this.isInAudioRoom = true});

  static void show(BuildContext context, {bool isInAudioRoom = true}) {
    if (!isInAudioRoom) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFF141422),
            body: SafeArea(
              child: Stack(
                children: [
                  const FoodSpinGameSheet(isInAudioRoom: false),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (context) => const FoodSpinGameSheet(isInAudioRoom: true),
      ).then((_) {
        WidgetsBinding.instance.scheduleFrame();
      });
    }
  }`
  );
  // Update height
  content = content.replace(
    /height: MediaQuery\.of\(context\)\.size\.height \* 0\.78,/,
    'height: MediaQuery.of(context).size.height * (widget.isInAudioRoom ? 0.70 : 1.0),'
  );
  fs.writeFileSync(foodSpinPath, content, 'utf8');
  console.log('Successfully updated food_spin_game_sheet.dart');
}

// 5. Update room_controls.dart to pass isInAudioRoom: true
const roomControlsPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'room_controls.dart');
if (fs.existsSync(roomControlsPath)) {
  let content = fs.readFileSync(roomControlsPath, 'utf8');
  content = content.replace(
    /onTap: \(\) => GameWallBottomSheet\.show\(context\),/,
    'onTap: () => GameWallBottomSheet.show(context, isInAudioRoom: true, roomId: widget.roomId),'
  );
  fs.writeFileSync(roomControlsPath, content, 'utf8');
  console.log('Successfully updated room_controls.dart');
}

// 6. Update voice_room.dart to pass isInAudioRoom: true
const voiceRoomPath = path.join(targetBase, 'screens', 'room', 'voice_room.dart');
if (fs.existsSync(voiceRoomPath)) {
  let content = fs.readFileSync(voiceRoomPath, 'utf8');
  content = content.replace(
    /onPressed: \(\) => GameWallBottomSheet\.show\(context\),/g,
    'onPressed: () => GameWallBottomSheet.show(context, isInAudioRoom: true),'
  );
  fs.writeFileSync(voiceRoomPath, content, 'utf8');
  console.log('Successfully updated voice_room.dart');
}

// 7. Update check.dart to pass isInAudioRoom: true
const checkPath = path.join(targetBase, 'screens', 'room', 'check.dart');
if (fs.existsSync(checkPath)) {
  let content = fs.readFileSync(checkPath, 'utf8');
  content = content.replace(
    /onPressed: \(\) => GameWallBottomSheet\.show\(context\),/g,
    'onPressed: () => GameWallBottomSheet.show(context, isInAudioRoom: true),'
  );
  fs.writeFileSync(checkPath, content, 'utf8');
  console.log('Successfully updated check.dart');
}

// 8. Update wallet_screen.dart to pass isInAudioRoom: false
const walletPath = path.join(targetBase, 'screens', 'room', 'wallet_screen.dart');
if (fs.existsSync(walletPath)) {
  let content = fs.readFileSync(walletPath, 'utf8');
  content = content.replace(
    /GameWallBottomSheet\.show\(context\);/g,
    'GameWallBottomSheet.show(context, isInAudioRoom: false);'
  );
  fs.writeFileSync(walletPath, content, 'utf8');
  console.log('Successfully updated wallet_screen.dart');
}

console.log('ALL UPDATES COMPLETE!');
