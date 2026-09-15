/**
 * Arabian Nights Gem Spin Slot - Main Application Controller
 */

class SlotApp {
  constructor() {
    this.engine = new SlotEngine();
    this.isSpinning = false;
    this.isTurbo = false;
    this.autoSpinsRemaining = 0;
    this.holdTimer = null;
    this.holdTriggered = false;

    // DOM Elements
    this.dom = {
      wrapper: document.getElementById('game-wrapper'),
      fxCanvas: document.getElementById('fx-canvas'),
      gridBox: document.getElementById('slot-grid-box'),
      reelCols: Array.from(document.querySelectorAll('.reel-col')),
      
      // Jackpot Values
      grandJackpot: document.getElementById('grand-jackpot-value'),
      majorJackpot: document.getElementById('major-jackpot-value'),
      minorJackpot: document.getElementById('minor-jackpot-value'),
      miniJackpot: document.getElementById('mini-jackpot-value'),
      
      // Balance & Win
      balance: document.getElementById('diamond-balance'),
      winBox: document.getElementById('win-box'),
      winAmount: document.getElementById('win-amount-text'),
      
      // Bet Controls
      betDisplay: document.getElementById('bet-display'),
      btnMinus: document.getElementById('btn-minus'),
      btnPlus: document.getElementById('btn-plus'),
      
      // Action Buttons
      btnSpin: document.getElementById('btn-spin'),
      spinText: document.getElementById('spin-btn-text'),
      autoSpinBadge: document.getElementById('auto-spin-badge'),
      btnTurbo: document.getElementById('btn-turbo'),
      btnSound: document.getElementById('btn-sound'),
      soundIconOn: document.getElementById('sound-icon-on'),
      soundIconOff: document.getElementById('sound-icon-off'),
      btnRulesDropdown: document.getElementById('btn-rules-dropdown'),
      autoSpinTip: document.getElementById('auto-spin-tip'),
      
      // Hold & Spin
      holdSpinBar: document.getElementById('hold-spin-bar'),
      orb1: document.getElementById('orb-1'),
      orb2: document.getElementById('orb-2'),
      orb3: document.getElementById('orb-3'),

      // Modals
      modalRules: document.getElementById('modal-rules'),
      modalRulesClose: document.getElementById('modal-rules-close'),
      modalAutospin: document.getElementById('modal-autospin'),
      modalAutospinClose: document.getElementById('modal-autospin-close'),
      modalMegawin: document.getElementById('megawin-modal'),
      megawinAmount: document.getElementById('megawin-amount'),
      btnMegawinCollect: document.getElementById('megawin-collect-btn'),

      // Containers
      paytableContainer: document.getElementById('paytable-container'),
      paylinesDiagramContainer: document.getElementById('paylines-diagram-container'),

      // Player Profile & Live Icons
      playerPill: document.getElementById('player-profile-pill'),
      playerAvatar: document.getElementById('player-avatar-img'),
      playerName: document.getElementById('player-name-text'),
      topDiamondIcon: document.getElementById('top-diamond-icon')
    };

    this.currentBetIndex = CONFIG.DEFAULT_BET_INDEX;
    this.db = null;
    this.walletUnsub = null;
    this.userId = null;
    this.userName = 'Player';
    this.userAvatar = '';
  }

  init() {
    this.parseQueryParams();
    this.initFirebaseSync();
    EFFECTS.init(this.dom.fxCanvas);
    this.updateJackpotDisplay();
    this.updateBalanceDisplay();
    this.renderGrid();
    this.buildPaytableModal();
    this.buildPaylinesDiagram();
    this.bindEvents();
    this.setupFlutterBridge();

    // Auto hide tooltip after 5 seconds
    setTimeout(() => {
      if (this.dom.autoSpinTip) {
        this.dom.autoSpinTip.style.transition = 'opacity 0.8s ease';
        this.dom.autoSpinTip.style.opacity = '0';
        setTimeout(() => this.dom.autoSpinTip.remove(), 800);
      }
    }, 5500);
  }

