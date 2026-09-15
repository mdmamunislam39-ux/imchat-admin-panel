/**
 * Arabian Nights Gem Spin Slot - Slot Engine
 * Handles Reel Matrix, RNG, Paylines, Bubbles, and Hold & Spin State Machine
 */

class SlotEngine {
  constructor() {
    this.bet = CONFIG.BETS[CONFIG.DEFAULT_BET_INDEX];
    this.balance = CONFIG.INITIAL_BALANCE;
    this.currentWin = 0;
    
    // Grid: 5 columns x 4 rows
    this.grid = [];
    this.initGrid();
    
    // Ascending Bubbles: array of { col, row }
    this.bubbles = [
      { col: 0, row: 1 },
      { col: 3, row: 2 },
      { col: 4, row: 1 }
    ];
    
    // Hold & Spin State
    this.mode = 'BASE'; // 'BASE' or 'HOLD_SPIN'
    this.holdSpinsLeft = 3;
    this.lockedGems = []; // array of { col, row, type, value, tier }
    
    // RTP & Profit Configuration (Target 75% Return to Player, 25% App Profit)
    this.targetRtp = 75.0; // 75% RTP
    this.houseMargin = 25.0; // 25% App Profit
    this.totalWagered = 0;
    this.totalPayout = 0;
    
    // Callbacks
    this.onStateChange = null;
  }

  initGrid() {
    this.grid = [];
    const regularIds = ['palm', 'moon', 'tent', 'falcon', 'camel', 'dagger', 'lamp', 'chest'];
    for (let c = 0; c < CONFIG.REEL_COUNT; c++) {
      const col = [];
      for (let r = 0; r < CONFIG.ROW_COUNT; r++) {
        const randId = regularIds[Math.floor(Math.random() * regularIds.length)];
        col.push({
          id: randId,
          type: 'regular',
          value: null,
          tier: null
        });
      }
      this.grid.push(col);
    }
  }

  setBet(newBet) {
    this.bet = newBet;
  }

  setTargetRtp(newRtp) {
    const rtp = Math.max(50, Math.min(95, parseFloat(newRtp) || 75.0));
    this.targetRtp = rtp;
    this.houseMargin = 100.0 - rtp;
  }

  getRtpStats() {
    const currentRtp = this.totalWagered > 0 
      ? ((this.totalPayout / this.totalWagered) * 100).toFixed(2)
      : this.targetRtp.toFixed(2);
    return {
      targetRtp: this.targetRtp,
      houseMargin: this.houseMargin,
      currentRtp: parseFloat(currentRtp),
      totalWagered: this.totalWagered,
      totalPayout: this.totalPayout,
      netProfit: this.totalWagered - this.totalPayout
    };
  }

  // Get current jackpot amounts scaled to bet
  getJackpotAmounts() {
    return {
      MINI: this.bet * CONFIG.JACKPOTS.MINI,
      MINOR: this.bet * CONFIG.JACKPOTS.MINOR,
      MAJOR: this.bet * CONFIG.JACKPOTS.MAJOR,
      GRAND: this.bet * CONFIG.JACKPOTS.GRAND
    };
  }

  // Float existing bubbles up 1 row and spawn new ones
  updateBubblesBeforeSpin() {
    const updated = [];
    for (const b of this.bubbles) {
      const nextRow = b.row - 1;
      if (nextRow >= 0) {
        updated.push({ col: b.col, row: nextRow });
      }
    }

    // Chance to spawn 1 or 2 new bubbles in lower rows (rows 2 or 3)
    if (updated.length < 5 && Math.random() < 0.65) {
      const spawnCol = Math.floor(Math.random() * CONFIG.REEL_COUNT);
      const spawnRow = Math.floor(Math.random() * 2) + 2; // row 2 or 3
      if (!updated.some(b => b.col === spawnCol && b.row === spawnRow)) {
        updated.push({ col: spawnCol, row: spawnRow });
      }
    }

    this.bubbles = updated;
  }

  isBubbleAt(col, row) {
    return this.bubbles.some(b => b.col === col && b.row === row);
  }

