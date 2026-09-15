/**
 * King of the Castle - Slot Machine Game Engine
 * 5 Reels x 3 Rows - 20 Paylines - HTML5 Canvas & Web Audio
 */

// 20 Standard Casino Paylines (row indices 0 = top, 1 = mid, 2 = bottom)
const PAYLINES = [
  [1, 1, 1, 1, 1], // Line 1: Mid horizontal
  [0, 0, 0, 0, 0], // Line 2: Top horizontal
  [2, 2, 2, 2, 2], // Line 3: Bottom horizontal
  [0, 1, 2, 1, 0], // Line 4: V shape
  [2, 1, 0, 1, 2], // Line 5: Inverted V
  [0, 0, 1, 2, 2], // Line 6: Step down
  [2, 2, 1, 0, 0], // Line 7: Step up
  [1, 2, 2, 2, 1], // Line 8
  [1, 0, 0, 0, 1], // Line 9
  [1, 0, 1, 2, 1], // Line 10
  [1, 2, 1, 0, 1], // Line 11
  [0, 1, 1, 1, 0], // Line 12
  [2, 1, 1, 1, 2], // Line 13
  [0, 1, 0, 1, 0], // Line 14
  [2, 1, 2, 1, 2], // Line 15
  [1, 1, 0, 1, 1], // Line 16
  [1, 1, 2, 1, 1], // Line 17
  [0, 0, 2, 0, 0], // Line 18
  [2, 2, 0, 2, 2], // Line 19
  [0, 2, 0, 2, 0]  // Line 20
];

const PAYLINE_COLORS = [
  '#ff3b30', '#ff9500', '#ffcc00', '#34c759', '#00c7be',
  '#30b0c7', '#32ade6', '#007aff', '#5856d6', '#af52de',
  '#ff2d55', '#a2845e', '#ff6482', '#ffd60a', '#30d158',
  '#66d4cf', '#40c8e0', '#64d2ff', '#7d7aff', '#bf5af2'
];

// Symbol payout multipliers for [2-of-a-kind, 3-of-a-kind, 4-of-a-kind, 5-of-a-kind]
const PAYTABLE = {
  'wild':   [0, 50, 500, 2500],
  'king':   [10, 80, 300, 1000],
  'queen':  [5, 50, 200, 600],
  'knight': [5, 40, 150, 400],
  'castle': [2, 10, 50, 200], // Scatter also awards Free Spins on 3+
  'k':      [0, 30, 100, 250],
  'q':      [0, 25, 80, 200],
  'j':      [0, 20, 60, 150],
  'ten':    [0, 15, 40, 100],
  'nine':   [0, 10, 30, 80]
};

// Reel Strip definition (balanced distribution for engaging gameplay)
const BASE_REEL_STRIP = [
  'nine', 'ten', 'knight', 'q', 'king', 'nine', 'j', 'castle', 'ten', 'queen',
  'k', 'knight', 'wild', 'nine', 'ten', 'king', 'j', 'queen', 'k', 'castle',
  'nine', 'ten', 'knight', 'q', 'wild', 'k', 'king', 'queen', 'j', 'castle'
];

/**
 * Smart Pool & RTP Revenue Controller
 * Enforces:
 * - App Owner Guaranteed Profit: 20% - 30% (default 28%)
 * - Total Player Return: Max 80% (Target 70% - 75%)
 * - Dynamically distributes wins to players over time without exceeding the prize pool
 */
class PoolManager {
  constructor() {
    const saved = JSON.parse(localStorage.getItem('kotc_pool_manager') || '{}');
    this.totalBets = Number(saved.totalBets) || 0;
    this.totalWins = Number(saved.totalWins) || 0;
    this.houseRevenue = Number(saved.houseRevenue) || 0;
    this.prizePool = Number(saved.prizePool) || 0;

    this.targetRtp = 0.72; // 72% target return (approx 700-750 back on 1000 bet)
    this.maxRtpCap = 0.80; // 80% maximum hard cap requested by user
    this.houseMargin = 0.28; // 28% app owner net profit
  }

  save() {
    localStorage.setItem('kotc_pool_manager', JSON.stringify({
      totalBets: this.totalBets,
      totalWins: this.totalWins,
      houseRevenue: this.houseRevenue,
      prizePool: this.prizePool
    }));
  }

  onBetPlaced(betAmount) {
    this.totalBets += betAmount;
    const profit = betAmount * this.houseMargin;
    const pool = betAmount * (1 - this.houseMargin);
    this.houseRevenue += profit;
    this.prizePool += pool;
    this.save();
  }

  canAffordWin(prospectiveWin) {
    if (prospectiveWin <= 0) return true;
    if (prospectiveWin > this.prizePool) return false;

    const projectedWins = this.totalWins + prospectiveWin;
    const projectedRtp = this.totalBets > 0 ? (projectedWins / this.totalBets) : 0;
    if (projectedRtp > this.maxRtpCap && this.totalBets >= 300) {
      return false;
    }
    return true;
  }

  onWinPaid(winAmount) {
    this.totalWins += winAmount;
    this.prizePool = Math.max(0, this.prizePool - winAmount);
    this.save();
  }

  getCurrentRtp() {
    if (this.totalBets === 0) return '72.0';
    return ((this.totalWins / this.totalBets) * 100).toFixed(1);
  }

  resetStats() {
    this.totalBets = 0;
    this.totalWins = 0;
    this.houseRevenue = 0;
    this.prizePool = 0;
    this.save();
  }
}

/**
 * Full-Screen Coin, Diamond & Star Particle FX Engine
 * Dynamically renders:
 * - Small win: 35 tumbling coins fountain
 * - Medium win: 100 cascading coins & sparkling diamonds
 * - Big win: 250+ full-screen explosion with fireworks, multi-wave rain & diamonds
 */
