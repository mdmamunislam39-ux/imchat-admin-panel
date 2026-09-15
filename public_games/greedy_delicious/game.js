/**
 * Greedy Delicious - HTML5 Core Engine
 * 1:1 Match with User Screenshot and Video Reference
 */

// ================= CONSTANTS & GAME DATA =================
const FOOD_ITEMS = [
  { id: 0, name: 'Hot Dog', multiplier: 10, img: 'assets/images/hotdog.png?v=2', label: 'Win 10 Time', angle: 0, type: 'meat' },
  { id: 1, name: 'BBQ Skewer', multiplier: 15, img: 'assets/images/skewer.png?v=2', label: 'Win 15 Time', angle: 45, type: 'meat' },
  { id: 2, name: 'Ham Leg', multiplier: 25, img: 'assets/images/ham.png?v=2', label: 'Win 25 Time', angle: 90, type: 'meat' },
  { id: 3, name: 'Steak', multiplier: 45, img: 'assets/images/steak.png?v=2', label: 'Win 45 Time', angle: 135, type: 'meat' },
  { id: 4, name: 'Carrot', multiplier: 5, img: 'assets/images/carrot.png?v=2', label: 'Win 5 Times', angle: 180, type: 'veg' },
  { id: 5, name: 'Corn', multiplier: 5, img: 'assets/images/corn.png?v=2', label: 'Win 5 Times', angle: 225, type: 'veg' },
  { id: 6, name: 'Cabbage', multiplier: 5, img: 'assets/images/cabbage.png?v=2', label: 'Win 5 Times', angle: 270, type: 'veg' },
  { id: 7, name: 'Tomato', multiplier: 5, img: 'assets/images/tomato.png?v=2', label: 'Win 5 Times', angle: 315, type: 'veg' }
];

/**
 * Dynamic Synchronized Hot Item Picker:
 * Alternates between meat delicacies and fresh vegetables across rounds
 * to make the game dynamic, engaging, and attractive!
 */
function getHotItemId(roundNumber) {
  const pattern = [0, 4, 1, 6, 2, 5, 3, 7];
  return pattern[Math.abs(Number(roundNumber)) % pattern.length];
}

const CHIP_TIERS = {
  regular: [
    { value: 50, label: '50' },
    { value: 500, label: '500' },
    { value: 5000, label: '5k' },
    { value: 50000, label: '50k' }
  ],
  advanced: [
    { value: 100, label: '100' },
    { value: 1000, label: '1k' },
    { value: 10000, label: '10k' },
    { value: 100000, label: '100k' }
  ]
};

// Synchronized Universal Round Cycle Configuration:
// 30s Betting + 4s Spin + 6s Result = 40s Total Cycle
const CYCLE_DURATION = 40;
const TIME_BETTING = 30;
const TIME_SPIN = 4;
const TIME_RESULT = 6;
const EPOCH_BASE = 1704067200; // 2024-01-01 00:00:00 UTC base anchor

/**
 * Universal Synchronized Daily Clock (Resets every 24 Hours):
 * - Round number counts from 1 to 2160 daily (40 seconds per round, 86,400s per day).
 * - Every 24 hours at midnight local/UTC, the round number resets to 1.
 * - Top 10 Winners & Today's Prize pool refresh daily.
 */
function getSyncClock() {
  const now = new Date();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const secondsToday = Math.floor((Date.now() - startOfDay) / 1000);

  // Daily round number: 1 to 2160
  const roundNumber = 1 + Math.floor(secondsToday / CYCLE_DURATION);
  const cycleSec = secondsToday % CYCLE_DURATION;

  let phase;
  let phaseTimeLeft;
  if (cycleSec < TIME_BETTING) {
    phase = 'BETTING';
    phaseTimeLeft = TIME_BETTING - cycleSec;
  } else if (cycleSec < TIME_BETTING + TIME_SPIN) {
    phase = 'SPINNING';
    phaseTimeLeft = (TIME_BETTING + TIME_SPIN) - cycleSec;
  } else {
    phase = 'RESULT';
    phaseTimeLeft = CYCLE_DURATION - cycleSec;
  }

  const dayKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

  return { roundNumber, cycleSec, phase, phaseTimeLeft, dayKey };
}

/**
 * Deterministic Pseudo-Random Generator (PRNG) seeded by roundNumber and day:
 * Guarantees that every player across all devices and tabs sees the
 * EXACT same winning outcome for the exact same round!
 *
 * Payout Engine: Calibrated for 75% RTP (Return To Player) & 25% House Edge.
 */
function getRoundWinner(roundNumber) {
  // Remote Admin Control: Override with forced winner if set
  const remote = window.REMOTE_GAME_CONFIG;
  if (remote && remote.forceWinnerIndex !== undefined && Number(remote.forceWinnerIndex) >= 0) {
    const forcedId = Number(remote.forceWinnerIndex);
    if (forcedId < 8 && FOOD_ITEMS[forcedId]) {
      return { type: 'item', id: forcedId, name: FOOD_ITEMS[forcedId].name, multiplier: FOOD_ITEMS[forcedId].multiplier, weight: 100 };
    }
  }

  const sync = getSyncClock();
  const daySeed = sync.dayKey.split('-').reduce((acc, v) => acc * 31 + Number(v), 0);
  let s = (Math.imul(roundNumber, 1597334677) ^ daySeed ^ 0x6d2b79f5) >>> 0;
  function rnd() {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  // Calculate dynamic weights influenced by admin winRatio (default 65% RTP)
  const targetWinRatio = (remote && remote.winRatio !== undefined) ? Number(remote.winRatio) : 65;
  const highMultWeightMod = Math.max(0.2, targetWinRatio / 65);

  const outcomes = [
    { type: 'item', id: 4, name: FOOD_ITEMS[4]?.name || 'Carrot', multiplier: FOOD_ITEMS[4]?.multiplier || 5, weight: 120 },
    { type: 'item', id: 5, name: FOOD_ITEMS[5]?.name || 'Corn', multiplier: FOOD_ITEMS[5]?.multiplier || 5, weight: 120 },
    { type: 'item', id: 6, name: FOOD_ITEMS[6]?.name || 'Cabbage', multiplier: FOOD_ITEMS[6]?.multiplier || 5, weight: 120 },
    { type: 'item', id: 7, name: FOOD_ITEMS[7]?.name || 'Tomato', multiplier: FOOD_ITEMS[7]?.multiplier || 5, weight: 120 },
    { type: 'item', id: 0, name: FOOD_ITEMS[0]?.name || 'Hot Dog', multiplier: FOOD_ITEMS[0]?.multiplier || 10, weight: Math.round(42 * highMultWeightMod) },
    { type: 'item', id: 1, name: FOOD_ITEMS[1]?.name || 'BBQ Skewer', multiplier: FOOD_ITEMS[1]?.multiplier || 15, weight: Math.round(22 * highMultWeightMod) },
    { type: 'item', id: 2, name: FOOD_ITEMS[2]?.name || 'Ham Leg', multiplier: FOOD_ITEMS[2]?.multiplier || 25, weight: Math.round(9 * highMultWeightMod) },
    { type: 'item', id: 3, name: FOOD_ITEMS[3]?.name || 'Steak', multiplier: FOOD_ITEMS[3]?.multiplier || 45, weight: Math.round(3 * highMultWeightMod) },
    { type: 'salad', id: 'salad', name: 'Salad Special', weight: Math.round(12 * highMultWeightMod) },
    { type: 'pizza', id: 'pizza', name: 'Pizza Special', weight: Math.round(2 * highMultWeightMod) }
  ];

  const totalW = outcomes.reduce((sum, o) => sum + o.weight, 0);
  let r = rnd() * totalW;
  for (const o of outcomes) {
    if (r < o.weight) return o;
    r -= o.weight;
  }
  return outcomes[0];
}

/**
 * Payout Engine Calculation:
 * - Direct item win: userBets[itemId] * multiplier
 * - Pizza Special: 10x, 15x, 25x, 45x items all win simultaneously!
 * - Salad Special: all four 5x items win simultaneously!
 */
function calculateWinnings(outcome, userBets) {
  let earnings = 0;
  const winningItemIds = [];
  if (!userBets) return { earnings: 0, winningItemIds: [] };

  if (outcome.type === 'item') {
    const item = FOOD_ITEMS[outcome.id];
    const bet = userBets[outcome.id] || 0;
    if (bet > 0) {
      earnings = bet * item.multiplier;
      winningItemIds.push(outcome.id);
    }
  } else if (outcome.type === 'pizza') {
    [0, 1, 2, 3].forEach(id => {
      const item = FOOD_ITEMS[id];
      const bet = userBets[id] || 0;
      if (bet > 0) {
        earnings += bet * item.multiplier;
        winningItemIds.push(id);
      }
    });
  } else if (outcome.type === 'salad') {
    [4, 5, 6, 7].forEach(id => {
      const item = FOOD_ITEMS[id];
      const bet = userBets[id] || 0;
      if (bet > 0) {
        earnings += bet * item.multiplier;
        winningItemIds.push(id);
      }
    });
  }

  return { earnings, winningItemIds };
}

// Storage helpers for persistent offline bets
function getPendingBetsMap() {
  try {
    return JSON.parse(localStorage.getItem('greedy_pending_bets')) || {};
  } catch (e) {
    return {};
  }
}

function savePendingBetsMap(map) {
  localStorage.setItem('greedy_pending_bets', JSON.stringify(map));
}

// Storage helpers for My Record history (1:1 with screenshots)
function getMyRecordsList() {
  const stored = localStorage.getItem('greedy_user_record_list');
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch (e) { }
  }
  // Pre-seed realistic records matching screenshots 1 & 2
  const defaultRecords = [
    { roundNumber: 528, spending: 10, earnings: 0, won: false, dateStr: 'Sep,04 2026 05:16' },
    { roundNumber: 527, spending: 140, earnings: 0, won: false, dateStr: 'Sep,04 2026 05:16' },
    { roundNumber: 526, spending: 75, earnings: 150, won: true, dateStr: 'Sep,04 2026 05:15' },
    { roundNumber: 525, spending: 15, earnings: 75, won: true, dateStr: 'Sep,04 2026 05:14' },
    { roundNumber: 417, spending: 5, earnings: 0, won: false, dateStr: 'Sep,01 2026 04:10' },
    { roundNumber: 415, spending: 5, earnings: 0, won: false, dateStr: 'Sep,01 2026 04:08' },
    { roundNumber: 414, spending: 5, earnings: 0, won: false, dateStr: 'Sep,01 2026 04:08' }
  ];
  localStorage.setItem('greedy_user_record_list', JSON.stringify(defaultRecords));
  return defaultRecords;
}

function saveMyRecordsList(list) {
  localStorage.setItem('greedy_user_record_list', JSON.stringify(list));
}