  // Weighted random symbol generator
  getRandomSymbol(isHoldSpin = false) {
    if (isHoldSpin) {
      // In Hold & Spin: only blanks, rubies, and emeralds
      const roll = Math.random();
      if (roll < 0.22) {
        // Ruby gem
        const mults = [1, 2, 3, 5, 8, 10];
        const m = mults[Math.floor(Math.random() * mults.length)];
        const val = this.bet * m;
        return {
          id: 'ruby',
          type: 'bonus',
          value: val >= 1000 ? `${val / 1000}k` : `${val}`,
          numericValue: val,
          tier: null
        };
      } else if (roll < 0.27) {
        // Emerald jackpot
        const tierRoll = Math.random();
        let tier = 'MINI';
        if (tierRoll < 0.55) tier = 'MINI';
        else if (tierRoll < 0.85) tier = 'MINOR';
        else if (tierRoll < 0.96) tier = 'MAJOR';
        else tier = 'GRAND';
        
        const jackpots = this.getJackpotAmounts();
        return {
          id: 'emerald',
          type: 'jackpot',
          tier: tier,
          value: tier,
          numericValue: jackpots[tier]
        };
      } else {
        return null; // Blank cell in Hold & Spin
      }
    }

    // Regular base spin weighted pool
    let totalWeight = 0;
    for (const key in CONFIG.SYMBOLS) {
      totalWeight += CONFIG.SYMBOLS[key].weight;
    }

    let rnd = Math.random() * totalWeight;
    for (const key in CONFIG.SYMBOLS) {
      const s = CONFIG.SYMBOLS[key];
      if (rnd < s.weight) {
        if (s.id === 'ruby') {
          const mults = [1, 2, 3, 5];
          const m = mults[Math.floor(Math.random() * mults.length)];
          const val = this.bet * m;
          return {
            id: 'ruby',
            type: 'bonus',
            value: val >= 1000 ? `${val / 1000}k` : `${val}`,
            numericValue: val,
            tier: null
          };
        } else if (s.id === 'emerald') {
          const tiers = ['MINI', 'MINOR', 'MAJOR', 'GRAND'];
          const tier = tiers[Math.floor(Math.random() * (Math.random() < 0.8 ? 2 : 4))];
          const jackpots = this.getJackpotAmounts();
          return {
            id: 'emerald',
            type: 'jackpot',
            tier: tier,
            value: tier,
            numericValue: jackpots[tier]
          };
        }
        return {
          id: s.id,
          type: s.type,
          value: null,
          tier: null
        };
      }
      rnd -= s.weight;
    }

    return { id: 'palm', type: 'regular', value: null, tier: null };
  }

  // Execute Base Game Spin
  generateSpinResult() {
    this.totalWagered += this.bet;
    this.updateBubblesBeforeSpin();
    
    // Check RTP balancing: if running higher than target RTP, adjust hit chance
    const currentSessionRtp = this.totalWagered > 0 ? (this.totalPayout / this.totalWagered) * 100 : this.targetRtp;
    const shouldCoolDown = this.totalWagered > this.bet * 5 && currentSessionRtp > (this.targetRtp + 8);
    
    let attempts = 0;
    let newGrid, gemsFound, lineWins, totalWin, triggerHoldSpin;

    do {
      newGrid = [];
      gemsFound = [];

      for (let c = 0; c < CONFIG.REEL_COUNT; c++) {
        const col = [];
        for (let r = 0; r < CONFIG.ROW_COUNT; r++) {
          const symbol = this.getRandomSymbol(false);
          col.push(symbol);

          if (symbol.id === 'ruby' || symbol.id === 'emerald') {
            gemsFound.push({ col: c, row: r, symbol: symbol });
          }
        }
        newGrid.push(col);
      }

      this.grid = newGrid;
      lineWins = this.evaluatePaylines();
      totalWin = lineWins.reduce((sum, item) => sum + item.winAmount, 0);
      triggerHoldSpin = gemsFound.length >= 3;

      attempts++;
      // If cooling down to maintain 75% RTP and this roll is an outsized hit, re-roll up to 2 times
      if (shouldCoolDown && (totalWin > this.bet * 4 || triggerHoldSpin) && attempts < 2) {
        continue;
      }
      break;
    } while (attempts < 2);

    this.totalPayout += totalWin;

    return {
      grid: this.grid,
      bubbles: this.bubbles,
      lineWins: lineWins,
      totalWin: totalWin,
      gemsFound: gemsFound,
      triggerHoldSpin: triggerHoldSpin
    };
  }

