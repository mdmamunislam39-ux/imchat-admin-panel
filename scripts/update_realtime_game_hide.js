const fs = require('fs');
const path = require('path');

const targetBase = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib';

// 1. Update models/game_model.dart in mobile app
const gameModelPath = path.join(targetBase, 'models', 'game_model.dart');
if (fs.existsSync(gameModelPath)) {
  let content = fs.readFileSync(gameModelPath, 'utf8');
  content = content.replace(
    /isEnabled:\s*map\['isEnabled'\]\s*\?\?\s*true,/,
    "isEnabled: (map['isEnabled'] != false && map['isActive'] != false && map['status'] != 'inactive'),"
  );
  fs.writeFileSync(gameModelPath, content, 'utf8');
  console.log('Mobile app game_model.dart updated successfully.');
}

// 2. Update game_wall_bottom_sheet.dart in mobile app
const gameWallPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'game_wall_bottom_sheet.dart');
if (fs.existsSync(gameWallPath)) {
  let content = fs.readFileSync(gameWallPath, 'utf8');

  const startMarker = '// Game List';
  const endMarker = 'class Html5GameFullScreenPage extends StatelessWidget {';

  const startIndex = content.indexOf(startMarker);
  const endIndex = content.indexOf(endMarker);

  if (startIndex === -1 || endIndex === -1) {
    console.error('Could not find markers in game_wall_bottom_sheet.dart');
    process.exit(1);
  }

  const replacement = `// Game List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('config').snapshots(),
              builder: (context, configSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('games').snapshots(),
                  builder: (context, gamesSnapshot) {
                    if ((!configSnapshot.hasData && configSnapshot.connectionState == ConnectionState.waiting) ||
                        (!gamesSnapshot.hasData && gamesSnapshot.connectionState == ConnectionState.waiting)) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }

                    // 1. Config lookup map
                    final Map<String, Map<String, dynamic>> configMap = {};
                    if (configSnapshot.hasData) {
                      for (var doc in configSnapshot.data!.docs) {
                        configMap[doc.id] = (doc.data() as Map<String, dynamic>?) ?? {};
                      }
                    }

                    // Helper to evaluate if a game is active
                    bool isDocActive(Map<String, dynamic>? data, {bool defaultActive = true}) {
                      if (data == null) return defaultActive;
                      if (data['isActive'] == false) return false;
                      if (data['isEnabled'] == false) return false;
                      if (data['status'] == 'inactive') return false;
                      return true;
                    }

                    final bool isGreedyActive = isDocActive(configMap['greedy_game'], defaultActive: true);
                    final bool isFruitActive = isDocActive(configMap['fruit_wheel'], defaultActive: true);
                    final bool isPinkActive = isDocActive(configMap['pink_greedy_game'], defaultActive: true);
                    final bool isFoodSpinActive = isDocActive(configMap['food_spin_game'], defaultActive: false);

                    // 2. Build list of active game widgets
                    final List<Widget> activeGameWidgets = [];
                    final Set<String> registeredCodes = {};

                    // Greedy Game (Built-in)
                    if (isGreedyActive) {
                      registeredCodes.add('greedy_game');
                      final thumbUrl = configMap['greedy_game']?['thumbnailUrl'] as String? ?? '';
                      activeGameWidgets.add(_buildGreedyGameCard(context, thumbUrl));
                    }

                    // Fruit Wheel (Built-in)
                    if (isFruitActive) {
                      registeredCodes.add('fruit_wheel');
                      final thumbUrl = configMap['fruit_wheel']?['thumbnailUrl'] as String? ?? '';
                      activeGameWidgets.add(_buildFruitWheelCard(context, thumbUrl));
                    }

                    // Pink Greedy (Built-in)
                    if (isPinkActive) {
                      registeredCodes.add('pink_greedy_game');
                      registeredCodes.add('pink_greedy');
                      final thumbUrl = configMap['pink_greedy_game']?['thumbnailUrl'] as String? ?? '';
                      activeGameWidgets.add(_buildPinkGreedyCard(context, thumbUrl));
                    }

                    // Food Spin (Built-in)
                    if (isFoodSpinActive) {
                      registeredCodes.add('food_spin_game');
                      registeredCodes.add('food_spin');
                      activeGameWidgets.add(_buildFoodSpinCard(context));
                    }

                    // 3. Dynamic / Custom / Webview / HTML5 games from 'games' collection
                    if (gamesSnapshot.hasData) {
                      for (var doc in gamesSnapshot.data!.docs) {
                        final data = (doc.data() as Map<String, dynamic>?) ?? {};
                        if (!isDocActive(data, defaultActive: true)) {
                          continue; // Hidden in games collection
                        }

                        final gameCode = (data['gameCode'] ?? data['gameId'] ?? doc.id).toString().toLowerCase();

                        // Built-in system games override check
                        if (gameCode == 'greedy_game' || doc.id == 'greedy_game') {
                          continue;
                        }
                        if (gameCode == 'fruit_wheel' || doc.id == 'fruit_wheel') {
                          continue;
                        }
                        if (gameCode == 'pink_greedy_game' || doc.id == 'pink_greedy_game' || gameCode == 'pink_greedy') {
                          continue;
                        }
                        if (gameCode == 'food_spin_game' || doc.id == 'food_spin_game' || gameCode == 'food_spin') {
                          continue;
                        }

                        // Prevent duplicates
                        if (registeredCodes.contains(gameCode) || registeredCodes.contains(doc.id)) {
                          continue;
                        }
                        registeredCodes.add(gameCode);
                        registeredCodes.add(doc.id);

                        activeGameWidgets.add(_buildDynamicGameCard(context, doc.id, data));
                      }
                    }

                    if (activeGameWidgets.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_esports_outlined, color: Colors.white24, size: 64),
                            SizedBox(height: 12),
                            Text(
                              'No games available right now',
                              style: TextStyle(color: Colors.white60, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: activeGameWidgets.length,
                      itemBuilder: (context, index) => activeGameWidgets[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreedyGameCard(BuildContext context, String thumbUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (!isInAudioRoom) {
          Get.to(() => Scaffold(
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
          ));
        } else {
          GreadyGameSheet.show(context, isInAudioRoom: true);
        }
      },
      child: _buildGameContainer(
        title: 'Gready Game',
        thumbUrl: thumbUrl,
        fallbackEmoji: '🎡',
        borderColor: Colors.amber,
      ),
    );
  }

  Widget _buildFruitWheelCard(BuildContext context, String thumbUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (!isInAudioRoom) {
          Get.to(() => Scaffold(
            backgroundColor: const Color(0xFF0D0020),
            body: SafeArea(
              child: Stack(
                children: [
                  const FruitWheelSheet(isInAudioRoom: false),
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
          ));
        } else {
          showFruitWheelSheet(context, isInAudioRoom: true);
        }
      },
      child: _buildGameContainer(
        title: 'Fruit Wheel',
        thumbUrl: thumbUrl,
        fallbackEmoji: '🍉',
        borderColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildPinkGreedyCard(BuildContext context, String thumbUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (!isInAudioRoom) {
          Get.to(() => Scaffold(
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
          ));
        } else {
          PinkGreedyGameSheet.show(context, isInAudioRoom: true);
        }
      },
      child: _buildGameContainer(
        title: 'Greedy Pink',
        thumbUrl: thumbUrl,
        fallbackEmoji: '🌸',
        borderColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildFoodSpinCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        FoodSpinGameSheet.show(context, isInAudioRoom: isInAudioRoom);
      },
      child: _buildGameContainer(
        title: 'Food Spin',
        thumbUrl: '',
        fallbackEmoji: '🍕',
        borderColor: Colors.deepOrangeAccent,
      ),
    );
  }

  Widget _buildGameContainer({
    required String title,
    required String thumbUrl,
    required String fallbackEmoji,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black26,
            ),
            clipBehavior: Clip.antiAlias,
            child: thumbUrl.isNotEmpty
                ? Image.network(
                    thumbUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Center(child: Text(fallbackEmoji, style: const TextStyle(fontSize: 30))),
                  )
                : Center(child: Text(fallbackEmoji, style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicGameCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final name = (data['name'] ?? data['title'] ?? 'Game').toString();
    final picture = (data['picture'] ?? data['thumbnailUrl'] ?? data['icon'] ?? data['image'] ?? '').toString();

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final gameType = (data['gameType'] ?? data['type'] ?? '').toString().toLowerCase();
        String gameUrl = (data['gameUrl'] ?? data['url'] ?? data['link'] ?? data['webViewUrl'] ?? '').toString().trim();
        final gameCode = (data['gameCode'] ?? data['gameId'] ?? docId).toString().toLowerCase();

        final bool effectiveInRoom = isInAudioRoom;

        // 1. Direct In-App WebView / HTML5 Game Opening (No external browser!)
        if (gameUrl.isNotEmpty || gameCode.contains('html5') || gameCode.contains('market') || gameCode.contains('delicious') || gameCode.contains('slot') || gameType == 'html5' || gameType == 'webview') {
          if (gameUrl.isEmpty) {
            if (gameCode.contains('delicious')) {
              gameUrl = 'https://greedy-delicious-game.web.app';
            } else if (gameCode.contains('slot')) {
              gameUrl = 'https://king-queen-slot-game.web.app';
            } else {
              gameUrl = 'https://greedy-market-game.web.app';
            }
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

          if (!effectiveInRoom) {
            // 💳 Standalone / Wallet Screen: Direct 100% Full Screen Page
            Get.to(
              () => Html5GameFullScreenPage(url: finalUrl, title: name),
              transition: Transition.rightToLeft,
            );
          } else {
            // 🎙️ Voice Room: Exactly 75% Bottom Sheet, Top 25% empty/transparent
            Html5GameSheet.show(
              context,
              url: finalUrl,
              title: name,
              isFullScreen: false,
              isInAudioRoom: true,
            );
          }
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
          showFruitWheelSheet(context, isInAudioRoom: effectiveInRoom);
        } else if (gameType == 'greedy' || gameType == 'gready') {
          GreadyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
        } else {
          GreadyGameSheet.show(context, isInAudioRoom: effectiveInRoom);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black26,
              ),
              clipBehavior: Clip.antiAlias,
              child: picture.isNotEmpty
                  ? Image.network(
                      picture,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.sports_esports, color: Colors.white54, size: 30),
                    )
                  : const Icon(Icons.videogame_asset, color: Colors.white54, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

`;

  const updatedContent = content.substring(0, startIndex) + replacement + content.substring(endIndex);
  fs.writeFileSync(gameWallPath, updatedContent, 'utf8');
  console.log('Mobile app game_wall_bottom_sheet.dart updated successfully!');
}
