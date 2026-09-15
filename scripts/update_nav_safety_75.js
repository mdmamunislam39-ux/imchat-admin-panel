const fs = require('fs');
const path = require('path');

const targetBase = 'C:\\imchat-new-own-dev\\imchat-new-own-dev\\lib';

// 1. Update game_wall_bottom_sheet.dart
const gameWallPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'game_wall_bottom_sheet.dart');
if (fs.existsSync(gameWallPath)) {
  let content = fs.readFileSync(gameWallPath, 'utf8');

  // In Html5GameFullScreenPage: change bottom: false to bottom: true
  content = content.replace(
    /body: SafeArea\(\s*top: true,\s*bottom: false,/,
    'body: SafeArea(\n        top: true,\n        bottom: true,'
  );

  // In Html5GameSheet.show: change heightFactor from 0.70 to 0.75 and add SafeArea(top: false, bottom: true)
  content = content.replace(
    /builder: \(ctx\) => FractionallySizedBox\(\s*heightFactor: 0\.70,[\s\S]*?child: Container\(\s*color: const Color\(0xFF030A1C\),\s*child: Column\(/,
    `builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.75, // Voice Room: Exactly 75% screen height!
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              color: const Color(0xFF030A1C),
              child: SafeArea(
                top: false,
                bottom: true,
                child: Column(`
  );

  // Close SafeArea inside Html5GameSheet.show
  content = content.replace(
    /child: Html5GameSheet\(url: url, title: title, isFullScreen: false\),\s*\),\s*\],\s*\),\s*\),\s*\),\s*\),/,
    `child: Html5GameSheet(url: url, title: title, isFullScreen: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),`
  );

  fs.writeFileSync(gameWallPath, content, 'utf8');
  console.log('game_wall_bottom_sheet.dart updated for 75% height and bottom navigation SafeArea');
}

// 2. Update gready_game_sheet.dart
const greadyPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'gready_game_sheet.dart');
if (fs.existsSync(greadyPath)) {
  let content = fs.readFileSync(greadyPath, 'utf8');
  content = content.replace(
    /height: MediaQuery\.of\(context\)\.size\.height \* \(widget\.isInAudioRoom \? 0\.70 : 1\.0\),/,
    'height: MediaQuery.of(context).size.height * (widget.isInAudioRoom ? 0.75 : 1.0),'
  );
  content = content.replace(
    /builder: \(context\) => const GreadyGameSheet\(isInAudioRoom: true\),/,
    'builder: (context) => const SafeArea(top: false, bottom: true, child: GreadyGameSheet(isInAudioRoom: true)),'
  );
  fs.writeFileSync(greadyPath, content, 'utf8');
  console.log('gready_game_sheet.dart updated for 75% height and SafeArea');
}

// 3. Update pink_greedy_game_sheet.dart
const pinkPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'pink_greedy_game_sheet.dart');
if (fs.existsSync(pinkPath)) {
  let content = fs.readFileSync(pinkPath, 'utf8');
  content = content.replace(
    /sheetHeight = MediaQuery\.of\(context\)\.size\.height \* \(widget\.isInAudioRoom \? 0\.70 : 1\.0\);/,
    'sheetHeight = MediaQuery.of(context).size.height * (widget.isInAudioRoom ? 0.75 : 1.0);'
  );
  content = content.replace(
    /builder: \(context\) => const PinkGreedyGameSheet\(isInAudioRoom: true\),/,
    'builder: (context) => const SafeArea(top: false, bottom: true, child: PinkGreedyGameSheet(isInAudioRoom: true)),'
  );
  fs.writeFileSync(pinkPath, content, 'utf8');
  console.log('pink_greedy_game_sheet.dart updated for 75% height and SafeArea');
}

// 4. Update food_spin_game_sheet.dart
const foodSpinPath = path.join(targetBase, 'screens', 'audio_rooms_v2', 'widgets', 'food_spin_game_sheet.dart');
if (fs.existsSync(foodSpinPath)) {
  let content = fs.readFileSync(foodSpinPath, 'utf8');
  content = content.replace(
    /height: MediaQuery\.of\(context\)\.size\.height \* \(widget\.isInAudioRoom \? 0\.70 : 1\.0\),/,
    'height: MediaQuery.of(context).size.height * (widget.isInAudioRoom ? 0.75 : 1.0),'
  );
  content = content.replace(
    /builder: \(context\) => const FoodSpinGameSheet\(isInAudioRoom: true\),/,
    'builder: (context) => const SafeArea(top: false, bottom: true, child: FoodSpinGameSheet(isInAudioRoom: true)),'
  );
  fs.writeFileSync(foodSpinPath, content, 'utf8');
  console.log('food_spin_game_sheet.dart updated for 75% height and SafeArea');
}

// 5. Update fruit_wheel_page.dart
const fruitWheelPath = path.join(targetBase, 'features', 'fruit_wheel', 'presentation', 'pages', 'fruit_wheel_page.dart');
if (fs.existsSync(fruitWheelPath)) {
  let content = fs.readFileSync(fruitWheelPath, 'utf8');
  content = content.replace(
    /height: screenHeight \* \(widget\.isInAudioRoom \? 0\.70 : 1\.0\),/,
    'height: screenHeight * (widget.isInAudioRoom ? 0.75 : 1.0),'
  );
  content = content.replace(
    /builder: \(_\) => const FruitWheelSheet\(isInAudioRoom: true\),/,
    'builder: (_) => const SafeArea(top: false, bottom: true, child: FruitWheelSheet(isInAudioRoom: true)),'
  );
  fs.writeFileSync(fruitWheelPath, content, 'utf8');
  console.log('fruit_wheel_page.dart updated for 75% height and SafeArea');
}

// 6. Update CSS in public_games/greedy_delicious and D:/All Game html5/Greedy-Delicious
const deliciousPaths = [
  'C:\\imchat-new-own-dev\\imchat_adminPaneL-main\\public_games\\greedy_delicious\\style.css',
  'D:\\All Game html5\\Greedy-Delicious\\style.css'
];

deliciousPaths.forEach(p => {
  if (fs.existsSync(p)) {
    let css = fs.readFileSync(p, 'utf8');
    // Ensure .bottom-stats-footer has safe-area padding and margin
    css = css.replace(
      /\.bottom-stats-footer\s*\{[\s\S]*?padding:\s*6px 12px 12px 12px;[\s\S]*?gap:\s*10px;\s*\}/,
      `.bottom-stats-footer {
  position: relative;
  z-index: 5;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px max(14px, env(safe-area-inset-bottom, 14px)) 12px;
  gap: 10px;
  margin-bottom: max(6px, env(safe-area-inset-bottom, 6px));
}`
    );

    // Ensure #app-container has safe area bottom padding
    css = css.replace(
      /#app-container\s*\{([\s\S]*?)z-index:\s*1;\s*\}/,
      `#app-container {$1z-index: 1;\n  padding-bottom: max(8px, env(safe-area-inset-bottom, 8px));\n}`
    );

    fs.writeFileSync(p, css, 'utf8');
    console.log('Updated CSS at: ' + p);
  }
});