  parseQueryParams() {
    try {
      const params = new URLSearchParams(window.location.search);
      const diamonds = params.get('diamonds') || params.get('coins');
      if (diamonds !== null) {
        const val = parseInt(diamonds, 10);
        if (!isNaN(val) && val >= 0) {
          this.engine.balance = val;
        }
      }

      const rtp = params.get('rtp');
      if (rtp !== null) {
        this.engine.setTargetRtp(parseFloat(rtp));
      }

      const name = params.get('name');
      if (name) {
        this.userName = decodeURIComponent(name);
      }

      const userId = params.get('userId') || params.get('uid');
      if (userId) {
        this.userId = userId;
      }
    } catch (e) {
      console.warn('Error reading URL query params:', e);
    }
  }

  setupFlutterBridge() {
    // Global hook called by Flutter Html5GameSheet / WebView
    window.setUserProfile = (profile) => {
      if (!profile) return;
      try {
        const data = typeof profile === 'string' ? JSON.parse(profile) : profile;
        if (data.userId || data.uid) {
          this.userId = data.userId || data.uid;
          this.initFirebaseSync();
        }
        if (data.name || data.fullname || data.username) {
          this.userName = data.name || data.fullname || data.username;
        }
        if (data.avatar || data.photoUrl || data.profilePic || data.image) {
          this.userAvatar = data.avatar || data.photoUrl || data.profilePic || data.image;
        }
        this.updateUserProfileUI();
        if (data.diamonds !== undefined) {
          const val = parseInt(data.diamonds, 10);
          if (!isNaN(val)) {
            this.engine.balance = val;
            this.updateBalanceDisplay();
          }
        }
        if (data.rtp) {
          this.engine.setTargetRtp(parseFloat(data.rtp));
        }
      } catch (e) {
        console.warn('setUserProfile error:', e);
      }
    };
  }

