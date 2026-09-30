const fs = require('fs');
const path = require('path');

const audioRoomScreenPath = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib\\screens\\audio_rooms_v2\\audio_room_screen.dart';

if (!fs.existsSync(audioRoomScreenPath)) {
  console.error('audio_room_screen.dart does not exist at:', audioRoomScreenPath);
  process.exit(1);
}

let content = fs.readFileSync(audioRoomScreenPath, 'utf8');

// 1. Add html5_game_sheet.dart import if not present
if (!content.includes("screens/audio_rooms_v2/widgets/html5_game_sheet.dart")) {
  const importTarget = "import 'package:chat_messenger/screens/audio_rooms_v2/widgets/room_pk_settings_sheet.dart';";
  if (content.includes(importTarget)) {
    content = content.replace(
      importTarget,
      importTarget + "\nimport 'package:chat_messenger/screens/audio_rooms_v2/widgets/html5_game_sheet.dart';"
    );
    console.log('Added html5_game_sheet.dart import.');
  }
}

// 2. Update _showVoiceRoomCustomize Room Mode & Room Game rows with real-time StreamBuilder
const oldCustomizeSection = `                      // 1. Room Mode Row
                      _buildSectionHeader('Room Mode'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 95,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildCustomizeItem('Ludo', Icons.gamepad, 'mode'),
                            const SizedBox(width: 15),
                            _buildCustomizeItem(
                              'Carrom',
                              Icons.blur_circular,
                              'mode',
                            ),
                            const SizedBox(width: 15),
                            _buildCustomizeItem(
                              'YouTube',
                              Icons.video_collection,
                              'mode',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      // 2. Room Game Row
                      _buildSectionHeader('Room Game'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 95,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildCustomizeItem(
                              'Ludo Champion',
                              Icons.casino,
                              'game',
                            ),
                            const SizedBox(width: 15),
                            _buildCustomizeItem(
                              'Vote Pro',
                              Icons.how_to_vote,
                              'game',
                            ),
                            const SizedBox(width: 15),
                            _buildCustomizeItem('Dice', Icons.casino, 'game'),
                            const SizedBox(width: 15),
                            _buildCustomizeItem(
                              'Custom Roulette',
                              Icons.circle_notifications,
                              'game',
                            ),
                            const SizedBox(width: 15),
                            _buildCustomizeItem(
                              'PK Battle',
                              Icons.sports_kabaddi,
                              'game',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),`;

