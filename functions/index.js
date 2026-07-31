const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

if (!admin.apps.length) {
    admin.initializeApp();
}

// ============================================================
// FRUIT WHEEL GAME — Global Multiplayer Spinning Wheel
// ============================================================
const FRUIT_WHEEL_CONFIG = {
    bettingDuration: 15,   // seconds
    spinDuration: 6,       // seconds
    resultDuration: 5,     // seconds
    cooldownDuration: 3,   // seconds
    symbols: {
        watermelon: { multiplier: 2, weight: 5 },  // 5/12 = 41.6%
        plum: { multiplier: 2, weight: 5 },  // 5/12 = 41.6%
        sevens: { multiplier: 8, weight: 2 },   // 2/12 = 16.7%
    },
    validBetAmounts: [500, 1000, 10000, 100000],
};

/**
 * Pick a winning symbol using house-profit priority.
 */
async function pickWinningSymbol(totalBets) {
    let highWeight = 6;
    let mediumWeight = 3;
    let lowWeight = 1;
    let symbolWeights = { watermelon: 1, sevens: 1, plum: 1 };
    try {
        const configDoc = await admin.firestore().collection("config").doc("fruit_wheel").get();
        if (configDoc.exists) {
            const cfg = configDoc.data() || {};
            if (typeof cfg.highWeight === "number") highWeight = cfg.highWeight;
            if (typeof cfg.mediumWeight === "number") mediumWeight = cfg.mediumWeight;
            if (typeof cfg.lowWeight === "number") lowWeight = cfg.lowWeight;
            if (typeof cfg.watermelonWeight === "number") symbolWeights.watermelon = cfg.watermelonWeight;
            if (typeof cfg.sevensWeight === "number") symbolWeights.sevens = cfg.sevensWeight;
            if (typeof cfg.grapeWeight === "number") symbolWeights.plum = cfg.grapeWeight;
        }
    } catch (err) {
        console.error(`Fruit Wheel: Config read error: ${err.message}`);
    }
    const bets = totalBets || {};
    const watermelonPayout = (bets.watermelon || 0) * FRUIT_WHEEL_CONFIG.symbols.watermelon.multiplier;
    const plumPayout = (bets.plum || 0) * FRUIT_WHEEL_CONFIG.symbols.plum.multiplier;
    const sevensPayout = (bets.sevens || 0) * FRUIT_WHEEL_CONFIG.symbols.sevens.multiplier;
    const sorted = [
        { symbol: "watermelon", payout: watermelonPayout },
        { symbol: "plum", payout: plumPayout },
        { symbol: "sevens", payout: sevensPayout },
    ].sort((a, b) => b.payout - a.payout);
    const eligible = sorted.filter(s => symbolWeights[s.symbol] > 0);
    if (eligible.length === 0) {
        eligible.push(...sorted);
    }
    const priorityLevels = [highWeight, mediumWeight, lowWeight];
    const finalWeights = {};
    for (let i = 0; i < eligible.length; i++) {
        const priorityWeight = priorityLevels[i] || lowWeight;
        finalWeights[eligible[i].symbol] = priorityWeight * symbolWeights[eligible[i].symbol];
    }
    const total = Object.values(finalWeights).reduce((a, b) => a + b, 0);
    if (total <= 0) return "watermelon";
    let rand = Math.random() * total;
    for (const [sym, w] of Object.entries(finalWeights)) {
        rand -= w;
        if (rand <= 0) {
            return sym;
        }
    }
    return eligible[eligible.length - 1].symbol;
}

function getGameRef() {
    return admin.database().ref("fruit_wheel");
}

async function advanceGame() {
    const gameRef = getGameRef();
    const currentRoundRef = gameRef.child("current_round");
    const snapshot = await currentRoundRef.once("value");
    const data = snapshot.val();
    const now = Date.now();
    if (!data || !data.phase) {
        return startNewRound(gameRef, 1);
    }
    if (data.phaseEndTime && now < data.phaseEndTime) {
        return { status: "waiting", phase: data.phase, round: data.roundNumber };
    }
    switch (data.phase) {
        case "betting":
            return transitionToSpin(gameRef, data);
        case "spinning":
            return transitionToResult(gameRef, data);
        case "result":
            return transitionToCooldown(gameRef, data);
        case "cooldown":
            return startNewRound(gameRef, (data.roundNumber || 0) + 1);
        default:
            return startNewRound(gameRef, 1);
    }
}

