/**
 * Ludo Game - Authentic Reference Edition
 * King tokens, in-yard interactive dice docks, circular timer ring, and AI bots
 */

class LudoGame {
    constructor() {
        this.boardGrid = document.getElementById('ludo-board-grid');
        this.tokensLayer = document.getElementById('tokens-layer');

        // Modals & Controls
        this.modalMode = document.getElementById('modal-mode');
        this.modalRules = document.getElementById('modal-rules');
        this.modalWinner = document.getElementById('modal-winner');
        this.btnSound = document.getElementById('btn-sound');
        this.soundIcon = document.getElementById('sound-icon');

        // Turn announcements
        this.statusMessage = document.getElementById('status-message');
        this.statusColorDot = document.getElementById('status-color-dot');

        // Reference order: Green (Top-Left) -> Yellow (Top-Right) -> Blue (Bottom-Right) -> Red (Bottom-Left)
        this.colors = ['green', 'yellow', 'blue', 'red'];
        this.activeColors = ['green', 'yellow', 'blue', 'red'];
        this.players = {};
        this.turnIndex = 0;
        this.diceValue = 1;
        this.consecutiveSixes = 0;
        this.gameState = 'INIT'; // WAITING_ROLL, ROLLING, SELECTING, MOVING, GAMEOVER
        this.confettiAnimId = null;
        this.timerInterval = null;

        // Default setup
        this.playerTypes = {
            green: 'human',
            yellow: 'bot',
            blue: 'bot',
            red: 'bot'
        };

        this.init();
    }

    init() {
        this.buildBoardCells();
        this.setupEventListeners();
        this.startNewGame();
    }

    /**
     * Generate 15x15 board cells with safe stars and decorative icons
     */
    buildBoardCells() {
        const trackCellMap = new Map();
        LUDO_DATA.TRACK.forEach((pos, idx) => {
            trackCellMap.set(`${pos.r},${pos.c}`, idx);
        });

        // Special decorative rockets and bonus dice positions from reference screenshot
        const rockets = ['3,7', '7,11', '11,7', '7,3'];
        const bonusDices = ['6,2', '8,0'];

        for (let r = 0; r < 15; r++) {
            for (let c = 0; c < 15; c++) {
                // Skip 4 yards and 3x3 center
                if (r < 6 && c < 6) continue;      // Green yard
                if (r < 6 && c >= 9) continue;     // Yellow yard
                if (r >= 9 && c < 6) continue;     // Red yard
                if (r >= 9 && c >= 9) continue;    // Blue yard
                if (r >= 6 && r <= 8 && c >= 6 && c <= 8) continue; // Center

                const cell = document.createElement('div');
                cell.className = 'cell';
                cell.style.gridRow = r + 1;
                cell.style.gridColumn = c + 1;

                const posKey = `${r},${c}`;

                // Colored Home Runway Paths
                if (r === 7 && c >= 1 && c <= 5) cell.classList.add('green-path');
                else if (c === 7 && r >= 1 && r <= 5) cell.classList.add('yellow-path');
                else if (r === 7 && c >= 9 && c <= 13) cell.classList.add('blue-path');
                else if (c === 7 && r >= 9 && r <= 13) cell.classList.add('red-path');

                // Starting Cells
                if (r === 6 && c === 1) cell.classList.add('start-cell', 'green-path');
                else if (r === 1 && c === 8) cell.classList.add('start-cell', 'yellow-path');
                else if (r === 8 && c === 13) cell.classList.add('start-cell', 'blue-path');
                else if (r === 13 && c === 6) cell.classList.add('start-cell', 'red-path');

                // Safe Star spots
                if (trackCellMap.has(posKey)) {
                    const trackIdx = trackCellMap.get(posKey);
                    if (LUDO_DATA.SAFE_SPOTS.includes(trackIdx)) {
                        cell.classList.add('safe-star');
                    }
                }

                // Decorative rocket and bonus dice icons matching reference
                if (rockets.includes(posKey)) {
                    cell.classList.add('rocket-icon');
                } else if (bonusDices.includes(posKey)) {
                    cell.classList.add('dice-bonus-icon');
                }

                this.boardGrid.appendChild(cell);
            }
        }
    }

