const fs = require('fs');
const path = require('path');

const gameWallPath = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib\\screens\\audio_rooms_v2\\widgets\\game_wall_bottom_sheet.dart';
let content = fs.readFileSync(gameWallPath, 'utf8');

// Replace the Game List itemBuilder section with direct routing
const oldItemBuilderRegex = /itemBuilder: \(context, index\) \{[\s\S]*?\/\/ Hardcoded games first[\s\S]*?final docIndex = index - 3;[\s\S]*?return GestureDetector\([\s\S]*?\}\);\s*\},[\s\S]*?\);[\s\S]*?\},[\s\S]*?\),[\s\S]*?\);[\s\S]*?\}\s*\}\s*class Html5GameFullScreenPage/;

// Let's find the exact section to update in game_wall_bottom_sheet.dart
const greadyTapIdx = content.indexOf('if (index == 0) {');
const html5ClassIdx = content.indexOf('class Html5GameFullScreenPage extends StatelessWidget {');

if (greadyTapIdx !== -1 && html5ClassIdx !== -1) {
  // Let's craft the exact clean itemBuilder
  const updatedItemBuilder = `if (index == 0) {
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D44),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                                width: 1.5),
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
                              StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('config')
                                      .doc('greedy_game')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    String? thumbUrl;
                                    if (snapshot.hasData &&
                                        snapshot.data!.exists) {
                                      final data = snapshot.data!.data()
                                          as Map<String, dynamic>?;
                                      thumbUrl =
                                          data?['thumbnailUrl'] as String?;
                                    }
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black26,
                                        image: (thumbUrl != null &&
                                                thumbUrl.isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(thumbUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (thumbUrl == null ||
                                              thumbUrl.isEmpty)
                                          ? const Center(
                                              child: Text('🎡',
                                                  style:
                                                      TextStyle(fontSize: 30)),
                                            )
                                          : null,
                                    );
                                  }),
                              const SizedBox(height: 12),
                              const Text(
                                'Gready Game',
                                style: TextStyle(
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

                    if (index == 1) {
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D44),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withValues(alpha: 0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('config')
                                      .doc('fruit_wheel')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    String? thumbUrl;
                                    if (snapshot.hasData &&
                                        snapshot.data!.exists) {
                                      final data = snapshot.data!.data()
                                          as Map<String, dynamic>?;
                                      thumbUrl =
                                          data?['thumbnailUrl'] as String?;
                                    }
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black26,
                                        image: (thumbUrl != null &&
                                                thumbUrl.isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(thumbUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (thumbUrl == null ||
                                              thumbUrl.isEmpty)
                                          ? const Center(
                                              child: Text('🍉',
                                                  style:
                                                      TextStyle(fontSize: 30)),
                                            )
                                          : null,
                                    );
                                  }),
                              const SizedBox(height: 12),
                              const Text(
                                'Fruit Wheel',
                                style: TextStyle(
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

                    if (index == 2) {
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D44),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.pinkAccent.withValues(alpha: 0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withValues(alpha: 0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('config')
                                      .doc('pink_greedy_game')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    String? thumbUrl;
                                    if (snapshot.hasData &&
                                        snapshot.data!.exists) {
                                      final data = snapshot.data!.data()
                                          as Map<String, dynamic>?;
                                      thumbUrl =
                                          data?['thumbnailUrl'] as String?;
                                    }
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.black26,
                                        image: (thumbUrl != null &&
                                                thumbUrl.isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(thumbUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: (thumbUrl == null ||
                                              thumbUrl.isEmpty)
                                          ? const Center(
                                              child: Text('🌸',
                                                  style:
                                                      TextStyle(fontSize: 30)),
                                            )
                                          : null,
                                    );
                                  }),
                              const SizedBox(height: 12),
                              const Text(
                                'Greedy Pink',
                                style: TextStyle(
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

                    // Dynamic games from firestore
                    final docIndex = index - 3;
                    final doc = docs[docIndex];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Game';
                    final picture = data['picture'] ?? '';

                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final gameType = (data['gameType'] ?? '').toString().toLowerCase();
                        String gameUrl = (data['gameUrl'] ?? data['url'] ?? data['link'] ?? data['webViewUrl'] ?? '').toString().trim();
                        final gameCode = (data['gameCode'] ?? data['gameId'] ?? doc.id).toString().toLowerCase();

                        final bool effectiveInRoom = isInAudioRoom;

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

                          if (!effectiveInRoom) {
                            // 💳 Standalone / Wallet Screen: Direct 100% Full Screen Page
                            Get.to(
                              () => Html5GameFullScreenPage(url: finalUrl, title: name),
                              transition: Transition.rightToLeft,
                            );
                          } else {
                            // 🎙️ Voice Room: Exactly 70% Bottom Sheet, Top 30% empty/transparent
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
                              width: 1.5),
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
                                image: picture.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(picture),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.black26,
                              ),
                              child: picture.isEmpty
                                  ? const Icon(Icons.videogame_asset,
                                      color: Colors.white54, size: 30)
                                  : null,
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

`;

  content = content.substring(0, greadyTapIdx) + updatedItemBuilder + content.substring(html5ClassIdx);
  fs.writeFileSync(gameWallPath, content, 'utf8');
  console.log('Successfully applied direct routing update to game_wall_bottom_sheet.dart');
} else {
  console.log('Could not find markers: greadyTapIdx=' + greadyTapIdx + ', html5ClassIdx=' + html5ClassIdx);
}
