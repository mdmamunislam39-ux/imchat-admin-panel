/**
 * Ludo Board Coordinate System & Track Definitions
 * 15x15 standard grid matrix
 */

const LUDO_DATA = {
    BOARD_SIZE: 15,

    // Safe squares on the 52-step main track (0-indexed)
    SAFE_SPOTS: [0, 8, 13, 21, 26, 34, 39, 47],

    // Player color configurations matching reference UI
    COLORS: {
        green: {
            id: 'green',
            name: 'সবুজ (Green)',
            startTrackIndex: 0,
            colorHex: '#00a859',
            gradient: 'linear-gradient(135deg, #10b981, #059669)',
            accent: '#a7f3d0',
            baseTokens: [
                { r: 3.2, c: 1.2 },
                { r: 3.2, c: 2.4 },
                { r: 3.2, c: 3.6 },
                { r: 3.2, c: 4.8 }
            ],
            homeRun: [
                { r: 7, c: 1 },
                { r: 7, c: 2 },
                { r: 7, c: 3 },
                { r: 7, c: 4 },
                { r: 7, c: 5 }
            ],
            homeTriangle: { r: 7, c: 6.2 }
        },
        yellow: {
            id: 'yellow',
            name: 'হলুদ (Yellow)',
            startTrackIndex: 13,
            colorHex: '#f59e0b',
            gradient: 'linear-gradient(135deg, #fbbf24, #d97706)',
            accent: '#fde68a',
            baseTokens: [
                { r: 3.2, c: 9.8 },
                { r: 3.2, c: 11.0 },
                { r: 3.2, c: 12.2 },
                { r: 3.2, c: 13.4 }
            ],
            homeRun: [
                { r: 1, c: 7 },
                { r: 2, c: 7 },
                { r: 3, c: 7 },
                { r: 4, c: 7 },
                { r: 5, c: 7 }
            ],
            homeTriangle: { r: 6.2, c: 7 }
        },
        blue: {
            id: 'blue',
            name: 'নীল (Blue)',
            startTrackIndex: 26,
            colorHex: '#0284c7',
            gradient: 'linear-gradient(135deg, #38bdf8, #0369a1)',
            accent: '#bae6fd',
            baseTokens: [
                { r: 10.2, c: 9.8 },
                { r: 10.2, c: 11.0 },
                { r: 10.2, c: 12.2 },
                { r: 10.2, c: 13.4 }
            ],
            homeRun: [
                { r: 7, c: 13 },
                { r: 7, c: 12 },
                { r: 7, c: 11 },
                { r: 7, c: 10 },
                { r: 7, c: 9 }
            ],
            homeTriangle: { r: 7, c: 7.8 }
        },
        red: {
            id: 'red',
            name: 'লাল (Red)',
            startTrackIndex: 39,
            colorHex: '#ef4444',
            gradient: 'linear-gradient(135deg, #f87171, #dc2626)',
            accent: '#fecaca',
            baseTokens: [
                { r: 10.2, c: 1.2 },
                { r: 10.2, c: 2.4 },
                { r: 10.2, c: 3.6 },
                { r: 10.2, c: 4.8 }
            ],
            homeRun: [
                { r: 13, c: 7 },
                { r: 12, c: 7 },
                { r: 11, c: 7 },
                { r: 10, c: 7 },
                { r: 9, c: 7 }
            ],
            homeTriangle: { r: 7.8, c: 7 }
        }
    },

    // 52 track squares clockwise (0 = Red start, 13 = Green start, 26 = Yellow start, 39 = Blue start)
    TRACK: [
        /* 0  */ { r: 6, c: 1 },  // Red start
        /* 1  */ { r: 6, c: 2 },
        /* 2  */ { r: 6, c: 3 },
        /* 3  */ { r: 6, c: 4 },
        /* 4  */ { r: 6, c: 5 },
        /* 5  */ { r: 5, c: 6 },
        /* 6  */ { r: 4, c: 6 },
        /* 7  */ { r: 3, c: 6 },
        /* 8  */ { r: 2, c: 6 },  // Safe Star
        /* 9  */ { r: 1, c: 6 },
        /* 10 */ { r: 0, c: 6 },
        /* 11 */ { r: 0, c: 7 },
        /* 12 */ { r: 0, c: 8 },
        /* 13 */ { r: 1, c: 8 },  // Green start
        /* 14 */ { r: 2, c: 8 },
        /* 15 */ { r: 3, c: 8 },
        /* 16 */ { r: 4, c: 8 },
        /* 17 */ { r: 5, c: 8 },
        /* 18 */ { r: 6, c: 9 },
        /* 19 */ { r: 6, c: 10 },
        /* 20 */ { r: 6, c: 11 },
        /* 21 */ { r: 6, c: 12 }, // Safe Star
        /* 22 */ { r: 6, c: 13 },
        /* 23 */ { r: 6, c: 14 },
        /* 24 */ { r: 7, c: 14 },
        /* 25 */ { r: 8, c: 14 },
        /* 26 */ { r: 8, c: 13 }, // Yellow start
        /* 27 */ { r: 8, c: 12 },
        /* 28 */ { r: 8, c: 11 },
        /* 29 */ { r: 8, c: 10 },
        /* 30 */ { r: 8, c: 9 },
        /* 31 */ { r: 9, c: 8 },
        /* 32 */ { r: 10, c: 8 },
        /* 33 */ { r: 11, c: 8 },
        /* 34 */ { r: 12, c: 8 }, // Safe Star
        /* 35 */ { r: 13, c: 8 },
        /* 36 */ { r: 14, c: 8 },
        /* 37 */ { r: 14, c: 7 },
        /* 38 */ { r: 14, c: 6 },
        /* 39 */ { r: 13, c: 6 }, // Blue start
        /* 40 */ { r: 12, c: 6 },
        /* 41 */ { r: 11, c: 6 },
        /* 42 */ { r: 10, c: 6 },
        /* 43 */ { r: 9, c: 6 },
        /* 44 */ { r: 8, c: 5 },
        /* 45 */ { r: 8, c: 4 },
        /* 46 */ { r: 8, c: 3 },
        /* 47 */ { r: 8, c: 2 },  // Safe Star
        /* 48 */ { r: 8, c: 1 },
        /* 49 */ { r: 8, c: 0 },
        /* 50 */ { r: 7, c: 0 },
        /* 51 */ { r: 6, c: 0 }
    ],

    /**
     * Get the position object {r, c} for a token at a given step (0..56)
     * step -1: in base
     * step 0..50: on common track (0 is color's start cell, up to 50 steps around)
     * step 51..55: on private home runway (5 cells)
     * step 56: reached center home triangle
     */
    getTokenCoordinates(color, step, tokenIndex = 0) {
        if (step === -1) {
            // Inside Yard Base
            return this.COLORS[color].baseTokens[tokenIndex];
        }

        if (step >= 0 && step <= 50) {
            const startIdx = this.COLORS[color].startTrackIndex;
            const trackIdx = (startIdx + step) % 52;
            return this.TRACK[trackIdx];
        }

        if (step >= 51 && step <= 55) {
            const homeIdx = step - 51;
            return this.COLORS[color].homeRun[homeIdx];
        }

        if (step >= 56) {
            return this.COLORS[color].homeTriangle;
        }

        return { r: 0, c: 0 };
    },

    /**
     * Get global track index for a token if it is on the common track (0..50)
     */
    getGlobalTrackIndex(color, step) {
        if (step >= 0 && step <= 50) {
            return (this.COLORS[color].startTrackIndex + step) % 52;
        }
        return -1; // In yard or home runway
    },

    /**
     * Check if a position is a safe cell
     */
    isSafePosition(color, step) {
        if (step < 0) return true; // Yard is safe
        if (step >= 51) return true; // Home run & center are safe
        const globalIdx = this.getGlobalTrackIndex(color, step);
        return this.SAFE_SPOTS.includes(globalIdx);
    }
};

window.LUDO_DATA = LUDO_DATA;