    /**
     * Start a new game session
     */
    startNewGame() {
        this.stopConfetti();
        if (this.timerInterval) clearInterval(this.timerInterval);
        this.tokensLayer.innerHTML = '';
        this.players = {};

        this.colors.forEach(color => {
            const isActive = this.activeColors.includes(color);
            const pType = this.playerTypes[color] || 'human';

            this.players[color] = {
                color: color,
                name: LUDO_DATA.COLORS[color].name,
                active: isActive,
                type: pType,
                finishedCount: 0,
                tokens: [
                    { id: 0, color, step: -1, el: null },
                    { id: 1, color, step: -1, el: null },
                    { id: 2, color, step: -1, el: null },
                    { id: 3, color, step: -1, el: null }
                ]
            };

            // Update Profile Name Tag
            const nameEl = document.getElementById(`name-${color}`);
            if (nameEl) {
                const label = pType === 'human' ? 'You' : 'Bot';
                nameEl.textContent = `${color.toUpperCase()} (${label})`;
            }

            if (isActive) {
                this.players[color].tokens.forEach(tok => {
                    tok.el = this.createRoyalKingToken(tok);
                    this.tokensLayer.appendChild(tok.el);
                });
            }
        });

        // Position tokens in yards
        this.repositionAllTokens();
        // Re-align on next frame to ensure computed DOM rects are ready
        requestAnimationFrame(() => {
            this.repositionAllTokens();
        });

        this.turnIndex = 0;
        while (!this.players[this.activeColors[this.turnIndex]]?.active) {
            this.turnIndex = (this.turnIndex + 1) % this.activeColors.length;
        }

        this.consecutiveSixes = 0;
        this.setGameState('WAITING_ROLL');
        this.updateTurnUI();
        this.checkBotTurn();
    }

    /**
     * Reposition all active tokens
     */
    repositionAllTokens() {
        this.activeColors.forEach(color => {
            if (!this.players[color]) return;
            this.players[color].tokens.forEach(tok => {
                this.positionToken(tok);
            });
        });
    }

    /**
     * Create Royal King Crowned Token Element
     */
    createRoyalKingToken(token) {
        const div = document.createElement('div');
        div.className = `token ${token.color}`;
        div.dataset.color = token.color;
        div.dataset.id = token.id;

        // Scalable Royal King SVG matching reference photo
        div.innerHTML = `
            <svg class="token-svg-pawn" viewBox="0 0 100 120" xmlns="http://www.w3.org/2000/svg">
                <!-- Drop Shadow beneath base -->
                <ellipse cx="50" cy="100" rx="34" ry="9" fill="rgba(0,0,0,0.3)"/>
                
                <!-- Concentric Round Royal Collar / Robe Base -->
                <ellipse cx="50" cy="94" rx="33" ry="14" fill="url(#pawnGrad-${token.color})"/>
                <ellipse cx="50" cy="87" rx="26" ry="11" fill="url(#pawnGrad-${token.color})"/>
                <ellipse cx="50" cy="84" rx="20" ry="7" fill="rgba(255,255,255,0.3)"/>
                
                <!-- Side Hair Puffs -->
                <circle cx="31" cy="54" r="9" fill="#2d1c08"/>
                <circle cx="69" cy="54" r="9" fill="#2d1c08"/>

                <!-- Cute Rosy Face -->
                <circle cx="50" cy="52" r="21" fill="#fed7aa"/>
                <circle cx="38" cy="56" r="4.5" fill="rgba(248, 113, 113, 0.45)"/>
                <circle cx="62" cy="56" r="4.5" fill="rgba(248, 113, 113, 0.45)"/>
                <!-- Cute Eyes -->
                <circle cx="42" cy="50" r="2.5" fill="#2d1c08"/>
                <circle cx="58" cy="50" r="2.5" fill="#2d1c08"/>
                <!-- Smile -->
                <path d="M 46 57 Q 50 62 54 57" stroke="#5a2e10" stroke-width="2.2" stroke-linecap="round" fill="none"/>
                
                <!-- Royal Golden 5-Peak Crown with Pink Gem -->
                <path d="M 23 38 L 18 18 L 34 27 L 50 10 L 66 27 L 82 18 L 77 38 Z" fill="url(#goldCrownGrad)" stroke="#b45309" stroke-width="1.5"/>
                <ellipse cx="50" cy="38" rx="26" ry="6" fill="#eab308"/>
                <!-- Crown Jewels (Pink Diamond in Center) -->
                <circle cx="19" cy="19" r="3" fill="#fb7185"/>
                <polygon points="50,16 54,23 50,30 46,23" fill="#f43f5e" stroke="#ffe4e6" stroke-width="0.8"/>
                <circle cx="81" cy="19" r="3" fill="#fb7185"/>
            </svg>
        `;

        div.addEventListener('click', (e) => {
            e.stopPropagation();
            this.handleTokenClick(token);
        });

        return div;
    }