class FullScreenCoinFX {
  constructor() {
    this.canvas = document.getElementById('fxCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.particles = [];
    this.resize();
    window.addEventListener('resize', () => this.resize());
    this.startLoop();
  }

  resize() {
    this.width = this.canvas.width = window.innerWidth;
    this.height = this.canvas.height = window.innerHeight;
  }

  triggerWin(level, amount) {
    if (level === 'small') {
      this.spawnFountain(35, this.width * 0.5, this.height * 0.75, 12, 22);
    } else if (level === 'medium') {
      this.spawnFountain(50, this.width * 0.35, this.height * 0.75, 14, 25);
      this.spawnFountain(50, this.width * 0.65, this.height * 0.75, 14, 25);
      this.spawnDiamonds(25);
    } else if (level === 'big') {
      let wave = 0;
      const interval = setInterval(() => {
        this.spawnFountain(45, this.width * (0.2 + Math.random() * 0.6), this.height * 0.8, 16, 28);
        this.spawnRain(35);
        this.spawnDiamonds(20);
        wave++;
        if (wave >= 6) clearInterval(interval);
      }, 320);
    }
  }

  spawnFountain(count, originX, originY, minV, maxV) {
    for (let i = 0; i < count; i++) {
      const angle = -Math.PI / 2 + (Math.random() - 0.5) * 1.3;
      const speed = minV + Math.random() * (maxV - minV);
      this.particles.push({
        type: Math.random() > 0.3 ? 'coin' : 'diamond',
        x: originX + (Math.random() - 0.5) * 50,
        y: originY,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        gravity: 0.65,
        size: 16 + Math.random() * 12,
        rotY: Math.random() * Math.PI,
        vRotY: 0.08 + Math.random() * 0.15,
        rotZ: Math.random() * Math.PI * 2,
        vRotZ: (Math.random() - 0.5) * 0.1,
        bounce: 0.45,
        bouncesLeft: 2,
        alpha: 1,
        life: 0,
        maxLife: 180 + Math.random() * 60
      });
    }
  }

  spawnRain(count) {
    for (let i = 0; i < count; i++) {
      this.particles.push({
        type: Math.random() > 0.35 ? 'coin' : 'diamond',
        x: Math.random() * this.width,
        y: -30 - Math.random() * 60,
        vx: (Math.random() - 0.5) * 5,
        vy: 4 + Math.random() * 9,
        gravity: 0.45,
        size: 15 + Math.random() * 11,
        rotY: Math.random() * Math.PI,
        vRotY: 0.06 + Math.random() * 0.12,
        rotZ: Math.random() * Math.PI * 2,
        vRotZ: (Math.random() - 0.5) * 0.08,
        bounce: 0.35,
        bouncesLeft: 1,
        alpha: 1,
        life: 0,
        maxLife: 200
      });
    }
  }

  spawnDiamonds(count) {
    for (let i = 0; i < count; i++) {
      this.particles.push({
        type: 'diamond',
        x: this.width * (0.2 + Math.random() * 0.6),
        y: this.height * 0.65,
        vx: (Math.random() - 0.5) * 16,
        vy: -10 - Math.random() * 14,
        gravity: 0.52,
        size: 14 + Math.random() * 10,
        rotY: 0,
        vRotY: 0,
        rotZ: Math.random() * Math.PI * 2,
        vRotZ: (Math.random() - 0.5) * 0.15,
        bounce: 0.3,
        bouncesLeft: 1,
        alpha: 1,
        life: 0,
        maxLife: 160
      });
    }
  }

  startLoop() {
    const render = () => {
      this.updateAndDraw();
      requestAnimationFrame(render);
    };
    requestAnimationFrame(render);
  }

  updateAndDraw() {
    this.ctx.clearRect(0, 0, this.width, this.height);
    if (this.particles.length === 0) return;

    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.life++;
      p.x += p.vx;
      p.y += p.vy;
      p.vy += p.gravity;
      p.rotY += p.vRotY;
      p.rotZ += p.vRotZ;

      if (p.y >= this.height - p.size && p.vy > 0) {
        if (p.bouncesLeft > 0) {
          p.bouncesLeft--;
          p.y = this.height - p.size;
          p.vy = -p.vy * p.bounce;
          p.vx *= 0.85;
        }
      }

      if (p.life > p.maxLife - 30) {
        p.alpha = Math.max(0, (p.maxLife - p.life) / 30);
      }

      this.drawParticle(p);

      if (p.life >= p.maxLife || p.alpha <= 0) {
        this.particles.splice(i, 1);
      }
    }
  }

  drawParticle(p) {
    this.ctx.save();
    this.ctx.globalAlpha = p.alpha;
    this.ctx.translate(p.x, p.y);
    this.ctx.rotate(p.rotZ);

    if (p.type === 'coin') {
      const scaleX = Math.cos(p.rotY);
      this.ctx.scale(scaleX, 1);

      const r = p.size;
      this.ctx.beginPath();
      this.ctx.arc(0, 0, r, 0, Math.PI * 2);
      const grad = this.ctx.createLinearGradient(-r, -r, r, r);
      grad.addColorStop(0, '#ffe57f');
      grad.addColorStop(0.4, '#d4af37');
      grad.addColorStop(1, '#8a6d1c');
      this.ctx.fillStyle = grad;
      this.ctx.fill();

      this.ctx.beginPath();
      this.ctx.arc(0, 0, r * 0.8, 0, Math.PI * 2);
      this.ctx.lineWidth = 1.5;
      this.ctx.strokeStyle = '#fff1a8';
      this.ctx.stroke();

      if (Math.abs(scaleX) > 0.3) {
        this.ctx.fillStyle = '#6b4c05';
        this.ctx.font = `bold ${Math.round(r * 0.85)}px sans-serif`;
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillText('★', 0, 0);
      }
    } else {
      const s = p.size;
      this.ctx.beginPath();
      this.ctx.moveTo(0, -s);
      this.ctx.lineTo(s * 0.8, -s * 0.3);
      this.ctx.lineTo(0, s);
      this.ctx.lineTo(-s * 0.8, -s * 0.3);
      this.ctx.closePath();

      const dGrad = this.ctx.createLinearGradient(-s, -s, s, s);
      dGrad.addColorStop(0, '#e0f7fa');
      dGrad.addColorStop(0.5, '#00e5ff');
      dGrad.addColorStop(1, '#0091ea');
      this.ctx.fillStyle = dGrad;
      this.ctx.fill();

      this.ctx.strokeStyle = '#ffffff';
      this.ctx.lineWidth = 1.2;
      this.ctx.stroke();
    }

    this.ctx.restore();
  }
}

