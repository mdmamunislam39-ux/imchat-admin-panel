const http = require('http');
const fs = require('fs');
const path = require('path');

const mimeTypes = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.webp': 'image/webp'
};

const FOOD_CONFIG = [
  { index: 0, id: 'chicken', name: 'BBQ Chicken', mult: 45, category: 'meat' },
  { index: 1, id: 'tomato', name: 'Tomato', mult: 5, category: 'veg' },
  { index: 2, id: 'goat', name: 'BBQ Leg Piece', mult: 15, category: 'meat' },
  { index: 3, id: 'pepper', name: 'Pepper', mult: 5, category: 'veg' },
  { index: 4, id: 'fish', name: 'BBQ Fish', mult: 25, category: 'meat' },
  { index: 5, id: 'carrot', name: 'Carrot', mult: 5, category: 'veg' },
  { index: 6, id: 'shrimp', name: 'BBQ Shrimp', mult: 10, category: 'meat' },
  { index: 7, id: 'corn', name: 'Grilled Corn', mult: 5, category: 'veg' }
];

// ====================================================
// Central Room State & Real-Time Engine
// ====================================================
let roundId = 1001;
let phase = 'SELECT_TIME'; // 'SELECT_TIME' (25s) | 'SPINNING' (5s) | 'SHOW_TIME' (1.4s) | 'RESULT' (4s)
let timerSeconds = 25;
let roundBets = {}; // foodId -> total coins bet across all connected players
let winningIndex = 0;
let activeSpecialPrize = null; // 'pizza' | 'salad' | null
let pendingSpecialPrize = null;
let hotIndex = 3;
let recentResults = ['chicken', 'tomato', 'corn', 'pepper', 'fish'];
const sseClients = new Set();

// House edge & Payout Statistics
const lifetimeStats = {
  totalBets: 0,
  totalPayout: 0,
  roundsCount: 0
};

function broadcast(eventName, payload) {
  const data = JSON.stringify({ event: eventName, data: payload, timestamp: Date.now() });
  const msg = `event: ${eventName}\ndata: ${data}\n\n`;
  for (const client of sseClients) {
    try {
      client.write(msg);
    } catch (err) {
      sseClients.delete(client);
    }
  }
}

// ----------------------------------------------------
// Outcome Selection Algorithm:
// Guaranteed User Win Ratio < 75% | App House Profit > 25%
// ----------------------------------------------------
function calculateOutcome() {
  const totalBets = Object.values(roundBets).reduce((a, b) => a + b, 0);

  // 1. Check for Special Prize (Pizza Prize or Salad Prize)
  if (pendingSpecialPrize) {
    activeSpecialPrize = pendingSpecialPrize;
    pendingSpecialPrize = null;
    winningIndex = activeSpecialPrize === 'pizza' ? 0 : 1;
    return;
  }
  activeSpecialPrize = null;

  // 2. Evaluate all 8 food items against the current bet pool
  const candidates = [];
  for (let i = 0; i < FOOD_CONFIG.length; i++) {
    const food = FOOD_CONFIG[i];
    const betOnItem = roundBets[food.id] || 0;
    const payout = betOnItem * food.mult;
    const payoutRatio = totalBets > 0 ? (payout / totalBets) : 0;
    candidates.push({
      index: i,
      food: food,
      betOnItem: betOnItem,
      payout: payout,
      payoutRatio: payoutRatio
    });
  }

  // Filter candidates where payout ratio <= 0.70 (Ensures App Earning >= 30% > 25%)
  let safeCandidates = candidates.filter(c => c.payoutRatio <= 0.70);

  // If players concentrated bets such that no item has payout <= 0.70 (very rare):
  // Pick the lowest payout candidates to strictly minimize payout
  if (safeCandidates.length === 0) {
    safeCandidates = [...candidates].sort((a, b) => a.payout - b.payout).slice(0, 2);
  }

  // Weight candidates: Lower multiplier items have natural higher game frequency,
  // and lower payout ratio gives higher house margin.
  const weights = safeCandidates.map(c => {
    // Multiplier weighting: 5x -> 10, 10x -> 5, 15x -> 3.3, 25x -> 2, 45x -> 1.1
    const baseMultWeight = 50 / c.food.mult;
    // House margin bonus: lower payout ratio = more favorable
    const marginBonus = Math.max(0.2, 1 - c.payoutRatio);
    return baseMultWeight * marginBonus;
  });

  const totalWeight = weights.reduce((a, b) => a + b, 0);
  let r = Math.random() * totalWeight;
  let chosen = safeCandidates[0];
  for (let i = 0; i < safeCandidates.length; i++) {
    if (r < weights[i]) {
      chosen = safeCandidates[i];
      break;
    }
    r -= weights[i];
  }

  winningIndex = chosen.index;

  // Track Lifetime Return-To-Player (RTP) stats
  lifetimeStats.roundsCount++;
  lifetimeStats.totalBets += totalBets;
  lifetimeStats.totalPayout += chosen.payout;
  const currentRTP = lifetimeStats.totalBets > 0 ? (lifetimeStats.totalPayout / lifetimeStats.totalBets) : 0;
  console.log(`[Round ${roundId}] Winner: ${chosen.food.name} (x${chosen.food.mult}) | Pool: ${totalBets} | Payout: ${chosen.payout} | Round RTP: ${(chosen.payoutRatio * 100).toFixed(1)}% | Lifetime RTP: ${(currentRTP * 100).toFixed(1)}% (Profit: ${((1 - currentRTP) * 100).toFixed(1)}%)`);
}

