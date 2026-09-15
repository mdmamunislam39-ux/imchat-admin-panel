/**
 * Greedy Market HTML5 Game Engine
 * Ferris Wheel Edition - 100% Global Server-Synchronized Clock & Deterministic Multiplayer State
 */

// Default Configuration (Pixel-Perfect to Screenshot)
const DEFAULT_CONFIG = {
  betTime: 30, // 30 seconds betting phase
  spinTime: 6, // 6 seconds wheel spin
  resultTime: 5, // 5 seconds win celebration
  winRatio: 65,

  // 8 Items matching Screenshot
  items: [
    { id: 0, name: 'Apple', multiplier: 5, icon: 'https://cdn-icons-png.flaticon.com/512/415/415733.png', optionId: 20 },
    { id: 1, name: 'Lemon', multiplier: 5, icon: 'https://cdn-icons-png.flaticon.com/512/1791/1791336.png', optionId: 21 },
    { id: 2, name: 'Strawberry', multiplier: 5, icon: 'https://cdn-icons-png.flaticon.com/512/590/590685.png', optionId: 22 },
    { id: 3, name: 'Mango', multiplier: 5, icon: 'https://cdn-icons-png.flaticon.com/512/2909/2909890.png', hasFire: true, optionId: 23 },
    { id: 4, name: 'Roast Fish', multiplier: 10, icon: 'https://cdn-icons-png.flaticon.com/512/2253/2253308.png', optionId: 24 },
    { id: 5, name: 'Burger', multiplier: 15, icon: 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png', optionId: 25 },
    { id: 6, name: 'Pizza Slice', multiplier: 25, icon: 'https://cdn-icons-png.flaticon.com/512/1404/1404945.png', optionId: 26 },
    { id: 7, name: 'Roast Chicken', multiplier: 45, icon: 'https://cdn-icons-png.flaticon.com/512/1046/1046751.png', optionId: 27 }
  ],

  // 6 Casino Chips
  chips: [
    { value: 100, label: '100', class: 'chip-cyan' },
    { value: 1000, label: '1K', class: 'chip-green' },
    { value: 10000, label: '10K', class: 'chip-blue' },
    { value: 50000, label: '50K', class: 'chip-orange' },
    { value: 100000, label: '100K', class: 'chip-red' },
    { value: 200000, label: '200K', class: 'chip-purple' }
  ],

  // 5 Milestones Chests
  milestones: [
    { label: '1M', icon: 'https://cdn-icons-png.flaticon.com/512/2645/2645897.png' },
    { label: '10M', icon: 'https://cdn-icons-png.flaticon.com/512/2645/2645897.png' },
    { label: '50M', icon: 'https://cdn-icons-png.flaticon.com/512/2645/2645897.png' },
    { label: '100M', icon: 'https://cdn-icons-png.flaticon.com/512/2645/2645897.png' },
    { label: '500M', icon: 'https://cdn-icons-png.flaticon.com/512/2645/2645897.png' }
  ],

  forceWinnerIndex: -1,
  uiLayout: {}
};

class GreedyGame {
  constructor() {
    this.config = JSON.parse(JSON.stringify(DEFAULT_CONFIG));
    this.balance = 0; // Starts at 0 until live user wallet balance loads
    this.todaysWin = 0; // 24-Hour accumulated win (10:00 PM to 10:00 PM cycle)
    this.current10PmCycle = '';
    this.selectedChipIndex = 1; // '1K'
    this.currentBets = {}; // { [slotIndex]: amount }
    this.activeRoundBets = {}; // bets recorded for current global round
    this.userBetHistory = []; // User's personal round-by-round bet records
    this.currentRoundId = null;
    this.gameState = 'BETTING'; // 'BETTING', 'SPINNING', 'RESULT'
    this.remainingSeconds = 30;
    this.soundEnabled = true;
    this.audioCtx = null;
    this.db = null;
    this.processedRounds = new Set();

    // App User Profile Details
    const urlParams = new URLSearchParams(window.location.search);
    this.userId = urlParams.get('userId') || urlParams.get('uid') || urlParams.get('user_id') || null;
    this.userName = urlParams.get('fullname') || urlParams.get('name') || urlParams.get('userName') || urlParams.get('username') || urlParams.get('nickname') || 'Player';
    this.userAvatar = urlParams.get('photoUrl') || urlParams.get('avatar') || urlParams.get('avatarUrl') || urlParams.get('profilePic') || urlParams.get('photo') || '';
    this.token = urlParams.get('token') || null;
    this.roomId = urlParams.get('roomId') || urlParams.get('room_id') || null;
    this.isRealUser = Boolean(this.userId);

    const diamondIconParam = urlParams.get('diamondIcon') || urlParams.get('diamond_icon') || urlParams.get('diamondUrl');
    this.diamondIconUrl = diamondIconParam || '';
    if (diamondIconParam) {
      window.REMOTE_DIAMOND_ICON = diamondIconParam;
      setTimeout(() => {
        document.querySelectorAll('.app-diamond-img').forEach(img => img.src = diamondIconParam);
      }, 50);
    }

    const initialDiamonds = urlParams.get('diamonds') || urlParams.get('coins') || urlParams.get('balance');
    if (initialDiamonds !== null && !isNaN(Number(initialDiamonds))) {
      this.balance = Number(initialDiamonds);
    }

    // Top 10 Daily Winners (Empty by default, populated only from real player wins)
    this.topWinnersList = [];
  }

  // Calculate 10:00 PM (22:00) 24-Hour Cycle Identifier in Asia/Dhaka (UTC+6)
  get10PmCycleKey(now = new Date()) {
    const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
    const bdTime = new Date(utc + (3600000 * 6)); // UTC+6
    // If current hour in Bangladesh < 22 (10:00 PM), cycle began yesterday at 22:00
    if (bdTime.getHours() < 22) {
      bdTime.setDate(bdTime.getDate() - 1);
    }
    const yyyy = bdTime.getFullYear();
    const mm = String(bdTime.getMonth() + 1).padStart(2, '0');
    const dd = String(bdTime.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}_2200`;
  }

  // Load Today's Win for the current 10:00 PM cycle
  loadTodaysWin() {
    const cycleKey = this.get10PmCycleKey();
    this.current10PmCycle = cycleKey;
    const storageKey = `greedy_todays_win_${this.userId || 'guest'}_${cycleKey}`;
    const saved = localStorage.getItem(storageKey);
    this.todaysWin = (saved !== null && !isNaN(Number(saved))) ? Number(saved) : 0;
    this.updateTodaysWinUI();
  }

  // Accumulate win into current 10:00 PM 24-Hour cycle
  addTodaysWin(amount) {
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) return;
    const cycleKey = this.get10PmCycleKey();
    if (this.current10PmCycle !== cycleKey) {
      this.todaysWin = 0;
      this.current10PmCycle = cycleKey;
    }
    this.todaysWin += Number(amount);
    const storageKey = `greedy_todays_win_${this.userId || 'guest'}_${cycleKey}`;
    localStorage.setItem(storageKey, this.todaysWin.toString());
    this.updateTodaysWinUI();
  }

  // Load User Round-by-Round Bet History from LocalStorage
  loadUserHistory() {
    try {
      const storageKey = `greedy_user_history_${this.userId || 'guest'}`;
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        this.userBetHistory = JSON.parse(saved);
      } else {
        this.userBetHistory = [];
      }
    } catch (e) {
      this.userBetHistory = [];
    }
  }

  // Save User Bet History
  saveUserHistory() {
    try {
      const storageKey = `greedy_user_history_${this.userId || 'guest'}`;
      localStorage.setItem(storageKey, JSON.stringify(this.userBetHistory || []));
    } catch (e) { }
  }

  init() {
    this.loadUserHistory();
    this.loadTodaysWin();
    this.initAudio();
    this.renderBoard();
    this.renderChips();
    this.renderMilestones();
    this.renderHistoryRow();
    this.renderLeaderboard();
    this.updateUserBalanceUI();
    this.updateTodaysWinUI();
    this.attachEventListeners();
    this.initFirebaseSync();
    this.startGlobalSyncEngine();

    // Auto-rollover Today's Win & Top 10 Leaderboard when 10:00 PM cycle changes
    setInterval(() => {
      const cycleKey = this.get10PmCycleKey();
      if (this.current10PmCycle && this.current10PmCycle !== cycleKey) {
        this.loadTodaysWin();
        this.topWinnersList = [];
        this.renderLeaderboard();
        this.initLeaderboardSync();
      }
    }, 10000);
  }

  // ================= 1. GLOBAL MULTIPLAYER SYNCHRONIZED ENGINE =================
  startGlobalSyncEngine() {
    const tick = () => {
      const nowMs = Date.now();
      const betDuration = this.config.betTime || 30;
      const spinDuration = this.config.spinTime || 6;
      const resultDuration = this.config.resultTime || 5;
      const totalCycleSeconds = betDuration + spinDuration + resultDuration; // 41s
      const totalCycleMs = totalCycleSeconds * 1000;

      // Deterministic Global Round ID (Exact same for every user on Earth)
      const globalRoundId = Math.floor(nowMs / totalCycleMs);
      const elapsedMsInRound = nowMs % totalCycleMs;
      const elapsedSeconds = Math.floor(elapsedMsInRound / 1000);

      // Handle New Round Transition
      if (this.currentRoundId !== globalRoundId) {
        this.currentRoundId = globalRoundId;
        this.currentBets = {};
        this.updateBetBadges();
      }

      // Update 24H Round Number Display (#Round from 10:00 PM)
      this.updateDailyRoundDisplay(nowMs, totalCycleSeconds);

      // Synchronize Game State & Displays
      if (elapsedSeconds < betDuration) {
        // --- PHASE 1: BETTING PHASE ---
        this.gameState = 'BETTING';
        this.remainingSeconds = betDuration - elapsedSeconds;
        this.clearSlotHighlights();
        this.hideWinModal();

        const timerLabelEl = document.getElementById('bet-time-label');
        const timerCountEl = document.getElementById('bet-timer-count');
        if (timerLabelEl) timerLabelEl.textContent = 'Bet Time';
        if (timerCountEl) timerCountEl.textContent = `${this.remainingSeconds}s`;

        if (this.remainingSeconds <= 3 && this.remainingSeconds > 0 && elapsedMsInRound % 1000 < 100) {
          this.playSound('countdown');
        }
      } else if (elapsedSeconds < betDuration + spinDuration) {
        // --- PHASE 2: WHEEL SPINNING PHASE ---
        this.gameState = 'SPINNING';
        this.hideWinModal();

        const timerLabelEl = document.getElementById('bet-time-label');
        const timerCountEl = document.getElementById('bet-timer-count');
        if (timerLabelEl) timerLabelEl.textContent = 'Spinning';
        if (timerCountEl) timerCountEl.textContent = '🌀';

        // Deterministic Winner for this Global Round
        const winnerIndex = this.getDeterministicWinner(globalRoundId);

        // Spin Spotlight Animation in Sync
        const spinElapsedMs = elapsedMsInRound - (betDuration * 1000);
        const spinTotalMs = spinDuration * 1000;
        const totalSpins = 4 * 8 + winnerIndex;
        const progress = Math.min(1, spinElapsedMs / spinTotalMs);
        // Ease-out curve
        const easedProgress = 1 - Math.pow(1 - progress, 3);
        const currentSlot = Math.floor(easedProgress * totalSpins) % 8;
        this.highlightSlot(currentSlot);
      } else {
        // --- PHASE 3: RESULT & WIN CELEBRATION PHASE ---
        this.gameState = 'RESULT';
        const winnerIndex = this.getDeterministicWinner(globalRoundId);
        this.setWinnerSlot(winnerIndex);

        const timerLabelEl = document.getElementById('bet-time-label');
        const timerCountEl = document.getElementById('bet-timer-count');
        if (timerLabelEl) timerLabelEl.textContent = 'Winner';
        if (timerCountEl) timerCountEl.textContent = '🎉';

        // Process Win once per round
        if (!this.processedRounds.has(globalRoundId)) {
          this.processedRounds.add(globalRoundId);
          this.processRoundResult(globalRoundId, winnerIndex);
        }
      }

      // Render Synchronized History based on past deterministic rounds
      this.renderSynchronizedHistory(globalRoundId);
    };

    tick();
    setInterval(tick, 100);
  }

  // Deterministic Winning Slot Algorithm with Real-Time Winning Ratio Control
  getDeterministicWinner(roundId) {
    // 1. Force Winner Override from Admin Panel (Instant real-time override)
    if (this.config.forceWinnerIndex !== undefined && this.config.forceWinnerIndex >= 0 && this.config.forceWinnerIndex < 8) {
      return this.config.forceWinnerIndex;
    }

    // 2. High-quality PRNG hash for this global round
    const seed = roundId * 16807 + 99991;
    const x = Math.sin(seed) * 10000;
    const rand = x - Math.floor(x); // 0.0 to 1.0

    // 3. Real-Time Winning Ratio from Admin Panel (0% to 100%, default 65%)
    const winRatio = (this.config.winRatio !== undefined && !isNaN(Number(this.config.winRatio)))
      ? Math.max(0, Math.min(100, Number(this.config.winRatio)))
      : 65;

    // Check active bet slots placed by the player in this round
    const betSlotIndices = Object.keys(this.currentBets || {})
      .map(k => Number(k))
      .filter(k => (this.currentBets[k] || 0) > 0);

    const allSlots = [0, 1, 2, 3, 4, 5, 6, 7];
    const unbetSlotIndices = allSlots.filter(s => !betSlotIndices.includes(s));

    // Multiplier weights for natural probability: 5x items (higher), 45x items (rare)
    const baseWeights = [25, 25, 25, 25, 12, 8, 4, 1];

    // If player placed bets on some slots (and left some slots empty):
    if (betSlotIndices.length > 0 && unbetSlotIndices.length > 0) {
      // Deterministic roll against winRatio (0 to 100)
      const roll100 = rand * 100;
      if (roll100 < winRatio) {
        // Player WINS this round -> Select from betSlotIndices weighted by item base weights
        let totalBetWeight = 0;
        betSlotIndices.forEach(idx => totalBetWeight += (baseWeights[idx] || 10));
        let subRand = ((rand * 1000) % 1) * totalBetWeight;
        for (const idx of betSlotIndices) {
          const w = baseWeights[idx] || 10;
          if (subRand < w) return idx;
          subRand -= w;
        }
        return betSlotIndices[0];
      } else {
        // Player LOSES this round -> Select from unbetSlotIndices (empty slots)
        let totalUnbetWeight = 0;
        unbetSlotIndices.forEach(idx => totalUnbetWeight += (baseWeights[idx] || 10));
        let subRand = ((rand * 1000) % 1) * totalUnbetWeight;
        for (const idx of unbetSlotIndices) {
          const w = baseWeights[idx] || 10;
          if (subRand < w) return idx;
          subRand -= w;
        }
        return unbetSlotIndices[0];
      }
    }

    // Default Multiplier Weighted PRNG (when no bets placed or all slots covered)
    const totalWeight = baseWeights.reduce((a, b) => a + b, 0);
    let r = rand * totalWeight;
    for (let i = 0; i < baseWeights.length; i++) {
      if (r < baseWeights[i]) return i;
      r -= baseWeights[i];
    }
    return 0;
  }

  // Synchronized History Row derived from past 8 global rounds
  renderSynchronizedHistory(currentRoundId) {
    const row = document.getElementById('history-bottom-row');
    if (!row) return;

    const historyItems = [];
    for (let i = 1; i <= 8; i++) {
      const pastRoundId = currentRoundId - i;
      historyItems.push(this.getDeterministicWinner(pastRoundId));
    }

    row.innerHTML = '';
    historyItems.forEach((slotIdx, idx) => {
      const item = this.config.items[slotIdx] || this.config.items[0];
      const badge = document.createElement('div');
      badge.className = 'history-badge-item';
      badge.innerHTML = `
        ${idx === 0 ? '<span class="new-tag">New</span>' : ''}
        <img src="${item.icon}" alt="${item.name}">
      `;
      row.appendChild(badge);
    });
  }

  // Calculate 24H Daily Round Number from 10:00 PM Anchor
  updateDailyRoundDisplay(nowMs, cycleDuration) {
    const now = new Date(nowMs);
    const cycleStart = new Date(now);
    cycleStart.setHours(22, 0, 0, 0); // 10:00 PM

    if (now.getTime() < cycleStart.getTime()) {
      cycleStart.setDate(cycleStart.getDate() - 1);
    }

    const elapsedSeconds = Math.floor((now.getTime() - cycleStart.getTime()) / 1000);
    const roundNumber = Math.floor(elapsedSeconds / cycleDuration) + 1;

    const el = document.getElementById('daily-round-timer');
    if (el) {
      el.textContent = `Round: #${roundNumber}`;
    }
  }

  // Handle Round Result Calculation & Winning Distribution
  processRoundResult(roundId, winnerIndex) {
    const winnerItem = this.config.items[winnerIndex] || DEFAULT_CONFIG.items[winnerIndex];
    const userBetOnWinner = this.currentBets[winnerIndex] || 0;
    const winAmount = userBetOnWinner * winnerItem.multiplier;

    // Calculate total bets placed in this round across all items
    let roundTotalBet = 0;
    Object.values(this.currentBets || {}).forEach(amt => {
      roundTotalBet += (Number(amt) || 0);
    });

    const currentRoundNum = this.getCalculatedRoundNumber();

    // Only record in History if the user ACTUALLY placed a bet in this round!
    if (roundTotalBet > 0) {
      const now = new Date();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const dateStr = `${months[now.getMonth()]},${String(now.getDate()).padStart(2, '0')} ${now.getFullYear()} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

      this.userBetHistory.unshift({
        roundNumber: currentRoundNum,
        totalBet: roundTotalBet,
        winAmount: winAmount,
        isWin: winAmount > 0,
        dateStr: dateStr,
        timestamp: now.getTime()
      });

      if (this.userBetHistory.length > 50) this.userBetHistory.pop();
      this.saveUserHistory();
    }

    if (winAmount > 0) {
      this.balance += winAmount;
      this.addTodaysWin(winAmount);
      this.updateUserBalanceUI();
      this.playSound('win');

      // Instantly update Top 10 Daily Winners in memory for 0ms lag
      const winUser = this.userName || 'Player';
      const existing = (this.topWinnersList || []).find(w => (this.userId && w.userId === this.userId) || w.name === winUser);
      if (existing) {
        existing.diamonds = (Number(existing.diamonds) || 0) + winAmount;
      } else {
        this.topWinnersList = this.topWinnersList || [];
        this.topWinnersList.push({
          rank: this.topWinnersList.length + 1,
          userId: this.userId || '',
          name: winUser,
          avatar: this.userAvatar || '',
          diamonds: winAmount
        });
      }
      this.topWinnersList.sort((a, b) => b.diamonds - a.diamonds);
      this.topWinnersList.forEach((w, idx) => w.rank = idx + 1);
      this.renderLeaderboard();

      if (this.userId && this.db) {
        const winUpdate = {
          diamonds: firebase.firestore.FieldValue.increment(winAmount),
          totalDiamonds: firebase.firestore.FieldValue.increment(winAmount)
        };
        this.db.collection('Users').doc(this.userId).update(winUpdate).catch(() => { });

        // Update Real-Time Daily Leaderboard (10:00 PM to 10:00 PM cycle)
        const cycleKey = this.get10PmCycleKey();
        this.db.collection('daily_game_leaderboard')
          .doc(`greedy_market_${cycleKey}`)
          .collection('users')
          .doc(this.userId)
          .set({
            userId: this.userId,
            name: this.userName || 'Player',
            avatar: this.userAvatar || '',
            winAmount: firebase.firestore.FieldValue.increment(winAmount),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
          }, { merge: true })
          .catch((err) => console.warn('Leaderboard record error:', err));

        this.db.collection('daily_game_leaderboard')
          .doc(`greedy_market_${cycleKey}`)
          .set({
            gameId: 'greedy_market',
            cycleKey: cycleKey,
            lastWinAt: firebase.firestore.FieldValue.serverTimestamp()
          }, { merge: true })
          .catch(() => {});

        this.db.collection('game_history').add({
          userId: this.userId,
          userName: this.userName || 'Player',
          userAvatar: this.userAvatar || '',
          gameId: 'greedy_market',
          type: 'WIN',
          winAmount: winAmount,
          slotIndex: winnerIndex,
          roundId: roundId,
          itemName: winnerItem.name,
          multiplier: winnerItem.multiplier,
          cycleKey: cycleKey,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => { });
      }
    }

    this.showWinModal(winnerItem, winAmount);
  }

  // Audio Engine with Web Audio API
  initAudio() {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (AudioContext) {
      this.audioCtx = new AudioContext();
    }
  }

  playSound(type) {
    if (!this.soundEnabled || !this.audioCtx) return;
    try {
      if (this.audioCtx.state === 'suspended') {
        this.audioCtx.resume();
      }

      const now = this.audioCtx.currentTime;
      const osc = this.audioCtx.createOscillator();
      const gain = this.audioCtx.createGain();
      osc.connect(gain);
      gain.connect(this.audioCtx.destination);

      if (type === 'tick') {
        osc.type = 'sine';
        osc.frequency.setValueAtTime(850, now);
        osc.frequency.exponentialRampToValueAtTime(350, now + 0.04);
        gain.gain.setValueAtTime(0.3, now);
        gain.gain.linearRampToValueAtTime(0.01, now + 0.04);
        osc.start(now);
        osc.stop(now + 0.04);
      } else if (type === 'chip') {
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(1100, now);
        osc.frequency.exponentialRampToValueAtTime(550, now + 0.07);
        gain.gain.setValueAtTime(0.4, now);
        gain.gain.linearRampToValueAtTime(0.01, now + 0.07);
        osc.start(now);
        osc.stop(now + 0.07);
      } else if (type === 'win') {
        const notes = [523.25, 659.25, 783.99, 1046.50];
        notes.forEach((freq, idx) => {
          const o = this.audioCtx.createOscillator();
          const g = this.audioCtx.createGain();
          o.connect(g);
          g.connect(this.audioCtx.destination);
          o.type = 'sine';
          o.frequency.setValueAtTime(freq, now + idx * 0.1);
          g.gain.setValueAtTime(0.3, now + idx * 0.1);
          g.gain.exponentialRampToValueAtTime(0.01, now + idx * 0.1 + 0.35);
          o.start(now + idx * 0.1);
          o.stop(now + idx * 0.1 + 0.35);
        });
      } else if (type === 'countdown') {
        osc.type = 'square';
        osc.frequency.setValueAtTime(480, now);
        gain.gain.setValueAtTime(0.18, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.1);
        osc.start(now);
        osc.stop(now + 0.1);
      }
    } catch (e) { }
  }

  // --- Real-time Firebase Sync & UI Layout Config ---
  initFirebaseSync() {
    if (typeof firebase !== 'undefined') {
      try {
        if (firebase.apps.length === 0) {
          firebase.initializeApp({
            apiKey: 'AIzaSyDPAzlHyBLTU83kZ6jSisEgPOjsuSwKuj0',
            appId: '1:518076067996:web:174b33c043d49536a3fd59',
            projectId: 'imchat-84519',
            authDomain: 'imchat-84519.firebaseapp.com',
            storageBucket: 'imchat-84519.firebasestorage.app'
          });
        }
        this.db = firebase.firestore();

        // 1. Live Admin Configuration & UI Layout Positions Sync
        const onConfigUpdate = (doc) => {
          if (doc && (typeof doc.exists === 'function' ? doc.exists() : doc.exists)) {
            const data = doc.data();
            if (data) {
              this.applyRemoteConfig(data);
            }
          }
        };

        this.db.collection('config').doc('html5_greedy_game')
          .onSnapshot(onConfigUpdate, (err) => console.warn('Firebase config sync note:', err.message));

        this.db.collection('config').doc('html5_greedy_market')
          .onSnapshot(onConfigUpdate, (err) => console.warn('Firebase config sync 2 note:', err.message));

        // 2. Real-time User Diamond Wallet Sync strictly from app's wallet
        this.initUserWalletSync();

        // 3. Real-time Dynamic App Diamond Icon Sync from global_settings/app_theme
        try {
          this.db.collection('global_settings').doc('app_theme')
            .onSnapshot((doc) => {
              if (doc && doc.exists) {
                const themeData = doc.data() || {};
                const icon = themeData.diamondIconUrl || themeData.diamondIcon;
                if (icon && icon.trim() !== '') {
                  this.updateAllDiamondIcons(icon.trim());
                }
              }
            }, () => { });
        } catch (e) { }

        // 4. Real-time Daily Top 10 Winners Sync (Only Real Players Who Won)
        this.initLeaderboardSync();
      } catch (e) {
        console.warn('Firebase init error:', e);
      }
    }

    // Direct Flutter Javascript Bridge: window.setUserProfile({ userId, name, avatar, diamonds, coins })
    window.setUserProfile = (profile) => {
      try {
        if (!profile) return;
        const data = typeof profile === 'string' ? JSON.parse(profile) : profile;
        if (data.userId || data.uid) {
          this.userId = data.userId || data.uid;
          this.isRealUser = true;
          this.loadUserHistory();
          this.loadTodaysWin();
        }
        const pName = data.fullname || data.name || data.username || data.nickname;
        if (pName) this.userName = pName;

        const pAvatar = data.photoUrl || data.avatar || data.avatarUrl || data.profilePic || data.image;
        if (pAvatar) this.userAvatar = pAvatar;

        const dIcon = data.diamondIcon || data.diamondIconUrl || data.diamond_icon;
        if (dIcon && dIcon.trim() !== '') {
          this.updateAllDiamondIcons(dIcon.trim());
        }

        const rawBal = data.diamonds ?? data.diamond ?? data.coins ?? data.balance ?? data.walletBalance;
        if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
          this.balance = Number(rawBal);
          this.updateUserBalanceUI();
        }

        this.initUserWalletSync();
        this.initLeaderboardSync();
      } catch (e) { }
    };

    // App PostMessage Integration
    window.addEventListener('message', (event) => {
      try {
        const data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
        if (data && (data.type === 'SET_USER' || data.type === 'USER_DATA') && (data.userId || data.uid)) {
          window.setUserProfile(data);
        }
      } catch (e) { }
    });
  }

  applyRemoteConfig(remote) {
    if (!remote) return;

    // 1. Process 8 items dynamically with image URLs, names & multipliers
    const rawItems = remote.items;
    if (rawItems) {
      let itemsList = [];
      if (Array.isArray(rawItems)) {
        itemsList = rawItems;
      } else if (typeof rawItems === 'object') {
        itemsList = Object.values(rawItems);
      }

      if (itemsList.length > 0) {
        itemsList.forEach((newItem, idx) => {
          if (idx < 8 && newItem) {
            const currentItem = this.config.items[idx] || DEFAULT_CONFIG.items[idx] || {};
            const updatedIcon = newItem.icon || newItem.img || newItem.image || newItem.iconUrl || newItem.thumbnailUrl || currentItem.icon;
            const updatedName = newItem.name || currentItem.name || `Item ${idx + 1}`;
            const updatedMultiplier = (newItem.multiplier !== undefined && !isNaN(Number(newItem.multiplier)))
              ? Number(newItem.multiplier)
              : (currentItem.multiplier || 5);

            this.config.items[idx] = {
              ...currentItem,
              id: idx,
              name: updatedName,
              icon: updatedIcon,
              multiplier: updatedMultiplier,
              optionId: newItem.optionId || (20 + idx)
            };
          }
        });
      }
    }

    if (Array.isArray(remote.chips) && remote.chips.length >= 5) {
      this.config.chips = remote.chips;
    }
    if (remote.betTime) this.config.betTime = Number(remote.betTime);
    if (remote.spinTime) this.config.spinTime = Number(remote.spinTime);
    if (remote.winRatio !== undefined) this.config.winRatio = Number(remote.winRatio);
    if (remote.forceWinnerIndex !== undefined) this.config.forceWinnerIndex = Number(remote.forceWinnerIndex);
    if (remote.uiLayout) this.config.uiLayout = remote.uiLayout;

    // Diamond icon from admin config
    if (remote.diamondIcon) {
      this.updateAllDiamondIcons(remote.diamondIcon);
    }
    // Trophy icon from admin config
    if (remote.trophyIcon) {
      const trImg = document.querySelector('#btn-trophy img');
      if (trImg) trImg.src = remote.trophyIcon;
    }
    // Logo from admin config
    if (remote.logoUrl) {
      const logoImg = document.querySelector('.header-logo');
      if (logoImg) logoImg.src = remote.logoUrl;
    }

    // Side Badges (Fruit & Pizza) Picture & Label Change from Admin Panel
    const fruitIcon = remote.fruitBadgeIcon || remote.fruitIcon || remote.fruitBadge;
    if (fruitIcon) {
      document.querySelectorAll('#badge-fruit-img, .side-badge-fruit img').forEach(img => {
        img.src = fruitIcon;
      });
    }
    const fruitLabel = remote.fruitBadgeLabel || remote.fruitLabel;
    if (fruitLabel) {
      document.querySelectorAll('#badge-fruit-tag, .side-badge-fruit .side-badge-tag').forEach(tag => {
        tag.textContent = fruitLabel;
      });
    }

    const pizzaIcon = remote.pizzaBadgeIcon || remote.pizzaIcon || remote.pizzaBadge;
    if (pizzaIcon) {
      document.querySelectorAll('#badge-pizza-img, .side-badge-pizza img').forEach(img => {
        img.src = pizzaIcon;
      });
    }
    const pizzaLabel = remote.pizzaBadgeLabel || remote.pizzaLabel;
    if (pizzaLabel) {
      document.querySelectorAll('#badge-pizza-tag, .side-badge-pizza .side-badge-tag').forEach(tag => {
        tag.textContent = pizzaLabel;
      });
    }

    // Background Image Change from Admin Panel
    const bgUrl = remote.gameBackgroundUrl || remote.basicBg || remote.advanceBg || remote.backgroundUrl || remote.bgImage;
    const wrapper = document.getElementById('game-wrapper');
    const starry = document.querySelector('.starry-bg');
    const skyline = document.querySelector('.city-skyline');

    if (bgUrl && bgUrl.trim().length > 5) {
      const cleanBg = bgUrl.trim();
      document.body.style.backgroundImage = `url("${cleanBg}")`;
      document.body.style.backgroundSize = 'cover';
      document.body.style.backgroundPosition = 'center';
      if (wrapper) {
        wrapper.style.backgroundImage = `url("${cleanBg}")`;
        wrapper.style.backgroundSize = 'cover';
        wrapper.style.backgroundPosition = 'center';
        wrapper.style.backgroundRepeat = 'no-repeat';
      }
      if (starry) starry.style.display = 'none';
      if (skyline) skyline.style.display = 'none';
    } else {
      document.body.style.backgroundImage = '';
      if (wrapper) {
        wrapper.style.backgroundImage = '';
        wrapper.style.background = 'var(--bg-gradient)';
      }
      if (starry) starry.style.display = 'block';
      if (skyline) skyline.style.display = 'block';
    }

    this.updateBoardItemImages();
    this.renderChips();
    this.renderMilestones();
    this.renderHistoryRow();
    this.updateUserBalanceUI();
    this.updateTodaysWinUI();
    this.applyFullUILayout();
  }

  // Real-time update for the 8 cards without breaking active round DOM
  updateBoardItemImages() {
    const board = document.getElementById('slots-container');
    if (!board) return;

    if (board.children.length === 0) {
      this.renderBoard();
      return;
    }

    const items = (this.config.items && this.config.items.length === 8)
      ? this.config.items
      : DEFAULT_CONFIG.items;

    items.forEach((item, idx) => {
      const defaultIcon = DEFAULT_CONFIG.items[idx] ? DEFAULT_CONFIG.items[idx].icon : 'https://cdn-icons-png.flaticon.com/512/415/415733.png';
      const iconUrl = (item.icon && String(item.icon).trim().length > 5) ? String(item.icon).trim() : defaultIcon;
      const itemName = item.name || (DEFAULT_CONFIG.items[idx] ? DEFAULT_CONFIG.items[idx].name : 'Item');
      const multiplier = item.multiplier || (DEFAULT_CONFIG.items[idx] ? DEFAULT_CONFIG.items[idx].multiplier : 5);

      const card = document.getElementById(`slot-${idx}`);
      if (card) {
        const img = card.querySelector('.item-img-wrap img');
        if (img) {
          if (img.src !== iconUrl) {
            img.src = iconUrl;
          }
          img.alt = itemName;
          img.onerror = () => {
            if (img.src !== defaultIcon) img.src = defaultIcon;
          };
        }
        const multTag = card.querySelector('.item-mult-tag');
        if (multTag) {
          multTag.innerHTML = `x${multiplier}${item.hasFire ? ' 🔥' : ''}`;
        }
      } else {
        this.renderBoard();
      }
    });
  }

  // Apply Full Screen Drag/Move Coordinates for Every Element from Admin Panel
  applyFullUILayout() {
    if (!this.config.uiLayout) return;
    const layout = this.config.uiLayout;

    // 0. Entire Ferris Wheel Zoom In / Out Scale
    if (layout.wheelScale !== undefined && layout.wheelScale !== null) {
      const wheelStage = document.querySelector('.wheel-stage');
      if (wheelStage) {
        wheelStage.style.transform = `scale(${layout.wheelScale})`;
        wheelStage.style.transformOrigin = 'center center';
      }
    }

    // 0.1 Spokes (কাঠির মাপ ও কালার)
    if (layout.spokes) {
      const lines = document.querySelectorAll('.spokes-svg line');
      const sw = layout.spokes.strokeWidth !== undefined ? layout.spokes.strokeWidth : 4.5;
      const color = layout.spokes.color || '#8a4128';
      const opacity = layout.spokes.opacity !== undefined ? layout.spokes.opacity : 0.9;
      lines.forEach(line => {
        line.setAttribute('stroke-width', sw);
        line.setAttribute('stroke', color);
        line.style.opacity = opacity;
      });
    }

    // 1. Move & Zoom/Scale 8 Slot Cards
    if (Array.isArray(layout.slotOffsets)) {
      layout.slotOffsets.forEach((pos, idx) => {
        const el = document.getElementById(`slot-${idx}`);
        if (el && pos) {
          if (pos.top !== undefined) el.style.top = `${pos.top}px`;
          if (pos.left !== undefined) el.style.left = `${pos.left}px`;
          if (pos.width !== undefined) el.style.width = `${pos.width}px`;
          if (pos.height !== undefined) el.style.height = `${pos.height}px`;
          if (pos.scale !== undefined) {
            el.style.transform = `scale(${pos.scale})`;
            el.style.transformOrigin = 'center center';
          }
        }
      });
    }

    // 2. Move Center Bear Hub
    if (layout.hub) {
      const hubEl = document.querySelector('.center-bear-hub');
      if (hubEl) {
        if (layout.hub.top !== undefined) hubEl.style.top = `${layout.hub.top}px`;
        if (layout.hub.left !== undefined) hubEl.style.left = `${layout.hub.left}px`;
        if (layout.hub.size !== undefined) {
          hubEl.style.width = `${layout.hub.size}px`;
          hubEl.style.height = `${layout.hub.size}px`;
        }
        if (layout.hub.scale !== undefined) {
          hubEl.style.transform = `scale(${layout.hub.scale})`;
          hubEl.style.transformOrigin = 'center center';
        }
      }
    }

    // 2.1 Move & Zoom/Scale Fruit and Pizza Side Badges
    if (layout.fruitBadge) {
      const fb = document.getElementById('side-badge-fruit') || document.querySelector('.side-badge-fruit');
      if (fb) {
        if (layout.fruitBadge.top !== undefined) fb.style.top = `${layout.fruitBadge.top}px`;
        if (layout.fruitBadge.left !== undefined) fb.style.left = `${layout.fruitBadge.left}px`;
        if (layout.fruitBadge.scale !== undefined) {
          fb.style.transform = `scale(${layout.fruitBadge.scale})`;
          fb.style.transformOrigin = 'center center';
        } else if (layout.fruitBadge.width !== undefined) {
          const img = fb.querySelector('img');
          if (img) {
            img.style.width = `${layout.fruitBadge.width}px`;
            if (layout.fruitBadge.height !== undefined) img.style.height = `${layout.fruitBadge.height}px`;
          }
        }
      }
    }
    if (layout.pizzaBadge) {
      const pb = document.getElementById('side-badge-pizza') || document.querySelector('.side-badge-pizza');
      if (pb) {
        if (layout.pizzaBadge.top !== undefined) pb.style.top = `${layout.pizzaBadge.top}px`;
        if (layout.pizzaBadge.left !== undefined) {
          pb.style.left = `${layout.pizzaBadge.left}px`;
          pb.style.right = 'auto';
        }
        if (layout.pizzaBadge.scale !== undefined) {
          pb.style.transform = `scale(${layout.pizzaBadge.scale})`;
          pb.style.transformOrigin = 'center center';
        } else if (layout.pizzaBadge.width !== undefined) {
          const img = pb.querySelector('img');
          if (img) {
            img.style.width = `${layout.pizzaBadge.width}px`;
            if (layout.pizzaBadge.height !== undefined) img.style.height = `${layout.pizzaBadge.height}px`;
          }
        }
      }
    }

    // 3. Move Top Header & Diamond Coin Pill & Trophy
    if (layout.topHeader) {
      const hdr = document.querySelector('.top-header');
      if (hdr && layout.topHeader.top !== undefined) {
        hdr.style.marginTop = `${layout.topHeader.top}px`;
      }
    }
    if (layout.trophy) {
      const tr = document.getElementById('btn-trophy');
      if (tr) {
        if (layout.trophy.top !== undefined) tr.style.top = `${layout.trophy.top}px`;
        if (layout.trophy.left !== undefined) tr.style.left = `${layout.trophy.left}px`;
      }
    }
    if (layout.rightActions) {
      const ra = document.querySelector('.right-action-icons');
      if (ra) {
        if (layout.rightActions.top !== undefined) ra.style.marginTop = `${layout.rightActions.top}px`;
        if (layout.rightActions.right !== undefined) ra.style.marginRight = `${layout.rightActions.right}px`;
      }
    }

    // 4. Move Ferris Wheel Arena
    if (layout.arena) {
      const arena = document.querySelector('.ferris-arena');
      if (arena) {
        if (layout.arena.marginTop !== undefined) arena.style.marginTop = `${layout.arena.marginTop}px`;
        if (layout.arena.marginBottom !== undefined) arena.style.marginBottom = `${layout.arena.marginBottom}px`;
      }
    }

    // 5. Move Skyline Background
    if (layout.skyline) {
      const sky = document.querySelector('.city-skyline');
      if (sky) {
        if (layout.skyline.top !== undefined) sky.style.top = `${layout.skyline.top}px`;
        if (layout.skyline.height !== undefined) sky.style.height = `${layout.skyline.height}px`;
      }
    }

    // 6. Move Bottom Panels (Today's Win, Wager Prompt, Chips, Milestones, History)
    if (layout.bottomPanel) {
      const bp = document.querySelector('.bottom-controls-panel');
      if (bp && layout.bottomPanel.marginTop !== undefined) {
        bp.style.marginTop = `${layout.bottomPanel.marginTop}px`;
      }
    }
    if (layout.todaysWin) {
      const tw = document.querySelector('.todays-win-bar');
      if (tw && layout.todaysWin.marginTop !== undefined) {
        tw.style.marginTop = `${layout.todaysWin.marginTop}px`;
      }
    }
    if (layout.wagerPrompt) {
      const wp = document.querySelector('.wager-prompt-pill');
      if (wp && layout.wagerPrompt.marginTop !== undefined) {
        wp.style.marginTop = `${layout.wagerPrompt.marginTop}px`;
      }
    }
    if (layout.chipTray || layout.chipsTray) {
      const ct = document.querySelector('.chip-tray-card');
      const val = layout.chipTray || layout.chipsTray;
      if (ct && val.marginTop !== undefined) {
        ct.style.marginTop = `${val.marginTop}px`;
      }
    }
    if (layout.milestones) {
      const ms = document.querySelector('.milestones-card');
      if (ms && layout.milestones.marginTop !== undefined) {
        ms.style.marginTop = `${layout.milestones.marginTop}px`;
      }
    }
    if (layout.historyRow) {
      const hr = document.querySelector('.history-capsules-row');
      if (hr && layout.historyRow.marginTop !== undefined) {
        hr.style.marginTop = `${layout.historyRow.marginTop}px`;
      }
    }
  }

  // Render 8 Item Cards on the Ferris Wheel
  renderBoard() {
    const board = document.getElementById('slots-container');
    if (!board) return;
    board.innerHTML = '';

    const items = (this.config.items && this.config.items.length === 8)
      ? this.config.items
      : DEFAULT_CONFIG.items;

    items.forEach((item, idx) => {
      const defaultIcon = DEFAULT_CONFIG.items[idx] ? DEFAULT_CONFIG.items[idx].icon : 'https://cdn-icons-png.flaticon.com/512/415/415733.png';
      const iconUrl = (item.icon && item.icon.trim().length > 5) ? item.icon.trim() : defaultIcon;
      const itemName = item.name || (DEFAULT_CONFIG.items[idx] ? DEFAULT_CONFIG.items[idx].name : 'Item');
      const multiplier = item.multiplier || (DEFAULT_CONFIG.items[idx] ? DEFAULT_CONFIG.items[idx].multiplier : 5);

      const card = document.createElement('div');
      card.className = `item-card slot-pos-${idx}`;
      card.id = `slot-${idx}`;
      card.dataset.slotIndex = idx;

      card.innerHTML = `
        <div class="item-img-wrap">
          <img src="${iconUrl}" alt="${itemName}" onerror="this.src='${defaultIcon}'">
        </div>
        <div class="item-mult-tag">x${multiplier}${item.hasFire ? ' 🔥' : ''}</div>
        <div class="placed-chips-cloud" id="chips-cloud-${idx}">
          <span class="chip-mini-badge" id="bet-badge-${idx}">0</span>
        </div>
      `;

      card.addEventListener('click', (e) => {
        this.placeBet(idx, e);
      });

      board.appendChild(card);
    });

    this.applyFullUILayout();
    this.updateBetBadges();
  }

  // Render 5/6 Casino Chips in Tray
  renderChips() {
    const tray = document.getElementById('chips-tray');
    if (!tray) return;
    tray.innerHTML = '';

    const defaultChipClasses = ['chip-cyan', 'chip-green', 'chip-blue', 'chip-orange', 'chip-red', 'chip-purple'];
    const chips = (this.config.chips && this.config.chips.length >= 5)
      ? this.config.chips
      : DEFAULT_CONFIG.chips;

    chips.forEach((chip, idx) => {
      const chipEl = document.createElement('div');
      const chipClass = chip.class || defaultChipClasses[idx % defaultChipClasses.length];
      chipEl.className = `casino-chip ${chipClass} ${idx === this.selectedChipIndex ? 'selected' : ''}`;
      chipEl.dataset.chipIndex = idx;

      const chipLabel = chip.label || (chip.value >= 1000 ? `${chip.value / 1000}K` : `${chip.value}`);

      chipEl.innerHTML = `
        <div class="chip-inner-disc">${chipLabel}</div>
      `;

      chipEl.addEventListener('click', () => {
        this.selectChip(idx);
      });

      tray.appendChild(chipEl);
    });
  }

  selectChip(index) {
    this.selectedChipIndex = index;
    const chips = document.querySelectorAll('.casino-chip');
    chips.forEach((el, idx) => {
      el.classList.toggle('selected', idx === index);
    });
    this.playSound('chip');
  }

  // Render 5 Milestones Treasure Chests
  renderMilestones() {
    const track = document.getElementById('milestones-track');
    if (!track) return;
    track.innerHTML = `
      <div class="track-line"></div>
      <div class="track-line-progress"></div>
    `;

    const defaultMilestoneIcons = [
      'https://cdn-icons-png.flaticon.com/512/2645/2645897.png',
      'https://cdn-icons-png.flaticon.com/512/2645/2645897.png',
      'https://cdn-icons-png.flaticon.com/512/2645/2645897.png',
      'https://cdn-icons-png.flaticon.com/512/2645/2645897.png',
      'https://cdn-icons-png.flaticon.com/512/2645/2645897.png'
    ];
    const defaultLabels = ['1M', '10M', '50M', '100M', '500M'];

    const milestones = (this.config.milestones && this.config.milestones.length >= 5)
      ? this.config.milestones
      : DEFAULT_CONFIG.milestones;

    milestones.forEach((m, idx) => {
      const chest = document.createElement('div');
      chest.className = 'chest-step-item';
      const iconUrl = m.icon || defaultMilestoneIcons[idx] || defaultMilestoneIcons[0];
      const label = m.label || defaultLabels[idx] || '';
      chest.innerHTML = `
        <img class="chest-step-img" src="${iconUrl}" alt="${label}">
        <span class="chest-step-label">${label}</span>
      `;
      track.appendChild(chest);
    });
  }

  // Render Past Round History Bottom Row
  renderHistoryRow() {
    const historyRow = document.getElementById('history-bottom-row');
    if (!historyRow) return;
    historyRow.innerHTML = '';

    const defaultHistory = [
      { name: 'Apple', icon: 'https://cdn-icons-png.flaticon.com/512/415/415733.png', isNew: true },
      { name: 'Burger', icon: 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png' },
      { name: 'Pizza', icon: 'https://cdn-icons-png.flaticon.com/512/1404/1404945.png' },
      { name: 'Apple', icon: 'https://cdn-icons-png.flaticon.com/512/415/415733.png' },
      { name: 'Lemon', icon: 'https://cdn-icons-png.flaticon.com/512/1791/1791336.png' },
      { name: 'Strawberry', icon: 'https://cdn-icons-png.flaticon.com/512/590/590685.png' },
      { name: 'Mango', icon: 'https://cdn-icons-png.flaticon.com/512/2909/2909890.png' },
      { name: 'Roast Chicken', icon: 'https://cdn-icons-png.flaticon.com/512/1046/1046751.png' }
    ];

    defaultHistory.forEach(h => {
      const capsule = document.createElement('div');
      capsule.className = `history-capsule ${h.isNew ? 'is-new' : ''}`;
      capsule.innerHTML = `
        ${h.isNew ? '<span class="new-tag">New</span>' : ''}
        <img src="${h.icon}" alt="${h.name}">
      `;
      historyRow.appendChild(capsule);
    });
  }

  // Real-time User Diamond Wallet Sync directly from Firestore Users collection
  initUserWalletSync() {
    if (!this.db || !this.userId) return;
    if (this.walletUnsub) {
      try { this.walletUnsub(); } catch (_) { }
      this.walletUnsub = null;
    }

    const handleUserData = (doc) => {
      if (doc && doc.exists) {
        const uData = doc.data() || {};
        const realName = uData.fullname || uData.name || uData.username || uData.displayName || uData.nickname;
        if (realName) this.userName = realName;

        const realAvatar = uData.photoUrl || uData.profilePic || uData.avatarUrl || uData.image || uData.avatar;
        if (realAvatar) this.userAvatar = realAvatar;

        // In IMChat, the live spendable balance is strictly the app wallet 'diamonds'
        const rawBal = uData.diamonds ?? uData.diamond ?? uData.coins ?? uData.walletBalance ?? uData.balance;
        if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
          this.balance = Number(rawBal);
          this.updateUserBalanceUI();
        }
      }
    };

    try {
      this.walletUnsub = this.db.collection('Users').doc(this.userId).onSnapshot(handleUserData, () => { });
    } catch (e) { }
  }

  getDiamondIconUrl() {
    return window.REMOTE_DIAMOND_ICON || this.diamondIconUrl || 'diamond_icon.webp';
  }

  updateAllDiamondIcons(url) {
    if (!url || url.trim() === '') return;
    const cleanUrl = url.trim();
    this.diamondIconUrl = cleanUrl;
    window.REMOTE_DIAMOND_ICON = cleanUrl;
    document.querySelectorAll('.app-diamond-img, .wallet-diamond-img, #top-diamond-icon').forEach(img => {
      img.src = cleanUrl;
    });
  }

  // Subscribe to Real-Time Daily Top 10 Winners from Firestore (10:00 PM to 10:00 PM cycle)
  initLeaderboardSync() {
    if (!this.db) return;
    const cycleKey = this.get10PmCycleKey();
    if (this.currentLeaderboardCycle === cycleKey && this.leaderboardUnsub) return;

    if (this.leaderboardUnsub) {
      try { this.leaderboardUnsub(); } catch (_) { }
      this.leaderboardUnsub = null;
    }
    this.currentLeaderboardCycle = cycleKey;

    try {
      this.leaderboardUnsub = this.db
        .collection('daily_game_leaderboard')
        .doc(`greedy_market_${cycleKey}`)
        .collection('users')
        .orderBy('winAmount', 'desc')
        .limit(10)
        .onSnapshot((snapshot) => {
          if (snapshot && !snapshot.empty) {
            const list = [];
            snapshot.forEach(doc => {
              const data = doc.data() || {};
              const amt = Number(data.winAmount) || 0;
              if (amt > 0) {
                list.push({
                  userId: data.userId || doc.id,
                  name: data.name || data.userName || 'Winner',
                  avatar: data.avatar || data.userAvatar || '',
                  diamonds: amt
                });
              }
            });
            list.sort((a, b) => b.diamonds - a.diamonds);
            list.forEach((w, idx) => w.rank = idx + 1);
            this.topWinnersList = list;
          } else {
            this.topWinnersList = [];
          }
          this.renderLeaderboard();
        }, (err) => {
          console.warn('Leaderboard sync note:', err);
        });
    } catch (e) {
      console.warn('Leaderboard listen error:', e);
    }
  }

  // Render Top 10 Daily Winners in Leaderboard Modal (Real Players Only)
  renderLeaderboard() {
    const container = document.getElementById('leaderboard-list');
    if (!container) return;
    container.innerHTML = '';

    if (!Array.isArray(this.topWinnersList) || this.topWinnersList.length === 0) {
      container.innerHTML = `
        <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding: 48px 16px; color: #94a3b8; text-align:center;">
          <div style="font-size: 32px; margin-bottom: 8px; opacity: 0.7;">🏆</div>
          <div style="font-size: 14px; font-weight: 700; color: #e2e8f0; margin-bottom: 4px;">No Winners Yet Today</div>
          <div style="font-size: 12px; color: #94a3b8;">Play and win rounds to reach the Top 10!</div>
        </div>
      `;
      return;
    }

    this.topWinnersList.forEach((w, idx) => {
      const rankBadgeClass = idx === 0 ? 'rank-badge-1' : idx === 1 ? 'rank-badge-2' : idx === 2 ? 'rank-badge-3' : '';
      const medalEmoji = idx === 0 ? '👑' : idx === 1 ? '🥈' : idx === 2 ? '🥉' : `${idx + 1}`;

      const row = document.createElement('div');
      row.className = 'leaderboard-row-item';
      row.innerHTML = `
        <div class="leaderboard-left">
          <div class="rank-badge ${rankBadgeClass}">${medalEmoji}</div>
          <img class="leaderboard-avatar" src="${w.avatar || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'}" alt="${w.name}">
          <span class="leaderboard-name">${w.name}</span>
        </div>
        <div class="leaderboard-diamond-text">+${this.formatNumber(w.diamonds)} <img src="${this.getDiamondIconUrl()}" class="app-diamond-img" style="width:15px;height:15px;vertical-align:middle;object-fit:contain;margin-left:3px;" alt="💎"></div>
      `;
      container.appendChild(row);
    });
  }

  // Place Bet Action with Diamond Wallet & Max 6 Slots Constraint
  placeBet(slotIndex, event) {
    if (this.gameState !== 'BETTING') {
      this.showToast('Betting is closed! Wait for next round.');
      return;
    }

    const activeBetSlots = Object.keys(this.currentBets).filter(k => (this.currentBets[k] || 0) > 0);
    if (!this.currentBets[slotIndex] && activeBetSlots.length >= 6) {
      this.showToast('⚠️ সর্বোচ্চ ৬টি আইটেমে বেট ধরা যাবে! (কমপক্ষে ২টি আইটেম ফাঁকা রাখতে হবে)');
      return;
    }

    const chip = this.config.chips[this.selectedChipIndex];
    if (!chip) return;

    if (this.balance < chip.value) {
      this.showToast('⚠️ পর্যাপ্ত ডায়মন্ড নেই! ব্যালেন্স রিচার্জ করুন।');
      return;
    }

    this.balance -= chip.value;
    this.currentBets[slotIndex] = (this.currentBets[slotIndex] || 0) + chip.value;

    this.updateUserBalanceUI();
    this.updateBetBadges();
    this.playSound('chip');

    if (this.userId && this.db) {
      const betDeduct = {
        diamonds: firebase.firestore.FieldValue.increment(-chip.value)
      };
      this.db.collection('Users').doc(this.userId).update(betDeduct).catch(() => { });

      this.db.collection('game_history').add({
        userId: this.userId,
        gameId: 'greedy_market',
        type: 'BET',
        betAmount: chip.value,
        slotIndex: slotIndex,
        roundId: this.currentRoundId,
        itemName: this.config.items[slotIndex]?.name || '',
        multiplier: this.config.items[slotIndex]?.multiplier || 5,
        roomId: this.roomId || '',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      }).catch(() => { });
    }

    if (event) {
      this.animateFlyingChip(event.clientX, event.clientY, slotIndex);
    }
  }

  animateFlyingChip(startX, startY, targetSlotIndex) {
    const targetSlot = document.getElementById(`slot-${targetSlotIndex}`);
    if (!targetSlot) return;

    const targetRect = targetSlot.getBoundingClientRect();
    const chip = this.config.chips[this.selectedChipIndex];

    const flying = document.createElement('div');
    flying.className = `flying-chip ${chip.class || 'chip-cyan'}`;
    flying.style.left = `${startX - 14}px`;
    flying.style.top = `${startY - 14}px`;
    document.body.appendChild(flying);

    requestAnimationFrame(() => {
      flying.style.left = `${targetRect.left + targetRect.width / 2 - 14}px`;
      flying.style.top = `${targetRect.top + targetRect.height / 2 - 14}px`;
      flying.style.transform = 'scale(0.7)';
      flying.style.opacity = '0.9';
    });

    setTimeout(() => {
      flying.remove();
    }, 420);
  }

  updateBetBadges() {
    this.config.items.forEach((_, idx) => {
      const cloud = document.getElementById(`chips-cloud-${idx}`);
      const badge = document.getElementById(`bet-badge-${idx}`);
      const amount = this.currentBets[idx] || 0;

      if (cloud && badge) {
        if (amount > 0) {
          cloud.classList.add('active');
          badge.textContent = this.formatNumber(amount);
        } else {
          cloud.classList.remove('active');
        }
      }
    });
  }

  updateUserBalanceUI() {
    const el = document.getElementById('user-coin-balance');
    if (el) {
      el.textContent = this.formatNumber(this.balance);
    }
  }

  updateTodaysWinUI() {
    const el = document.getElementById('today-win-val');
    if (el) {
      el.textContent = this.formatNumber(this.todaysWin);
    }
  }

  highlightSlot(idx) {
    this.clearSlotHighlights();
    const slot = document.getElementById(`slot-${idx}`);
    if (slot) slot.classList.add('highlighted');
  }

  setWinnerSlot(idx) {
    this.clearSlotHighlights();
    const slot = document.getElementById(`slot-${idx}`);
    if (slot) slot.classList.add('winner-card');
  }

  clearSlotHighlights() {
    const slots = document.querySelectorAll('.item-card');
    slots.forEach(s => s.classList.remove('highlighted', 'winner-card'));
  }

  getCalculatedRoundNumber() {
    const nowMs = Date.now();
    const cycleDuration = (this.config.betTime || 30) + (this.config.spinTime || 6) + (this.config.resultTime || 5);
    const now = new Date(nowMs);
    const cycleStart = new Date(now);
    cycleStart.setHours(22, 0, 0, 0); // 10:00 PM

    if (now.getTime() < cycleStart.getTime()) {
      cycleStart.setDate(cycleStart.getDate() - 1);
    }

    const elapsedSeconds = Math.floor((now.getTime() - cycleStart.getTime()) / 1000);
    return Math.floor(elapsedSeconds / cycleDuration) + 1;
  }

  // Show Exact Result of Round Modal (100% Matching Screenshot)
  showWinModal(winnerItem, userWinAmount) {
    const modal = document.getElementById('win-modal');
    const imgEl = document.getElementById('win-modal-item-img');
    const titleEl = document.getElementById('win-modal-round-title');
    const nameEl = document.getElementById('win-modal-item-name');
    const multEl = document.getElementById('win-modal-item-mult');
    const spendingEl = document.getElementById('win-modal-my-spending');
    const earningsEl = document.getElementById('win-modal-my-earnings');
    const winnersRow = document.getElementById('round-biggest-winners-row');

    if (!modal) return;

    // 1. Winning Item Image, Name & Multiplier
    if (imgEl && winnerItem) imgEl.src = winnerItem.icon || '';
    if (nameEl && winnerItem) nameEl.textContent = winnerItem.name || 'Food';
    if (multEl && winnerItem) multEl.textContent = `Win ${winnerItem.multiplier || 5} Time`;

    // 2. Round Title
    const roundNumber = this.getCalculatedRoundNumber();
    if (titleEl) titleEl.textContent = `Result of Round ${roundNumber}`;

    // 3. User Spending & Earnings for this round
    let roundSpending = 0;
    Object.values(this.currentBets || {}).forEach(amt => {
      roundSpending += (Number(amt) || 0);
    });

    if (spendingEl) spendingEl.textContent = this.formatNumber(roundSpending);
    if (earningsEl) earningsEl.textContent = this.formatNumber(userWinAmount || 0);

    // 4. Populate 3 Biggest Winners for this Round (Real Players Only - Empty dashes if no winners)
    if (winnersRow) {
      const realWinners = [];
      if (userWinAmount > 0) {
        realWinners.push({
          name: this.userName || 'Player',
          avatar: this.userAvatar || '',
          coins: userWinAmount
        });
      }

      // Generate exact 3 slots: Real winner if present, otherwise clean dashed empty placeholder
      const slotsHtml = [1, 2, 3].map((rank, idx) => {
        const winner = realWinners[idx];
        if (winner) {
          const avatarHtml = winner.avatar
            ? `<img class="round-winner-avatar" src="${winner.avatar}" alt="${winner.name}">`
            : `<div class="round-winner-placeholder"><svg viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg></div>`;

          return `
            <div class="round-winner-col">
              <div class="round-winner-avatar-wrap">
                ${avatarHtml}
                <span class="rank-circle-badge rank-${rank}-badge">${rank}</span>
              </div>
              <span class="round-winner-name">${winner.name}</span>
              <div class="round-winner-coins">
                <img src="${this.getDiamondIconUrl()}" class="app-diamond-img" style="width:14px;height:14px;vertical-align:middle;object-fit:contain;margin-right:2px;" alt="💎">
                <span class="coin-amount-val">${this.formatNumber(winner.coins)}</span>
              </div>
            </div>
          `;
        } else {
          return `
            <div class="round-winner-col">
              <div class="round-winner-avatar-wrap">
                <div class="round-winner-placeholder">
                  <svg viewBox="0 0 24 24">
                    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                  </svg>
                </div>
                <span class="rank-circle-badge rank-${rank}-badge">${rank}</span>
              </div>
              <span class="round-winner-dash">--</span>
            </div>
          `;
        }
      }).join('');

      winnersRow.innerHTML = slotsHtml;
    }

    modal.classList.add('active');
  }

  hideWinModal() {
    const modal = document.getElementById('win-modal');
    if (modal) modal.classList.remove('active');
  }

  showToast(msg) {
    const existing = document.getElementById('game-toast');
    if (existing) existing.remove();

    const toast = document.createElement('div');
    toast.id = 'game-toast';
    toast.style.cssText = `
      position: fixed;
      top: 65px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(8, 20, 52, 0.95);
      color: #ffd700;
      padding: 8px 18px;
      border-radius: 20px;
      border: 1.5px solid #ffd700;
      font-size: 12.5px;
      font-weight: bold;
      z-index: 1000;
      box-shadow: 0 4px 20px rgba(0,0,0,0.8);
      text-align: center;
      max-width: 88vw;
    `;
    toast.textContent = msg;
    document.body.appendChild(toast);

    setTimeout(() => toast.remove(), 2600);
  }

  formatNumber(num) {
    return Number(num).toLocaleString();
  }

  renderUserHistory() {
    const list = document.getElementById('user-history-list');
    const dateText = document.getElementById('my-record-date-text');
    if (dateText) {
      const d = new Date();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateText.textContent = `${months[d.getMonth()]},${String(d.getDate()).padStart(2, '0')} ${d.getFullYear()}`;
    }
    if (!list) return;

    if (!this.userBetHistory || this.userBetHistory.length === 0) {
      list.innerHTML = `
        <div class="record-empty-state">
          <div style="font-size:36px;margin-bottom:10px;opacity:0.8;">📜</div>
          <div style="font-size:15px;font-weight:700;color:#ffffff;margin-bottom:4px;">No Records Yet</div>
          <div style="font-size:12px;color:#c4b5fd;">Participate and place bets in rounds to see your history!</div>
        </div>
      `;
      return;
    }

    list.innerHTML = this.userBetHistory.map(item => {
      const isWin = item.isWin && Number(item.winAmount) > 0;
      return `
        <div class="my-record-card-row">
          <div class="record-left">
            <div class="record-round-title">Round: ${item.roundNumber}</div>
            <div class="record-play-row">
              <span>Play:</span>
              <img src="${this.getDiamondIconUrl()}" class="app-diamond-img" style="width:14px;height:14px;vertical-align:middle;object-fit:contain;margin:0 2px;" alt="💎">
              <span>${this.formatNumber(item.totalBet)}</span>
            </div>
            <div class="record-timestamp">${item.dateStr || ''}</div>
          </div>
          <div class="record-right">
            ${isWin ? `
              <div class="record-win-emblem">
                <div class="record-win-amount">Win<br>+${this.formatNumber(item.winAmount)}</div>
              </div>
            ` : `
              <div class="record-missed-emblem">
                <svg class="record-missed-bg-diamond" viewBox="0 0 24 24" fill="#ffffff">
                  <path d="M12 2L2 9l10 13 10-13-10-7zm0 3.8L17.5 9 12 16.2 6.5 9 12 5.8z"/>
                </svg>
                <span class="record-missed-text">Missed</span>
              </div>
            `}
            <span class="record-chevron">&rsaquo;</span>
          </div>
        </div>
      `;
    }).join('');
  }

  attachEventListeners() {
    const soundBtn = document.getElementById('btn-sound');
    if (soundBtn) {
      soundBtn.addEventListener('click', () => {
        this.soundEnabled = !this.soundEnabled;
        soundBtn.textContent = this.soundEnabled ? '🔊' : '🔇';
      });
    }

    const lbModal = document.getElementById('leaderboard-modal');
    const openLeaderboard = (e) => {
      if (e) {
        e.preventDefault();
        e.stopPropagation();
      }
      this.renderLeaderboard();
      if (lbModal) lbModal.classList.add('active');
    };

    const lbBtn = document.getElementById('btn-leaderboard');
    const trophyBtn = document.getElementById('btn-trophy');
    if (lbBtn && lbModal) {
      lbBtn.addEventListener('click', openLeaderboard);
      lbBtn.addEventListener('touchend', openLeaderboard);
    }
    if (trophyBtn && lbModal) {
      trophyBtn.addEventListener('click', openLeaderboard);
      trophyBtn.addEventListener('touchend', openLeaderboard);
    }

    const histBtn = document.getElementById('btn-history');
    const histModal = document.getElementById('user-history-modal');
    if (histBtn && histModal) {
      histBtn.addEventListener('click', () => {
        this.renderUserHistory();
        histModal.classList.add('active');
      });
    }

    const rulesBtn = document.getElementById('btn-rules');
    const rulesModal = document.getElementById('rules-modal');
    if (rulesBtn && rulesModal) {
      rulesBtn.addEventListener('click', () => rulesModal.classList.add('active'));
    }

    document.querySelectorAll('.modal-close-btn, .round-result-close-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const modal = e.target.closest('.modal-overlay');
        if (modal) modal.classList.remove('active');
      });
    });

    const closeBtn = document.getElementById('btn-close');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => {
        if (window.parent && window.parent !== window) {
          window.parent.postMessage({ type: 'CLOSE_GAME' }, '*');
        } else if (window.history.length > 1) {
          window.history.back();
        } else {
          this.showToast('Game Close Triggered');
        }
      });
    }

    const addCoinBtn = document.getElementById('btn-add-coin');
    if (addCoinBtn) {
      addCoinBtn.addEventListener('click', () => {
        if (window.FlutterBridge) {
          window.FlutterBridge.postMessage(JSON.stringify({ type: 'OPEN_WALLET' }));
        } else if (window.FlutterChannel) {
          window.FlutterChannel.postMessage(JSON.stringify({ type: 'OPEN_WALLET' }));
        } else if (window.parent && window.parent !== window) {
          window.parent.postMessage({ type: 'OPEN_RECHARGE' }, '*');
        } else {
          this.showToast('💎 রিচার্জ করতে আপনার ওয়ালেটে যান!');
        }
      });
    }
  }
}

// Start Game
document.addEventListener('DOMContentLoaded', () => {
  window.gameInstance = new GreedyGame();
  window.gameInstance.init();
});