class SlotGame {
  constructor() {
    this.canvas = document.getElementById('reelsCanvas');
    this.ctx = this.canvas.getContext('2d');

    // Grid config
    this.cols = 5;
    this.rows = 3;

    // Dimensions in canvas space (matching 4340 x 2340 aspect ratio 1.8547:1)
    this.width = 1200;
    this.height = 648;
    this.colWidth = this.width / this.cols; // 240px
    this.rowHeight = this.height / this.rows; // 216px

    // Betting & Balance (Starting at 100, stepping: 100 -> 1k -> 5k -> 10k -> 50k -> 100k)
    this.coins = parseInt(localStorage.getItem('kotc_coins') || '200000', 10);
    this.betLevels = [100, 1000, 5000, 10000, 50000, 100000];
    this.betIndex = 0; // Starts normally at 100
    this.betPerLine = this.betLevels[this.betIndex] / PAYLINES.length;
    this.jackpot = parseInt(localStorage.getItem('kotc_jackpot') || '52480', 10);

    // IMChat App User Profile Detection
    const urlParams = new URLSearchParams(window.location.search);
    this.userId = urlParams.get('userId') || urlParams.get('user_id') || urlParams.get('uid') || '';
    this.userName = urlParams.get('name') || urlParams.get('username') || urlParams.get('fullname') || 'Player';
    this.userAvatar = urlParams.get('photoUrl') || urlParams.get('avatar') || urlParams.get('avatarUrl') || '';
    this.roomId = urlParams.get('roomId') || urlParams.get('room_id') || '';
    this.isRealUser = Boolean(this.userId);

    const initialDiamonds = urlParams.get('diamonds') || urlParams.get('coins') || urlParams.get('balance');
    if (initialDiamonds !== null && !isNaN(Number(initialDiamonds))) {
      this.coins = Number(initialDiamonds);
    }

    // Smart Pool & RTP Revenue Controller (Max 80% Player Return, 20-30% App Revenue)
    this.pool = new PoolManager();

    // Free Spins & Bonus
    this.freeSpinsRemaining = 0;
    this.freeSpinsTotalWin = 0;
    this.isFreeSpinMode = false;
    this.winMultiplier = 1;

    // Auto Play
    this.autoSpinsRemaining = 0;
    this.isAutoPlaying = false;
    this.turboMode = false;

    // Reels State
    this.reels = [];
    this.reelSymbols = [[], [], [], [], []]; // 5 columns x 3 rows currently visible
    this.isSpinning = false;
    this.lastWinAmount = 0;
    this.activeWinningLines = [];
    this.winAnimationStep = 0;

    // Confetti / Coin particles
    this.particles = [];
    this.fx = new FullScreenCoinFX();

    this.initReels();
    this.setupUI();
    this.updateHUD();
    this.startRenderLoop();

    // Real-time Firebase & IMChat Wallet Sync
    this.initFirebaseSync();
    this.updateUserProfileUI();

    // Secret Owner Shortcut (Ctrl + Shift + S) to inspect hidden RTP without players knowing
    window.addEventListener('keydown', (e) => {
      if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === 's') {
        window.kotc_stats();
        alert(`👑 [SECRET OWNER STATS]\nTotal Bets: ${this.pool.totalBets.toLocaleString()}\nTotal Paid: ${this.pool.totalWins.toLocaleString()}\nApp Profit: ${this.pool.houseRevenue.toLocaleString()}\nCurrent RTP: ${this.pool.getCurrentRtp()}% (Max 80%)`);
      }
    });
  }

  initReels() {
    // Canvas sizing with high DPI support
    const rect = this.canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    this.canvas.width = this.width * dpr;
    this.canvas.height = this.height * dpr;
    this.ctx.scale(dpr, dpr);

    // Initial visible symbols matching artwork
    const initialGrid = [
      ['nine', 'queen', 'knight'],
      ['ten', 'king', 'knight'],
      ['k', 'q', 'knight'],
      ['king', 'k', 'castle'],
      ['castle', 'j', 'queen']
    ];

    for (let c = 0; c < this.cols; c++) {
      // Create continuous reel strip
      const strip = [...BASE_REEL_STRIP, ...BASE_REEL_STRIP];
      this.reels.push({
        col: c,
        strip: strip,
        pos: 10 + c * 3, // Current floating position in symbol units
        targetPos: 10 + c * 3,
        speed: 0,
        state: 'IDLE',
        stopTimer: 0
      });
      this.reelSymbols[c] = [...initialGrid[c]];
    }
  }

  setupUI() {
    // SPIN button
    const spinBtn = document.getElementById('spinBtn');
    spinBtn.addEventListener('click', () => {
      window.soundEngine.playClick();
      if (this.isSpinning) {
        this.quickStop();
      } else {
        this.startSpin();
      }
    });

    // Top-Left Back Button: Exits game / closes modal webview
    const infoBtn = document.getElementById('infoBtn');
    if (infoBtn) {
      infoBtn.addEventListener('click', () => {
        if (window.soundEngine) window.soundEngine.playClick();
        if (window.parent && window.parent !== window) {
          window.parent.postMessage({ type: 'CLOSE_GAME' }, '*');
        }
        if (window.FlutterBridge) {
          try { window.FlutterBridge.postMessage('CLOSE_GAME'); } catch (e) {}
        }
        try { window.close(); } catch (e) {}
        try { window.history.back(); } catch (e) {}
      });
    }

    // BET buttons (Top arrow increases, Bottom arrow decreases)
    const betUpBtn = document.getElementById('betUpBtn');
    const betDownBtn = document.getElementById('betDownBtn');

    betUpBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.increaseBet();
    });

    betDownBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.decreaseBet();
    });

    betUpBtn.addEventListener('touchstart', (e) => {
      e.preventDefault();
      this.increaseBet();
    }, { passive: false });

    betDownBtn.addEventListener('touchstart', (e) => {
      e.preventDefault();
      this.decreaseBet();
    }, { passive: false });

    // 5x and 10x quick bet buttons
    document.getElementById('btn5x').addEventListener('click', () => {
      window.soundEngine.playClick();
      if (this.isSpinning) return;
      this.betIndex = 2; // 5k
      this.betPerLine = this.betLevels[this.betIndex] / PAYLINES.length;
      this.updateHUD();
    });

    document.getElementById('btn10x').addEventListener('click', () => {
      window.soundEngine.playClick();
      if (this.isSpinning) return;
      this.betIndex = 3; // 10k
      this.betPerLine = this.betLevels[this.betIndex] / PAYLINES.length;
      this.updateHUD();
    });

    // Auto Play Button
    document.getElementById('autoPlayBtn').addEventListener('click', () => {
      window.soundEngine.playClick();
      if (this.isAutoPlaying) {
        this.stopAutoPlay();
      } else {
        this.showAutoPlayModal();
      }
    });

    // Bonus Info Button
    document.getElementById('bonusBtn').addEventListener('click', () => {
      window.soundEngine.playClick();
      this.showModal('bonusModal');
    });

    // Top Right: Paytable & Rules Modal Button
    const soundBtn = document.getElementById('soundBtn');
    if (soundBtn) {
      soundBtn.addEventListener('click', () => {
        if (window.soundEngine) window.soundEngine.playClick();
        this.showModal('paytableModal');
      });
    }

    // Menu Modal toggles
    const modalSoundToggle = document.getElementById('modalSoundToggle');
    if (modalSoundToggle) {
      modalSoundToggle.addEventListener('click', () => {
        const isMuted = window.soundEngine.toggleMute();
        modalSoundToggle.textContent = isMuted ? '🔇 Sound: MUTED' : '🔊 Sound: ON';
        soundBtn.classList.toggle('muted', isMuted);
      });
    }

    const modalTurboToggle = document.getElementById('modalTurboToggle');
    if (modalTurboToggle) {
      modalTurboToggle.addEventListener('click', () => {
        window.soundEngine.playClick();
        this.turboMode = !this.turboMode;
        modalTurboToggle.textContent = this.turboMode ? '⚡ Turbo: ACTIVE' : '⚡ Turbo: OFF';
      });
    }

    const modalAddDiamonds = document.getElementById('modalAddDiamonds');
    if (modalAddDiamonds) {
      modalAddDiamonds.addEventListener('click', () => {
        window.soundEngine.playCoin();
        this.coins += 50000;
        localStorage.setItem('kotc_coins', this.coins);
        this.updateHUD();
      });
    }

    const modalPaytableBtn = document.getElementById('modalPaytableBtn');
    if (modalPaytableBtn) {
      modalPaytableBtn.addEventListener('click', () => {
        window.soundEngine.playClick();
        document.getElementById('menuModal').classList.remove('active');
        this.showModal('paytableModal');
      });
    }

    // Modal Close buttons
    document.querySelectorAll('.modal-close').forEach(btn => {
      btn.addEventListener('click', (e) => {
        window.soundEngine.playClick();
        const modal = e.target.closest('.game-modal');
        if (modal) modal.classList.remove('active');
      });
    });

    // Close modal when clicking outside content
    document.querySelectorAll('.game-modal').forEach(modal => {
      modal.addEventListener('click', (e) => {
        if (e.target === modal) {
          modal.classList.remove('active');
        }
      });
    });

    // Keyboard support (Space to spin)
    window.addEventListener('keydown', (e) => {
      if (e.code === 'Space') {
        e.preventDefault();
        spinBtn.click();
      }
    });
  }

  formatCompact(val) {
    const num = Number(val);
    if (isNaN(num)) return val;
    if (num <= 999) return num.toString();
    if (num < 1_000_000) {
      const k = num / 1_000;
      const formatted = (k % 1 === 0 || k >= 100) ? Math.floor(k) : k.toFixed(1).replace(/\.0$/, '');
      return `${formatted}k`;
    }
    if (num < 1_000_000_000) {
      const m = num / 1_000_000;
      const formatted = (m % 1 === 0 || m >= 100) ? Math.floor(m) : m.toFixed(1).replace(/\.0$/, '');
      return `${formatted}M`;
    }
    const b = num / 1_000_000_000;
    const formatted = (b % 1 === 0 || b >= 100) ? Math.floor(b) : b.toFixed(1).replace(/\.0$/, '');
    return `${formatted}B`;
  }

  increaseBet() {
    if (this.isSpinning) return;
    window.soundEngine.playClick();
    if (this.betIndex < this.betLevels.length - 1) {
      this.betIndex++;
    } else {
      this.betIndex = 0; // Wrap around to 100 so it never gets stuck at maximum
    }
    this.betPerLine = this.betLevels[this.betIndex] / PAYLINES.length;
    this.updateHUD();

    const btn = document.getElementById('betUpBtn');
    if (btn) {
      btn.classList.add('btn-pressed');
      setTimeout(() => btn.classList.remove('btn-pressed'), 180);
    }
  }

  decreaseBet() {
    if (this.isSpinning) return;
    window.soundEngine.playClick();
    if (this.betIndex > 0) {
      this.betIndex--;
    } else {
      this.betIndex = this.betLevels.length - 1; // Wrap around to 100k so it never gets stuck at minimum
    }
    this.betPerLine = this.betLevels[this.betIndex] / PAYLINES.length;
    this.updateHUD();

    const btn = document.getElementById('betDownBtn');
    if (btn) {
      btn.classList.add('btn-pressed');
      setTimeout(() => btn.classList.remove('btn-pressed'), 180);
    }
  }

  getTotalBet() {
    return this.betLevels[this.betIndex];
  }

  updateHUD() {
    const totalBet = this.getTotalBet();
    document.getElementById('betValue').textContent = this.formatCompact(totalBet);
    document.getElementById('coinsValue').textContent = this.formatCompact(this.coins);
    // Jackpot always keeps full numbers as requested
    document.getElementById('jackpotValue').textContent = Math.floor(this.jackpot).toLocaleString();

    // Auto Play button label
    const autoBtn = document.getElementById('autoPlayBtn');
    if (this.isAutoPlaying) {
      autoBtn.textContent = `STOP (${this.autoSpinsRemaining})`;
      autoBtn.classList.add('active');
    } else {
      autoBtn.textContent = 'AUTO PLAY';
      autoBtn.classList.remove('active');
    }

    // Free spins banner
    const fsBanner = document.getElementById('freeSpinsBanner');
    if (this.isFreeSpinMode) {
      fsBanner.style.display = 'block';
      document.getElementById('freeSpinsCount').textContent = this.freeSpinsRemaining;
      document.getElementById('freeSpinsWin').textContent = this.freeSpinsTotalWin.toLocaleString();
    } else {
      fsBanner.style.display = 'none';
    }

    this.updatePoolDashboard();
  }

  updatePoolDashboard() {
    const elBets = document.getElementById('statTotalBets');
    const elWins = document.getElementById('statTotalWins');
    const elRevenue = document.getElementById('statHouseRevenue');
    const elRtp = document.getElementById('statCurrentRtp');

    if (elBets) elBets.textContent = this.formatCompact(this.pool.totalBets);
    if (elWins) elWins.textContent = this.formatCompact(this.pool.totalWins);
    if (elRevenue) elRevenue.textContent = this.formatCompact(this.pool.houseRevenue);
    if (elRtp) elRtp.textContent = `${this.pool.getCurrentRtp()}%`;
  }

  showModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.add('active');
  }

  showAutoPlayModal() {
    const modal = document.getElementById('autoPlayModal');
    if (modal) modal.classList.add('active');
  }

  startAutoPlay(spins) {
    this.autoSpinsRemaining = spins;
    this.isAutoPlaying = true;
    document.getElementById('autoPlayModal').classList.remove('active');
    this.updateHUD();
    if (!this.isSpinning) {
      this.startSpin();
    }
  }

  stopAutoPlay() {
    this.isAutoPlaying = false;
    this.autoSpinsRemaining = 0;
    this.updateHUD();
  }

  startSpin() {
    if (this.isSpinning) return;

    const totalBet = this.getTotalBet();

    // Free spin or regular bet deduction
    if (!this.isFreeSpinMode) {
      if (this.coins < totalBet) {
        this.showInsufficientDiamondsAlert(totalBet);
        this.stopAutoPlay();
        return;
      }
      this.coins -= totalBet;
      this.jackpot += totalBet * 0.01; // 1% progressive contribution
      this.pool.onBetPlaced(totalBet); // Add to house revenue and prize pool
      localStorage.setItem('kotc_coins', this.coins);
      localStorage.setItem('kotc_jackpot', Math.floor(this.jackpot));

      // Real-time Firestore deduction for IMChat App User
      if (this.userId && this.db) {
        this.db.collection('Users').doc(this.userId).update({
          diamonds: firebase.firestore.FieldValue.increment(-totalBet),
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }).catch((err) => {
          console.warn('Real-time bet deduction error:', err);
        });
      }
    } else {
      this.freeSpinsRemaining--;
    }

    this.isSpinning = true;
    this.activeWinningLines = [];
    document.getElementById('spinBtn').classList.add('spinning');
    this.updateHUD();

    window.soundEngine.startSpinSound();

    // Determine results ahead of time based on pool rules (max 80% return, 20%+ app profit)
    const resultGrid = this.generateSpinOutcome();

    // Staggered stop times
    const baseStop = this.turboMode ? 400 : 900;
    const interval = this.turboMode ? 150 : 350;

    for (let c = 0; c < this.cols; c++) {
      const reel = this.reels[c];
      reel.state = 'SPINNING';
      reel.speed = this.turboMode ? 42 : 28;

      // Find where in reel.strip resultGrid[c] is located or insert it
      const targetIndex = 20 + Math.floor(Math.random() * 5);
      reel.strip[targetIndex] = resultGrid[c][0];
      reel.strip[targetIndex + 1] = resultGrid[c][1];
      reel.strip[targetIndex + 2] = resultGrid[c][2];

      reel.targetPos = reel.pos + 35 + c * 8;
      // Align to whole symbol
      reel.targetPos = Math.ceil(reel.targetPos / 3) * 3;

      const stopDelay = baseStop + c * interval;
      reel.stopTimer = setTimeout(() => {
        if (reel.state === 'SPINNING') {
          this.stopReel(c, resultGrid[c]);
        }
      }, stopDelay);
    }
  }

  quickStop() {
    for (let c = 0; c < this.cols; c++) {
      clearTimeout(this.reels[c].stopTimer);
      if (this.reels[c].state === 'SPINNING') {
        this.reels[c].state = 'STOPPING';
        this.reels[c].speed = 15;
      }
    }
  }

  stopReel(colIndex, finalSymbols) {
    const reel = this.reels[colIndex];
    reel.state = 'STOPPING';
    this.reelSymbols[colIndex] = finalSymbols;
  }

  onReelLanded(colIndex) {
    window.soundEngine.playReelStop(colIndex);

    // If last reel landed, finalize spin
    if (colIndex === this.cols - 1) {
      window.soundEngine.stopSpinSound();
      this.isSpinning = false;
      document.getElementById('spinBtn').classList.remove('spinning');
      this.evaluateSpin();
    }
  }

  calculateGridWin(grid, betPerLine, multiplier = 1) {
    let total = 0;
    PAYLINES.forEach(line => {
      const lineSymbols = [
        grid[0][line[0]],
        grid[1][line[1]],
        grid[2][line[2]],
        grid[3][line[3]],
        grid[4][line[4]]
      ];
      let first = lineSymbols[0];
      let matchSymbol = first === 'wild' ? null : first;
      let count = 1;
      for (let i = 1; i < 5; i++) {
        const s = lineSymbols[i];
        if (s === 'wild' && matchSymbol !== 'castle') count++;
        else if (!matchSymbol && s !== 'castle') { matchSymbol = s; count++; }
        else if (s === matchSymbol) count++;
        else break;
      }
      const sym = matchSymbol || 'wild';
      const payouts = PAYTABLE[sym];
      if (payouts && count >= 2 && payouts[count - 2] > 0) {
        total += payouts[count - 2] * betPerLine * multiplier;
      }
    });

    let castles = 0;
    for (let c = 0; c < this.cols; c++) {
      for (let r = 0; r < this.rows; r++) {
        if (grid[c][r] === 'castle') castles++;
      }
    }
    if (castles >= 3) {
      const scMult = castles === 3 ? 5 : (castles === 4 ? 20 : 100);
      total += (betPerLine * 20) * scMult * multiplier;
    }
    return total;
  }

  generateRandomGrid() {
    const symbolsList = ['nine', 'nine', 'ten', 'ten', 'j', 'j', 'q', 'k', 'knight', 'queen', 'king', 'castle', 'wild'];
    const weights = [18, 16, 15, 14, 12, 10, 8, 5, 4, 3, 3, 2, 2];

    const getRandomSymbol = () => {
      let total = weights.reduce((a, b) => a + b, 0);
      let r = Math.random() * total;
      for (let i = 0; i < symbolsList.length; i++) {
        r -= weights[i];
        if (r <= 0) return symbolsList[i];
      }
      return 'nine';
    };

    const grid = [];
    for (let c = 0; c < this.cols; c++) {
      grid.push([
        getRandomSymbol(),
        getRandomSymbol(),
        getRandomSymbol()
      ]);
    }
    return grid;
  }

  generateNonWinGrid() {
    return [
      ['nine', 'ten', 'knight'],
      ['ten', 'j', 'q'],
      ['k', 'nine', 'ten'],
      ['queen', 'k', 'j'],
      ['king', 'knight', 'nine']
    ];
  }

  // Controlled Outcome Engine (Enforces 70-80% return, 20-30% app profit)
  generateSpinOutcome() {
    const multiplier = this.isFreeSpinMode ? 3 : 1;
    const currentRtp = this.pool.totalBets > 0 ? (this.pool.totalWins / this.pool.totalBets) : 0;
    
    // Dynamic hit decision:
    // If pool is above 80% ceiling, force 0% win until pool replenishes
    let winEligible = true;
    if (currentRtp >= this.pool.maxRtpCap) {
      winEligible = false;
    } else {
      const hitChance = currentRtp < 0.65 ? 0.38 : (currentRtp < 0.74 ? 0.28 : 0.16);
      winEligible = Math.random() < hitChance;
    }

    let bestGrid = null;
    let nonWinGrid = null;

    for (let attempt = 0; attempt < 35; attempt++) {
      const cand = this.generateRandomGrid();
      const candWin = this.calculateGridWin(cand, this.betPerLine, multiplier);

      if (candWin === 0 && !nonWinGrid) {
        nonWinGrid = cand;
      }

      if (winEligible && candWin > 0) {
        if (this.pool.canAffordWin(candWin)) {
          bestGrid = cand;
          break;
        }
      } else if (!winEligible && candWin === 0) {
        bestGrid = cand;
        break;
      }
    }

    return bestGrid || nonWinGrid || this.generateNonWinGrid();
  }

  evaluateSpin() {
    let totalWin = 0;
    const winningLines = [];
    const multiplier = this.isFreeSpinMode ? 3 : 1;

    // Check all 20 paylines
    PAYLINES.forEach((line, lineIndex) => {
      const lineSymbols = [
        this.reelSymbols[0][line[0]],
        this.reelSymbols[1][line[1]],
        this.reelSymbols[2][line[2]],
        this.reelSymbols[3][line[3]],
        this.reelSymbols[4][line[4]]
      ];

      let firstSymbol = lineSymbols[0];
      let matchSymbol = firstSymbol === 'wild' ? null : firstSymbol;
      let count = 1;

      for (let i = 1; i < 5; i++) {
        const s = lineSymbols[i];
        if (s === 'wild' && matchSymbol !== 'castle') {
          count++;
        } else if (!matchSymbol && s !== 'castle') {
          matchSymbol = s;
          count++;
        } else if (s === matchSymbol) {
          count++;
        } else {
          break;
        }
      }

      const targetSym = matchSymbol || 'wild';
      const payouts = PAYTABLE[targetSym];

      if (payouts && count >= 2 && payouts[count - 2] > 0) {
        const lineWin = payouts[count - 2] * this.betPerLine * multiplier;
        totalWin += lineWin;
        winningLines.push({
          lineIndex: lineIndex,
          pattern: line,
          symbol: targetSym,
          count: count,
          win: lineWin,
          color: PAYLINE_COLORS[lineIndex % PAYLINE_COLORS.length]
        });

        if (lineIndex === 0 && count === 5 && (targetSym === 'king' || targetSym === 'wild')) {
          this.triggerJackpotWin();
        }
      }
    });

    // Check Scatters
    let castleCount = 0;
    const castleCoords = [];
    for (let c = 0; c < this.cols; c++) {
      for (let r = 0; r < this.rows; r++) {
        if (this.reelSymbols[c][r] === 'castle') {
          castleCount++;
          castleCoords.push({ col: c, row: r });
        }
      }
    }

    if (castleCount >= 3) {
      const scatterMultiplier = castleCount === 3 ? 5 : (castleCount === 4 ? 20 : 100);
      const scatterWin = this.getTotalBet() * scatterMultiplier * multiplier;
      totalWin += scatterWin;

      setTimeout(() => {
        this.triggerCastleBonus(castleCount);
      }, 1000);
    }

    this.activeWinningLines = winningLines;
    this.lastWinAmount = totalWin;

    if (totalWin > 0) {
      this.coins += totalWin;
      this.pool.onWinPaid(totalWin); // Deduct from prize pool, update house stats
      if (this.isFreeSpinMode) {
        this.freeSpinsTotalWin += totalWin;
      }
      localStorage.setItem('kotc_coins', this.coins);
      this.updateHUD();

      // Real-time Firestore win credit for IMChat App User
      if (this.userId && this.db) {
        this.db.collection('Users').doc(this.userId).update({
          diamonds: firebase.firestore.FieldValue.increment(totalWin),
          updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        }).catch((err) => {
          console.warn('Real-time win payout error:', err);
        });

        // Record in game_history for profit analysis & leaderboard
        this.db.collection('game_history').add({
          userId: this.userId,
          userName: this.userName || 'Player',
          userAvatar: this.userAvatar || '',
          gameName: 'King Queen Slot Game',
          gameType: 'slot',
          roomId: this.roomId || '',
          betAmount: this.getTotalBet(),
          winAmount: totalWin,
          type: 'WIN',
          timestamp: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});
      }

      // Sound, Tiered Full-Screen Coin Animation & Celebration
      const betRatio = totalWin / this.getTotalBet();
      if (betRatio >= 25) {
        window.soundEngine.playWin('mega');
        this.showCelebration('MEGA WIN', totalWin);
        this.fx.triggerWin('big', totalWin);
      } else if (betRatio >= 8) {
        window.soundEngine.playWin('big');
        this.showCelebration('BIG WIN', totalWin);
        this.fx.triggerWin('medium', totalWin);
      } else {
        window.soundEngine.playWin('normal');
      }
    } else {
      // Record non-winning spin in game_history for profit analysis
      if (this.userId && this.db && !this.isFreeSpinMode) {
        this.db.collection('game_history').add({
          userId: this.userId,
          userName: this.userName || 'Player',
          userAvatar: this.userAvatar || '',
          gameId: 'king_queen_slot',
          gameCode: 'html5_king_queen_slot',
          gameName: 'King Queen Slot Game',
          gameType: 'slot',
          roomId: this.roomId || '',
          betAmount: this.getTotalBet(),
          winAmount: 0,
          type: 'BET',
          timestamp: firebase.firestore.FieldValue.serverTimestamp(),
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});
      }
    }

    // Handle Free Spins continuation or exit
    if (this.isFreeSpinMode) {
      if (this.freeSpinsRemaining <= 0) {
        setTimeout(() => {
          this.endFreeSpins();
        }, 1800);
      } else {
        setTimeout(() => {
          if (this.isFreeSpinMode) this.startSpin();
        }, 1500);
      }
      return;
    }

    // Auto Play continuation
    if (this.isAutoPlaying) {
      this.autoSpinsRemaining--;
      this.updateHUD();
      if (this.autoSpinsRemaining <= 0 || (totalWin / this.getTotalBet() >= 25)) {
        this.stopAutoPlay();
      } else {
        setTimeout(() => {
          if (this.isAutoPlaying) this.startSpin();
        }, 1200);
      }
    }
  }

  triggerCastleBonus(count) {
    window.soundEngine.playBonusTrumpet();
    this.isFreeSpinMode = true;
    this.freeSpinsRemaining = 10;
    this.freeSpinsTotalWin = 0;
    this.updateHUD();

    const banner = document.getElementById('bonusTriggerOverlay');
    if (banner) {
      banner.classList.add('active');
      document.getElementById('bonusAwardText').textContent = `3+ CASTLES HIT!\n10 FREE SPINS WITH 3x MULTIPLIER AWARDED!`;
      setTimeout(() => {
        banner.classList.remove('active');
        this.startSpin();
      }, 3000);
    }
  }

  endFreeSpins() {
    this.isFreeSpinMode = false;
    this.updateHUD();
    this.showCelebration('CASTLE SIEGE BONUS COMPLETE', this.freeSpinsTotalWin);
    this.fx.triggerWin('big', this.freeSpinsTotalWin);
  }

  triggerJackpotWin() {
    window.soundEngine.playWin('jackpot');
    const jackpotWon = Math.floor(this.jackpot);
    this.coins += jackpotWon;
    this.jackpot = 50000;
    localStorage.setItem('kotc_coins', this.coins);
    localStorage.setItem('kotc_jackpot', this.jackpot);
    this.updateHUD();
    this.showCelebration('PROGRESSIVE JACKPOT!', jackpotWon);
    this.fx.triggerWin('big', jackpotWon);
  }

  showCelebration(title, amount) {
    const overlay = document.getElementById('celebrationModal');
    if (!overlay) return;

    document.getElementById('celebTitle').textContent = title;
    const valEl = document.getElementById('celebAmount');
    overlay.classList.add('active');

    // Rollup counter effect - SHOW FULL NUMBERS (e.g. 10,000, 100,000 - NOT 10k)
    let current = 0;
    const step = Math.ceil(amount / 40);
    const rollup = setInterval(() => {
      current = Math.min(current + step, amount);
      valEl.textContent = current.toLocaleString(); // FULL NUMBER!
      window.soundEngine.playCoin();
      if (current >= amount) {
        clearInterval(rollup);
        valEl.textContent = amount.toLocaleString(); // FULL NUMBER!
      }
    }, 40);

    setTimeout(() => {
      overlay.classList.remove('active');
    }, 4500);
  }

  showMiniWinNotification(amount) {
    const notify = document.getElementById('winNotification');
    if (notify) {
      // FULL NUMBER! (e.g. 10,000, 100,000 - NOT 1k or 10k)
      notify.textContent = `WIN: ${amount.toLocaleString()} DIAMONDS`;
      notify.classList.add('show');
      setTimeout(() => notify.classList.remove('show'), 2200);
    }
  }

  spawnCoinBurst(count = 35) {
    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: this.width * (0.3 + Math.random() * 0.4),
        y: this.height * 0.5,
        vx: (Math.random() - 0.5) * 16,
        vy: -Math.random() * 14 - 6,
        gravity: 0.55,
        size: 14 + Math.random() * 12,
        rot: Math.random() * Math.PI * 2,
        vRot: (Math.random() - 0.5) * 0.3,
        alpha: 1
      });
    }
  }

  // Master 60 FPS Render Loop
  startRenderLoop() {
    let lastTime = performance.now();

    const loop = (now) => {
      const dt = Math.min((now - lastTime) / 1000, 0.1);
      lastTime = now;

      this.updatePhysics(dt);
      this.render();

      requestAnimationFrame(loop);
    };

    requestAnimationFrame(loop);
  }

  updatePhysics(dt) {
    // Update Reels
    for (let c = 0; c < this.cols; c++) {
      const reel = this.reels[c];
      if (reel.state === 'SPINNING') {
        reel.pos += reel.speed * dt * 10;
      } else if (reel.state === 'STOPPING') {
        const dist = reel.targetPos - reel.pos;
        if (dist > 0.05) {
          reel.pos += Math.min(dist * 0.35, reel.speed * dt * 10);
        } else {
          reel.pos = reel.targetPos;
          reel.state = 'BOUNCE';
          reel.bounceOffset = -0.15; // Elastic overshoot
          reel.bounceVel = 2.5;
        }
      } else if (reel.state === 'BOUNCE') {
        reel.bounceOffset += reel.bounceVel * dt;
        reel.bounceVel -= 15 * dt;
        if (reel.bounceOffset >= 0) {
          reel.bounceOffset = 0;
          reel.state = 'IDLE';
          this.onReelLanded(c);
        }
      }
    }

    // Update Particles
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += p.gravity;
      p.rot += p.vRot;
      p.alpha -= 0.012;
      if (p.alpha <= 0 || p.y > this.height + 50) {
        this.particles.splice(i, 1);
      }
    }

    this.winAnimationStep += dt * 3;
  }

  render() {
    const ctx = this.ctx;
    ctx.clearRect(0, 0, this.width, this.height);

    if (!window.assetManager || !window.assetManager.loaded) return;

    // 1. Draw Reel Background Columns
    for (let c = 0; c < this.cols; c++) {
      const x = c * this.colWidth;
      ctx.drawImage(window.assetManager.reelBackground, x, 0, this.colWidth, this.height);
    }

    // 2. Draw Symbols on each Reel
    for (let c = 0; c < this.cols; c++) {
      const reel = this.reels[c];
      const x = c * this.colWidth;

      if (reel.state === 'IDLE') {
        // Draw static 3 symbols cleanly centered
        for (let r = 0; r < this.rows; r++) {
          const symId = this.reelSymbols[c][r];
          this.renderSymbol(ctx, symId, x, r * this.rowHeight, c, r);
        }
      } else {
        // Continuous spinning / bouncing rendering
        const floatPos = (reel.pos + (reel.bounceOffset || 0)) % reel.strip.length;
        const baseIndex = Math.floor(floatPos);
        const subOffset = (floatPos - baseIndex) * this.rowHeight;

        for (let i = -1; i <= this.rows + 1; i++) {
          const idx = (baseIndex + i + reel.strip.length) % reel.strip.length;
          const symId = reel.strip[idx];
          const y = i * this.rowHeight - subOffset;

          // Add motion blur during high-speed spin
          if (reel.state === 'SPINNING') {
            ctx.save();
            ctx.globalAlpha = 0.88;
            this.renderSymbol(ctx, symId, x, y, c, -1);
            ctx.restore();
          } else {
            this.renderSymbol(ctx, symId, x, y, c, -1);
          }
        }
      }
    }

    // 3. Draw Winning Paylines & Glowing Highlights
    if (!this.isSpinning && this.activeWinningLines.length > 0) {
      this.renderWinningLines(ctx);
    }

    // 4. Draw Confetti & Coin Particles
    this.renderParticles(ctx);
  }

  renderSymbol(ctx, symId, x, y, col, row) {
    const symObj = window.assetManager.symbols[symId];
    if (!symObj || !symObj.canvas) return;

    const size = Math.min(this.colWidth, this.rowHeight) * 0.94; // ~203px
    const padX = (this.colWidth - size) / 2;
    const padY = (this.rowHeight - size) / 2;

    const destX = x + padX;
    const destY = y + padY;

    // Check if symbol is part of a win to add pulse animation
    let isWinSymbol = false;
    if (!this.isSpinning && col >= 0 && row >= 0) {
      isWinSymbol = this.activeWinningLines.some(line => {
        return col < line.count && line.pattern[col] === row;
      });
    }

    ctx.save();
    if (isWinSymbol) {
      const pulse = 1 + Math.sin(this.winAnimationStep * 2.5) * 0.07;
      ctx.translate(destX + size/2, destY + size/2);
      ctx.scale(pulse, pulse);
      ctx.translate(-(destX + size/2), -(destY + size/2));

      // Golden aura behind winning symbol
      ctx.shadowColor = '#ffd700';
      ctx.shadowBlur = 22;
    }

    ctx.drawImage(symObj.canvas, destX, destY, size, size);
    ctx.restore();
  }

  renderWinningLines(ctx) {
    // Rotate through active lines smoothly or draw all glowing
    const lineIndexToShow = Math.floor(this.winAnimationStep * 0.6) % this.activeWinningLines.length;
    const currentLine = this.activeWinningLines[lineIndexToShow];

    if (!currentLine) return;

    ctx.save();
    ctx.strokeStyle = currentLine.color;
    ctx.lineWidth = 8;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.shadowColor = currentLine.color;
    ctx.shadowBlur = 15;

    ctx.beginPath();
    for (let c = 0; c < this.cols; c++) {
      const r = currentLine.pattern[c];
      const px = c * this.colWidth + this.colWidth / 2;
      const py = r * this.rowHeight + this.rowHeight / 2;
      if (c === 0) ctx.moveTo(px, py);
      else ctx.lineTo(px, py);
    }
    ctx.stroke();

    // Draw glowing node circles over matching symbols
    for (let c = 0; c < currentLine.count; c++) {
      const r = currentLine.pattern[c];
      const px = c * this.colWidth + this.colWidth / 2;
      const py = r * this.rowHeight + this.rowHeight / 2;

      ctx.beginPath();
      ctx.arc(px, py, 18, 0, Math.PI * 2);
      ctx.fillStyle = '#ffffff';
      ctx.fill();
      ctx.strokeStyle = currentLine.color;
      ctx.lineWidth = 4;
      ctx.stroke();
    }
    ctx.restore();
  }

  renderParticles(ctx) {
    ctx.save();
    for (const p of this.particles) {
      ctx.save();
      ctx.globalAlpha = p.alpha;
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);

      // Shiny Gold Coin
      ctx.beginPath();
      ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
      ctx.fillStyle = '#ffd700';
      ctx.fill();
      ctx.lineWidth = 2.5;
      ctx.strokeStyle = '#e5a93b';
      ctx.stroke();

      // Inner coin rim & star/crown
      ctx.beginPath();
      ctx.arc(0, 0, p.size / 3, 0, Math.PI * 2);
      ctx.strokeStyle = '#fff';
      ctx.lineWidth = 1;
      ctx.stroke();

      ctx.restore();
    }
    ctx.restore();
  }

  initFirebaseSync() {
    if (typeof firebase !== 'undefined') {
      try {
        if (firebase.apps.length === 0) {
          firebase.initializeApp({ projectId: 'imchat-84519' });
        }
        this.db = firebase.firestore();

        // 1. Listen to Remote Game Config (RTP, House Margin, Bet levels, Jackpot Base, Background Image)
        this.db.collection('config').doc('html5_slot_game')
          .onSnapshot((doc) => {
            if (doc && doc.exists) {
              const data = doc.data() || {};
              if (data.targetRtp && !isNaN(Number(data.targetRtp))) {
                this.pool.targetRtp = Number(data.targetRtp) / 100;
              }
              if (data.houseMargin && !isNaN(Number(data.houseMargin))) {
                this.pool.houseMargin = Number(data.houseMargin) / 100;
              }
              if (data.jackpotBase && !isNaN(Number(data.jackpotBase))) {
                this.jackpot = Math.max(this.jackpot, Number(data.jackpotBase));
                this.updateHUD();
              }
              if (data.backgroundImageUrl) {
                document.body.style.backgroundImage = `radial-gradient(circle at 50% 30%, rgba(31, 24, 18, 0.78) 0%, rgba(7, 6, 5, 0.92) 100%), url("${data.backgroundImageUrl}")`;
                document.body.style.backgroundSize = 'cover';
                document.body.style.backgroundPosition = 'center';
              }
            }
          }, (err) => console.warn('Slot remote config note:', err));

        // 2. Real-time User Diamond Wallet Sync
        if (this.userId) {
          this.db.collection('Users').doc(this.userId)
            .onSnapshot((doc) => {
              if (doc && doc.exists) {
                const uData = doc.data() || {};
                const rName = uData.fullname || uData.name || uData.username || uData.displayName;
                if (rName) this.userName = rName;
                const rAvatar = uData.photoUrl || uData.avatarUrl || uData.avatar || uData.image;
                if (rAvatar) this.userAvatar = rAvatar;

                const rawBal = uData.diamonds ?? uData.diamond ?? uData.coins ?? uData.walletBalance ?? uData.balance;
                if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
                  this.coins = Number(rawBal);
                  this.updateHUD();
                }
                this.updateUserProfileUI();
              }
            }, (err) => console.warn('User balance sync error:', err));
        }
      } catch (e) {
        console.warn('Firebase init error:', e);
      }
    }

    // Flutter / Webview Bridge
    window.setUserProfile = (profile) => {
      try {
        if (!profile) return;
        const data = typeof profile === 'string' ? JSON.parse(profile) : profile;
        if (data.userId || data.uid) {
          this.userId = data.userId || data.uid;
          this.isRealUser = true;
          this.initFirebaseSync();
        }
        if (data.fullname || data.name || data.username) {
          this.userName = data.fullname || data.name || data.username;
        }
        if (data.photoUrl || data.avatar || data.avatarUrl) {
          this.userAvatar = data.photoUrl || data.avatar || data.avatarUrl;
        }
        const rawBal = data.diamonds ?? data.diamond ?? data.coins ?? data.balance ?? data.walletBalance;
        if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
          this.coins = Number(rawBal);
          this.updateHUD();
        }
        this.updateUserProfileUI();
      } catch (e) { }
    };

    window.addEventListener('message', (event) => {
      try {
        const data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
        if (data && (data.type === 'SET_USER' || data.type === 'USER_DATA')) {
          window.setUserProfile(data);
        }
      } catch (e) { }
    });
  }

  updateUserProfileUI() {
    const pill = document.getElementById('userPill');
    const avatar = document.getElementById('userAvatarImg');
    const name = document.getElementById('userNameText');
    if (this.isRealUser && pill && avatar && name) {
      pill.style.display = 'flex';
      if (this.userAvatar) avatar.src = this.userAvatar;
      if (this.userName) name.textContent = this.userName;
    }
  }

  showInsufficientDiamondsAlert(needed) {
    const existing = document.getElementById('insufficientDiamondsModal');
    if (existing) existing.remove();

    const modal = document.createElement('div');
    modal.id = 'insufficientDiamondsModal';
    modal.className = 'game-modal active';
    modal.innerHTML = `
      <div class="modal-box" style="max-width: 360px; text-align: center; border: 2px solid #ffd700; background: linear-gradient(135deg, #1a0826, #2d0b42); box-shadow: 0 10px 30px rgba(0,0,0,0.8);">
        <h2 style="color: #ffd700; margin-bottom: 10px; font-size: 20px;">Insufficient Diamonds!</h2>
        <p style="color: #fff; font-size: 14px; margin: 15px 0;">You need at least <strong>${needed.toLocaleString()}</strong> 💎 diamonds to spin.</p>
        <div style="display: flex; gap: 10px; justify-content: center; margin-top: 20px;">
          <button class="autoplay-opt-btn" onclick="document.getElementById('insufficientDiamondsModal').remove()" style="padding: 10px 20px; font-size: 14px; background: #555;">Close</button>
          <button class="autoplay-opt-btn" onclick="if(window.parent){window.parent.postMessage({type:'RECHARGE_WALLET'},'*');} document.getElementById('insufficientDiamondsModal').remove()" style="padding: 10px 20px; font-size: 14px; background: linear-gradient(135deg, #11998e, #38ef7d); border: none; color: #fff; font-weight: bold;">Get Diamonds</button>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
  }
}

// Global bootstrap
window.addEventListener('DOMContentLoaded', async () => {
  try {
    await window.assetManager.load();
    window.game = new SlotGame();
    console.log('King of the Castle Slot Game initialized successfully!');

    // Secret Owner Diagnostic (invisible to normal users)
    window.kotc_stats = () => {
      const p = window.game ? window.game.pool : null;
      if (!p) return 'Game not ready';
      console.log('%c👑 [KING OF THE CASTLE - SECRET OWNER REPORT] 👑', 'color: #ffd700; font-size: 16px; font-weight: bold;');
      console.table({
        'Total Bets Placed': p.totalBets.toLocaleString(),
        'Total Paid to Users': `${p.totalWins.toLocaleString()} (${p.getCurrentRtp()}%)`,
        'House Net Profit (28%)': p.houseRevenue.toLocaleString(),
        'Current RTP %': `${p.getCurrentRtp()}% (Max 80% Rule)`,
        'Prize Pool Reserve': p.prizePool.toLocaleString()
      });
      return 'Secret stats printed.';
    };
  } catch (err) {
    console.error('Initialization error:', err);
  }
});