    /**
     * Position token on grid with dead-center precision
     */
    positionToken(token, animated = false) {
        if (!token.el) return;

        if (token.step === -1) {
            // In Yard: Find its exact slot indent element
            const slotEl = document.getElementById(`slot-${token.color}-${token.id}`);
            if (slotEl) {
                const boardRect = this.boardGrid.getBoundingClientRect();
                const slotRect = slotEl.getBoundingClientRect();

                if (boardRect.width > 0 && slotRect.width > 0) {
                    const centerX = ((slotRect.left + slotRect.width / 2) - boardRect.left) / boardRect.width * 100;
                    const centerY = ((slotRect.top + slotRect.height / 2) - boardRect.top) / boardRect.height * 100;

                    token.el.style.left = `${centerX}%`;
                    token.el.style.top = `${centerY}%`;
                }
            }
        } else {
            // On Track or Home: Center of cell (r, c)
            const coords = LUDO_DATA.getTokenCoordinates(token.color, token.step, token.id);
            const cellPercent = 100 / 15;

            token.el.style.left = `${(coords.c + 0.5) * cellPercent}%`;
            token.el.style.top = `${(coords.r + 0.5) * cellPercent}%`;
        }

        if (animated) {
            token.el.classList.add('hopping');
            setTimeout(() => {
                if (token.el) token.el.classList.remove('hopping');
            }, 220);
        }

        this.updateAllClusters();
    }

    /**
     * Prevent overlapping on same tile by applying neat offset clusters
     */
    updateAllClusters() {
        const occupied = new Map();

        this.activeColors.forEach(color => {
            if (!this.players[color]) return;
            this.players[color].tokens.forEach(tok => {
                if (tok.step >= 0 && tok.step < 56) {
                    const coords = LUDO_DATA.getTokenCoordinates(tok.color, tok.step, tok.id);
                    const key = `${coords.r.toFixed(1)},${coords.c.toFixed(1)}`;
                    if (!occupied.has(key)) occupied.set(key, []);
                    occupied.get(key).push(tok);
                } else if (tok.el) {
                    tok.el.classList.remove('cluster-0', 'cluster-1', 'cluster-2', 'cluster-3');
                }
            });
        });

        occupied.forEach(tokList => {
            if (tokList.length === 1) {
                if (tokList[0].el) {
                    tokList[0].el.classList.remove('cluster-0', 'cluster-1', 'cluster-2', 'cluster-3');
                }
            } else {
                tokList.forEach((tok, idx) => {
                    if (tok.el) {
                        tok.el.classList.remove('cluster-0', 'cluster-1', 'cluster-2', 'cluster-3');
                        tok.el.classList.add(`cluster-${idx % 4}`);
                    }
                });
            }
        });
    }

    getCurrentPlayer() {
        const color = this.activeColors[this.turnIndex];
        return this.players[color];
    }

    setGameState(newState) {
        this.gameState = newState;
    }

