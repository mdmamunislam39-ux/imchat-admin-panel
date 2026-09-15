/**
 * Ludo Game Web Audio Synthesizer
 * Zero-dependency procedural sound effects generator
 */
class LudoAudio {
    constructor() {
        this.ctx = null;
        this.muted = localStorage.getItem('ludo_muted') === 'true';
        this.volume = 0.7;
    }

    init() {
        if (!this.ctx) {
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            if (AudioContext) {
                this.ctx = new AudioContext();
            }
        }
        if (this.ctx && this.ctx.state === 'suspended') {
            this.ctx.resume();
        }
    }

    toggleMute() {
        this.muted = !this.muted;
        localStorage.setItem('ludo_muted', this.muted);
        return this.muted;
    }

    // Play dice rolling rattle sound
    playDiceRoll() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const totalDuration = 0.55;
        const rattleCount = 6;

        for (let i = 0; i < rattleCount; i++) {
            const time = now + (i * (totalDuration / rattleCount)) + (Math.random() * 0.02);
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            const filter = this.ctx.createBiquadFilter();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(140 + Math.random() * 220, time);
            osc.frequency.exponentialRampToValueAtTime(60, time + 0.05);

            filter.type = 'lowpass';
            filter.frequency.setValueAtTime(800, time);

            gain.gain.setValueAtTime(0.3 * this.volume, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.06);

            osc.connect(filter);
            filter.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(time);
            osc.stop(time + 0.07);
        }
    }

    // Token step hop sound
    playTokenStep(stepIndex = 0) {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        const baseFreq = 380 + (stepIndex % 6) * 35;
        osc.type = 'sine';
        osc.frequency.setValueAtTime(baseFreq, now);
        osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.5, now + 0.04);
        osc.frequency.exponentialRampToValueAtTime(baseFreq * 0.8, now + 0.08);

        gain.gain.setValueAtTime(0.25 * this.volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(now);
        osc.stop(now + 0.1);
    }

    // Capture sound (impact/strike)
    playCapture() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        // Low punch
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(280, now);
        osc.frequency.exponentialRampToValueAtTime(40, now + 0.25);

        gain.gain.setValueAtTime(0.4 * this.volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.28);

        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(now);
        osc.stop(now + 0.3);

        // Zap sound
        const osc2 = this.ctx.createOscillator();
        const gain2 = this.ctx.createGain();
        osc2.type = 'triangle';
        osc2.frequency.setValueAtTime(600, now);
        osc2.frequency.linearRampToValueAtTime(150, now + 0.2);

        gain2.gain.setValueAtTime(0.3 * this.volume, now);
        gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.2);

        osc2.connect(gain2);
        gain2.connect(this.ctx.destination);
        osc2.start(now);
        osc2.stop(now + 0.22);
    }

    // Safe star landing chime
    playSafeZone() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const notes = [523.25, 659.25, 783.99, 1046.50]; // C, E, G, High C
        const now = this.ctx.currentTime;

        notes.forEach((freq, idx) => {
            const time = now + idx * 0.06;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, time);

            gain.gain.setValueAtTime(0.2 * this.volume, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.25);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(time);
            osc.stop(time + 0.26);
        });
    }

    // Bonus roll sound (rolled 6 or captured)
    playBonus() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const notes = [440, 554.37, 659.25, 880];
        notes.forEach((freq, idx) => {
            const time = now + idx * 0.07;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, time);

            gain.gain.setValueAtTime(0.25 * this.volume, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.2);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(time);
            osc.stop(time + 0.22);
        });
    }

    // Token reaching home finish
    playTokenHome() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const notes = [523.25, 659.25, 783.99, 1046.50, 1318.51];
        notes.forEach((freq, idx) => {
            const time = now + idx * 0.08;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, time);

            gain.gain.setValueAtTime(0.3 * this.volume, time);
            gain.gain.exponentialRampToValueAtTime(0.001, time + 0.35);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(time);
            osc.stop(time + 0.36);
        });
    }

    // Victory fanfare
    playWin() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const melody = [
            { f: 523.25, d: 0.15 },
            { f: 523.25, d: 0.15 },
            { f: 523.25, d: 0.15 },
            { f: 659.25, d: 0.4 },
            { f: 587.33, d: 0.2 },
            { f: 659.25, d: 0.2 },
            { f: 783.99, d: 0.6 }
        ];

        let curTime = this.ctx.currentTime;
        melody.forEach(note => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(note.f, curTime);

            gain.gain.setValueAtTime(0.35 * this.volume, curTime);
            gain.gain.exponentialRampToValueAtTime(0.001, curTime + note.d);

            osc.connect(gain);
            gain.connect(this.ctx.destination);

            osc.start(curTime);
            osc.stop(curTime + note.d + 0.05);

            curTime += note.d * 0.9;
        });
    }

    // Turn alert chime
    playTurnChime() {
        if (this.muted) return;
        this.init();
        if (!this.ctx) return;

        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(650, now);
        osc.frequency.exponentialRampToValueAtTime(880, now + 0.12);

        gain.gain.setValueAtTime(0.15 * this.volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.18);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(now);
        osc.stop(now + 0.2);
    }
}

window.ludoAudio = new LudoAudio();
