/**
 * Arabian Nights Gem Spin Slot - Web Audio System
 * Real-time synthesis for low-latency, crisp slot sounds
 */

class SoundManager {
  constructor() {
    this.ctx = null;
    this.isMuted = false;
    this.spinLoopNode = null;
    this.spinGainNode = null;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  toggleMute() {
    this.isMuted = !this.isMuted;
    if (this.isMuted && this.spinGainNode) {
      this.spinGainNode.gain.setValueAtTime(0, this.ctx.currentTime);
    }
    return this.isMuted;
  }

  // Play a gentle button click
  playClick() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;
    
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(300, this.ctx.currentTime + 0.04);
    gain.gain.setValueAtTime(0.15, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.04);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.05);
  }

  // Spinning loop (rattling reels)
  startSpinSound() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    this.stopSpinSound();

    const bufferSize = this.ctx.sampleRate * 0.1;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = (Math.random() * 2 - 1) * 0.2;
    }

    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;
    noise.loop = true;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = 650;
    filter.Q.value = 3.0;

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(0.12, this.ctx.currentTime);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.ctx.destination);

    noise.start();
    this.spinLoopNode = noise;
    this.spinGainNode = gain;
  }

  stopSpinSound() {
    if (this.spinLoopNode) {
      try {
        if (this.spinGainNode) {
          this.spinGainNode.gain.linearRampToValueAtTime(0.001, this.ctx.currentTime + 0.05);
        }
        setTimeout(() => {
          if (this.spinLoopNode) {
            this.spinLoopNode.stop();
            this.spinLoopNode.disconnect();
            this.spinLoopNode = null;
          }
        }, 50);
      } catch (e) {
        this.spinLoopNode = null;
      }
    }
  }

  // Reel stop thump with rising pitch for anticipation
  playReelStop(reelIndex = 0) {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    const baseFreq = 160 + reelIndex * 35;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(baseFreq, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(45, this.ctx.currentTime + 0.12);

    gain.gain.setValueAtTime(0.35, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.12);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.13);

    // Subtle click impact
    const clickOsc = this.ctx.createOscillator();
    const clickGain = this.ctx.createGain();
    clickOsc.type = 'sine';
    clickOsc.frequency.setValueAtTime(900 + reelIndex * 150, this.ctx.currentTime);
    clickGain.gain.setValueAtTime(0.15, this.ctx.currentTime);
    clickGain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.04);
    clickOsc.connect(clickGain);
    clickGain.connect(this.ctx.destination);
    clickOsc.start();
    clickOsc.stop(this.ctx.currentTime + 0.05);
  }

  // Payline win chime
  playWinLine() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    notes.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const startTime = this.ctx.currentTime + idx * 0.07;

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, startTime);

      gain.gain.setValueAtTime(0.2, startTime);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.25);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(startTime);
      osc.stop(startTime + 0.26);
    });
  }

  // Coin rollup counter tick
  playCoinTick() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(1400 + Math.random() * 200, this.ctx.currentTime);
    gain.gain.setValueAtTime(0.15, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.03);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.035);
  }

  // Hold & Spin mode triggered: Arabian mystery fanfare
  playHoldSpinTrigger() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    // Arabian scale: D, Eb, F#, G, A, Bb, C#, D
    const melody = [293.66, 311.13, 369.99, 392.00, 440.00, 587.33];
    melody.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const startTime = this.ctx.currentTime + idx * 0.12;

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(freq, startTime);

      const filter = this.ctx.createBiquadFilter();
      filter.type = 'lowpass';
      filter.frequency.setValueAtTime(1200, startTime);

      gain.gain.setValueAtTime(0.22, startTime);
      gain.gain.exponentialRampToValueAtTime(0.01, startTime + 0.45);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(startTime);
      osc.stop(startTime + 0.46);
    });
  }

  // Gem locked in Hold & Spin (electric zap)
  playGemLock() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'square';
    osc.frequency.setValueAtTime(700, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(120, this.ctx.currentTime + 0.18);

    gain.gain.setValueAtTime(0.25, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.18);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.2);
  }

  // Energy beam collection sound (neon sweep)
  playEnergyBeam(index = 0) {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    const baseFreq = 440 + index * 60;

    osc.type = 'sine';
    osc.frequency.setValueAtTime(baseFreq, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.8, this.ctx.currentTime + 0.2);

    gain.gain.setValueAtTime(0.25, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, this.ctx.currentTime + 0.25);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.26);
  }

  // Mega Win celebratory fanfare
  playMegaWin() {
    if (this.isMuted) return;
    this.init();
    if (!this.ctx) return;

    const chords = [
      [523.25, 659.25, 783.99], // C
      [587.33, 739.99, 880.00], // D
      [659.25, 830.61, 987.77], // E
      [783.99, 987.77, 1174.66, 1567.98] // G major triumphant
    ];

    chords.forEach((chord, step) => {
      const startTime = this.ctx.currentTime + step * 0.22;
      chord.forEach(freq => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, startTime);
        gain.gain.setValueAtTime(0.18, startTime);
        gain.gain.exponentialRampToValueAtTime(0.01, startTime + (step === chords.length - 1 ? 1.2 : 0.28));
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start(startTime);
        osc.stop(startTime + 1.3);
      });
    });
  }
}

const SOUND = new SoundManager();