    /**
     * Update active turn indicators (In-Yard Dice Dock & Circular Progress Timer)
     */
    updateTurnUI() {
        const curPlayer = this.getCurrentPlayer();
        if (!curPlayer) return;

        // Update In-Yard Dice Docks & Profiles
        this.colors.forEach(col => {
            const dock = document.getElementById(`dice-dock-${col}`);
            const profile = document.getElementById(`profile-${col}`);
            const timerCircle = document.getElementById(`timer-${col}`);

            const isCurrent = (col === curPlayer.color);
            if (dock) dock.classList.toggle('active', isCurrent);
            if (profile) profile.classList.toggle('turn-active', isCurrent);

            if (timerCircle) {
                if (isCurrent) {
                    this.startTurnTimer(timerCircle);
                } else {
                    timerCircle.style.strokeDashoffset = '125.6';
                }
            }
        });

        // Status Bar
        this.statusColorDot.style.background = LUDO_DATA.COLORS[curPlayer.color].colorHex;
        if (curPlayer.type === 'human') {
            this.statusMessage.textContent = `${curPlayer.name}: আপনার চাল! ডাইস রোল করুন 🎲`;
        } else {
            this.statusMessage.textContent = `${curPlayer.name}: চাল ভাবছে... 🤖`;
        }
    }

    /**
     * Animate Circular Turn Timer around avatar
     */
    startTurnTimer(timerCircle) {
        if (this.timerInterval) clearInterval(this.timerInterval);
        
        let remaining = 15; // 15 seconds
        const total = 15;
        const totalDash = 125.6;

        timerCircle.style.strokeDashoffset = '0';

        this.timerInterval = setInterval(() => {
            remaining -= 0.1;
            const progress = (remaining / total);
            timerCircle.style.strokeDashoffset = `${totalDash * (1 - progress)}`;

            if (remaining <= 0) {
                clearInterval(this.timerInterval);
                if (this.gameState === 'WAITING_ROLL') {
                    // Auto roll if time runs out
                    this.rollDice();
                }
            }
        }, 100);
    }

    /**
     * Render pips inside dice display
     */
    renderDicePips(color, roll) {
        const display = document.getElementById(`dice-display-${color}`);
        if (!display) return;

        display.innerHTML = '';
        const pipConfigs = {
            1: [{ r: 2, c: 2, red: true }],
            2: [{ r: 1, c: 1 }, { r: 3, c: 3 }],
            3: [{ r: 1, c: 1 }, { r: 2, c: 2 }, { r: 3, c: 3 }],
            4: [{ r: 1, c: 1 }, { r: 1, c: 3 }, { r: 3, c: 1 }, { r: 3, c: 3 }],
            5: [{ r: 1, c: 1 }, { r: 1, c: 3 }, { r: 2, c: 2 }, { r: 3, c: 1 }, { r: 3, c: 3 }],
            6: [{ r: 1, c: 1 }, { r: 1, c: 3 }, { r: 2, c: 1 }, { r: 2, c: 3 }, { r: 3, c: 1 }, { r: 3, c: 3 }]
        };

        const pips = pipConfigs[roll] || pipConfigs[1];
        pips.forEach(p => {
            const pip = document.createElement('span');
            pip.className = 'pip';
            if (p.red) pip.classList.add('pip-red');
            pip.style.gridRow = p.r;
            pip.style.gridColumn = p.c;
            display.appendChild(pip);
        });
    }

    /**
     * Dice Roll Action
     */
    rollDice() {
        if (this.gameState !== 'WAITING_ROLL') return;

        const player = this.getCurrentPlayer();
        const diceBox = document.getElementById(`dice-box-${player.color}`);

        this.setGameState('ROLLING');
        window.ludoAudio.playDiceRoll();

        if (diceBox) diceBox.classList.add('rolling');

        // Roll 1..6
        const roll = Math.floor(Math.random() * 6) + 1;
        this.diceValue = roll;

        // Rapid pip cycling animation while rolling
        let cycleCount = 0;
        const cycleInterval = setInterval(() => {
            const randRoll = Math.floor(Math.random() * 6) + 1;
            this.renderDicePips(player.color, randRoll);
            cycleCount++;
            if (cycleCount > 6) {
                clearInterval(cycleInterval);
                this.renderDicePips(player.color, roll);
                if (diceBox) diceBox.classList.remove('rolling');
                this.handlePostRoll(roll);
            }
        }, 80);
    }

