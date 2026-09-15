/**
 * Web Audio API Sound Effects Generator for "King of the Castle" Slot Game
 * 100% synthesized in real-time - Zero external audio file dependencies
 */
class SoundEngine {
  constructor() {
    this.ctx = null;
    this.muted = false;
    this.spinOsc = null;
    this.spinInterval = null;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  toggleMute() {
    this.muted = !this.muted;
    return this.muted;
  }

  // Tactile click for buttons
  playClick() {
    if (this.muted) return;
    this.init();
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(600, now);
      osc.frequency.exponentialRampToValueAtTime(200, now + 0.05);

      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(now);
      osc.stop(now + 0.06);
    } catch (e) {}
  }

  // Continuous mechanical reel spin ratchet ticks
  startSpinSound() {
    if (this.muted) return;
    this.init();
    this.stopSpinSound();

    let step = 0;
    this.spinInterval = setInterval(() => {
      if (this.muted || !this.ctx) return;
      try {
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        // Mechanical clicking ratchet
        const baseFreq = (step % 2 === 0) ? 380 : 420;
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(baseFreq, now);
        osc.frequency.exponentialRampToValueAtTime(120, now + 0.035);

        gain.gain.setValueAtTime(0.18, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(now);
        osc.stop(now + 0.04);
        step++;
      } catch (e) {}
    }, 70);
  }

  stopSpinSound() {
    if (this.spinInterval) {
      clearInterval(this.spinInterval);
      this.spinInterval = null;
    }
  }

  // Solid mechanical clunk when a reel lands (ascending pitch reel 1 -> 5)
  playReelStop(reelIndex = 0) {
    if (this.muted) return;
    this.init();
    try {
      const now = this.ctx.currentTime;
      const baseFreq = 110 + reelIndex * 24;

      // Heavy bass thud
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(baseFreq, now);
      osc.frequency.exponentialRampToValueAtTime(35, now + 0.12);

      gain.gain.setValueAtTime(0.45, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(now);
      osc.stop(now + 0.13);

      // Subtle metallic tick
      const tick = this.ctx.createOscillator();
      const tickGain = this.ctx.createGain();
      tick.type = 'triangle';
      tick.frequency.setValueAtTime(600 + reelIndex * 100, now);
      tick.frequency.exponentialRampToValueAtTime(250, now + 0.04);
      tickGain.gain.setValueAtTime(0.15, now);
      tickGain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
      tick.connect(tickGain);
      tickGain.connect(this.ctx.destination);
      tick.start(now);
      tick.stop(now + 0.05);
    } catch (e) {}
  }

  // Crisp metallic coin drop / clink sound
  playCoin() {
    if (this.muted) return;
    this.init();
    try {
      const now = this.ctx.currentTime;
      const osc1 = this.ctx.createOscillator();
      const osc2 = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      const baseF = 1800 + Math.random() * 400;
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(baseF, now);

      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(baseF * 1.5, now);

      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(this.ctx.destination);

      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + 0.09);
      osc2.stop(now + 0.09);
    } catch (e) {}
  }

  // Payline win chimes
  playWin(tier = 'normal') {
    if (this.muted) return;
    this.init();
    try {
      const notes = {
        normal: [523.25, 659.25, 783.99, 1046.50], // C5, E5, G5, C6
        big: [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98],
        mega: [440, 554.37, 659.25, 880, 1108.73, 1318.51, 1760],
        jackpot: [523.25, 659.25, 783.99, 1046.5, 1174.66, 1318.51, 1567.98, 2093.00]
      }[tier] || [523.25, 659.25, 783.99];

      const duration = tier === 'jackpot' ? 0.12 : 0.09;
      notes.forEach((freq, idx) => {
        const startT = this.ctx.currentTime + idx * duration;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, startT);

        gain.gain.setValueAtTime(0, startT);
        gain.gain.linearRampToValueAtTime(0.25, startT + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.001, startT + 0.28);

        osc.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(startT);
        osc.stop(startT + 0.3);
      });
    } catch (e) {}
  }

  // Royal Trumpet / Fanfare for Castle Bonus trigger
  playBonusTrumpet() {
    if (this.muted) return;
    this.init();
    try {
      // Royal fanfare triad: C4, G4, C5, E5, G5
      const fanfare = [
        { f: 261.63, t: 0.0, d: 0.15 },
        { f: 392.00, t: 0.16, d: 0.15 },
        { f: 523.25, t: 0.32, d: 0.22 },
        { f: 659.25, t: 0.55, d: 0.22 },
        { f: 783.99, t: 0.80, d: 0.50 }
      ];

      fanfare.forEach(note => {
        const startT = this.ctx.currentTime + note.t;
        const osc = this.ctx.createOscillator();
        const osc2 = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(note.f, startT);

        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(note.f * 2, startT);

        gain.gain.setValueAtTime(0, startT);
        gain.gain.linearRampToValueAtTime(0.28, startT + 0.04);
        gain.gain.exponentialRampToValueAtTime(0.001, startT + note.d);

        osc.connect(gain);
        osc2.connect(gain);
        gain.connect(this.ctx.destination);

        osc.start(startT);
        osc2.start(startT);
        osc.stop(startT + note.d + 0.05);
        osc2.stop(startT + note.d + 0.05);
      });
    } catch (e) {}
  }
}

window.soundEngine = new SoundEngine();