  // --- Real-time Firebase Firestore Sync & Live Diamond Wallet ---
  initFirebaseSync() {
    if (typeof firebase !== 'undefined') {
      try {
        if (firebase.apps.length === 0) {
          firebase.initializeApp({ projectId: 'imchat-84519' });
        }
        this.db = firebase.firestore();

        // 1. Live Remote RTP Config Listener from config/html5_gem_spin_slot
        this.db.collection('config').doc('html5_gem_spin_slot')
          .onSnapshot((doc) => {
            if (doc && doc.exists) {
              const data = doc.data();
              if (data.targetRtp) {
                this.engine.setTargetRtp(parseFloat(data.targetRtp));
              }
            }
          }, (err) => console.warn('Slot remote config note:', err));

        // 2. Real-time User Diamond Wallet Listener on Users/{userId}
        this.initUserWalletSync();

        // 3. Real-time Global App Theme Diamond Icon Listener from global_settings/app_theme
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
            }, () => {});
        } catch (e) {}
      } catch (e) {
        console.warn('Firebase init note:', e);
      }
    }
  }

  initUserWalletSync() {
    if (!this.db || !this.userId) return;
    if (this.walletUnsub) {
      try { this.walletUnsub(); } catch (_) {}
      this.walletUnsub = null;
    }

    const handleUserData = (doc) => {
      if (doc && doc.exists) {
        const uData = doc.data() || {};
        const realName = uData.fullname || uData.name || uData.username || uData.displayName;
        if (realName) this.userName = realName;

        const realAvatar = uData.photoUrl || uData.profilePic || uData.avatarUrl || uData.image || uData.avatar;
        if (realAvatar) this.userAvatar = realAvatar;

        this.updateUserProfileUI();

        // In IMChat, wallet currency is strictly in 'diamonds' (1 Coin = 1 Diamond)
        const rawBal = uData.diamonds ?? uData.diamond ?? uData.coins ?? uData.walletBalance ?? uData.balance;
        if (rawBal !== undefined && rawBal !== null && !isNaN(Number(rawBal))) {
          this.engine.balance = Number(rawBal);
          this.updateBalanceDisplay();
        }
      }
    };

    try {
      this.walletUnsub = this.db.collection('Users').doc(this.userId).onSnapshot(handleUserData, (err) => console.warn('Wallet listener note:', err));
    } catch (e) {
      console.warn('Wallet sync error:', e);
    }
  }

  updateUserProfileUI() {
    if (this.dom.playerPill) {
      if (this.userId) {
        this.dom.playerPill.style.display = 'inline-flex';
        if (this.dom.playerName && this.userName) {
          this.dom.playerName.textContent = this.userName;
        }
        if (this.dom.playerAvatar && this.userAvatar) {
          this.dom.playerAvatar.src = this.userAvatar;
        }
      }
    }
  }

  updateAllDiamondIcons(url) {
    if (!url) return;
    const icons = document.querySelectorAll('.diamond-icon, .win-diamond-img');
    icons.forEach(img => {
      if (img.tagName === 'IMG') {
        img.src = url;
      }
    });
  }

  notifyBalanceChange() {
    const payload = JSON.stringify({
      type: 'BALANCE_UPDATE',
      action: 'BALANCE_UPDATE',
      userId: this.userId || '',
      diamonds: this.engine.balance,
      currentWin: this.engine.currentWin
    });

    if (window.FlutterBridge) {
      try { window.FlutterBridge.postMessage(payload); } catch (_) {}
    } else if (window.FlutterChannel) {
      try { window.FlutterChannel.postMessage(payload); } catch (_) {}
    }
    if (window.parent && window.parent !== window) {
      try { window.parent.postMessage(payload, '*'); } catch (_) {}
    }
  }

  // Format numbers with commas (e.g. 10,000)
  formatNumber(num) {
    return Number(num).toLocaleString('en-US');
  }

  updateJackpotDisplay() {
    const jackpots = this.engine.getJackpotAmounts();
    this.dom.grandJackpot.textContent = this.formatNumber(jackpots.GRAND);
    this.dom.majorJackpot.textContent = this.formatNumber(jackpots.MAJOR);
    this.dom.minorJackpot.textContent = this.formatNumber(jackpots.MINOR);
    this.dom.miniJackpot.textContent = this.formatNumber(jackpots.MINI);
  }

  updateBalanceDisplay() {
    this.dom.balance.textContent = this.formatNumber(this.engine.balance);
  }

  // Render initial or updated grid into DOM
  renderGrid() {
    this.dom.reelCols.forEach((colEl, colIndex) => {
      const wrapper = colEl.querySelector('.reel-cells-wrapper');
      wrapper.innerHTML = '';

      for (let rowIndex = 0; rowIndex < CONFIG.ROW_COUNT; rowIndex++) {
        const cellData = this.engine.grid[colIndex][rowIndex];
        const cell = document.createElement('div');
        cell.className = 'symbol-cell';
        cell.dataset.col = colIndex;
        cell.dataset.row = rowIndex;

        // Render symbol SVG
        let svgHtml = '';
        if (cellData) {
          if (cellData.id === 'ruby') {
            svgHtml = SYMBOL_RENDERERS.ruby(cellData.value || '5');
          } else if (cellData.id === 'emerald') {
            svgHtml = SYMBOL_RENDERERS.emerald(cellData.tier || 'MINI');
          } else if (SYMBOL_RENDERERS[cellData.id]) {
            svgHtml = SYMBOL_RENDERERS[cellData.id]();
          }
        }
        cell.innerHTML = svgHtml;

        // Check if bubble is on this cell
        if (this.engine.isBubbleAt(colIndex, rowIndex)) {
          const bubble = document.createElement('div');
          bubble.className = 'bubble-wrap';
          cell.appendChild(bubble);
        }

        // In Hold & Spin mode, check if locked
        if (this.engine.mode === 'HOLD_SPIN') {
          const isLocked = this.engine.lockedGems.some(g => g.col === colIndex && g.row === rowIndex);
          if (isLocked) {
            cell.classList.add('gem-locked');
          }
        }

        wrapper.appendChild(cell);
      }
    });
  }

  // Roll up win amount in WIN box
  animateWinRollup(targetAmount, duration = 1000) {
    return new Promise(resolve => {
      const startAmount = this.engine.currentWin;
      this.engine.currentWin = targetAmount;
      const startTime = performance.now();

      const step = (now) => {
        const progress = Math.min(1, (now - startTime) / duration);
        const current = Math.round(startAmount + (targetAmount - startAmount) * progress);
        this.dom.winAmount.textContent = this.formatNumber(current);

        if (Math.random() < 0.4) {
          SOUND.playCoinTick();
        }

        if (progress < 1) {
          requestAnimationFrame(step);
        } else {
          this.dom.winAmount.textContent = this.formatNumber(targetAmount);
          resolve();
        }
      };
      requestAnimationFrame(step);
    });
  }

  // Populate Payout Table modal tab
  buildPaytableModal() {
    this.dom.paytableContainer.innerHTML = '';
    const order = ['palm', 'moon', 'tent', 'falcon', 'camel', 'dagger', 'lamp', 'chest', 'wild'];

    order.forEach(id => {
      const sym = CONFIG.SYMBOLS[id.toUpperCase()];
      if (!sym) return;

      const card = document.createElement('div');
      card.className = 'paytable-card';

      const svgWrap = document.createElement('div');
      svgWrap.innerHTML = SYMBOL_RENDERERS[id]();

      const details = document.createElement('div');
      details.className = 'payout-lines';
      details.innerHTML = `
        <div style="color:#fef08a; font-weight:800; margin-bottom:2px;">${sym.name}</div>
        <div>5 - ${sym.payouts[5]}x</div>
        <div>4 - ${sym.payouts[4]}x</div>
        <div>3 - ${sym.payouts[3]}x</div>
      `;

      card.appendChild(svgWrap);
      card.appendChild(details);
      this.dom.paytableContainer.appendChild(card);
    });
  }

  // Populate 20 Paylines visual diagrams
  buildPaylinesDiagram() {
    this.dom.paylinesDiagramContainer.innerHTML = '';
    CONFIG.PAYLINES.forEach((linePattern, idx) => {
      const card = document.createElement('div');
      card.className = 'payline-mini-card';

      const title = document.createElement('div');
      title.style.fontSize = '10px';
      title.style.fontWeight = '700';
      title.style.color = '#c084fc';
      title.textContent = `Line ${idx + 1}`;

      const dotsBox = document.createElement('div');
      dotsBox.className = 'payline-mini-dots';

      for (let r = 0; r < CONFIG.ROW_COUNT; r++) {
        for (let c = 0; c < CONFIG.REEL_COUNT; c++) {
          const dot = document.createElement('div');
          dot.className = 'mini-dot';
          if (linePattern[c] === r) {
            dot.classList.add('active');
          }
          dotsBox.appendChild(dot);
        }
      }

      card.appendChild(title);
      card.appendChild(dotsBox);
      this.dom.paylinesDiagramContainer.appendChild(card);
    });
  }

  // Main Spin Handler
  async handleSpin() {
    if (this.isSpinning) return;

    if (this.engine.mode === 'HOLD_SPIN') {
      await this.executeHoldRespin();
      return;
    }

    // Check balance
    if (this.engine.balance < this.engine.bet) {
      alert("Not enough diamonds! Please refill balance.");
      this.stopAutoSpin();
      return;
    }

    this.isSpinning = true;
    EFFECTS.clearPaylines();

    // Deduct bet
    this.engine.balance -= this.engine.bet;
    this.updateBalanceDisplay();
    this.notifyBalanceChange();
    this.dom.winAmount.textContent = '0';
    this.engine.currentWin = 0;

    // Real-time Firestore user diamond wallet deduction (1 Coin = 1 Diamond)
    if (this.userId && this.db) {
      this.db.collection('Users').doc(this.userId).update({
        diamonds: firebase.firestore.FieldValue.increment(-this.engine.bet)
      }).catch((err) => console.warn('Wallet bet deduct error:', err));

      this.db.collection('game_history').add({
        userId: this.userId,
        userName: this.userName || 'Player',
        userAvatar: this.userAvatar || '',
        gameId: 'arabian_spin_game',
        gameCode: 'html5_gem_spin_slot',
        type: 'BET',
        betAmount: this.engine.bet,
        timestamp: firebase.firestore.FieldValue.serverTimestamp()
      }).catch(() => {});
    }

    SOUND.startSpinSound();

    // Start reel blur animations
    this.dom.reelCols.forEach(col => col.classList.add('spinning'));

    // Generate spin result in background
    const result = this.engine.generateSpinResult();

    const spinDuration = this.isTurbo ? CONFIG.TIMINGS.SPIN_TURBO_DURATION : CONFIG.TIMINGS.SPIN_NORMAL_DURATION;
    const stopDelay = this.isTurbo ? CONFIG.TIMINGS.TURBO_REEL_STOP_DELAY : CONFIG.TIMINGS.REEL_STOP_DELAY;

    // Staggered stop for reels
    for (let c = 0; c < CONFIG.REEL_COUNT; c++) {
      await new Promise(r => setTimeout(r, spinDuration / CONFIG.REEL_COUNT + (c === 0 ? 0 : stopDelay)));
      this.dom.reelCols[c].classList.remove('spinning');
      this.renderColumn(c, result.grid[c]);
      SOUND.playReelStop(c);
    }

    SOUND.stopSpinSound();

    // Evaluate Wins
    if (result.lineWins.length > 0) {
      SOUND.playWinLine();
      EFFECTS.drawPaylines(result.lineWins, this.dom.reelCols, this.dom.gridBox);
      
      // Highlight winning symbol cells
      result.lineWins.forEach(win => {
        win.positions.forEach(pos => {
          const cell = this.dom.reelCols[pos.col].children[0].children[pos.row];
          if (cell) cell.classList.add('winner');
        });
      });

      // Roll up win amount
      await this.animateWinRollup(result.totalWin, 800);
      this.engine.balance += result.totalWin;
      this.updateBalanceDisplay();
      this.notifyBalanceChange();

      // Real-time Firestore user diamond credit
      if (this.userId && this.db && result.totalWin > 0) {
        this.db.collection('Users').doc(this.userId).update({
          diamonds: firebase.firestore.FieldValue.increment(result.totalWin),
          totalDiamonds: firebase.firestore.FieldValue.increment(result.totalWin)
        }).catch((err) => console.warn('Wallet win credit error:', err));

        this.db.collection('game_history').add({
          userId: this.userId,
          userName: this.userName || 'Player',
          userAvatar: this.userAvatar || '',
          gameId: 'arabian_spin_game',
          gameCode: 'html5_gem_spin_slot',
          type: 'WIN',
          winAmount: result.totalWin,
          betAmount: this.engine.bet,
          timestamp: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});
      }

      // Check Mega Win
      if (result.totalWin >= this.engine.bet * 15) {
        this.showMegaWin(result.totalWin);
      }
    }

    // Check Hold & Spin Trigger
    if (result.triggerHoldSpin) {
      this.stopAutoSpin();
      await new Promise(r => setTimeout(r, 600));
      this.startHoldAndSpinSequence(result.gemsFound);
      this.isSpinning = false;
      return;
    }

    this.isSpinning = false;

    // Continue auto-spin if active
    if (this.autoSpinsRemaining > 0) {
      this.autoSpinsRemaining--;
      this.updateAutoSpinBadge();
      if (this.autoSpinsRemaining > 0) {
        setTimeout(() => this.handleSpin(), 500);
      } else {
        this.stopAutoSpin();
      }
    }
  }

  // Render individual reel column upon stop
  renderColumn(colIndex, colData) {
    const wrapper = this.dom.reelCols[colIndex].querySelector('.reel-cells-wrapper');
    wrapper.innerHTML = '';

    for (let rowIndex = 0; rowIndex < CONFIG.ROW_COUNT; rowIndex++) {
      const cellData = colData[rowIndex];
      const cell = document.createElement('div');
      cell.className = 'symbol-cell';
      cell.dataset.col = colIndex;
      cell.dataset.row = rowIndex;

      let svgHtml = '';
      if (cellData) {
        if (cellData.id === 'ruby') {
          svgHtml = SYMBOL_RENDERERS.ruby(cellData.value || '5');
        } else if (cellData.id === 'emerald') {
          svgHtml = SYMBOL_RENDERERS.emerald(cellData.tier || 'MINI');
        } else if (SYMBOL_RENDERERS[cellData.id]) {
          svgHtml = SYMBOL_RENDERERS[cellData.id]();
        }
      }
      cell.innerHTML = svgHtml;

      if (this.engine.isBubbleAt(colIndex, rowIndex)) {
        const bubble = document.createElement('div');
        bubble.className = 'bubble-wrap';
        cell.appendChild(bubble);
      }

      wrapper.appendChild(cell);
    }
  }

  // Trigger Hold & Spin mode
  startHoldAndSpinSequence(gemsFound) {
    SOUND.playHoldSpinTrigger();
    this.engine.startHoldAndSpin(gemsFound);

    // Update UI for Hold & Spin
    this.dom.holdSpinBar.classList.add('active');
    this.updateHoldOrbs(3);
    this.dom.btnSpin.classList.add('hold-mode');
    this.dom.spinText.textContent = 'FREE SPIN';

    // Lock gems visually
    this.renderGrid();
  }

  updateHoldOrbs(count) {
    this.dom.orb1.classList.toggle('lit', count >= 1);
    this.dom.orb2.classList.toggle('lit', count >= 2);
    this.dom.orb3.classList.toggle('lit', count >= 3);
  }

  // Single respin in Hold & Spin mode
  async executeHoldRespin() {
    this.isSpinning = true;
    SOUND.startSpinSound();

    // Spin only unlocked columns
    this.dom.reelCols.forEach(col => col.classList.add('spinning'));

    await new Promise(r => setTimeout(r, this.isTurbo ? 500 : 900));

    this.dom.reelCols.forEach(col => col.classList.remove('spinning'));
    SOUND.stopSpinSound();

    const res = this.engine.executeHoldSpin();

    // Render updated locked grid
    this.renderGrid();

    // If new gems landed
    if (res.newGemsLanded.length > 0) {
      SOUND.playGemLock();
      res.newGemsLanded.forEach(gem => {
        const cell = this.dom.reelCols[gem.col].children[0].children[gem.row];
        if (cell) {
          const rect = cell.getBoundingClientRect();
          EFFECTS.spawnGemSparks(rect.left + rect.width / 2, rect.top + rect.height / 2, '#38bdf8');
        }
      });
    }

    this.updateHoldOrbs(res.holdSpinsLeft);

    if (res.isComplete) {
      await this.finishHoldAndSpin(res.totalPrize);
    }

    this.isSpinning = false;
  }

  // Finish Hold & Spin: Sequential Energy Beam Collection
  async finishHoldAndSpin(totalPrize) {
    await new Promise(r => setTimeout(r, 600));

    // Gather all locked gem DOM cells
    const gemCells = [];
    this.engine.lockedGems.forEach(g => {
      const cell = this.dom.reelCols[g.col].children[0].children[g.row];
      if (cell) gemCells.push(cell);
    });

    // Animate energy beam zapping each gem to WIN box
    await EFFECTS.animateEnergyBeam(gemCells, this.dom.winBox);

    // Roll up win
    await this.animateWinRollup(totalPrize, 1200);
    this.engine.balance += totalPrize;
    this.updateBalanceDisplay();
    this.notifyBalanceChange();

    // Real-time Firestore user diamond credit for Hold & Spin Jackpot
    if (this.userId && this.db && totalPrize > 0) {
      this.db.collection('Users').doc(this.userId).update({
        diamonds: firebase.firestore.FieldValue.increment(totalPrize),
        totalDiamonds: firebase.firestore.FieldValue.increment(totalPrize)
      }).catch((err) => console.warn('Hold & Spin credit error:', err));

      this.db.collection('game_history').add({
        userId: this.userId,
        userName: this.userName || 'Player',
        userAvatar: this.userAvatar || '',
        gameId: 'arabian_spin_game',
        gameCode: 'html5_gem_spin_slot',
        type: 'JACKPOT_WIN',
        winAmount: totalPrize,
        betAmount: this.engine.bet,
        timestamp: firebase.firestore.FieldValue.serverTimestamp()
      }).catch(() => {});
    }

    // Show celebration if large win
    if (totalPrize >= this.engine.bet * 10) {
      this.showMegaWin(totalPrize);
    }

    // Reset back to Base Game mode
    this.engine.mode = 'BASE';
    this.dom.holdSpinBar.classList.remove('active');
    this.dom.btnSpin.classList.remove('hold-mode');
    this.dom.spinText.textContent = 'SPIN!';
  }

  showMegaWin(amount) {
    SOUND.playMegaWin();
    EFFECTS.spawnCoinExplosion(90);
    this.dom.megawinAmount.textContent = this.formatNumber(amount);
    this.dom.modalMegawin.classList.add('active');
  }

  updateAutoSpinBadge() {
    if (this.autoSpinsRemaining > 0) {
      this.dom.autoSpinBadge.style.display = 'block';
      this.dom.autoSpinBadge.textContent = this.autoSpinsRemaining > 900 ? '∞' : this.autoSpinsRemaining;
    } else {
      this.dom.autoSpinBadge.style.display = 'none';
    }
  }

  stopAutoSpin() {
    this.autoSpinsRemaining = 0;
    this.updateAutoSpinBadge();
  }

  // Event Listeners
  bindEvents() {
    // Spin button click and long press
    this.dom.btnSpin.addEventListener('pointerdown', () => {
      this.holdTriggered = false;
      this.holdTimer = setTimeout(() => {
        this.holdTriggered = true;
        this.dom.modalAutospin.classList.add('active');
      }, 550);
    });

    this.dom.btnSpin.addEventListener('pointerup', () => {
      if (this.holdTimer) clearTimeout(this.holdTimer);
      if (!this.holdTriggered) {
        if (this.autoSpinsRemaining > 0) {
          this.stopAutoSpin();
        } else {
          this.handleSpin();
        }
      }
    });

    this.dom.btnSpin.addEventListener('pointerleave', () => {
      if (this.holdTimer) clearTimeout(this.holdTimer);
    });

    // Spacebar to spin
    window.addEventListener('keydown', (e) => {
      if (e.code === 'Space' && !this.isSpinning) {
        e.preventDefault();
        this.handleSpin();
      }
    });

    // Bet Minus
    this.dom.btnMinus.addEventListener('click', () => {
      SOUND.playClick();
      if (this.currentBetIndex > 0) {
        this.currentBetIndex--;
        const newBet = CONFIG.BETS[this.currentBetIndex];
        this.engine.setBet(newBet);
        this.dom.betDisplay.textContent = this.formatNumber(newBet);
        this.updateJackpotDisplay();
      }
    });

    // Bet Plus
    this.dom.btnPlus.addEventListener('click', () => {
      SOUND.playClick();
      if (this.currentBetIndex < CONFIG.BETS.length - 1) {
        this.currentBetIndex++;
        const newBet = CONFIG.BETS[this.currentBetIndex];
        this.engine.setBet(newBet);
        this.dom.betDisplay.textContent = this.formatNumber(newBet);
        this.updateJackpotDisplay();
      }
    });

    // Turbo toggle
    this.dom.btnTurbo.addEventListener('click', () => {
      SOUND.playClick();
      this.isTurbo = !this.isTurbo;
      this.dom.btnTurbo.classList.toggle('active', this.isTurbo);
    });

    // Sound toggle
    this.dom.btnSound.addEventListener('click', () => {
      const isMuted = SOUND.toggleMute();
      this.dom.soundIconOn.style.display = isMuted ? 'none' : 'block';
      this.dom.soundIconOff.style.display = isMuted ? 'block' : 'none';
      this.dom.btnSound.classList.toggle('active-green', !isMuted);
    });

    // Rules Modal Open / Close
    this.dom.btnRulesDropdown.addEventListener('click', () => {
      SOUND.playClick();
      this.dom.modalRules.classList.add('active');
    });
    this.dom.modalRulesClose.addEventListener('click', () => {
      SOUND.playClick();
      this.dom.modalRules.classList.remove('active');
    });

    // Rules Tabs
    const tabs = Array.from(document.querySelectorAll('.modal-tab'));
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        SOUND.playClick();
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        const tabKey = tab.dataset.tab;
        document.getElementById('tab-payouts').style.display = tabKey === 'payouts' ? 'block' : 'none';
        document.getElementById('tab-holdspin').style.display = tabKey === 'holdspin' ? 'block' : 'none';
        document.getElementById('tab-paylines').style.display = tabKey === 'paylines' ? 'block' : 'none';
      });
    });

    // Auto-spin count selections
    document.querySelectorAll('.autospin-opt').forEach(btn => {
      btn.addEventListener('click', () => {
        SOUND.playClick();
        this.autoSpinsRemaining = parseInt(btn.dataset.count, 10);
        this.updateAutoSpinBadge();
        this.dom.modalAutospin.classList.remove('active');
        this.handleSpin();
      });
    });
    this.dom.modalAutospinClose.addEventListener('click', () => {
      this.dom.modalAutospin.classList.remove('active');
    });

    // Mega Win Collect button
    this.dom.btnMegawinCollect.addEventListener('click', () => {
      SOUND.playClick();
      this.dom.modalMegawin.classList.remove('active');
    });

    // Back Button (Close Game via FlutterBridge)
    const btnBack = document.getElementById('btn-back');
    if (btnBack) {
      btnBack.addEventListener('click', () => {
        SOUND.playClick();
        if (window.FlutterBridge) {
          try { window.FlutterBridge.postMessage('CLOSE_GAME'); } catch (_) {}
        } else if (window.FlutterChannel) {
          try { window.FlutterChannel.postMessage('CLOSE_GAME'); } catch (_) {}
        } else if (window.parent && window.parent !== window) {
          try { window.parent.postMessage('CLOSE_GAME', '*'); } catch (_) {}
        } else {
          window.history.back();
        }
      });
    }

    // Refill / Open Wallet when diamond badge is clicked
    const diamondBadge = document.getElementById('diamond-badge');
    if (diamondBadge) {
      diamondBadge.addEventListener('click', () => {
        SOUND.playClick();
        if (window.FlutterBridge || window.FlutterChannel) {
          const msg = JSON.stringify({ action: 'OPEN_WALLET', type: 'wallet' });
          try { if (window.FlutterBridge) window.FlutterBridge.postMessage(msg); } catch (_) {}
          try { if (window.FlutterChannel) window.FlutterChannel.postMessage(msg); } catch (_) {}
        } else {
          this.engine.balance += 25000;
          this.updateBalanceDisplay();
          EFFECTS.spawnGemSparks(window.innerWidth - 60, 30, '#38bdf8');
        }
      });
    }
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  const app = new SlotApp();
  app.init();
  window.app = app; // For debugging and automated testing
});