    /**
     * Process result after dice lands
     */
    handlePostRoll(roll) {
        const player = this.getCurrentPlayer();

        if (roll === 6) {
            this.consecutiveSixes++;
            if (this.consecutiveSixes === 3) {
                this.statusMessage.textContent = 'পরপর ৩ বার ৬! চাল বাতিল হলো ❌';
                window.ludoAudio.playCapture();
                this.consecutiveSixes = 0;
                setTimeout(() => this.passTurn(), 1000);
                return;
            }
            window.ludoAudio.playBonus();
        } else {
            this.consecutiveSixes = 0;
        }

        const validMoves = this.getValidMoves(player, roll);

        if (validMoves.length === 0) {
            this.statusMessage.textContent = `${player.name}: কোনো চাল সম্ভব নয়! 🛑`;
            setTimeout(() => this.passTurn(), 800);
            return;
        }

        this.setGameState('SELECTING');
        this.highlightMovableTokens(validMoves, true);

        if (player.type === 'human') {
            if (validMoves.length === 1) {
                setTimeout(() => {
                    this.executeMove(validMoves[0], roll);
                }, 350);
            }
        } else {
            // Bot Move
            setTimeout(() => {
                const chosenToken = this.chooseBestBotMove(validMoves, roll);
                this.executeMove(chosenToken, roll);
            }, 600);
        }
    }

    getValidMoves(player, roll) {
        const list = [];
        player.tokens.forEach(tok => {
            if (tok.step === -1) {
                if (roll === 6) list.push(tok);
            } else if (tok.step < 56) {
                if (tok.step + roll <= 56) {
                    list.push(tok);
                }
            }
        });
        return list;
    }

    highlightMovableTokens(tokens, isHighlighted) {
        document.querySelectorAll('.token').forEach(el => el.classList.remove('movable'));
        if (isHighlighted) {
            tokens.forEach(tok => {
                tok.el.classList.add('movable');
            });
        }
    }

    handleTokenClick(token) {
        if (this.gameState !== 'SELECTING') return;
        const curPlayer = this.getCurrentPlayer();

        if (curPlayer.type !== 'human' || token.color !== curPlayer.color) return;

        const validMoves = this.getValidMoves(curPlayer, this.diceValue);
        const isValid = validMoves.some(t => t.id === token.id);

        if (isValid) {
            this.executeMove(token, this.diceValue);
        }
    }

    async executeMove(token, roll) {
        this.setGameState('MOVING');
        this.highlightMovableTokens([], false);
        if (this.timerInterval) clearInterval(this.timerInterval);

        const player = this.players[token.color];

        if (token.step === -1) {
            token.step = 0;
            this.positionToken(token, true);
            window.ludoAudio.playTokenStep(0);
            await this.sleep(280);
        } else {
            const startStep = token.step;
            const targetStep = token.step + roll;

            for (let s = startStep + 1; s <= targetStep; s++) {
                token.step = s;
                this.positionToken(token, true);
                window.ludoAudio.playTokenStep(s);
                await this.sleep(170);
            }
        }

        let getsBonusRoll = (roll === 6);

        if (token.step === 56) {
            player.finishedCount++;
            window.ludoAudio.playTokenHome();
            getsBonusRoll = true;

            if (player.finishedCount === 4) {
                this.handleGameWinner(player);
                return;
            }
        } else {
            const captured = this.checkCapture(token);
            if (captured) {
                getsBonusRoll = true;
            } else if (LUDO_DATA.isSafePosition(token.color, token.step)) {
                window.ludoAudio.playSafeZone();
            }
        }

        await this.sleep(220);

        if (getsBonusRoll && this.consecutiveSixes < 3) {
            this.statusMessage.textContent = `${player.name}: বোনাস চাল! আবার ডাইস রোল করুন 🎉`;
            this.setGameState('WAITING_ROLL');
            this.updateTurnUI();
            this.checkBotTurn();
        } else {
            this.passTurn();
        }
    }