  // Payline matching logic
  evaluatePaylines() {
    const wins = [];

    CONFIG.PAYLINES.forEach((linePattern, lineIndex) => {
      // Gather symbols along this line
      const lineSymbols = [];
      for (let col = 0; col < CONFIG.REEL_COUNT; col++) {
        const row = linePattern[col];
        lineSymbols.push(this.grid[col][row]);
      }

      // Determine match starting from col 0
      let matchSymbol = null;
      let matchCount = 0;
      let winningPositions = [];

      for (let col = 0; col < CONFIG.REEL_COUNT; col++) {
        const sym = lineSymbols[col];

        // Ruby and Emerald do not pay on regular paylines
        if (sym.id === 'ruby' || sym.id === 'emerald') {
          break;
        }

        if (col === 0) {
          matchSymbol = sym.id;
          matchCount = 1;
          winningPositions.push({ col: 0, row: linePattern[0] });
        } else {
          if (matchSymbol === 'wild') {
            if (sym.id !== 'wild') {
              matchSymbol = sym.id;
            }
            matchCount++;
            winningPositions.push({ col: col, row: linePattern[col] });
          } else if (sym.id === matchSymbol || sym.id === 'wild') {
            matchCount++;
            winningPositions.push({ col: col, row: linePattern[col] });
          } else {
            break;
          }
        }
      }

      if (matchCount >= 3 && matchSymbol) {
        const symConfig = CONFIG.SYMBOLS[matchSymbol.toUpperCase()];
        if (symConfig && symConfig.payouts && symConfig.payouts[matchCount]) {
          const payoutMult = symConfig.payouts[matchCount];
          const winAmount = Math.round(this.bet * payoutMult);
          wins.push({
            lineIndex: lineIndex,
            symbolId: matchSymbol,
            count: matchCount,
            multiplier: payoutMult,
            winAmount: winAmount,
            positions: winningPositions
          });
        }
      }
    });

    return wins;
  }

  // Start Hold & Spin Mode
  startHoldAndSpin(triggeringGems) {
    this.mode = 'HOLD_SPIN';
    this.holdSpinsLeft = 3;
    this.lockedGems = [];

    // Lock triggering gems
    triggeringGems.forEach(item => {
      this.lockedGems.push({
        col: item.col,
        row: item.row,
        id: item.symbol.id,
        type: item.symbol.type,
        value: item.symbol.value,
        numericValue: item.symbol.numericValue || (this.bet * 2),
        tier: item.symbol.tier
      });
    });
  }

  // Execute a single respin during Hold & Spin
  executeHoldSpin() {
    let newGemsLanded = [];

    for (let c = 0; c < CONFIG.REEL_COUNT; c++) {
      for (let r = 0; r < CONFIG.ROW_COUNT; r++) {
        const isLocked = this.lockedGems.some(g => g.col === c && g.row === r);
        if (!isLocked) {
          const sym = this.getRandomSymbol(true);
          if (sym) {
            const newGem = {
              col: c,
              row: r,
              id: sym.id,
              type: sym.type,
              value: sym.value,
              numericValue: sym.numericValue,
              tier: sym.tier
            };
            this.lockedGems.push(newGem);
            newGemsLanded.push(newGem);
          }
        }
      }
    }

    if (newGemsLanded.length > 0) {
      // Reset spins back to 3!
      this.holdSpinsLeft = 3;
    } else {
      this.holdSpinsLeft--;
    }

    const isComplete = this.holdSpinsLeft <= 0 || this.lockedGems.length >= (CONFIG.REEL_COUNT * CONFIG.ROW_COUNT);

    // Calculate total prize sum
    let totalPrize = 0;
    if (isComplete) {
      totalPrize = this.lockedGems.reduce((sum, g) => sum + g.numericValue, 0);
      // If all 20 positions filled, award Grand Jackpot bonus!
      if (this.lockedGems.length >= 20) {
        totalPrize += this.getJackpotAmounts().GRAND;
      }
      this.totalPayout += totalPrize;
    }

    return {
      newGemsLanded: newGemsLanded,
      lockedGems: [...this.lockedGems],
      holdSpinsLeft: this.holdSpinsLeft,
      isComplete: isComplete,
      totalPrize: totalPrize
    };
  }
}
