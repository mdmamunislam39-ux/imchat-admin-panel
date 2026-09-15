const fs = require('fs');
const path = require('path');

const targetBase = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib';

// 1. Update game_wall_bottom_sheet.dart
const gameWallPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'game_wall_bottom_sheet.dart');
if (fs.existsSync(gameWallPath)) {
  let content = fs.readFileSync(gameWallPath, 'utf8');

  // Update effectiveInRoom in show()
  content = content.replace(
    /final bool effectiveInRoom = isInAudioRoom \?\? \([\s\S]*?\);[\s\S]*?showModalBottomSheet/,
    'final bool effectiveInRoom = isInAudioRoom ?? (room != null || roomId != null);\n\n    showModalBottomSheet'
  );

  // Update dynamic games onTap effectiveInRoom
  content = content.replace(
    /final bool effectiveInRoom = isInAudioRoom \|\|[\s\S]*?Get\.find<MinimizedRoomController>\(\)\.currentRoom != null\)\);/,
    'final bool effectiveInRoom = isInAudioRoom;'
  );

  // Update fruit wheel in hardcoded index 1
  content = content.replace(
    /showFruitWheelSheet\(context\);/g,
    'showFruitWheelSheet(context, isInAudioRoom: isInAudioRoom);'
  );

  fs.writeFileSync(gameWallPath, content, 'utf8');
  console.log('Updated game_wall_bottom_sheet.dart successfully');
}

// 2. Update fruit_wheel_page.dart
const fruitWheelPath = path.join(targetBase, 'features', 'fruit_wheel', 'presentation', 'pages', 'fruit_wheel_page.dart');
if (fs.existsSync(fruitWheelPath)) {
  let content = fs.readFileSync(fruitWheelPath, 'utf8');

  const oldDef = `/// Shows the Fruit Wheel game as a bottom sheet.
void showFruitWheelSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    enableDrag: true,
    builder: (_) => const FruitWheelSheet(),
  );
}

class FruitWheelSheet extends StatelessWidget {
  const FruitWheelSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FruitWheelBloc(
        repository: FruitWheelRepositoryImpl(
          realtimeDb: FirebaseDatabase.instance,
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      )..add(ConnectToGame()),
      child: const _FruitWheelSheetContent(),
    );
  }
}

class _FruitWheelSheetContent extends StatefulWidget {
  const _FruitWheelSheetContent();`;

  const newDef = `/// Shows the Fruit Wheel game as a bottom sheet (in voice room) or full screen (outside voice room).
void showFruitWheelSheet(BuildContext context, {bool isInAudioRoom = true}) {
  if (!isInAudioRoom) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
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
      enableDrag: true,
      builder: (_) => const FruitWheelSheet(isInAudioRoom: true),
    );
  }
}

class FruitWheelSheet extends StatelessWidget {
  final bool isInAudioRoom;
  const FruitWheelSheet({super.key, this.isInAudioRoom = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FruitWheelBloc(
        repository: FruitWheelRepositoryImpl(
          realtimeDb: FirebaseDatabase.instance,
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        ),
      )..add(ConnectToGame()),
      child: _FruitWheelSheetContent(isInAudioRoom: isInAudioRoom),
    );
  }
}

class _FruitWheelSheetContent extends StatefulWidget {
  final bool isInAudioRoom;
  const _FruitWheelSheetContent({this.isInAudioRoom = true});`;

  if (content.includes(oldDef)) {
    content = content.replace(oldDef, newDef);
    content = content.replace(
      'height: screenHeight * 0.75,',
      'height: screenHeight * (widget.isInAudioRoom ? 0.70 : 1.0),'
    );
    fs.writeFileSync(fruitWheelPath, content, 'utf8');
    console.log('Updated fruit_wheel_page.dart successfully');
  } else {
    console.log('fruit_wheel_page.dart signature not matched, skipping or already modified');
  }
}