    checkCapture(landingToken) {
        if (LUDO_DATA.isSafePosition(landingToken.color, landingToken.step)) {
            return false;
        }

        const landingCoords = LUDO_DATA.getTokenCoordinates(landingToken.color, landingToken.step, landingToken.id);
        let capturedAny = false;

        this.activeColors.forEach(col => {
            if (col === landingToken.color) return;

            this.players[col].tokens.forEach(oppTok => {
                if (oppTok.step >= 0 && oppTok.step <= 50) {
                    const oppCoords = LUDO_DATA.getTokenCoordinates(oppTok.color, oppTok.step, oppTok.id);
                    if (oppCoords.r === landingCoords.r && oppCoords.c === landingCoords.c) {
                        capturedAny = true;
                        window.ludoAudio.playCapture();
                        this.statusMessage.textContent = `${landingToken.color.toUpperCase()} প্রতিপক্ষের গুটি কাটল! ⚔️`;

                        oppTok.el.classList.add('knockout');
                        setTimeout(() => {
                            oppTok.el.classList.remove('knockout');
                            oppTok.step = -1;
                            this.positionToken(oppTok, true);
                        }, 400);
                    }
                }
            });
        });

        return capturedAny;
    }

    passTurn() {
        this.turnIndex = (this.turnIndex + 1) % this.activeColors.length;
        this.consecutiveSixes = 0;
        this.setGameState('WAITING_ROLL');
        this.updateTurnUI();
        window.ludoAudio.playTurnChime();
        this.checkBotTurn();
    }

    checkBotTurn() {
        const curPlayer = this.getCurrentPlayer();
        if (curPlayer && curPlayer.type === 'bot' && this.gameState === 'WAITING_ROLL') {
            setTimeout(() => {
                if (this.gameState === 'WAITING_ROLL') {
                    this.rollDice();
                }
            }, 700);
        }
    }

    chooseBestBotMove(validMoves, roll) {
        if (validMoves.length === 1) return validMoves[0];

        let bestScore = -999;
        let chosenToken = validMoves[0];

        validMoves.forEach(tok => {
            let score = 0;

            if (tok.step === -1 && roll === 6) {
                score += 85;
            } else {
                const targetStep = tok.step + roll;

                if (targetStep === 56) score += 130;
                if (targetStep >= 51 && tok.step < 51) score += 75;

                if (targetStep <= 50) {
                    const targetCoords = LUDO_DATA.getTokenCoordinates(tok.color, targetStep, tok.id);
                    const isSafe = LUDO_DATA.isSafePosition(tok.color, targetStep);

                    if (!isSafe) {
                        this.activeColors.forEach(otherCol => {
                            if (otherCol !== tok.color) {
                                this.players[otherCol].tokens.forEach(oppTok => {
                                    if (oppTok.step >= 0 && oppTok.step <= 50) {
                                        const oppCoords = LUDO_DATA.getTokenCoordinates(oppTok.color, oppTok.step, oppTok.id);
                                        if (oppCoords.r === targetCoords.r && oppCoords.c === targetCoords.c) {
                                            score += 150;
                                        }
                                    }
                                });
                            }
                        });
                    } else {
                        score += 60;
                    }
                }

                score += tok.step * 1.2;
            }

            if (score > bestScore) {
                bestScore = score;
                chosenToken = tok;
            }
        });

        return chosenToken;
    }

    handleGameWinner(player) {
        this.setGameState('GAMEOVER');
        window.ludoAudio.playWin();

        const winnerNameEl = document.getElementById('winner-name');
        if (winnerNameEl) {
            winnerNameEl.textContent = `অভিনন্দন! ${player.name} বিজয়ী! 👑`;
        }

        this.modalWinner.classList.add('active');
        this.startConfetti();
    }