async function startNewRound(gameRef, roundNumber) {
    const now = Date.now();
    const phaseEndTime = now + (FRUIT_WHEEL_CONFIG.bettingDuration * 1000);
    await gameRef.child("current_round").set({
        roundNumber: roundNumber,
        phase: "betting",
        phaseEndTime: phaseEndTime,
        result: null,
        bets: null,
        totalBets: { watermelon: 0, plum: 0, sevens: 0 },
        startedAt: now,
    });
    return { status: "new_round", phase: "betting", round: roundNumber };
}

async function transitionToSpin(gameRef, data) {
    const now = Date.now();
    const totalBetsSnap = await gameRef.child("current_round/totalBets").once("value");
    const freshTotalBets = totalBetsSnap.val() || { watermelon: 0, plum: 0, sevens: 0 };
    const result = await pickWinningSymbol(freshTotalBets);
    const phaseEndTime = now + (FRUIT_WHEEL_CONFIG.spinDuration * 1000);
    await gameRef.child("current_round").update({
        phase: "spinning",
        phaseEndTime: phaseEndTime,
        result: result,
    });
    return { status: "spinning", phase: "spinning", round: data.roundNumber, result };
}

async function transitionToResult(gameRef, data) {
    const now = Date.now();
    const phaseEndTime = now + (FRUIT_WHEEL_CONFIG.resultDuration * 1000);
    const result = data.result;
    const multiplier = FRUIT_WHEEL_CONFIG.symbols[result].multiplier;
    const bets = data.bets || {};
    const payoutPromises = [];
    const winners = {};
    const winnerUserIds = [];
    for (const [userId, userBets] of Object.entries(bets)) {
        const betOnWinner = userBets[result] || 0;
        if (betOnWinner > 0) {
            const payout = betOnWinner * multiplier;
            winnerUserIds.push(userId);
            winners[userId] = { payout: payout, name: "", photo: "" };
            payoutPromises.push(
                admin.firestore().collection("users").doc(userId).update({
                    diamonds: admin.firestore.FieldValue.increment(payout),
                })
            );
        }
    }
    if (winnerUserIds.length > 0) {
        const namePromises = winnerUserIds.map(async (uid) => {
            try {
                const userDoc = await admin.firestore().collection("users").doc(uid).get();
                if (userDoc.exists) {
                    const data = userDoc.data();
                    winners[uid].name = data.displayName || data.username || data.name || "Player";
                    winners[uid].photo = data.photoUrl || "";
                } else {
                    winners[uid].name = "Player";
                    winners[uid].photo = "";
                }
            } catch (err) {
                winners[uid].name = "Player";
                winners[uid].photo = "";
            }
        });
        payoutPromises.push(...namePromises);
    }
    await Promise.all(payoutPromises);
    const historyData = {
        roundNumber: data.roundNumber,
        result: result,
        totalBets: data.totalBets || {},
        winnersCount: Object.keys(winners).length,
        timestamp: now,
    };
    await gameRef.child("history").child(String(data.roundNumber)).set(historyData);
    const historyRef = gameRef.child("history");
    const historySnap = await historyRef.orderByKey().once("value");
    const historyData2 = historySnap.val();
    if (historyData2) {
        const keys = Object.keys(historyData2).sort((a, b) => Number(a) - Number(b));
        if (keys.length > 50) {
            const toDelete = keys.slice(0, keys.length - 50);
            const deleteUpdates = {};
            toDelete.forEach((key) => { deleteUpdates[key] = null; });
            await historyRef.update(deleteUpdates);
        }
    }
    const betHistoryPromises = [];
    for (const [userId, userBets] of Object.entries(bets)) {
        const totalBet = Object.values(userBets).reduce((sum, v) => sum + v, 0);
        const betOnWinner = userBets[result] || 0;
        const payout = betOnWinner > 0 ? betOnWinner * multiplier : 0;
        betHistoryPromises.push(
            admin.firestore()
                .collection("users").doc(userId)
                .collection("bet_history").doc(String(data.roundNumber))
                .set({
                    roundNumber: data.roundNumber,
                    bets: userBets,
                    result: result,
                    payout: payout,
                    totalBet: totalBet,
                    timestamp: now,
                })
        );
    }
    await Promise.all(betHistoryPromises);
    await gameRef.child("current_round").update({
        phase: "result",
        phaseEndTime: phaseEndTime,
        winners: winners,
    });
    return { status: "result", phase: "result", round: data.roundNumber, result, winners };
}