const newCustomizeSection = `                      // 1. & 2. Dynamic Room Mode & Room Game Sections with Real-Time Firestore Sync
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('config')
                            .doc('room_games')
                            .snapshots(),
                        builder: (context, configSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('room_games')
                                .snapshots(),
                            builder: (context, roomGamesSnapshot) {
                              final Map<String, dynamic> configMap =
                                  (configSnapshot.hasData &&
                                          configSnapshot.data!.exists)
                                      ? (configSnapshot.data!.data()
                                              as Map<String, dynamic>? ??
                                          {})
                                      : {};

                              final Map<String, Map<String, dynamic>>
                                  roomGamesMap = {};
                              final List<DocumentSnapshot>
                                  customRoomGameDocs = [];
                              final Set<String> builtInKeys = {
                                'ludo',
                                'carrom',
                                'youtube',
                                'vote_pro',
                                'dice',
                                'custom_roulette',
                                'pk_battle',
                              };

                              if (roomGamesSnapshot.hasData) {
                                for (final doc in roomGamesSnapshot.data!.docs) {
                                  final data =
                                      (doc.data() as Map<String, dynamic>?) ??
                                          {};
                                  final docId = doc.id.toLowerCase();
                                  roomGamesMap[docId] = data;
                                  final gameCode = (data['gameCode'] ?? doc.id)
                                      .toString()
                                      .toLowerCase();
                                  if (!builtInKeys.contains(docId) &&
                                      !builtInKeys.contains(gameCode)) {
                                    customRoomGameDocs.add(doc);
                                  }
                                }
                              }

                              // Helper to check if built-in game is active
                              bool isGameActive(String key) {
                                if (roomGamesMap.containsKey(key)) {
                                  final d = roomGamesMap[key]!;
                                  if (d['isActive'] == false ||
                                      d['isActive'] == 0 ||
                                      d['isActive'] == 'false') {
                                    return false;
                                  }
                                  if (d['isEnabled'] == false ||
                                      d['isEnabled'] == 0 ||
                                      d['isEnabled'] == 'false') {
                                    return false;
                                  }
                                  final s = (d['status'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  if (s == 'inactive' ||
                                      s == 'disabled' ||
                                      s == 'hidden') {
                                    return false;
                                  }
                                }
                                if (configMap.containsKey(key)) {
                                  final val = configMap[key];
                                  if (val is Map) {
                                    final a = val['isActive'] ??
                                        val['isEnabled'] ??
                                        val['active'];
                                    if (a == false ||
                                        a == 0 ||
                                        a == 'false' ||
                                        a == '0') {
                                      return false;
                                    }
                                    final s = (val['status'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    if (s == 'inactive' ||
                                        s == 'disabled' ||
                                        s == 'hidden') {
                                      return false;
                                    }
                                  } else if (val is bool) {
                                    if (!val) return false;
                                  }
                                }
                                if (configMap.containsKey('\${key}_active')) {
                                  final f = configMap['\${key}_active'];
                                  if (f == false ||
                                      f == 0 ||
                                      f == 'false' ||
                                      f == '0') {
                                    return false;
                                  }
                                }
                                return true;
                              }

                              // 1. Build Room Mode list
                              final List<Widget> modeItems = [];
                              if (isGameActive('ludo')) {
                                modeItems.add(
                                  _buildCustomizeItem('Ludo', Icons.gamepad, 'mode'),
                                );
                              }
                              if (isGameActive('carrom')) {
                                modeItems.add(
                                  _buildCustomizeItem(
                                    'Carrom',
                                    Icons.blur_circular,
                                    'mode',
                                  ),
                                );
                              }
                              if (isGameActive('youtube')) {
                                modeItems.add(
                                  _buildCustomizeItem(
                                    'YouTube',
                                    Icons.video_collection,
                                    'mode',
                                  ),
                                );
                              }

                              // Custom room modes from room_games
                              for (final doc in customRoomGameDocs) {
                                final data =
                                    (doc.data() as Map<String, dynamic>?) ?? {};
                                final cat = (data['category'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                if (cat != 'mode' && cat != 'room_mode') continue;

                                if (data['isActive'] == false ||
                                    data['isActive'] == 0 ||
                                    data['isActive'] == 'false') {
                                  continue;
                                }
                                if (data['isEnabled'] == false ||
                                    data['isEnabled'] == 0 ||
                                    data['isEnabled'] == 'false') {
                                  continue;
                                }
                                final s = (data['status'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                if (s == 'inactive' ||
                                    s == 'disabled' ||
                                    s == 'hidden') {
                                  continue;
                                }

                                final name = (data['name'] ??
                                        data['title'] ??
                                        'Custom Mode')
                                    .toString();
                                final thumb = (data['thumbnailUrl'] ??
                                        data['picture'] ??
                                        data['icon'] ??
                                        '')
                                    .toString();
                                final url = (data['gameUrl'] ??
                                        data['url'] ??
                                        data['link'] ??
                                        data['webViewUrl'] ??
                                        '')
                                    .toString()
                                    .trim();

                                modeItems.add(
                                  _buildCustomizeItem(
                                    name,
                                    Icons.sports_esports_rounded,
                                    'mode',
                                    customThumbnailUrl:
                                        thumb.isNotEmpty ? thumb : null,
                                    onCustomTap: () {
                                      if (url.isNotEmpty) {
                                        Html5GameSheet.show(
                                          context,
                                          url: url,
                                          title: name,
                                          isInAudioRoom: true,
                                          roomId: _currentRoom.id,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('\$name launched'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }

                              // 2. Build Room Game list
                              final List<Widget> gameItems = [];
                              if (isGameActive('ludo')) {
                                gameItems.add(
                                  _buildCustomizeItem(
                                    'Ludo Champion',
                                    Icons.casino,
                                    'game',
                                  ),
                                );
                              }
                              if (isGameActive('vote_pro')) {
                                gameItems.add(
                                  _buildCustomizeItem(
                                    'Vote Pro',
                                    Icons.how_to_vote,
                                    'game',
                                  ),
                                );
                              }
                              if (isGameActive('dice')) {
                                gameItems.add(
                                  _buildCustomizeItem('Dice', Icons.casino, 'game'),
                                );
                              }
                              if (isGameActive('custom_roulette')) {
                                gameItems.add(
                                  _buildCustomizeItem(
                                    'Custom Roulette',
                                    Icons.circle_notifications,
                                    'game',
                                  ),
                                );
                              }
                              if (isGameActive('pk_battle')) {
                                gameItems.add(
                                  _buildCustomizeItem(
                                    'PK Battle',
                                    Icons.sports_kabaddi,
                                    'game',
                                  ),
                                );
                              }

                              // Custom room games from room_games
                              for (final doc in customRoomGameDocs) {
                                final data =
                                    (doc.data() as Map<String, dynamic>?) ?? {};
                                final cat = (data['category'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                if (cat == 'mode' || cat == 'room_mode') continue;

                                if (data['isActive'] == false ||
                                    data['isActive'] == 0 ||
                                    data['isActive'] == 'false') {
                                  continue;
                                }
                                if (data['isEnabled'] == false ||
                                    data['isEnabled'] == 0 ||
                                    data['isEnabled'] == 'false') {
                                  continue;
                                }
                                final s = (data['status'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                if (s == 'inactive' ||
                                    s == 'disabled' ||
                                    s == 'hidden') {
                                  continue;
                                }

                                final name = (data['name'] ??
                                        data['title'] ??
                                        'Custom Game')
                                    .toString();
                                final thumb = (data['thumbnailUrl'] ??
                                        data['picture'] ??
                                        data['icon'] ??
                                        '')
                                    .toString();
                                final url = (data['gameUrl'] ??
                                        data['url'] ??
                                        data['link'] ??
                                        data['webViewUrl'] ??
                                        '')
                                    .toString()
                                    .trim();

                                gameItems.add(
                                  _buildCustomizeItem(
                                    name,
                                    Icons.casino_rounded,
                                    'game',
                                    customThumbnailUrl:
                                        thumb.isNotEmpty ? thumb : null,
                                    onCustomTap: () {
                                      if (url.isNotEmpty) {
                                        Html5GameSheet.show(
                                          context,
                                          url: url,
                                          title: name,
                                          isInAudioRoom: true,
                                          roomId: _currentRoom.id,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('\$name launched'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }

                              // Layout horizontal spaced items
                              final List<Widget> modeWidgets = [];
                              for (int i = 0; i < modeItems.length; i++) {
                                if (i > 0) {
                                  modeWidgets.add(const SizedBox(width: 15));
                                }
                                modeWidgets.add(modeItems[i]);
                              }

                              final List<Widget> gameWidgets = [];
                              for (int i = 0; i < gameItems.length; i++) {
                                if (i > 0) {
                                  gameWidgets.add(const SizedBox(width: 15));
                                }
                                gameWidgets.add(gameItems[i]);
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (modeItems.isNotEmpty) ...[
                                    _buildSectionHeader('Room Mode'),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 95,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        children: modeWidgets,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],

                                  if (gameItems.isNotEmpty) ...[
                                    _buildSectionHeader('Room Game'),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 95,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        children: gameWidgets,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      ),`;