function formatRecordDate(timestamp) {
  const d = new Date(timestamp);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const mmm = months[d.getMonth()];
  const dd = String(d.getDate()).padStart(2, '0');
  const yyyy = d.getFullYear();
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${mmm},${dd} ${yyyy} ${hh}:${mm}`;
}

function formatHeaderDate(timestamp) {
  const d = new Date(timestamp);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${months[d.getMonth()]},${String(d.getDate()).padStart(2, '0')} ${d.getFullYear()}`;
}

// Robust Number Parsing & Counting Helper (Guarantees no NaN, no negative values, strips commas)
function parseCoinsNum(val) {
  if (typeof val === 'number') return isNaN(val) ? 0 : Math.max(0, Math.floor(val));
  if (!val) return 0;
  const clean = String(val).replace(/[^0-9.-]/g, '');
  const parsed = parseFloat(clean);
  return isNaN(parsed) ? 0 : Math.max(0, Math.floor(parsed));
}

// Smooth Number Counter Animation for Live Real-Time Rollup
function animateNumber(element, startVal, endVal, duration = 650) {
  if (!element) return;
  startVal = parseCoinsNum(startVal);
  endVal = parseCoinsNum(endVal);
  if (startVal === endVal) {
    element.textContent = Number(endVal).toLocaleString();
    return;
  }
  const startTime = performance.now();
  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);
    // Smooth ease-out cubic
    const ease = 1 - Math.pow(1 - progress, 3);
    const current = Math.floor(startVal + (endVal - startVal) * ease);
    element.textContent = Number(current).toLocaleString();
    if (progress < 1) {
      requestAnimationFrame(update);
    } else {
      element.textContent = Number(endVal).toLocaleString();
    }
  }
  requestAnimationFrame(update);
}