    startConfetti() {
        const canvas = document.getElementById('confetti-canvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');

        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        const particles = [];
        const colors = ['#00a859', '#ffbc00', '#0090ff', '#ef3f3f', '#f59e0b', '#ec4899'];

        for (let i = 0; i < 150; i++) {
            particles.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height - canvas.height,
                w: Math.random() * 12 + 6,
                h: Math.random() * 8 + 4,
                color: colors[Math.floor(Math.random() * colors.length)],
                vx: Math.random() * 4 - 2,
                vy: Math.random() * 4 + 3,
                rot: Math.random() * 360,
                vrot: Math.random() * 10 - 5
            });
        }

        const render = () => {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            particles.forEach(p => {
                p.x += p.vx;
                p.y += p.vy;
                p.rot += p.vrot;

                if (p.y > canvas.height) {
                    p.y = -20;
                    p.x = Math.random() * canvas.width;
                }

                ctx.save();
                ctx.translate(p.x, p.y);
                ctx.rotate((p.rot * Math.PI) / 180);
                ctx.fillStyle = p.color;
                ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
                ctx.restore();
            });

            this.confettiAnimId = requestAnimationFrame(render);
        };

        render();
    }

    stopConfetti() {
        if (this.confettiAnimId) {
            cancelAnimationFrame(this.confettiAnimId);
            this.confettiAnimId = null;
        }
        const canvas = document.getElementById('confetti-canvas');
        if (canvas) {
            const ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);
        }
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    setupEventListeners() {
        // In-Yard Dice box clicks
        this.colors.forEach(col => {
            const diceBox = document.getElementById(`dice-box-${col}`);
            if (diceBox) {
                diceBox.addEventListener('click', () => {
                    const curPlayer = this.getCurrentPlayer();
                    if (curPlayer.color === col && curPlayer.type === 'human') {
                        this.rollDice();
                    }
                });
            }
        });

        // Top Navigation Buttons
        this.btnSound.addEventListener('click', () => {
            const muted = window.ludoAudio.toggleMute();
            this.soundIcon.textContent = muted ? '🔇' : '🔊';
        });

        document.getElementById('btn-restart').addEventListener('click', () => {
            if (confirm('আপনি কি নতুন খেলা শুরু করতে চান?')) {
                this.startNewGame();
            }
        });

        document.getElementById('btn-rules').addEventListener('click', () => {
            this.modalRules.classList.add('active');
        });
        document.getElementById('modal-close-rules').addEventListener('click', () => {
            this.modalRules.classList.remove('active');
        });

        document.getElementById('btn-mode').addEventListener('click', () => {
            this.modalMode.classList.add('active');
        });
        document.getElementById('modal-close-mode').addEventListener('click', () => {
            this.modalMode.classList.remove('active');
        });

        const btnInfo = document.getElementById('btn-info');
        if (btnInfo) {
            btnInfo.addEventListener('click', () => {
                this.modalMode.classList.add('active');
            });
        }

        document.getElementById('btn-winner-rematch').addEventListener('click', () => {
            this.modalWinner.classList.remove('active');
            this.startNewGame();
        });

        // Mode Card selection
        const modeCards = document.querySelectorAll('.mode-card');
        modeCards.forEach(card => {
            card.addEventListener('click', () => {
                modeCards.forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');

                const mode = card.dataset.mode;
                if (mode === '2-players') {
                    this.activeColors = ['green', 'blue'];
                } else if (mode === '3-players') {
                    this.activeColors = ['green', 'yellow', 'blue'];
                } else if (mode === '4-players') {
                    this.activeColors = ['green', 'yellow', 'blue', 'red'];
                } else if (mode === 'vs-computer') {
                    this.activeColors = ['green', 'yellow', 'blue', 'red'];
                    document.getElementById('setup-type-green').value = 'human';
                    document.getElementById('setup-type-yellow').value = 'bot';
                    document.getElementById('setup-type-blue').value = 'bot';
                    document.getElementById('setup-type-red').value = 'bot';
                }
            });
        });

        document.getElementById('btn-apply-settings').addEventListener('click', () => {
            this.playerTypes.green = document.getElementById('setup-type-green').value;
            this.playerTypes.yellow = document.getElementById('setup-type-yellow').value;
            this.playerTypes.blue = document.getElementById('setup-type-blue').value;
            this.playerTypes.red = document.getElementById('setup-type-red').value;

            this.modalMode.classList.remove('active');
            this.startNewGame();
        });

        // Spacebar to roll
        window.addEventListener('keydown', (e) => {
            if (e.code === 'Space' && this.gameState === 'WAITING_ROLL') {
                const curPlayer = this.getCurrentPlayer();
                if (curPlayer && curPlayer.type === 'human') {
                    e.preventDefault();
                    this.rollDice();
                }
            }
        });

        // Window resize listener to keep tokens centered
        window.addEventListener('resize', () => {
            this.repositionAllTokens();
        });
    }
}

document.addEventListener('DOMContentLoaded', () => {
    window.game = new LudoGame();
});
