const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
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

// ============================================================
// SMS WEBHOOK & AUTO PAYMENT APPROVAL ENDPOINT
// ============================================================

/**
 * Helper to parse TrxID & Amount from SMS text (bKash, Nagad, Rocket, Upay)
 */
function parseSmsDetails(text, fallbackSender = "SMS") {
    if (!text || typeof text !== "string") return { trxId: null, amount: null, sender: fallbackSender };
    
    // 1. Detect sender
    let detectedSender = fallbackSender;
    const lower = text.toLowerCase();
    if (lower.includes("bkash") || lower.includes("বিকাশ")) {
        detectedSender = "bKash";
    } else if (lower.includes("nagad") || lower.includes("নগদ")) {
        detectedSender = "Nagad";
    } else if (lower.includes("rocket") || lower.includes("রকেট")) {
        detectedSender = "Rocket";
    } else if (lower.includes("upay") || lower.includes("উপায়")) {
        detectedSender = "Upay";
    }

    // 2. Extract TrxID / TxnID
    const trxMatch = text.match(/(?:TrxID|TxnID|TxID|Transaction ID|TID|ট্রানজেকশন আইডি)[:\s]+([A-Za-z0-9]+)/i);
    const trxId = trxMatch ? trxMatch[1].trim().toUpperCase() : null;

    // 3. Extract Amount
    const amountMatch = text.match(/(?:Tk\.?|BDT|টাকা|Amount:?\s*Tk\.?)\s*([\d,]+(?:\.\d{1,2})?)/i);
    let amount = null;
    if (amountMatch) {
        const cleanStr = amountMatch[1].replace(/,/g, "");
        amount = parseFloat(cleanStr);
    }

    return { trxId, amount, sender: detectedSender };
}