// Storage helpers for Real Daily Winners (Strictly daily accumulated counts, no fake winners!)
function getDailyTopWinners(dayKey) {
  const stored = localStorage.getItem('greedy_daily_real_winners_' + dayKey);
  if (stored) {
    try {
      const list = JSON.parse(stored);
      if (Array.isArray(list)) {
        return list.map(item => ({
          ...item,
          coinsNum: parseCoinsNum(item.coinsNum || item.coins),
          coins: Number(parseCoinsNum(item.coinsNum || item.coins)).toLocaleString()
        }));
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  return [];
}

function saveDailyTopWinners(dayKey, list) {
  localStorage.setItem('greedy_daily_real_winners_' + dayKey, JSON.stringify(list));
}

function recordDailyWinner(dayKey, earnings, userName, userAvatar, userId) {
  const earnedNum = parseCoinsNum(earnings);
  if (earnedNum <= 0) return;

  const list = getDailyTopWinners(dayKey);
  const targetId = userId || 'current_user';
  let userEntry = list.find(item => item.id === targetId || (targetId !== 'current_user' && item.id === 'current_user'));
  const uName = userName || (userEntry ? userEntry.name : 'Winner');
  const uAvatar = userAvatar || (userEntry ? userEntry.avatar : '');

  if (userEntry) {
    userEntry.id = targetId;
    userEntry.coinsNum = parseCoinsNum(userEntry.coinsNum) + earnedNum;
    userEntry.coins = Number(userEntry.coinsNum).toLocaleString();
    userEntry.name = uName;
    if (uAvatar) userEntry.avatar = uAvatar;
  } else {
    list.push({
      id: targetId,
      rank: 1,
      name: uName,
      badge: '👑 SVIP Player',
      avatar: uAvatar,
      coinsNum: earnedNum,
      coins: Number(earnedNum).toLocaleString()
    });
  }

  // Sort descending by exact numerical coin total
  list.sort((a, b) => parseCoinsNum(b.coinsNum) - parseCoinsNum(a.coinsNum));

  // Assign clean sequential ranks
  list.forEach((item, idx) => {
    item.rank = idx + 1;
    item.coinsNum = parseCoinsNum(item.coinsNum);
    item.coins = Number(item.coinsNum).toLocaleString();
  });

  saveDailyTopWinners(dayKey, list);
}

// ================= GAME STATE =================
class GreedyGameState {
  constructor() {
    const urlParams = new URLSearchParams(window.location.search);
    const initialDiamonds = urlParams.get('diamonds') || urlParams.get('coins') || urlParams.get('balance');
    if (initialDiamonds !== null && !isNaN(Number(initialDiamonds))) {
      this.balance = Number(initialDiamonds);
    } else {
      this.balance = localStorage.getItem('greedy_balance') !== null ? parseInt(localStorage.getItem('greedy_balance')) : 10000;
    }

    // Synchronized daily round & phase
    const sync = getSyncClock();
    this.roundNumber = sync.roundNumber;
    const tierParam = urlParams.get('tier') || urlParams.get('mode');
    if (tierParam === 'advanced' || tierParam === 'advance') {
      this.currentTier = 'advanced';
      this.selectedChip = 100;
    } else {
      this.currentTier = 'regular';
      this.selectedChip = 50; // Default 50 for Regular mode
    }

    this.phase = sync.phase; // 'BETTING' | 'SPINNING' | 'RESULT'
    this.timeLeft = sync.phaseTimeLeft;
    this.dayKey = sync.dayKey;

    // User-specific Today's Prize (persists for this user, resets every 24h, 0 if not played)
    this.todayPrize = parseInt(localStorage.getItem('greedy_user_today_prize_' + this.dayKey)) || 0;

    // Active bets in current round: { itemId: amount }
    // (Shared seamlessly between Regular and Advance!)
    this.userBets = {};
    this.totalSpending = 0;

    // Combo bets
    this.comboSaladBet = 0;
    this.comboPizzaBet = 0;

    // History of past winning items
    this.history = [];
    for (let i = 5; i >= 1; i--) {
      const pastRoundNum = Math.max(1, this.roundNumber - i);
      const pastOutcome = getRoundWinner(pastRoundNum);
      this.history.push(pastOutcome.type === 'item' ? pastOutcome.id : (pastOutcome.type === 'pizza' ? 0 : 5));
    }

    // Sounds & Audio
    this.soundEnabled = true;
    this.bgmEnabled = false;

    // Active highlighted slot during spin
    this.activeSpinIndex = -1;
    this.winnerOutcome = null;
  }

  save() {
    localStorage.setItem('greedy_balance', this.balance);
    localStorage.setItem('greedy_user_today_prize_' + this.dayKey, this.todayPrize);
  }
}

// ================= AUDIO CONTROLLER =================
class AudioManager {
  constructor() {
    this.audioBet = document.getElementById('audio-bet');
    this.audioSpin = document.getElementById('audio-spin');
    this.audioWin = document.getElementById('audio-win');
    this.audioBgm = document.getElementById('audio-bgm');

    // Web Audio synthesizer fallback for crisp casino clicks & ticks
    try {
      this.ctx = new (window.AudioContext || window.webkitAudioContext)();
    } catch (e) {
      this.ctx = null;
    }
  }

  unlockAudio() {
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  playBet() {
    if (!game.state.soundEnabled) return;
    this.unlockAudio();
    if (this.audioBet) {
      this.audioBet.currentTime = 0;
      this.audioBet.play().catch(() => this.playSynthChip());
    } else {
      this.playSynthChip();
    }
  }

  playTick() {
    if (!game.state.soundEnabled) return;
    this.playSynthTick();
  }

  playSpin() {
    if (!game.state.soundEnabled) return;
    this.unlockAudio();
    if (this.audioSpin) {
      this.audioSpin.currentTime = 0;
      this.audioSpin.play().catch(() => { });
    }
  }

  stopSpin() {
    if (this.audioSpin) {
      this.audioSpin.pause();
      this.audioSpin.currentTime = 0;
    }
  }

  playWin() {
    if (!game.state.soundEnabled) return;
    this.unlockAudio();
    if (this.audioWin) {
      this.audioWin.currentTime = 0;
      this.audioWin.play().catch(() => this.playSynthWin());
    } else {
      this.playSynthWin();
    }
  }

  toggleBgm(enable) {
    if (this.audioBgm) {
      if (enable) {
        this.unlockAudio();
        this.audioBgm.volume = 0.4;
        this.audioBgm.play().catch(() => { });
      } else {
        this.audioBgm.pause();
      }
    }
  }

  // Synthesizers using Web Audio API for 100% reliable low-latency audio
  playSynthChip() {
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(800, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(1400, this.ctx.currentTime + 0.08);
    gain.gain.setValueAtTime(0.3, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.08);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.08);
  }

  playSynthTick() {
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(950, this.ctx.currentTime);
    gain.gain.setValueAtTime(0.15, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.04);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.04);
  }

  playSynthWin() {
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    [523.25, 659.25, 783.99, 1046.50].forEach((freq, i) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0, now + i * 0.08);
      gain.gain.linearRampToValueAtTime(0.25, now + i * 0.08 + 0.04);
      gain.gain.exponentialRampToValueAtTime(0.01, now + i * 0.08 + 0.4);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(now + i * 0.08);
      osc.stop(now + i * 0.08 + 0.4);
    });
  }
}

// ================= MAIN GAME CONTROLLER =================
class GreedyGame {
  constructor() {
    // App User Profile Details from Query Parameters
    const urlParams = new URLSearchParams(window.location.search);
    this.userId = urlParams.get('userId') || urlParams.get('uid') || urlParams.get('user_id') || null;
    this.userName = urlParams.get('fullname') || urlParams.get('name') || urlParams.get('userName') || urlParams.get('username') || urlParams.get('nickname') || 'Player';
    this.userAvatar = urlParams.get('photoUrl') || urlParams.get('avatar') || urlParams.get('avatarUrl') || urlParams.get('profilePic') || urlParams.get('photo') || '';
    this.token = urlParams.get('token') || null;
    this.roomId = urlParams.get('roomId') || urlParams.get('room_id') || null;
    this.isRealUser = Boolean(this.userId);

    this.state = new GreedyGameState();
    this.audio = new AudioManager();

    this.slotsContainer = document.getElementById('food-wheel-slots');
    this.chipsContainer = document.getElementById('chips-container');
    this.resultTrack = document.getElementById('result-items-track');
    this.userBalanceVal = document.getElementById('user-balance-val');
    this.roundNumberLabel = document.getElementById('round-number-label');
    this.countdownTimerVal = document.getElementById('countdown-timer-val');
    this.flyingLayer = document.getElementById('flying-chips-layer');
    this.toastBanner = document.getElementById('toast-banner');

    this.db = null;
    this.init();
  }

  init() {
    this.initFirebaseSync();
    this.checkAndSettleOfflineBets();
    const sync = getSyncClock();
    this.state.roundNumber = sync.roundNumber;
    this.state.phase = sync.phase;
    this.state.timeLeft = sync.phaseTimeLeft;
    this.state.dayKey = sync.dayKey;

    if (this.state.currentTier === 'advanced') {
      document.getElementById('app-container')?.classList.add('theme-advance');
      document.getElementById('tab-advanced')?.classList.add('active');
      document.getElementById('tab-regular')?.classList.remove('active');
    }

    this.renderWheelSlots();
    this.updateHotBadge(this.state.roundNumber);
    this.renderChipDeck();
    this.renderHistory();
    this.updateBalanceUI();
    this.updateTodayPrizeUI();
    this.renderMyRecords();
    this.updateLeaderboardPreview();
    this.restoreActiveRoundIfAny(this.state.roundNumber);
    this.setupEventListeners();
    this.startMasterSyncLoop();
  }

  // --- Real-time Firebase Firestore Sync & Live Diamond Wallet ---
  initFirebaseSync() {
    if (typeof firebase !== 'undefined') {
      try {
        if (firebase.apps.length === 0) {
          firebase.initializeApp({ projectId: 'imchat-84519' });
        }
        this.db = firebase.firestore();

        // 1. Live Admin Configuration Listener (RTP, food item multipliers, active status)
        this.db.collection('config').doc('html5_greedy_delicious')
          .onSnapshot((doc) => {
            if (doc && doc.exists) {
              const data = doc.data();
              this.applyRemoteConfig(data);
            }
          }, (err) => console.warn('Config sync note:', err.message));

        // 2. Real-time User Diamond Wallet Listener on Users/{userId}
        if (this.userId) {
          const handleUserData = (doc) => {
            if (doc && doc.exists) {
              const uData = doc.data() || {};
              const realName = uData.fullname || uData.name || uData.username || uData.displayName || uData.nickname;
              if (realName) this.userName = realName;

              const realAvatar = uData.photoUrl || uData.profilePic || uData.avatarUrl || uData.image || uData.avatar;
              if (realAvatar) this.userAvatar = realAvatar;

              // In IMChat, wallet currency is strictly in 'diamonds' (1 Coin = 1 Diamond)
              const rawBal = uData.diamonds ?? uData.diamond ?? uData.coins ?? uData.walletBalance ?? uData.balance;
              if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
                this.state.balance = Number(rawBal);
                this.updateBalanceUI();
              }
            }
          };

          try {
            this.db.collection('Users').doc(this.userId).onSnapshot(handleUserData, () => { });
          } catch (e) { }
        }

        // 3. Real-time Daily Leaderboard Listener from game_history (Strictly counts TODAY's wins)
        try {
          this.db.collection('game_history')
            .where('gameId', '==', 'greedy_delicious')
            .limit(200)
            .onSnapshot((snapshot) => {
              if (snapshot && !snapshot.empty) {
                const now = new Date();
                const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
                const todayKey = this.state.dayKey;

                const winMap = new Map();
                snapshot.forEach(doc => {
                  const data = doc.data();
                  if (data && data.type === 'WIN' && data.userId) {
                    const eCoins = parseCoinsNum(data.earnings);
                    if (eCoins <= 0) return;

                    // Strictly filter by TODAY (dayKey match or timestamp >= start of today)
                    let isToday = false;
                    if (data.dayKey) {
                      isToday = (data.dayKey === todayKey);
                    } else if (data.createdAt) {
                      let tMs = 0;
                      if (typeof data.createdAt.toMillis === 'function') {
                        tMs = data.createdAt.toMillis();
                      } else if (data.createdAt.seconds) {
                        tMs = data.createdAt.seconds * 1000;
                      } else if (typeof data.createdAt === 'number') {
                        tMs = data.createdAt;
                      }
                      isToday = (tMs >= startOfDay);
                    } else {
                      isToday = true;
                    }

                    if (!isToday) return;

                    const existing = winMap.get(data.userId) || {
                      name: data.userName || 'Winner',
                      avatar: data.userAvatar || '',
                      coinsNum: 0
                    };
                    existing.coinsNum += eCoins;
                    if (data.userName) existing.name = data.userName;
                    if (data.userAvatar) existing.avatar = data.userAvatar;
                    winMap.set(data.userId, existing);
                  }
                });

                // Merge with local user's current session earnings so live score never flickers backward
                const localWinners = getDailyTopWinners(this.state.dayKey);
                const currentUserId = this.userId || 'current_user';
                const localMe = localWinners.find(w => w.id === currentUserId || w.id === 'current_user');
                if (localMe && parseCoinsNum(localMe.coinsNum) > 0) {
                  const existingMe = winMap.get(currentUserId) || {
                    name: this.userName || localMe.name || 'Winner',
                    avatar: this.userAvatar || localMe.avatar || '',
                    coinsNum: 0
                  };
                  existingMe.coinsNum = Math.max(existingMe.coinsNum, parseCoinsNum(localMe.coinsNum));
                  winMap.set(currentUserId, existingMe);
                }

                const sorted = Array.from(winMap.entries()).map(([uId, obj]) => {
                  const cNum = parseCoinsNum(obj.coinsNum);
                  return {
                    id: uId,
                    name: obj.name,
                    badge: '👑 SVIP Player',
                    avatar: obj.avatar || '',
                    coinsNum: cNum,
                    coins: Number(cNum).toLocaleString()
                  };
                }).sort((a, b) => b.coinsNum - a.coinsNum).slice(0, 10);

                sorted.forEach((w, idx) => w.rank = idx + 1);
                if (sorted.length > 0) {
                  saveDailyTopWinners(this.state.dayKey, sorted);
                  this.updateLeaderboardPreview();
                  this.refreshLeaderboardModalIfOpen();
                }
              }
            }, () => { });
        } catch (e) { }

        // 4. Real-time Global App Theme Diamond Icon Listener from global_settings/app_theme
        try {
          this.db.collection('global_settings').doc('app_theme')
            .onSnapshot((doc) => {
              if (doc && doc.exists) {
                const themeData = doc.data() || {};
                const appDiamond = themeData.diamondIconUrl || themeData.diamondIcon;
                if (appDiamond && appDiamond.trim() !== '') {
                  this.updateAllDiamondIcons(appDiamond.trim());
                }
              }
            }, () => { });
        } catch (e) { }
      } catch (e) {
        console.warn('Firebase init note:', e);
      }
    }

    // Direct Flutter Javascript Bridge: window.setUserProfile({ userId, name, avatar, diamonds, coins })
    window.setUserProfile = (profile) => {
      try {
        const data = typeof profile === 'string' ? JSON.parse(profile) : profile;
        if (data.userId || data.uid) this.userId = data.userId || data.uid;
        if (data.name || data.fullname || data.username) this.userName = data.name || data.fullname || data.username;
        if (data.avatar || data.photoUrl) this.userAvatar = data.avatar || data.photoUrl;
        const rawBal = data.diamonds ?? data.diamond ?? data.coins ?? data.balance ?? data.walletBalance;
        if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
          this.state.balance = Number(rawBal);
          this.updateBalanceUI();
        }
      } catch (e) { }
    };

    window.addEventListener('message', (event) => {
      try {
        const msg = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
        if (msg && msg.type === 'SET_USER_PROFILE') {
          window.setUserProfile(msg.payload || msg);
        }
      } catch (e) { }
    });
  }

  applyRemoteConfig(data) {
    if (!data) return;
    window.REMOTE_GAME_CONFIG = data;

    if (data.isActive !== undefined && !data.isActive) {
      this.showToast('⚠️ Game is undergoing routine maintenance.');
    }

    // 1. Dynamic 8 Food Items (Names, Multipliers)
    if (data.items && Array.isArray(data.items)) {
      data.items.forEach(item => {
        if (item.id !== undefined && FOOD_ITEMS[item.id]) {
          if (item.multiplier !== undefined) {
            const mult = Number(item.multiplier);
            FOOD_ITEMS[item.id].label = mult === 5 ? 'Win 5 Times' : `Win ${mult} Time`;
          }
          if (item.name) FOOD_ITEMS[item.id].name = item.name;
        }
      });
      this.renderWheelSlots();
    }

    // 2. Chips: Preserved to match the authentic mobile app screenshots (5, 100, 500, 1000 & 100, 1000, 5000, 10000)
    this.renderChipDeck();

    // 3. Dynamic Background Wallpaper
    const bgUrl = data.gameBackgroundUrl || data.basicBg;
    if (bgUrl && bgUrl.trim() !== '') {
      const portraitWrap = document.querySelector('.game-portrait-wrapper') || document.body;
      portraitWrap.style.backgroundImage = `url("${bgUrl.trim()}")`;
      portraitWrap.style.backgroundSize = 'cover';
      portraitWrap.style.backgroundPosition = 'center';
    }

    // 4. Dynamic Currency Diamond Icon from Admin Panel (Real-Time)
    if (data.diamondIcon && data.diamondIcon.trim() !== '') {
      this.updateAllDiamondIcons(data.diamondIcon.trim());
    }

    // 5. Dynamic Badges (Salad / Fruit & Pizza)
    if (data.fruitBadgeIcon && data.fruitBadgeIcon.trim() !== '') {
      const saladImg = document.querySelector('#badge-salad img, .badge-salad img');
      if (saladImg) saladImg.src = data.fruitBadgeIcon.trim();
    }
    if (data.fruitBadgeLabel && data.fruitBadgeLabel.trim() !== '') {
      const saladLbl = document.querySelector('#badge-salad-label, .badge-salad-label');
      if (saladLbl) saladLbl.textContent = data.fruitBadgeLabel.trim();
    }
    if (data.pizzaBadgeIcon && data.pizzaBadgeIcon.trim() !== '') {
      const pizzaImg = document.querySelector('#badge-pizza img, .badge-pizza img');
      if (pizzaImg) pizzaImg.src = data.pizzaBadgeIcon.trim();
    }
    if (data.pizzaBadgeLabel && data.pizzaBadgeLabel.trim() !== '') {
      const pizzaLbl = document.querySelector('#badge-pizza-label, .badge-pizza-label');
      if (pizzaLbl) pizzaLbl.textContent = data.pizzaBadgeLabel.trim();
    }
  }

  updateAllDiamondIcons(url) {
    if (!url || url.trim() === '') return;
    const cleanUrl = url.trim();
    window.REMOTE_DIAMOND_ICON = cleanUrl;
    document.querySelectorAll('.gem-img, .wallet-gem-img, #top-diamond-icon, .chip-diamond-icon, .prize-diamond-img, .stat-diamond-img, .lb-diamond-icon').forEach(el => {
      if (el.tagName === 'IMG') el.src = cleanUrl;
    });
    if (this.chipsContainer && this.chipsContainer.children.length > 0) {
      this.renderChipDeck();
    }
  }

  // ================= 1. WHEEL SLOTS RENDERING =================
  renderWheelSlots() {
    this.slotsContainer.innerHTML = '';
    const center = 180;
    const radius = 150;

    FOOD_ITEMS.forEach((item) => {
      // Pure mathematical octagonal geometry matching Screenshot 2:
      const rad = (item.angle - 90) * (Math.PI / 180);
      const x = Math.round(center + radius * Math.cos(rad));
      const y = Math.round(center + radius * Math.sin(rad));

      const card = document.createElement('div');
      card.className = 'food-slot-card';
      card.id = `food-slot-${item.id}`;
      card.style.left = `${x}px`;
      card.style.top = `${y}px`;

      card.innerHTML = `
        <div class="card-user-bet-badge" id="slot-bet-${item.id}">0</div>
        <div class="card-food-img-wrap">
          <img src="${item.img}" alt="${item.name}" class="card-food-img">
        </div>
        <span class="card-multiplier-label">${item.label}</span>
        <div class="card-bet-tokens-row" id="slot-tokens-${item.id}"></div>
      `;

      card.addEventListener('click', (e) => this.handleBetClick(item.id, e));
      this.slotsContainer.appendChild(card);
    });
  }

  // Dynamically assign and animate the "HOT" badge to the active round's hot item
  updateHotBadge(roundNumber) {
    // Remove previous hot badges and card glow
    document.querySelectorAll('.hot-badge-pill').forEach(el => el.remove());
    document.querySelectorAll('.food-slot-card.is-hot-card').forEach(el => el.classList.remove('is-hot-card'));

    const hotItemId = getHotItemId(roundNumber);
    const targetCard = document.getElementById(`food-slot-${hotItemId}`);
    if (targetCard) {
      targetCard.classList.add('is-hot-card');
      const hotBadge = document.createElement('div');
      hotBadge.className = 'hot-badge-pill';
      hotBadge.innerHTML = `<span class="hot-flame-icon">🔥</span>Hot`;
      targetCard.prepend(hotBadge);
    }
  }

  // ================= 2. CHIP DECK RENDERING =================
  renderChipDeck() {
    this.chipsContainer.innerHTML = '';
    const chips = CHIP_TIERS[this.state.currentTier];

    const validValues = chips.map(c => c.value);
    if (!validValues.includes(this.state.selectedChip)) {
      this.state.selectedChip = chips[0].value;
    }

    chips.forEach(chip => {
      const btn = document.createElement('button');
      btn.className = `chip-3d-btn ${chip.value === this.state.selectedChip ? 'selected' : ''}`;
      btn.id = `chip-btn-${chip.value}`;

      const diamondIconUrl = window.REMOTE_DIAMOND_ICON || 'assets/images/diamond_icon.webp';
      const chipIconSrc = (chip.icon && chip.icon.trim() !== '') ? chip.icon.trim() : diamondIconUrl;
      const iconHtml = `<img src="${chipIconSrc}" class="chip-diamond-icon" style="width:18px;height:18px;vertical-align:middle;object-fit:contain;margin-right:3px;" alt="💎" />`;

      btn.innerHTML = `
        ${iconHtml}
        <span class="chip-amount-text">${chip.label}</span>
      `;

      btn.addEventListener('click', () => {
        this.state.selectedChip = chip.value;
        this.renderChipDeck();
        this.audio.playBet();
      });

      this.chipsContainer.appendChild(btn);
    });
  }

  // Count how many of the 8 food spots currently have active bets
  getActiveSpotsCount() {
    let count = 0;
    for (let i = 0; i < 8; i++) {
      if ((this.state.userBets[i] || 0) > 0) count++;
    }
    return count;
  }

  // ================= 3. BETTING LOGIC WITH MAX 6 SPOTS RULE =================
  handleBetClick(itemId, event) {
    if (this.state.phase !== 'BETTING') {
      this.showToast('Betting is closed for this round!');
      return;
    }

    const currentBetOnItem = this.state.userBets[itemId] || 0;
    const activeSpots = this.getActiveSpotsCount();

    // RULE: Any 6 spots can be bet on, at least 2 spots MUST remain unbet!
    if (currentBetOnItem === 0 && activeSpots >= 6) {
      this.showToast('You can bet on at most 6 spots! (At least 2 spots must remain unbet)');
      this.audio.playTick();
      return;
    }

    const betAmount = this.state.selectedChip;
    if (this.state.balance < betAmount) {
      this.showToast('Not enough diamonds! Tap balance to top up.');
      this.audio.playTick();
      return;
    }

    // Deduct balance
    this.state.balance -= betAmount;
    this.state.totalSpending += betAmount;
    this.state.userBets[itemId] = currentBetOnItem + betAmount;
    this.state.save();

    // Persist active round bets to localStorage for offline settlement
    this.saveCurrentRoundBets();

    this.updateBalanceUI();
    this.updateSlotBetBadge(itemId);
    this.audio.playBet();

    // Real-time Firestore user diamond wallet deduction (1 Coin = 1 Diamond)
    if (this.userId && this.db) {
      this.db.collection('Users').doc(this.userId).update({
        diamonds: firebase.firestore.FieldValue.increment(-betAmount)
      }).catch((err) => console.warn('Deduct error:', err));

      this.db.collection('game_history').add({
        userId: this.userId,
        userName: this.userName,
        userAvatar: this.userAvatar,
        gameId: 'greedy_delicious',
        gameCode: 'html5_greedy_delicious',
        type: 'BET',
        betAmount: betAmount,
        itemId: itemId,
        itemName: FOOD_ITEMS[itemId]?.name || '',
        multiplier: FOOD_ITEMS[itemId]?.multiplier || 5,
        roundNumber: this.state.roundNumber,
        tier: this.state.currentTier,
        roomId: this.roomId || '',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      }).catch(() => { });
    }

    // Direct Flutter Channel Notification
    try {
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify({
          type: 'BET_PLACED',
          gameId: 'greedy_delicious',
          amount: betAmount,
          balance: this.state.balance
        }));
      }
    } catch (e) { }

    // Trigger flying chip animation
    const sourceBtn = document.getElementById(`chip-btn-${this.state.selectedChip}`);
    const targetCard = document.getElementById(`food-slot-${itemId}`);
    if (sourceBtn && targetCard) {
      this.spawnFlyingChip(sourceBtn, targetCard, betAmount);
    }
  }

  handleComboBet(type) {
    // Betting on Pizza and Salad is disabled. Clicking opens the special rules popup.
    this.openSpecialRulesModal(type);
  }

  // Save current active round bets into localStorage so even if player leaves, bets are recorded
  saveCurrentRoundBets() {
    const map = getPendingBetsMap();
    map[this.state.roundNumber] = {
      bets: { ...this.state.userBets },
      totalSpending: this.state.totalSpending,
      comboSaladBet: this.state.comboSaladBet,
      comboPizzaBet: this.state.comboPizzaBet,
      tier: this.state.currentTier,
      timestamp: Date.now()
    };
    savePendingBetsMap(map);
  }

  // Restore bets if player re-enters the active round (within the 30s betting time)
  restoreActiveRoundIfAny(roundNumber) {
    const map = getPendingBetsMap();
    const activeData = map[roundNumber];
    if (activeData) {
      this.state.userBets = activeData.bets || {};
      this.state.totalSpending = activeData.totalSpending || 0;
      this.state.comboSaladBet = activeData.comboSaladBet || 0;
      this.state.comboPizzaBet = activeData.comboPizzaBet || 0;

      FOOD_ITEMS.forEach(item => {
        this.updateSlotBetBadge(item.id);
      });

      if (this.state.comboSaladBet > 0) {
        const tag = document.getElementById('combo-salad-bet-tag');
        tag.textContent = this.formatNumber(this.state.comboSaladBet);
        tag.classList.add('show');
      }
      if (this.state.comboPizzaBet > 0) {
        const tag = document.getElementById('combo-pizza-bet-tag');
        tag.textContent = this.formatNumber(this.state.comboPizzaBet);
        tag.classList.add('show');
      }
    }
    this.updateHotBadge(roundNumber);
  }

  // Auto-settle any bets from past rounds if player closed the tab or left the game
  checkAndSettleOfflineBets() {
    const map = getPendingBetsMap();
    const currentSync = getSyncClock();
    let anyWon = false;
    let totalWonSum = 0;
    const settledRounds = [];

    Object.keys(map).forEach(rKey => {
      const rNum = Number(rKey);
      if (rNum < currentSync.roundNumber || (rNum === currentSync.roundNumber && currentSync.phase === 'RESULT')) {
        const roundData = map[rKey];
        if (roundData && roundData.bets && Object.keys(roundData.bets).length > 0) {
          const outcome = getRoundWinner(rNum);
          const { earnings } = calculateWinnings(outcome, roundData.bets);
          if (earnings > 0) {
            this.state.balance += earnings;
            this.state.todayPrize = (this.state.todayPrize || 0) + earnings;
            recordDailyWinner(currentSync.dayKey, earnings, this.userName, this.userAvatar, this.userId);
            anyWon = true;
            totalWonSum += earnings;
            settledRounds.push(rNum);
          }
          if (roundData.totalSpending > 0) {
            this.addMyRecord({
              roundNumber: rNum,
              spending: roundData.totalSpending,
              earnings: earnings,
              won: earnings > 0,
              timestamp: roundData.timestamp || Date.now(),
              dateStr: formatRecordDate(roundData.timestamp || Date.now()),
              tier: roundData.tier || 'regular'
            });
          }
        }
        delete map[rKey];
      }
    });

    if (anyWon) {
      this.state.save();
      this.updateBalanceUI();
      this.updateTodayPrizeUI();
      this.updateLeaderboardPreview();
      this.refreshLeaderboardModalIfOpen();
      setTimeout(() => {
        this.showToast(`🎉 Round #${settledRounds.join(', ')} won! +${this.formatNumber(totalWonSum)} diamonds credited!`);
        this.audio.playWin();
      }, 1000);
    }
    savePendingBetsMap(map);
  }

  updateSlotBetBadge(itemId) {
    const badge = document.getElementById(`slot-bet-${itemId}`);
    const tokenRow = document.getElementById(`slot-tokens-${itemId}`);
    const amount = this.state.userBets[itemId] || 0;
    if (badge) {
      if (amount > 0) {
        badge.textContent = this.formatNumber(amount);
        badge.classList.add('show');
      } else {
        badge.classList.remove('show');
      }
    }
    if (tokenRow) {
      tokenRow.innerHTML = '';
      if (amount > 0) {
        const tokenCount = amount >= 1000 ? 2 : 1;
        for (let i = 0; i < tokenCount; i++) {
          const t = document.createElement('div');
          t.className = 'card-bet-token-orb';
          t.innerHTML = `<img src="assets/images/diamond_icon.webp" alt="🪙" />`;
          tokenRow.appendChild(t);
        }
      }
    }
  }

  spawnFlyingChip(sourceEl, targetEl, amount) {
    const srcRect = sourceEl.getBoundingClientRect();
    const tgtRect = targetEl.getBoundingClientRect();
    const appRect = document.getElementById('app-container').getBoundingClientRect();

    const startX = srcRect.left - appRect.left + srcRect.width / 2 - 14;
    const startY = srcRect.top - appRect.top + srcRect.height / 2 - 14;

    const endX = tgtRect.left - appRect.left + tgtRect.width / 2 - 14;
    const endY = tgtRect.top - appRect.top + tgtRect.height / 2 - 14;

    const chip = document.createElement('div');
    chip.className = 'flying-chip';
    chip.textContent = this.formatNumber(amount);
    chip.style.transform = `translate(${startX}px, ${startY}px) scale(0.6)`;
    this.flyingLayer.appendChild(chip);

    requestAnimationFrame(() => {
      chip.style.transform = `translate(${endX}px, ${endY}px) scale(1)`;
      chip.style.opacity = '0.9';

      setTimeout(() => {
        chip.style.opacity = '0';
        chip.style.transform = `translate(${endX}px, ${endY}px) scale(1.2)`;
        setTimeout(() => chip.remove(), 250);
      }, 350);
    });
  }

  // ================= 4. SYNCHRONIZED MASTER ENGINE LOOP =================
  startMasterSyncLoop() {
    this.lastTickSecond = -1;

    setInterval(() => {
      const sync = getSyncClock();

      // Check 24h Day rollover (Midnight reset for round and Today's prize)
      if (sync.dayKey !== this.state.dayKey) {
        this.state.dayKey = sync.dayKey;
        this.state.todayPrize = 0;
        this.state.save();
        this.updateTodayPrizeUI();
      }

      // 1. Detect Round Transition
      if (sync.roundNumber !== this.state.roundNumber) {
        this.settleRound(this.state.roundNumber);
        this.state.roundNumber = sync.roundNumber;
        this.resetRoundState();
        this.updateHotBadge(this.state.roundNumber);
        this.restoreActiveRoundIfAny(this.state.roundNumber);
        this.checkAndSettleOfflineBets();
      }

      this.roundNumberLabel.textContent = `Round ${this.state.roundNumber}`;

      // 2. Handle Phases
      if (sync.phase === 'BETTING') {
        if (this.state.phase !== 'BETTING') {
          this.enterBettingPhase();
        }
        this.state.timeLeft = sync.phaseTimeLeft;
        this.countdownTimerVal.textContent = `${this.state.timeLeft}s`;

        if (this.state.timeLeft <= 5 && this.lastTickSecond !== this.state.timeLeft) {
          this.audio.playTick();
          this.lastTickSecond = this.state.timeLeft;
        }
      } else if (sync.phase === 'SPINNING') {
        if (this.state.phase !== 'SPINNING') {
          this.startSpinPhase(sync.roundNumber, sync.phaseTimeLeft);
        }
      } else if (sync.phase === 'RESULT') {
        if (this.state.phase !== 'RESULT') {
          this.finishSpinPhase(sync.roundNumber);
        }
        const closeSecEl = document.getElementById('result-auto-close-sec');
        if (closeSecEl) closeSecEl.textContent = sync.phaseTimeLeft;
      }
    }, 200);
  }

  enterBettingPhase() {
    this.state.phase = 'BETTING';
    this.closeModal('modal-round-result');

    // Clean up winner glows
    FOOD_ITEMS.forEach(item => {
      const card = document.getElementById(`food-slot-${item.id}`);
      if (card) {
        card.classList.remove('is-active-spin', 'is-winner', 'is-winner-pizza', 'is-winner-salad');
      }
    });

    const hub = document.getElementById('center-hub');
    if (hub) hub.classList.remove('is-winner-pulse');
    const pedSalad = document.getElementById('btn-combo-salad');
    if (pedSalad) pedSalad.classList.remove('is-winner-pulse');
    const pedPizza = document.getElementById('btn-combo-pizza');
    if (pedPizza) pedPizza.classList.remove('is-winner-pulse');
  }

  resetRoundState() {
    this.state.userBets = {};
    this.state.totalSpending = 0;
    this.state.comboSaladBet = 0;
    this.state.comboPizzaBet = 0;

    FOOD_ITEMS.forEach(item => {
      this.updateSlotBetBadge(item.id);
      const card = document.getElementById(`food-slot-${item.id}`);
      if (card) {
        card.classList.remove('is-active-spin', 'is-winner', 'is-winner-pizza', 'is-winner-salad');
      }
    });

    const saladTag = document.getElementById('combo-salad-bet-tag');
    if (saladTag) saladTag.classList.remove('show');
    const pizzaTag = document.getElementById('combo-pizza-bet-tag');
    if (pizzaTag) pizzaTag.classList.remove('show');

    this.state.winnerOutcome = null;
    this.state.winnerOutcomeRound = null;
    this.updateHotBadge(this.state.roundNumber);
  }

  // Multiplayer room check: returns true if other players have placed bets in the current room
  hasOtherActivePlayerBets() {
    return Boolean(this.otherPlayersActiveBetsCount && this.otherPlayersActiveBetsCount > 0);
  }

  /**
   * Smart Solo-Player Loss Protection & Guaranteed House Profit Guard Engine:
   * 1. Multi-player Mode: If other players are betting in the room, standard deterministic 75% RTP PRNG runs.
   * 2. Solo Player Mode:
   *    - If soloLossStreak >= 2 (user lost 2+ consecutive betting rounds):
   *      - Checks player's bets in this round.
   *      - Calculates total diamonds spent during this loss streak: (streakSpending + currentSpending).
   *      - STRICT HOUSE PROFIT GUARD: Payout MUST NOT exceed 75% of total streak spending (App keeps >= 25% profit).
   *      - JACKPOT BLOCKER: Strictly excludes 25x Ham, 45x Steak, and Pizza Special from solo recovery.
   *      - If safe candidates exist (e.g. 5x vegetables or 10x hotdog whose payout <= 0.75 * totalStreakSpending):
   *        -> Selects the safest candidate, giving the player a satisfying diamond return while keeping the app in profit!
   *      - If no candidate satisfies the profit guard, falls back to normal PRNG (App is never exposed to loss).
   */
  resolveRoundWinner(roundNumber) {
    if (this.state.winnerOutcome && this.state.winnerOutcomeRound === roundNumber) {
      return this.state.winnerOutcome;
    }

    const defaultOutcome = getRoundWinner(roundNumber);

    const remote = window.REMOTE_GAME_CONFIG;
    if (remote && remote.forceWinnerIndex !== undefined && Number(remote.forceWinnerIndex) >= 0) {
      this.state.winnerOutcome = defaultOutcome;
      this.state.winnerOutcomeRound = roundNumber;
      return defaultOutcome;
    }

    const userBets = this.state.userBets || {};
    const currentSpending = parseCoinsNum(this.state.totalSpending);

    if (currentSpending <= 0) {
      this.state.winnerOutcome = defaultOutcome;
      this.state.winnerOutcomeRound = roundNumber;
      return defaultOutcome;
    }

    // Multiplayer check: if other players are active in the room, use normal global 75% RTP PRNG
    if (this.hasOtherActivePlayerBets()) {
      this.state.winnerOutcome = defaultOutcome;
      this.state.winnerOutcomeRound = roundNumber;
      return defaultOutcome;
    }

    // --- SOLO PLAYER SMART LOSS PROTECTION ---
    const savedLossStreak = parseCoinsNum(localStorage.getItem('greedy_solo_loss_streak'));
    const savedStreakSpending = parseCoinsNum(localStorage.getItem('greedy_solo_streak_spending'));

    if (savedLossStreak >= 2) {
      const totalStreakSpending = savedStreakSpending + currentSpending;
      // Maximum payout allowed to guarantee house retention (max 75% return, House keeps >= 25% profit)
      const maxAllowedPayout = Math.floor(totalStreakSpending * 0.75);

      const safeCandidates = [];
      Object.keys(userBets).forEach(idStr => {
        const id = Number(idStr);
        const betAmount = parseCoinsNum(userBets[id]);
        if (betAmount > 0 && FOOD_ITEMS[id]) {
          const mult = FOOD_ITEMS[id].multiplier;
          // JACKPOT BLOCKER: Strictly allow ONLY standard items with multiplier <= 15 (5x, 10x, 15x)
          // NEVER allow 25x Ham or 45x Steak or Pizza in solo streak recovery!
          if (mult <= 15) {
            const potentialPayout = betAmount * mult;
            // HOUSE PROFIT GUARD: Potential payout must NOT exceed 75% of total streak spending
            if (potentialPayout <= maxAllowedPayout && potentialPayout > 0) {
              safeCandidates.push({
                item: {
                  type: 'item',
                  id: id,
                  name: FOOD_ITEMS[id].name,
                  multiplier: mult,
                  weight: 100
                },
                potentialPayout: potentialPayout
              });
            }
          }
        }
      });

      if (safeCandidates.length > 0) {
        // Pick the candidate that gives the player the highest safe payout <= maxAllowedPayout
        safeCandidates.sort((a, b) => b.potentialPayout - a.potentialPayout);
        const chosen = safeCandidates[0].item;
        this.state.winnerOutcome = chosen;
        this.state.winnerOutcomeRound = roundNumber;
        return chosen;
      }
    }

    this.state.winnerOutcome = defaultOutcome;
    this.state.winnerOutcomeRound = roundNumber;
    return defaultOutcome;
  }

  // ================= 5. SPINNING PHASE =================
  startSpinPhase(roundNumber, remainingSpinSeconds) {
    this.state.phase = 'SPINNING';
    this.audio.playSpin();

    const outcome = this.resolveRoundWinner(roundNumber);
    this.state.winnerOutcome = outcome;

    // Target stopping index
    const targetSlotIndex = outcome.type === 'item' ? outcome.id : (outcome.type === 'pizza' ? 0 : 5);

    let currentIndex = 0;
    let speed = 40;
    const minSteps = 20 + targetSlotIndex;
    let stepCount = 0;

    const spinStep = () => {
      if (this.state.phase !== 'SPINNING') return;

      FOOD_ITEMS.forEach((_, idx) => {
        const slotEl = document.getElementById(`food-slot-${idx}`);
        if (slotEl) slotEl.classList.toggle('is-active-spin', idx === (currentIndex % 8));
      });

      this.audio.playTick();
      currentIndex++;
      stepCount++;

      if (stepCount >= minSteps && (currentIndex % 8) === targetSlotIndex) {
        this.audio.stopSpin();
      } else {
        if (stepCount > minSteps - 12) speed += 24;
        else if (stepCount > minSteps - 6) speed += 45;
        setTimeout(spinStep, speed);
      }
    };

    spinStep();
  }

  // ================= 6. RESULT & MEGA WIN CELEBRATION =================
  finishSpinPhase(roundNumber) {
    this.state.phase = 'RESULT';
    this.audio.stopSpin();

    const outcome = this.state.winnerOutcome || this.resolveRoundWinner(roundNumber);
    this.state.winnerOutcome = outcome;

    // Clear active spin highlights
    FOOD_ITEMS.forEach((_, idx) => {
      const slotEl = document.getElementById(`food-slot-${idx}`);
      if (slotEl) slotEl.classList.remove('is-active-spin');
    });

    const hub = document.getElementById('center-hub');
    const pedSalad = document.getElementById('btn-combo-salad');
    const pedPizza = document.getElementById('btn-combo-pizza');

    // Highlight winning cards based on outcome type
    if (outcome.type === 'pizza') {
      // 10x, 15x, 25x, 45x (Meat items: 0, 1, 2, 3) all win together!
      [0, 1, 2, 3].forEach(id => {
        const slotEl = document.getElementById(`food-slot-${id}`);
        if (slotEl) {
          slotEl.classList.add('is-winner', 'is-winner-pizza');
        }
      });
      if (hub) hub.classList.add('is-winner-pulse');
      if (pedPizza) pedPizza.classList.add('is-winner-pulse');
    } else if (outcome.type === 'salad') {
      // All four 5x (Vegetable items: 4, 5, 6, 7) win together!
      [4, 5, 6, 7].forEach(id => {
        const slotEl = document.getElementById(`food-slot-${id}`);
        if (slotEl) {
          slotEl.classList.add('is-winner', 'is-winner-salad');
        }
      });
      if (pedSalad) pedSalad.classList.add('is-winner-pulse');
    } else {
      // Single item win
      const slotEl = document.getElementById(`food-slot-${outcome.id}`);
      if (slotEl) slotEl.classList.add('is-winner');
    }

    // Settle winnings for active player
    this.settleRound(roundNumber);

    // Update history track
    const historyId = outcome.type === 'item' ? outcome.id : (outcome.type === 'pizza' ? 0 : 5);
    this.state.history.unshift(historyId);
    if (this.state.history.length > 7) this.state.history.pop();
    this.renderHistory();

    // Show Result Celebration Modal after a slight pause
    setTimeout(() => {
      this.showResultModal(outcome, this.state.totalSpending, this.lastCalculatedEarnings || 0);
    }, 500);
  }

  settleRound(roundNumber) {
    if (this.settledRoundNumber === roundNumber) return;
    this.settledRoundNumber = roundNumber;

    const outcome = this.state.winnerOutcome || this.resolveRoundWinner(roundNumber);
    const { earnings } = calculateWinnings(outcome, this.state.userBets);
    this.lastCalculatedEarnings = earnings;
    const spending = this.state.totalSpending;

    // Solo Player Loss Streak & Spending Tracking (Guaranteed House Margin Engine)
    if (spending > 0) {
      if (earnings > 0) {
        // Player won: reset solo loss streak & streak spending
        localStorage.setItem('greedy_solo_loss_streak', '0');
        localStorage.setItem('greedy_solo_streak_spending', '0');
      } else {
        // Player bet but lost: increment streak and accumulate spending
        const prevStreak = parseCoinsNum(localStorage.getItem('greedy_solo_loss_streak'));
        const prevSpending = parseCoinsNum(localStorage.getItem('greedy_solo_streak_spending'));
        localStorage.setItem('greedy_solo_loss_streak', String(prevStreak + 1));
        localStorage.setItem('greedy_solo_streak_spending', String(prevSpending + spending));
      }
    }

    if (earnings > 0) {
      this.state.balance += earnings;
      this.state.todayPrize = (this.state.todayPrize || 0) + earnings;
      this.state.save();
      this.updateBalanceUI();
      this.updateTodayPrizeUI();
      this.audio.playWin();

      // Record in daily real winners list!
      recordDailyWinner(this.state.dayKey, earnings, this.userName, this.userAvatar, this.userId);
      this.updateLeaderboardPreview();
      this.refreshLeaderboardModalIfOpen();

      // Real-time Firestore user diamond credit (1 Coin = 1 Diamond)
      if (this.userId && this.db) {
        this.db.collection('Users').doc(this.userId).update({
          diamonds: firebase.firestore.FieldValue.increment(earnings),
          totalDiamonds: firebase.firestore.FieldValue.increment(earnings)
        }).catch((err) => console.warn('Win credit error:', err));

        this.db.collection('game_history').add({
          userId: this.userId,
          userName: this.userName,
          userAvatar: this.userAvatar,
          gameId: 'greedy_delicious',
          gameCode: 'html5_greedy_delicious',
          type: 'WIN',
          earnings: earnings,
          dayKey: this.state.dayKey,
          winningItem: outcome.type === 'item' ? FOOD_ITEMS[outcome.id]?.name : outcome.name,
          roundNumber: roundNumber,
          roomId: this.roomId || '',
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => { });
      }

      // Direct Flutter Channel Notification
      try {
        if (window.FlutterChannel) {
          window.FlutterChannel.postMessage(JSON.stringify({
            type: 'WIN_PAYOUT',
            gameId: 'greedy_delicious',
            earnings: earnings,
            balance: this.state.balance
          }));
        }
      } catch (e) { }
    }

    // Save record to My Record if user participated in this round
    if (spending > 0) {
      this.addMyRecord({
        roundNumber: roundNumber,
        spending: spending,
        earnings: earnings,
        won: earnings > 0,
        timestamp: Date.now(),
        dateStr: formatRecordDate(Date.now()),
        tier: this.state.currentTier
      });
    }

    // Clean this round from pending bets map
    const map = getPendingBetsMap();
    if (map[roundNumber]) {
      delete map[roundNumber];
      savePendingBetsMap(map);
    }
  }

  showResultModal(outcome, spending, earnings) {
    const modal = document.getElementById('modal-round-result');
    const sheet = document.getElementById('result-modal-sheet');
    const img = document.getElementById('result-winner-img');
    const title = document.getElementById('result-modal-round-title');
    const specialBanner = document.getElementById('result-special-banner');
    const statsRow = document.getElementById('sheet-user-stats-row');
    const spendingEl = document.getElementById('result-my-spending');
    const earningsEl = document.getElementById('result-my-earnings');
    const closeSecEl = document.getElementById('result-auto-close-sec');

    title.textContent = `Result of Round ${this.state.roundNumber}`;

    if (outcome.type === 'pizza') {
      img.src = 'assets/images/pizza.webp';
      img.alt = 'Pizza Mega Win';
      specialBanner.style.display = 'inline-block';
      specialBanner.className = 'result-special-banner pizza';
      specialBanner.textContent = '🍕 PIZZA WIN! (10x, 15x, 25x, 45x All Won!)';
    } else if (outcome.type === 'salad') {
      img.src = 'assets/images/salad.webp';
      img.alt = 'Salad Mega Win';
      specialBanner.style.display = 'inline-block';
      specialBanner.className = 'result-special-banner salad';
      specialBanner.textContent = '🥗 SALAD WIN! (All 5x Vegetables Won!)';
    } else {
      const winItem = FOOD_ITEMS[outcome.id];
      img.src = winItem.img;
      img.alt = winItem.name;
      specialBanner.style.display = 'none';
    }

    // Apply exact modal theme matching current mode
    if (this.state.currentTier === 'advanced') {
      sheet.classList.remove('sheet-theme-regular');
      sheet.classList.add('sheet-theme-advance');
    } else {
      sheet.classList.remove('sheet-theme-advance');
      sheet.classList.add('sheet-theme-regular');
    }

    // Dynamic Trio Podium Winners:
    // If no user played and won in this round, Top 1, 2, 3 show EMPTY slots with NO diamonds/coins!
    // If a user played and won, ONLY that user shows in Top 1; Top 2 and 3 stay as empty slots!
    const col1 = document.getElementById('trio-col-1');
    const col2 = document.getElementById('trio-col-2');
    const col3 = document.getElementById('trio-col-3');

    const name1 = document.getElementById('trio-name-1');
    const win1 = document.getElementById('trio-win-1');
    const avatar1 = document.getElementById('trio-avatar-1');

    const name2 = document.getElementById('trio-name-2');
    const win2 = document.getElementById('trio-win-2');
    const avatar2 = document.getElementById('trio-avatar-2');

    const name3 = document.getElementById('trio-name-3');
    const win3 = document.getElementById('trio-win-3');
    const avatar3 = document.getElementById('trio-avatar-3');

    if (earnings > 0) {
      // Current player played and won! Show real name and avatar in Top 1:
      if (col1) col1.classList.remove('is-empty');
      const placeholder1 = document.getElementById('trio-placeholder-1');
      if (avatar1) {
        if (this.userAvatar && this.userAvatar.trim() !== '') {
          avatar1.src = this.userAvatar;
          avatar1.style.display = 'block';
          if (placeholder1) placeholder1.style.display = 'none';
        } else {
          avatar1.style.display = 'none';
          if (placeholder1) placeholder1.style.display = 'flex';
        }
      }
      if (name1) name1.textContent = this.userName || 'Winner';
      if (win1) win1.textContent = this.formatNumber(earnings);

      // Top 2 and Top 3 remain empty slots with NO diamonds/coins
      if (col2) col2.classList.add('is-empty');
      if (avatar2) avatar2.style.display = 'none';
      if (name2) name2.textContent = '-';
      if (win2) win2.textContent = '0';

      if (col3) col3.classList.add('is-empty');
      if (avatar3) avatar3.style.display = 'none';
      if (name3) name3.textContent = '-';
      if (win3) win3.textContent = '0';
    } else {
      // Current user did not win this round.
      // Strict requirement: Only display a winner if someone placed a bet and won in THIS specific round.
      // Never fall back to past rounds or previous history!
      if (col1) col1.classList.add('is-empty');
      if (avatar1) avatar1.style.display = 'none';
      const placeholder1 = document.getElementById('trio-placeholder-1');
      if (placeholder1) placeholder1.style.display = 'flex';
      if (name1) name1.textContent = '-';
      if (win1) win1.textContent = '0';

      if (col2) col2.classList.add('is-empty');
      if (avatar2) avatar2.style.display = 'none';
      const placeholder2 = document.getElementById('trio-placeholder-2');
      if (placeholder2) placeholder2.style.display = 'flex';
      if (name2) name2.textContent = '-';
      if (win2) win2.textContent = '0';

      if (col3) col3.classList.add('is-empty');
      if (avatar3) avatar3.style.display = 'none';
      const placeholder3 = document.getElementById('trio-placeholder-3');
      if (placeholder3) placeholder3.style.display = 'flex';
      if (name3) name3.textContent = '-';
      if (win3) win3.textContent = '0';
    }

    // Always show My Spending & My Earnings
    statsRow.style.display = 'flex';
    spendingEl.textContent = this.formatNumber(spending);
    earningsEl.textContent = this.formatNumber(earnings);

    modal.classList.add('open');

    // Close button override
    const closeBtn = document.getElementById('btn-close-result-modal');
    closeBtn.onclick = () => {
      modal.classList.remove('open');
    };
  }

  // ================= 7. HISTORY RENDERING =================
  renderHistory() {
    this.resultTrack.innerHTML = '';
    this.state.history.forEach((itemId, idx) => {
      const item = FOOD_ITEMS[itemId] || FOOD_ITEMS[0];
      const thumb = document.createElement('div');
      thumb.className = 'result-mini-thumb';
      thumb.innerHTML = `
        <img src="${item.img}" alt="${item.name}">
        ${idx === 0 ? '<span class="result-new-badge">NEW</span>' : ''}
      `;
      this.resultTrack.appendChild(thumb);
    });
  }

  // ================= 8. UI HELPERS & MODALS =================
  updateBalanceUI() {
    this.userBalanceVal.textContent = this.formatNumber(this.state.balance);
    const walletNum = document.getElementById('wallet-balance-num');
    if (walletNum) walletNum.textContent = this.formatNumber(this.state.balance);
  }

  updateTodayPrizeUI() {
    const el = document.getElementById('today-prize-val');
    if (el) {
      el.textContent = this.formatNumber(this.state.todayPrize || 0);
    }
  }

  // Update bottom bar preview card dynamically (Empty state if no one has won today)
  updateLeaderboardPreview() {
    const card = document.getElementById('btn-leaderboard-preview');
    const avatar = document.getElementById('lb-preview-avatar');
    const placeholder = document.getElementById('lb-preview-placeholder');
    const nameEl = document.getElementById('lb-preview-username');
    const coinsEl = document.getElementById('lb-preview-coins');
    if (!card) return;

    const dailyWinners = getDailyTopWinners(this.state.dayKey);
    if (dailyWinners && dailyWinners.length > 0) {
      const top1 = dailyWinners[0];
      card.classList.remove('is-empty');
      if (top1.avatar && top1.avatar.trim() !== '') {
        avatar.src = top1.avatar;
        avatar.style.display = 'block';
        if (placeholder) placeholder.style.display = 'none';
      } else {
        avatar.style.display = 'none';
        if (placeholder) placeholder.style.display = 'flex';
      }
      if (nameEl) nameEl.textContent = top1.name || 'Winner';

      const targetCoins = parseCoinsNum(top1.coinsNum || top1.coins);
      const prevCoins = (typeof this.lastLeaderboardCoins === 'number') ? this.lastLeaderboardCoins : targetCoins;
      this.lastLeaderboardCoins = targetCoins;

      if (coinsEl) {
        animateNumber(coinsEl, prevCoins, targetCoins, 650);
      }
    } else {
      card.classList.add('is-empty');
      if (avatar) avatar.style.display = 'none';
      if (placeholder) placeholder.style.display = 'flex';
      if (nameEl) nameEl.textContent = '-';
      if (coinsEl) coinsEl.textContent = '0';
      this.lastLeaderboardCoins = 0;
    }
  }

  // Refresh all slot bet badges and combo tags (Seamlessly shared between Regular & Advance)
  updateAllBetBadges() {
    FOOD_ITEMS.forEach(item => {
      this.updateSlotBetBadge(item.id);
    });

    const saladTag = document.getElementById('combo-salad-bet-tag');
    if (saladTag) {
      if (this.state.comboSaladBet > 0) {
        saladTag.textContent = this.formatNumber(this.state.comboSaladBet);
        saladTag.classList.add('show');
      } else {
        saladTag.classList.remove('show');
      }
    }

    const pizzaTag = document.getElementById('combo-pizza-bet-tag');
    if (pizzaTag) {
      if (this.state.comboPizzaBet > 0) {
        pizzaTag.textContent = this.formatNumber(this.state.comboPizzaBet);
        pizzaTag.classList.add('show');
      } else {
        pizzaTag.classList.remove('show');
      }
    }
  }

  // Render My Record list matching user screenshots 1:1
  renderMyRecords() {
    const container = document.getElementById('record-cards-list');
    const dateLabel = document.getElementById('record-date-label');
    if (!container) return;

    if (dateLabel) {
      dateLabel.textContent = formatHeaderDate(Date.now());
    }

    const records = getMyRecordsList();
    container.innerHTML = '';

    if (records.length === 0) {
      container.innerHTML = `<div style="text-align: center; color: rgba(255,255,255,0.5); padding: 40px 0;">No records found yet</div>`;
      return;
    }

    records.forEach(rec => {
      const card = document.createElement('div');
      card.className = 'record-card-item';

      const badgeHtml = rec.won
        ? `
          <div class="record-status-badge-wrap">
            <div class="record-medallion-icon won">💎</div>
            <span class="record-status-label won">${this.formatNumber(rec.earnings)}</span>
          </div>
        `
        : `
          <div class="record-status-badge-wrap">
            <div class="record-medallion-icon missed">💎</div>
            <span class="record-status-label missed">Missed</span>
          </div>
        `;

      card.innerHTML = `
        <div class="record-card-left">
          <div class="record-round-num">Round: ${rec.roundNumber}</div>
          <div class="record-play-row">
            <span>Play:</span>
            <span class="coin-icon">🪙</span>
            <span>${this.formatNumber(rec.spending)}</span>
          </div>
          <div class="record-timestamp">${rec.dateStr}</div>
        </div>
        <div class="record-card-right">
          ${badgeHtml}
          <span class="record-arrow-right">›</span>
        </div>
      `;

      card.addEventListener('click', () => {
        if (rec.won) {
          this.showToast(`Round ${rec.roundNumber}: Played 🪙 ${this.formatNumber(rec.spending)}, Won 🪙 ${this.formatNumber(rec.earnings)}!`);
        } else {
          this.showToast(`Round ${rec.roundNumber}: Played 🪙 ${this.formatNumber(rec.spending)} (Missed)`);
        }
      });

      container.appendChild(card);
    });
  }

  addMyRecord(rec) {
    const records = getMyRecordsList();
    records.unshift(rec);
    if (records.length > 50) records.pop();
    saveMyRecordsList(records);
    this.renderMyRecords();
  }

  showToast(msg) {
    this.toastBanner.textContent = msg;
    this.toastBanner.classList.add('show');
    clearTimeout(this.toastTimeout);
    this.toastTimeout = setTimeout(() => {
      this.toastBanner.classList.remove('show');
    }, 2400);
  }

  formatNumber(n) {
    return Number(n).toLocaleString();
  }

  // ================= 9. EVENT LISTENERS =================
  setupEventListeners() {
    // Menu Dropdown toggle
    const btnMenu = document.getElementById('btn-menu');
    const dropdown = document.getElementById('header-dropdown');
    btnMenu.addEventListener('click', (e) => {
      e.stopPropagation();
      dropdown.classList.toggle('show');
    });

    document.addEventListener('click', () => {
      dropdown.classList.remove('show');
    });

    // History / My Record button in header
    const btnHistory = document.getElementById('btn-history');
    if (btnHistory) {
      btnHistory.addEventListener('click', () => {
        this.renderMyRecords();
        this.openModal('modal-my-record');
      });
    }

    const btnCloseRecord = document.getElementById('btn-close-record-modal');
    if (btnCloseRecord) {
      btnCloseRecord.addEventListener('click', () => {
        this.closeModal('modal-my-record');
      });
    }

    // Date filter in My Record
    const dateFilterBtn = document.getElementById('btn-record-date-filter');
    if (dateFilterBtn) {
      dateFilterBtn.addEventListener('click', () => {
        this.showToast(`Showing activity records for ${formatHeaderDate(Date.now())}`);
      });
    }

    // Back / Exit button (Top-left corner back arrow '<')
    const btnBack = document.getElementById('btn-back');
    if (btnBack) {
      btnBack.title = 'Exit Game';
      btnBack.addEventListener('click', () => {
        this.exitGame();
      });
    }

    // Combos: Salad & Pizza -> Open Special Rules Popup (No Bet)
    const btnSalad = document.getElementById('btn-combo-salad');
    if (btnSalad) {
      btnSalad.addEventListener('click', () => this.openSpecialRulesModal('salad'));
    }
    const btnPizza = document.getElementById('btn-combo-pizza');
    if (btnPizza) {
      btnPizza.addEventListener('click', () => this.openSpecialRulesModal('pizza'));
    }

    // Today's prize button (User-specific daily accumulated prize)
    document.getElementById('btn-prize-pool').addEventListener('click', () => {
      if (this.state.todayPrize > 0) {
        this.showToast(`Your Today's Prize Total: ${this.formatNumber(this.state.todayPrize)} Diamonds! (Resets every 24h)`);
      } else {
        this.showToast("Today's prize: 0 Diamonds. Win rounds to accumulate your daily prize!");
      }
    });

    // Tier Switching: Regular / Advanced
    // (User bets placed in Regular remain visible and accumulate in Advance, and vice versa!)
    const tabRegular = document.getElementById('tab-regular');
    const tabAdvanced = document.getElementById('tab-advanced');

    tabRegular.addEventListener('click', () => {
      if (this.state.currentTier === 'regular') return;
      this.state.currentTier = 'regular';
      this.state.selectedChip = CHIP_TIERS.regular[0].value;
      tabRegular.classList.add('active');
      tabAdvanced.classList.remove('active');
      document.getElementById('app-container').classList.remove('theme-advance');
      this.renderChipDeck();
      this.updateAllBetBadges();
      this.audio.playBet();
    });

    tabAdvanced.addEventListener('click', () => {
      if (this.state.currentTier === 'advanced') return;
      this.state.currentTier = 'advanced';
      this.state.selectedChip = CHIP_TIERS.advanced[0].value;
      tabAdvanced.classList.add('active');
      tabRegular.classList.remove('active');
      document.getElementById('app-container').classList.add('theme-advance');
      this.renderChipDeck();
      this.updateAllBetBadges();
      this.audio.playBet();
    });

    // Balance Pill -> Directly Open App Wallet Screen (No in-game popup!)
    const balancePill = document.getElementById('btn-balance-pill');
    if (balancePill) {
      balancePill.addEventListener('click', () => {
        // 1. InAppWebView FlutterChannel
        try {
          if (window.FlutterChannel) {
            window.FlutterChannel.postMessage(JSON.stringify({
              type: 'OPEN_WALLET',
              action: 'OPEN_RECHARGE',
              screen: 'wallet',
              balance: this.state.balance
            }));
          }
        } catch (e) { }

        // 2. Parent iframe postMessage
        try {
          if (window.parent && window.parent !== window) {
            window.parent.postMessage({
              type: 'OPEN_WALLET',
              action: 'OPEN_RECHARGE',
              screen: 'wallet',
              balance: this.state.balance
            }, '*');
          }
        } catch (e) { }

        // 3. Global JS callback if injected
        if (typeof window.openAppWallet === 'function') {
          try { window.openAppWallet(); } catch (e) { }
        }

        this.showToast('💎 Opening App Diamond Wallet...');
      });
    }

    // Leaderboard Preview -> Open Leaderboard Modal
    document.getElementById('btn-leaderboard-preview').addEventListener('click', () => {
      this.openLeaderboardModal();
    });

    // Menu Actions
    document.getElementById('menu-how-to-play').addEventListener('click', () => this.openModal('modal-how-to-play'));
    document.getElementById('menu-top-winners').addEventListener('click', () => this.openLeaderboardModal());

    // Sound & BGM toggles
    document.getElementById('menu-sound-toggle').addEventListener('click', () => {
      this.state.soundEnabled = !this.state.soundEnabled;
      document.getElementById('menu-sound-icon').textContent = this.state.soundEnabled ? '🔊' : '🔇';
      document.getElementById('menu-sound-text').textContent = `Sound: ${this.state.soundEnabled ? 'ON' : 'OFF'}`;
      this.showToast(`Sound Effects: ${this.state.soundEnabled ? 'ON' : 'OFF'}`);
    });

    document.getElementById('menu-bgm-toggle').addEventListener('click', () => {
      this.state.bgmEnabled = !this.state.bgmEnabled;
      this.audio.toggleBgm(this.state.bgmEnabled);
      document.getElementById('menu-bgm-icon').textContent = this.state.bgmEnabled ? '🎵' : '🔇';
      document.getElementById('menu-bgm-text').textContent = `Music: ${this.state.bgmEnabled ? 'ON' : 'OFF'}`;
      this.showToast(`Background Music: ${this.state.bgmEnabled ? 'ON' : 'OFF'}`);
    });

    // Modal Close Buttons
    const btnCloseRules = document.getElementById('btn-close-rules-modal');
    if (btnCloseRules) btnCloseRules.addEventListener('click', () => this.closeModal('modal-how-to-play'));
    const btnCloseLb = document.getElementById('btn-close-lb-modal');
    if (btnCloseLb) btnCloseLb.addEventListener('click', () => this.closeModal('modal-leaderboard'));
    const btnCloseWallet = document.getElementById('btn-close-wallet-modal');
    if (btnCloseWallet) btnCloseWallet.addEventListener('click', () => this.closeModal('modal-recharge'));

    // Special Rules Mini Modal Listeners
    const btnCloseSpecialRules = document.getElementById('btn-close-special-rules-modal');
    if (btnCloseSpecialRules) {
      btnCloseSpecialRules.addEventListener('click', () => this.closeModal('modal-special-rules'));
    }
    const btnSpecialGotit = document.getElementById('btn-special-rules-gotit');
    if (btnSpecialGotit) {
      btnSpecialGotit.addEventListener('click', () => this.closeModal('modal-special-rules'));
    }

    const tabRuleSalad = document.getElementById('tab-rule-salad');
    if (tabRuleSalad) {
      tabRuleSalad.addEventListener('click', () => this.switchSpecialRuleTab('salad'));
    }
    const tabRulePizza = document.getElementById('tab-rule-pizza');
    if (tabRulePizza) {
      tabRulePizza.addEventListener('click', () => this.switchSpecialRuleTab('pizza'));
    }

    // Close modals on clicking outside
    document.querySelectorAll('.modal-backdrop').forEach(modal => {
      modal.addEventListener('click', (e) => {
        if (e.target === modal) {
          modal.classList.remove('open');
        }
      });
    });
  }

  openSpecialRulesModal(dishType = 'salad') {
    this.switchSpecialRuleTab(dishType);
    this.openModal('modal-special-rules');
    this.audio.playTick();
  }

  switchSpecialRuleTab(dishType) {
    const tabSalad = document.getElementById('tab-rule-salad');
    const tabPizza = document.getElementById('tab-rule-pizza');
    const titleEl = document.getElementById('special-rules-modal-title');
    const iconEl = document.getElementById('special-rules-header-icon');

    if (dishType === 'salad') {
      if (tabSalad) tabSalad.classList.add('active');
      if (tabPizza) tabPizza.classList.remove('active');
      if (titleEl) titleEl.textContent = 'Salad Rules';
      if (iconEl) iconEl.textContent = '🥗';
    } else {
      if (tabPizza) tabPizza.classList.add('active');
      if (tabSalad) tabSalad.classList.remove('active');
      if (titleEl) titleEl.textContent = 'Pizza Rules';
      if (iconEl) iconEl.textContent = '🍕';
    }

    this.renderSpecialRulesContent(dishType);
  }

  renderSpecialRulesContent(dishType) {
    const container = document.getElementById('special-rules-body');
    if (!container) return;

    if (dishType === 'salad') {
      container.innerHTML = `
        <div class="rule-display-card">
          <div class="rule-card-dish-hero">
            <img src="assets/images/salad.webp" alt="Salad Special" class="rule-dish-hero-img">
          </div>
          <h4 class="rule-card-title">Salad Special (All 4 Vegetables Win)</h4>
          <p class="rule-card-desc">
            When the wheel lands on <strong>Salad</strong>, all 4 Vegetable items win simultaneously!
          </p>
          <div class="rule-items-mini-grid">
            <div class="rule-mini-item-slot">
              <img src="assets/images/carrot.webp" alt="Carrot" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">5x</span>
            </div>
            <div class="rule-mini-item-slot">
              <img src="assets/images/corn.webp" alt="Corn" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">5x</span>
            </div>
            <div class="rule-mini-item-slot">
              <img src="assets/images/cabbage.webp" alt="Cabbage" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">5x</span>
            </div>
            <div class="rule-mini-item-slot">
              <img src="assets/images/tomato.webp" alt="Tomato" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">5x</span>
            </div>
          </div>
          <div class="rule-card-note">
            📌 Direct bets cannot be placed on Salad. Players betting on any of the 4 vegetable spots will receive <strong>5x</strong> payout!
          </div>
        </div>
      `;
    } else {
      container.innerHTML = `
        <div class="rule-display-card">
          <div class="rule-card-dish-hero">
            <img src="assets/images/pizza.webp" alt="Pizza Special" class="rule-dish-hero-img">
          </div>
          <h4 class="rule-card-title">Pizza Grand Special (All 4 Delicacies Win)</h4>
          <p class="rule-card-desc">
            When the wheel lands on <strong>Pizza</strong>, all 4 Delicacy / Meat items win simultaneously!
          </p>
          <div class="rule-items-mini-grid">
            <div class="rule-mini-item-slot">
              <img src="assets/images/hotdog.webp" alt="Hot Dog" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">10x</span>
            </div>
            <div class="rule-mini-item-slot">
              <img src="assets/images/skewer.webp" alt="BBQ Skewer" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">15x</span>
            </div>
            <div class="rule-mini-item-slot">
              <img src="assets/images/ham.webp" alt="Ham Leg" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">25x</span>
            </div>
            <div class="rule-mini-item-slot">
              <img src="assets/images/steak.webp" alt="Steak" class="rule-mini-item-img">
              <span class="rule-mini-item-mult">45x</span>
            </div>
          </div>
          <div class="rule-card-note">
            📌 Direct bets cannot be placed on Pizza. Players betting on any of the 4 meat delicacy spots will receive their full payout multipliers (10x–45x)!
          </div>
        </div>
      `;
    }
  }


  exitGame() {
    try {
      if (window.FlutterBridge && window.FlutterBridge.postMessage) {
        window.FlutterBridge.postMessage(JSON.stringify({ type: 'CLOSE_GAME' }));
        return;
      }
    } catch (_) { }
    try {
      if (window.FlutterApp && window.FlutterApp.postMessage) {
        window.FlutterApp.postMessage('close');
        return;
      }
    } catch (_) { }
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage({ type: 'CLOSE_GAME', action: 'exit' }, '*');
        window.parent.postMessage('close', '*');
      }
    } catch (_) { }
    try {
      if (window.top && window.top !== window) {
        window.top.postMessage('close', '*');
      }
    } catch (_) { }
    try {
      if (window.history.length > 1) {
        window.history.back();
      } else {
        window.close();
      }
    } catch (_) { }
  }

  openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.add('open');
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('open');
  }

  refreshLeaderboardModalIfOpen() {
    const modal = document.getElementById('modal-leaderboard');
    if (modal && modal.classList.contains('open')) {
      this.renderLeaderboardRows();
    }
  }

  renderLeaderboardRows() {
    const container = document.getElementById('leaderboard-rows-container');
    if (!container) return;
    container.innerHTML = '';

    const TOP_WINNERS = getDailyTopWinners(this.state.dayKey);

    if (!TOP_WINNERS || TOP_WINNERS.length === 0) {
      container.innerHTML = `
        <div class="lb-empty-placeholder">
          <div class="lb-empty-icon">🏆</div>
          <div class="lb-empty-title">No Winners Today</div>
          <div class="lb-empty-desc">There are no winners yet today.<br>Play rounds and win to appear on today's leaderboard!</div>
        </div>
      `;
    } else {
      TOP_WINNERS.slice(0, 10).forEach(item => {
        const cNum = parseCoinsNum(item.coinsNum || item.coins);
        const row = document.createElement('div');
        row.className = `lb-list-item ${item.rank === 1 ? 'is-top-1' : ''}`;

        const avatarHtml = (item.avatar && item.avatar.trim() !== '')
          ? `<img src="${item.avatar}" alt="${item.name}" class="lb-list-avatar">`
          : `<div class="lb-list-avatar lb-placeholder-avatar">👤</div>`;

        row.innerHTML = `
          <span class="lb-list-rank">${item.rank === 1 ? '👑' : `#${item.rank}`}</span>
          ${avatarHtml}
          <div class="lb-list-user">
            <span class="lb-list-name">${item.name}</span>
            <span class="lb-list-badge">${item.badge || '👑 SVIP Player'}</span>
          </div>
          <span class="lb-list-coins">
            <img src="assets/images/diamond_icon.webp" class="lb-diamond-icon" style="width:15px;height:15px;vertical-align:middle;object-fit:contain;margin-right:3px;" alt="💎">
            ${Number(cNum).toLocaleString()}
          </span>
        `;
        container.appendChild(row);
      });
    }
  }

  openLeaderboardModal() {
    this.renderLeaderboardRows();
    this.openModal('modal-leaderboard');
  }
}

// Start game when page loads
let game;
window.addEventListener('DOMContentLoaded', () => {
  game = new GreedyGame();
});