if (content.includes(oldCustomizeSection)) {
  content = content.replace(oldCustomizeSection, newCustomizeSection);
  console.log('Replaced Customize section with real-time StreamBuilder.');
} else {
  console.error('Could not find oldCustomizeSection in audio_room_screen.dart');
}

// 3. Update _buildCustomizeItem signature & implementation
const oldCustomizeItemSig = `  Widget _buildCustomizeItem(
    String title,
    IconData defaultIcon,
    String category,
  ) {`;

const newCustomizeItemSig = `  Widget _buildCustomizeItem(
    String title,
    IconData defaultIcon,
    String category, {
    String? customThumbnailUrl,
    VoidCallback? onCustomTap,
  }) {`;

if (content.includes(oldCustomizeItemSig)) {
  content = content.replace(oldCustomizeItemSig, newCustomizeItemSig);
  console.log('Updated _buildCustomizeItem signature.');
}

const oldDismissTarget = `        // First dismiss the customize dialog
        Navigator.of(context).pop();

        // Execute action based on title`;

const newDismissTarget = `        // First dismiss the customize dialog
        Navigator.of(context).pop();

        if (onCustomTap != null) {
          onCustomTap();
          return;
        }

        // Execute action based on title`;

if (content.includes(oldDismissTarget)) {
  content = content.replace(oldDismissTarget, newDismissTarget);
  console.log('Updated _buildCustomizeItem onTap handling.');
}

const oldIconHandling = `            Obx(() {
              String? customIconUrl;
              if (Get.isRegistered<AppThemeService>()) {
                final themeService = Get.find<AppThemeService>();
                customIconUrl = _getCustomIconUrl(themeService, settingKey);
              }

              // Determine icon container styling
              Widget iconWidget;
              if (customIconUrl != null && customIconUrl.isNotEmpty) {`;

const newIconHandling = `            Obx(() {
              String? themeIconUrl;
              if (Get.isRegistered<AppThemeService>()) {
                final themeService = Get.find<AppThemeService>();
                themeIconUrl = _getCustomIconUrl(themeService, settingKey);
              }

              final effectiveIconUrl = (customThumbnailUrl != null && customThumbnailUrl.isNotEmpty)
                  ? customThumbnailUrl
                  : themeIconUrl;

              // Determine icon container styling
              Widget iconWidget;
              if (effectiveIconUrl != null && effectiveIconUrl.isNotEmpty) {`;

if (content.includes(oldIconHandling)) {
  content = content.replace(oldIconHandling, newIconHandling);
  content = content.replace(
    /imageUrl:\s*customIconUrl,/g,
    'imageUrl: effectiveIconUrl,'
  );
  content = content.replace(
    /key:\s*ValueKey\(customIconUrl\),/g,
    'key: ValueKey(effectiveIconUrl),'
  );
  console.log('Updated _buildCustomizeItem icon handling.');
}

fs.writeFileSync(audioRoomScreenPath, content, 'utf8');
console.log('Successfully updated audio_room_screen.dart for real-time Room Game hide!');