exports.smsWebhook = onRequest({ cors: true }, async (req, res) => {
    // Health check endpoint
    if (req.method === "GET") {
        return res.status(200).json({
            status: "active",
            service: "IMChat SMS Webhook & Auto Payment Gateway",
            timestamp: new Date().toISOString(),
        });
    }

    if (req.method !== "POST") {
        return res.status(405).json({ error: "Method Not Allowed. Use POST." });
    }

    try {
        let body = req.body || {};
        if (typeof body === "string") {
            try {
                body = JSON.parse(body);
            } catch (e) {
                body = { message: body };
            }
        }
        const query = req.query || {};
        const headers = req.headers || {};

        // Extract secret token
        const incomingSecret =
            headers["x-api-key"] ||
            headers["x-webhook-secret"] ||
            query.apiKey ||
            query.secret ||
            body.secret ||
            body.apiKey;

        const db = admin.firestore();

        // Validate secret against Firestore app_settings/auto_approve_config
        const configDoc = await db.doc("app_settings/auto_approve_config").get();
        const configData = configDoc.exists ? configDoc.data() || {} : {};
        const expectedSecret = configData.webhookSecret || "imchat_secret_84519_sms";
        const isAutoApproveEnabled = configData.isAutoApproveEnabled !== false;

        if (expectedSecret && incomingSecret !== expectedSecret) {
            console.warn(`[smsWebhook] Unauthorized attempt with key: ${incomingSecret}`);
            return res.status(401).json({
                error: "Unauthorized. Invalid or missing secret token in x-api-key header or secret field.",
            });
        }

        console.log("[smsWebhook] Incoming Request Headers:", JSON.stringify(headers));
        console.log("[smsWebhook] Incoming Request Body:", JSON.stringify(body));

        // Smart detection of SMS content across any key
        let rawMessage =
            body.message ||
            body.msg ||
            body.body ||
            body.text ||
            body.content ||
            body.sms ||
            body.sms_body ||
            body.SMS ||
            "";

        // If rawMessage was sent as literal placeholder like "%body", "[message]" or "{msg}", scan all body values
        const isPlaceholder = (str) =>
            !str ||
            str === "%body" ||
            str === "[body]" ||
            str === "[message]" ||
            str === "{msg}" ||
            str === "{message}";

        if (isPlaceholder(rawMessage)) {
            for (const [k, v] of Object.entries(body)) {
                if (typeof v === "string" && !isPlaceholder(v) && v.length > 10) {
                    if (v.toLowerCase().includes("tk") || v.toLowerCase().includes("trxid") || v.toLowerCase().includes("txnid") || v.toLowerCase().includes("received")) {
                        rawMessage = v;
                        console.log(`[smsWebhook] Auto-detected SMS in key "${k}": ${rawMessage}`);
                        break;
                    }
                }
            }
        }

        const rawSender =
            body.sender ||
            body.from ||
            body.address ||
            body.phone ||
            body.originatingAddress ||
            "SMS";

        if (!rawMessage || typeof rawMessage !== "string" || !rawMessage.trim()) {
            return res.status(400).json({ error: "Missing SMS message content in payload." });
        }

        const { trxId, amount, sender } = parseSmsDetails(rawMessage, rawSender);

        if (!trxId || !amount || amount <= 0) {
            console.log(`[smsWebhook] Non-payment SMS ignored: "${rawMessage.substring(0, 80)}..."`);
            return res.status(200).json({
                status: "ignored",
                message: "SMS does not contain a recognized TrxID or valid amount.",
                parsed: { trxId, amount, sender },
            });
        }

        const trxRef = db.collection("incoming_transactions").doc(trxId);
        const existingSnap = await trxRef.get();

        // 1. Record incoming transaction
        if (!existingSnap.exists) {
            await trxRef.set({
                trxId: trxId,
                amount: amount,
                sender: sender,
                rawMessage: rawMessage.trim(),
                status: "unclaimed",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        // 2. Auto-Approval Process
        let autoApproved = false;
        let matchedOrderId = null;
        let creditedDiamonds = 0;

        if (isAutoApproveEnabled) {
            const pendingOrders = await db.collection("rechargeOrders")
                .where("transactionId", "==", trxId)
                .where("status", "==", "Pending")
                .limit(1)
                .get();

            if (!pendingOrders.empty) {
                const orderDoc = pendingOrders.docs[0];
                const freshTrx = await trxRef.get();
                const approveRes = await performAutoApprove(db, orderDoc.id, orderDoc.data(), freshTrx);
                if (approveRes.success) {
                    autoApproved = true;
                    matchedOrderId = orderDoc.id;
                    creditedDiamonds = approveRes.creditedDiamonds;
                }
            }
        }

        return res.status(200).json({
            success: true,
            trxId: trxId,
            amount: amount,
            sender: sender,
            autoApproved: autoApproved,
            matchedOrderId: matchedOrderId,
            creditedDiamonds: creditedDiamonds,
            message: autoApproved
                ? `Order ${matchedOrderId} auto-approved with ${creditedDiamonds} diamonds!`
                : "Transaction recorded (Unclaimed, waiting for user order).",
        });
    } catch (err) {
        console.error("[smsWebhook] Exception:", err);
        return res.status(500).json({
            error: "Internal server error processing SMS webhook.",
            details: err.message,
        });
    }
});

/**
 * Calculates standard week ID for weekly recharge benefits tracking (e.g. 2026_W37)
 */
function getCurrentWeekId() {
    const now = new Date();
    const dayOfWeek = (now.getDay() + 6) % 7; // Monday = 0
    const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dayOfWeek);
    const startOfYear = new Date(monday.getFullYear(), 0, 1);
    const weekNum = Math.ceil(((monday - startOfYear) / (24 * 3600 * 1000)) / 7);
    return `${monday.getFullYear()}_W${weekNum}`;
}

/**
 * Atomically approves an order against an incoming transaction doc.
 */
async function performAutoApprove(db, orderId, orderData, trxDoc) {
    const trxData = trxDoc.data() || {};
    const trxId = trxDoc.id;
    const orderAmount = Number(orderData.amount) || 0;
    const trxAmount = Number(trxData.amount) || 0;

    // Validate amount matching (allow within 1 Tk tolerance)
    if (Math.abs(orderAmount - trxAmount) >= 1) {
        console.warn(`[AutoApprove] Amount mismatch for order ${orderId}: Order=${orderAmount}, SMS=${trxAmount}`);
        await db.collection("rechargeOrders").doc(orderId).update({
            autoApproveFailedReason: `Amount mismatch: Order requested Tk ${orderAmount}, but SMS payment was Tk ${trxAmount}`,
        }).catch(() => {});
        return {
            success: false,
            reason: `Amount mismatch: Order requested Tk ${orderAmount}, but received SMS for Tk ${trxAmount}.`,
        };
    }

    const userId = orderData.userId;
    if (!userId) {
        console.warn(`[AutoApprove] Order ${orderId} missing userId`);
        return { success: false, reason: "Order missing userId" };
    }

    const diamondAmount = Number(orderData.diamondAmount) || 0;
    const bonusDiamonds = Number(orderData.bonusDiamonds) || 0;
    const creditedDiamonds = diamondAmount + bonusDiamonds;
    const sender = trxData.sender || orderData.paymentMethod || "Online";

    const orderRef = db.collection("rechargeOrders").doc(orderId);
    const userRef = db.collection("Users").doc(userId);
    const trxRef = db.collection("incoming_transactions").doc(trxId);

    await db.runTransaction(async (transaction) => {
        const freshOrder = await transaction.get(orderRef);
        if (!freshOrder.exists || (freshOrder.data().status || "").toLowerCase() !== "pending") {
            throw new Error(`Order ${orderId} is no longer pending.`);
        }

        const freshTrx = await transaction.get(trxRef);
        if (!freshTrx.exists || (freshTrx.data().status || "") !== "unclaimed") {
            throw new Error(`Transaction ${trxId} is no longer unclaimed.`);
        }

        // 1. Approve order
        transaction.update(orderRef, {
            status: "Approved",
            verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            verifiedBy: "SYSTEM_AUTO_APPROVE",
            autoApproveFailedReason: admin.firestore.FieldValue.delete(),
        });

        // 2. Increment diamonds on User document
        transaction.update(userRef, {
            diamonds: admin.firestore.FieldValue.increment(creditedDiamonds),
            totalDiamonds: admin.firestore.FieldValue.increment(creditedDiamonds),
            monthlyRechargeAmount: admin.firestore.FieldValue.increment(creditedDiamonds),
            weeklyRechargeAmount: admin.firestore.FieldValue.increment(creditedDiamonds),
            lastRechargeWeek: getCurrentWeekId(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 3. Log to wallet_transactions
        const txId = `tx_${Date.now()}_${Math.floor(Math.random() * 9999)}`;
        const txRef = db.collection("wallet_transactions").doc(txId);
        transaction.set(txRef, {
            id: txId,
            userId: userId,
            type: "online_recharge",
            diamonds: creditedDiamonds,
            baseDiamonds: diamondAmount,
            bonusDiamonds: bonusDiamonds,
            beans: 0,
            amountBdt: orderAmount,
            paymentMethod: sender,
            transactionId: trxId,
            orderId: orderId,
            description: bonusDiamonds > 0
                ? `Auto-Approved Online Diamond Recharge (+${creditedDiamonds} Diamonds [${diamondAmount} + ${bonusDiamonds} Bonus] via ${sender})`
                : `Auto-Approved Online Diamond Recharge (+${creditedDiamonds} Diamonds via ${sender})`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 4. Mark incoming transaction as claimed
        transaction.update(trxRef, {
            status: "auto_approved",
            claimedByUserId: userId,
            claimedByUserName: orderData.userName || "",
            claimedOrderId: orderId,
            claimedDiamonds: creditedDiamonds,
            claimedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

    console.log(`[AutoApprove] Successfully auto-approved order ${orderId} for user ${userId} (+${creditedDiamonds} diamonds)`);

    // Send official congratulations message to user's chat & push notification
    const notifMsg = `🎉 Congratulations! Your online recharge of ${creditedDiamonds} diamonds (৳${orderAmount} via ${sender}) has been successfully credited to your wallet. TrxID: ${trxId}`;
    await sendOfficialNotification(db, userId, notifMsg);
    await orderRef.update({ notificationSent: true }).catch(() => {});

    return { success: true, creditedDiamonds };
}

/**
 * Sends an official notification and push message to the user from "official_team"
 */
async function sendOfficialNotification(db, userId, messageText) {
    if (!userId || !messageText) return;
    try {
        const userDoc = await db.collection("Users").doc(userId).get();
        const userData = userDoc.exists ? userDoc.data() || {} : {};
        const deviceToken = userData.deviceToken || "";

        const msgId = `msg_${Date.now()}_${Math.floor(Math.random() * 999999)}`;
        const batch = db.batch();

        // 1. Save in receiver's chat messages subcollection (Users/{uid}/Chats/official_team/Messages/{msgId})
        const chatMsgRef = db.collection("Users").doc(userId)
            .collection("Chats").doc("official_team")
            .collection("Messages").doc(msgId);
        batch.set(chatMsgRef, {
            msgId: msgId,
            senderId: "official_team",
            type: "text",
            textMsg: messageText,
            fileUrl: "",
            gifUrl: "",
            videoThumbnail: "",
            isRead: false,
            isDelivered: false,
            isRecAudio: false,
            isForwarded: false,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Save in receiver's official_notifications subcollection
        const notifRef = db.collection("Users").doc(userId)
            .collection("official_notifications").doc(msgId);
        batch.set(notifRef, {
            msgId: msgId,
            senderId: "official_team",
            type: "text",
            textMsg: messageText,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 3. Update the Chat Node for receiver
        const chatNodeRef = db.collection("Users").doc(userId)
            .collection("Chats").doc("official_team");
        batch.set(chatNodeRef, {
            senderId: "official_team",
            msgType: "text",
            lastMsg: messageText,
            msgId: msgId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // 4. Centralized audit log
        const auditRef = db.collection("official_notification_logs").doc(msgId);
        batch.set(auditRef, {
            msgId: msgId,
            senderId: "official_team",
            receiverId: userId,
            textMsg: messageText,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await batch.commit();
        console.log(`[OfficialTeam] Sent official notification to user ${userId}: "${messageText}"`);

        // 5. Send FCM Push Notification
        if (deviceToken) {
            try {
                await admin.messaging().send({
                    token: deviceToken,
                    notification: {
                        title: "imChat Official team",
                        body: messageText,
                    },
                    data: {
                        type: "message",
                        senderId: "official_team",
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                });
                console.log(`[OfficialTeam] FCM notification sent successfully to user ${userId}`);
            } catch (fcmErr) {
                console.warn(`[OfficialTeam] FCM send note for user ${userId}:`, fcmErr.message);
            }
        }
    } catch (err) {
        console.error(`[OfficialTeam] Error sending official notification to user ${userId}:`, err);
    }
}

/**
 * Firestore Trigger: Runs immediately when a user creates (or updates) a rechargeOrder.
 * 1. If status transitioned to "Approved" (e.g. manual admin approval), sends official notification.
 * 2. If status is "Pending", matches with any already-received incoming transaction in `incoming_transactions`.
 */
exports.onRechargeOrderWritten = onDocumentWritten("rechargeOrders/{orderId}", async (event) => {
    const after = event.data ? event.data.after : null;
    const before = event.data ? event.data.before : null;
    if (!after || !after.exists) return;

    const orderData = after.data();
    const beforeData = before && before.exists ? before.data() : null;
    const db = admin.firestore();

    // Check if order just transitioned to "Approved" (e.g. approved manually by admin)
    if (orderData.status === "Approved" && (!beforeData || beforeData.status !== "Approved")) {
        if (orderData.notificationSent !== true) {
            const userId = orderData.userId;
            const diamonds = (Number(orderData.diamondAmount) || 0) + (Number(orderData.bonusDiamonds) || 0);
            const amount = orderData.amount || 0;
            const method = orderData.paymentMethod || "Online";
            const trxId = orderData.transactionId || "";
            const notifMsg = `🎉 Congratulations! Your online recharge of ${diamonds} diamonds (৳${amount} via ${method}) has been successfully credited to your wallet. TrxID: ${trxId}`;

            await sendOfficialNotification(db, userId, notifMsg);
            await after.ref.update({ notificationSent: true }).catch(() => {});
        }
        return;
    }

    if ((orderData.status || "").toLowerCase() !== "pending") return;

    const rawTrxId = (orderData.transactionId || "").trim();
    if (!rawTrxId) return;

    const trxId = rawTrxId.toUpperCase();

    // Check if auto-approve is globally enabled
    const configDoc = await db.doc("app_settings/auto_approve_config").get();
    const configData = configDoc.exists ? configDoc.data() || {} : {};
    if (configData.isAutoApproveEnabled === false) {
        console.log(`[onRechargeOrderWritten] Auto-approve is disabled globally.`);
        return;
    }

    // Look for matching incoming transaction
    const trxRef = db.collection("incoming_transactions").doc(trxId);
    const trxSnap = await trxRef.get();

    if (!trxSnap.exists) {
        console.log(`[onRechargeOrderWritten] No incoming SMS found yet for TrxID: ${trxId}`);
        return;
    }

    const trxData = trxSnap.data();
    if (trxData.status !== "unclaimed") {
        console.log(`[onRechargeOrderWritten] TrxID ${trxId} already processed with status: ${trxData.status}`);
        return;
    }

    try {
        const result = await performAutoApprove(db, event.params.orderId, orderData, trxSnap);
        if (!result.success) {
            console.warn(`[onRechargeOrderWritten] Auto-approval check failed: ${result.reason}`);
        }
    } catch (err) {
        console.error(`[onRechargeOrderWritten] Error executing auto-approve for order ${event.params.orderId}:`, err);
    }
});

/**
 * HTTP Endpoint to manually scan & match any pending recharge orders against unclaimed incoming transactions.
 */
exports.matchPendingRechargeOrders = onRequest({ cors: true }, async (req, res) => {
    const db = admin.firestore();
    const pendingSnap = await db.collection("rechargeOrders")
        .where("status", "==", "Pending")
        .get();

    const results = [];
    const debugList = [];
    for (const doc of pendingSnap.docs) {
        const orderData = doc.data();
        const trxId = (orderData.transactionId || "").trim().toUpperCase();
        const trxSnap = trxId ? await db.collection("incoming_transactions").doc(trxId).get() : null;

        const info = {
            orderId: doc.id,
            orderTrxId: trxId,
            orderAmount: orderData.amount,
            trxExists: trxSnap ? trxSnap.exists : false,
            trxStatus: trxSnap && trxSnap.exists ? trxSnap.data().status : null,
            trxAmount: trxSnap && trxSnap.exists ? trxSnap.data().amount : null,
        };
        debugList.push(info);

        if (trxSnap && trxSnap.exists && trxSnap.data().status === "unclaimed") {
            try {
                const resApprove = await performAutoApprove(db, doc.id, orderData, trxSnap);
                results.push({ orderId: doc.id, trxId, result: resApprove });
            } catch (e) {
                results.push({ orderId: doc.id, trxId, error: e.message });
            }
        }
    }

    const allIncSnap = await db.collection("incoming_transactions").limit(10).get();
    const recentIncoming = allIncSnap.docs.map(d => ({ id: d.id, ...d.data() }));

    return res.status(200).json({
        checked: pendingSnap.size,
        recentIncoming: recentIncoming,
        debugList: debugList,
        processed: results,
    });
});