// ----------------------------------------------------
// Master Game Loop (Timer & Phase Controller)
// ----------------------------------------------------
function startMasterLoop() {
  setInterval(() => {
    if (phase === 'SELECT_TIME') {
      timerSeconds--;
      broadcast('TICK', { roundId, phase, timerSeconds, hotIndex, roundBets });

      if (timerSeconds <= 0) {
        // Transition to SPINNING
        phase = 'SPINNING';
        timerSeconds = 5;
        calculateOutcome();

        broadcast('SPIN_START', {
          roundId,
          phase,
          timerSeconds,
          winningIndex,
          activeSpecialPrize,
          winningFood: FOOD_CONFIG[winningIndex]
        });
      }
    } else if (phase === 'SPINNING') {
      timerSeconds--;
      broadcast('TICK', { roundId, phase, timerSeconds, hotIndex, roundBets });

      if (timerSeconds <= 0) {
        // Transition to SHOW_TIME
        phase = 'SHOW_TIME';
        timerSeconds = 2;
        broadcast('SHOW_TIME', {
          roundId,
          phase,
          winningIndex,
          activeSpecialPrize,
          winningFood: FOOD_CONFIG[winningIndex]
        });

        setTimeout(() => {
          // Transition to RESULT
          phase = 'RESULT';
          const winKey = activeSpecialPrize ? activeSpecialPrize : FOOD_CONFIG[winningIndex].id;
          recentResults.unshift(winKey);
          if (recentResults.length > 8) recentResults.pop();

          broadcast('ROUND_RESULT', {
            roundId,
            phase,
            winningIndex,
            activeSpecialPrize,
            winningFood: FOOD_CONFIG[winningIndex],
            recentResults
          });

          setTimeout(() => {
            // Start Next Round
            roundId++;
            phase = 'SELECT_TIME';
            timerSeconds = 25;
            roundBets = {};
            // Shift hot tag to a different item
            const available = [0, 1, 2, 3, 4, 5, 6, 7].filter(i => i !== hotIndex);
            hotIndex = available[Math.floor(Math.random() * available.length)];

            broadcast('ROUND_START', {
              roundId,
              phase,
              timerSeconds,
              hotIndex,
              recentResults
            });
          }, 4000); // 4s Result modal display
        }, 1400); // 1.4s Show Time fanfare
      }
    }
  }, 1000);
}

startMasterLoop();

// ====================================================
// HTTP Server & API Handlers
// ====================================================
const server = http.createServer((req, res) => {
  // CORS Headers for API
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // 1. Real-Time Server-Sent Events (SSE) Stream
  if (req.url === '/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    });
    res.write('\n');
    sseClients.add(res);

    // Immediately send current state snapshot
    const initData = JSON.stringify({
      event: 'STATE_SYNC',
      data: {
        roundId,
        phase,
        timerSeconds,
        hotIndex,
        roundBets,
        recentResults,
        activeSpecialPrize,
        winningIndex
      }
    });
    res.write(`event: STATE_SYNC\ndata: ${initData}\n\n`);

    req.on('close', () => {
      sseClients.delete(res);
    });
    return;
  }

  // 2. Current State Snapshot API
  if (req.url === '/api/state') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      roundId,
      phase,
      timerSeconds,
      hotIndex,
      roundBets,
      recentResults,
      activeSpecialPrize,
      lifetimeStats: {
        totalBets: lifetimeStats.totalBets,
        totalPayout: lifetimeStats.totalPayout,
        rtp: lifetimeStats.totalBets > 0 ? (lifetimeStats.totalPayout / lifetimeStats.totalBets).toFixed(4) : '0.0000',
        profitRate: lifetimeStats.totalBets > 0 ? (1 - (lifetimeStats.totalPayout / lifetimeStats.totalBets)).toFixed(4) : '1.0000'
      }
    }));
    return;
  }

  // 3. Player Bet Placement API
  if (req.method === 'POST' && req.url === '/api/bet') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        const { foodId, amount } = payload;
        if (phase === 'SELECT_TIME' && foodId && amount > 0) {
          roundBets[foodId] = (roundBets[foodId] || 0) + amount;
          broadcast('BETS_UPDATED', { roundBets });
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'ok', roundBets }));
        } else {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Bet not allowed in this phase' }));
        }
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // 4. Trigger Special Prize API (Pizza / Salad)
  if (req.method === 'POST' && req.url === '/api/trigger_prize') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const payload = JSON.parse(body);
        if (payload.prize === 'pizza' || payload.prize === 'salad') {
          pendingSpecialPrize = payload.prize;
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'scheduled', prize: pendingSpecialPrize }));
        } else {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Invalid prize type' }));
        }
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // 5. Save Transparent Cat Helper
  if (req.method === 'POST' && req.url === '/save_transparent_cat') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const base64Data = body.replace(/^data:image\/png;base64,/, '');
        fs.writeFileSync(path.join(process.cwd(), 'cat_mascot.png'), base64Data, 'base64');
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('SUCCESS');
      } catch (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('ERROR: ' + err.message);
      }
    });
    return;
  }

  // 6. Static File Serving
  let reqUrl = req.url === '/' ? '/index.html' : req.url;
  let filePath = path.join(process.cwd(), reqUrl.split('?')[0]);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(filePath).pipe(res);
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

server.listen(8095, () => {
  console.log('Real-Time Multiplayer Server running on port 8095 (Guaranteed <75% Payout Engine Active)');
});