async function transitionToCooldown(gameRef, data) {
    const now = Date.now();
    const phaseEndTime = now + (FRUIT_WHEEL_CONFIG.cooldownDuration * 1000);
    await gameRef.child("current_round").update({
        phase: "cooldown",
        phaseEndTime: phaseEndTime,
    });
    return { status: "cooldown", phase: "cooldown", round: data.roundNumber };
}

exports.placeFruitWheelBet = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in to play.");
    }
    const uid = request.auth.uid;
    const { symbol, amount } = request.data;
    if (!FRUIT_WHEEL_CONFIG.symbols[symbol]) {
        throw new HttpsError("invalid-argument", `Invalid symbol: ${symbol}`);
    }
    if (!Number.isInteger(amount) || amount <= 0) {
        throw new HttpsError("invalid-argument", "Bet amount must be a positive integer.");
    }
    if (!FRUIT_WHEEL_CONFIG.validBetAmounts.includes(amount)) {
        throw new HttpsError("invalid-argument", `Invalid bet amount.`);
    }
    const gameRef = getGameRef();
    const roundSnap = await gameRef.child("current_round").once("value");
    const roundData = roundSnap.val();
    if (!roundData || roundData.phase !== "betting") {
        throw new HttpsError("failed-precondition", "Betting is not open right now.");
    }
    if (Date.now() > roundData.phaseEndTime) {
        throw new HttpsError("failed-precondition", "Betting time has expired for this round.");
    }
    const userExistingBets = (roundData.bets && roundData.bets[uid]) || {};
    const hasWatermelon = (userExistingBets.watermelon || 0) > 0;
    const hasPlum = (userExistingBets.plum || 0) > 0;
    if (symbol === "watermelon" && hasPlum) {
        throw new HttpsError("failed-precondition", "You can only pick one fruit! Combine it with 77.");
    }
    if (symbol === "plum" && hasWatermelon) {
        throw new HttpsError("failed-precondition", "You can only pick one fruit! Combine it with 77.");
    }
    const userRef = admin.firestore().collection("users").doc(uid);
    await admin.firestore().runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new HttpsError("not-found", "User profile not found.");
        const userData = userDoc.data();
        const currentDiamonds = userData.diamonds || 0;
        if (currentDiamonds < amount) {
            throw new HttpsError("failed-precondition", `Insufficient diamonds.`);
        }
        transaction.update(userRef, {
            diamonds: admin.firestore.FieldValue.increment(-amount),
        });
    });
    const userBetRef = gameRef.child(`current_round/bets/${uid}/${symbol}`);
    const existingBetSnap = await userBetRef.once("value");
    const existingBet = existingBetSnap.val() || 0;
    await userBetRef.set(existingBet + amount);
    const totalBetRef = gameRef.child(`current_round/totalBets/${symbol}`);
    const totalSnap = await totalBetRef.once("value");
    const currentTotal = totalSnap.val() || 0;
    await totalBetRef.set(currentTotal + amount);
    return {
        success: true,
        symbol: symbol,
        amount: amount,
        totalBetOnSymbol: existingBet + amount,
        round: roundData.roundNumber,
    };
});

exports.tickFruitWheelGame = onCall(async (request) => {
    return await advanceGame();
});

exports.fruitWheelGameLoop = onSchedule(
    { schedule: "every 1 minutes" },
    async (event) => {
        let iterations = 0;
        const maxIterations = 10;
        while (iterations < maxIterations) {
            const result = await advanceGame();
            iterations++;
            if (result.status === "waiting") break;
            await new Promise((resolve) => setTimeout(resolve, 200));
        }
    }
);
