/**
 * Arabian Nights Gem Spin Slot - Configuration
 */

const CONFIG = {
  REEL_COUNT: 5,
  ROW_COUNT: 4,
  TOTAL_PAYLINES: 20,
  
  // Available Bets
  BETS: [5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000],
  DEFAULT_BET_INDEX: 4, // 100 default
  
  // Jackpot multipliers based on bet
  JACKPOTS: {
    MINI: 10,      // 10x bet
    MINOR: 20,     // 20x bet
    MAJOR: 30,     // 30x bet
    GRAND: 50      // 50x bet base up to 100x
  },
  
  // Symbols definition with payouts for 3, 4, 5 of a kind (multipliers of bet)
  SYMBOLS: {
    PALM: {
      id: 'palm',
      name: 'Palm Tree',
      type: 'regular',
      payouts: { 3: 0.3, 4: 1.0, 5: 2.0 },
      weight: 24
    },
    MOON: {
      id: 'moon',
      name: 'Crescent Moon & Star',
      type: 'regular',
      payouts: { 3: 0.5, 4: 1.2, 5: 3.0 },
      weight: 22
    },
    TENT: {
      id: 'tent',
      name: 'Bedouin Tent',
      type: 'regular',
      payouts: { 3: 1.0, 4: 1.5, 5: 5.0 },
      weight: 18
    },
    FALCON: {
      id: 'falcon',
      name: 'White Falcon',
      type: 'regular',
      payouts: { 3: 1.2, 4: 2.0, 5: 10.0 },
      weight: 16
    },
    CAMEL: {
      id: 'camel',
      name: 'Desert Camel',
      type: 'regular',
      payouts: { 3: 1.5, 4: 3.0, 5: 20.0 },
      weight: 14
    },
    DAGGER: {
      id: 'dagger',
      name: 'Arabian Dagger',
      type: 'regular',
      payouts: { 3: 2.0, 4: 5.0, 5: 30.0 },
      weight: 12
    },
    LAMP: {
      id: 'lamp',
      name: 'Magic Genie Lamp',
      type: 'regular',
      payouts: { 3: 3.0, 4: 10.0, 5: 50.0 },
      weight: 9
    },
    CHEST: {
      id: 'chest',
      name: 'Treasure Chest',
      type: 'regular',
      payouts: { 3: 5.0, 4: 50.0, 5: 100.0 },
      weight: 6
    },
    WILD: {
      id: 'wild',
      name: 'Wild Crystal',
      type: 'wild',
      payouts: { 3: 30.0, 4: 500.0, 5: 800.0 },
      weight: 4
    },
    RUBY: {
      id: 'ruby',
      name: 'Bonus Ruby',
      type: 'bonus',
      multipliers: [1, 2, 3, 4, 5, 8, 10], // Multipliers for ruby prize values
      weight: 6
    },
    EMERALD: {
      id: 'emerald',
      name: 'Jackpot Emerald',
      type: 'jackpot',
      tiers: ['MINI', 'MINOR', 'MAJOR', 'GRAND'],
      weight: 3
    }
  },
  
  // 20 Paylines defined by row index (0 to 3) for each of the 5 reels (col 0 to 4)
  PAYLINES: [
    [1, 1, 1, 1, 1], // Line 1: Row 1 horizontal
    [0, 0, 0, 0, 0], // Line 2: Row 0 horizontal
    [2, 2, 2, 2, 2], // Line 3: Row 2 horizontal
    [3, 3, 3, 3, 3], // Line 4: Row 3 horizontal
    [0, 1, 2, 1, 0], // Line 5: V shape top
    [3, 2, 1, 2, 3], // Line 6: Inverted V bottom
    [1, 2, 3, 2, 1], // Line 7: V shape middle-down
    [2, 1, 0, 1, 2], // Line 8: Inverted V middle-up
    [1, 0, 1, 2, 1], // Line 9: Wave
    [2, 3, 2, 1, 2], // Line 10: Wave
    [0, 1, 0, 1, 0], // Line 11: Zig-zag high
    [3, 2, 3, 2, 3], // Line 12: Zig-zag low
    [1, 2, 1, 2, 1], // Line 13: Zig-zag mid
    [2, 1, 2, 1, 2], // Line 14: Zig-zag mid-high
    [0, 0, 1, 2, 2], // Line 15: Step down
    [3, 3, 2, 1, 1], // Line 16: Step up
    [1, 1, 2, 3, 3], // Line 17: Step down low
    [2, 2, 1, 0, 0], // Line 18: Step up high
    [0, 1, 2, 3, 3], // Line 19: Long diagonal down
    [3, 2, 1, 0, 0]  // Line 20: Long diagonal up
  ],
  
  // Timing parameters (in milliseconds)
  TIMINGS: {
    SPIN_NORMAL_DURATION: 1600,
    SPIN_TURBO_DURATION: 600,
    REEL_STOP_DELAY: 220,
    TURBO_REEL_STOP_DELAY: 90,
    WIN_SHOW_DURATION: 1800,
    HOLD_SPIN_RESET_DELAY: 1200
  },
  
  // Initial demo balance
  INITIAL_BALANCE: 50000
};
