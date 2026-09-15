/**
 * Arabian Nights Gem Spin Slot - Visual Effects & Particles
 * Handles Coin Rain, Energy Laser Beams, and Winning Line Overlays
 */

class EffectsManager {
  constructor() {
    this.canvas = null;
    this.ctx = null;
    this.particles = [];
    this.animId = null;
    this.lastTime = 0;
  }

  init(canvasElement) {
    this.canvas = canvasElement;
    if (this.canvas) {
      this.ctx = this.canvas.getContext('2d');
      this.resize();
      window.addEventListener('resize', () => this.resize());
      this.startLoop();
    }
  }

  resize() {
    if (this.canvas) {
      this.canvas.width = this.canvas.clientWidth || window.innerWidth;
      this.canvas.height = this.canvas.clientHeight || window.innerHeight;
    }
  }

  startLoop() {
    const loop = (timestamp) => {
      this.update(timestamp);
      this.render();
      this.animId = requestAnimationFrame(loop);
    };
    this.animId = requestAnimationFrame(loop);
  }

  // Spawn celebratory gold coins for Big Win / Mega Win
  spawnCoinExplosion(count = 70) {
    if (!this.canvas) return;
    const cx = this.canvas.width / 2;
    const cy = this.canvas.height / 2;

    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 12 + 4;
      this.particles.push({
        type: 'coin',
        x: cx + (Math.random() * 80 - 40),
        y: cy + (Math.random() * 60 - 30),
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 8,
        gravity: 0.35,
        rotation: Math.random() * Math.PI,
        vRot: (Math.random() - 0.5) * 0.25,
        scaleX: 1,
        vScale: (Math.random() * 0.15 + 0.05),
        radius: Math.random() * 6 + 10,
        alpha: 1,
        life: 1
      });
    }
  }

  // Spawn gem collection spark burst
  spawnGemSparks(x, y, color = '#22d3ee') {
    for (let i = 0; i < 25; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = Math.random() * 7 + 2;
      this.particles.push({
        type: 'spark',
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        gravity: 0.1,
        radius: Math.random() * 3 + 2,
        color: color,
        alpha: 1,
        life: 1
      });
    }
  }

  update(timestamp) {
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += p.gravity;
      p.rotation += p.vRot || 0;
      if (p.type === 'coin') {
        p.scaleX = Math.cos(p.rotation);
      }
      p.life -= 0.012;
      p.alpha = Math.max(0, p.life);

      if (p.life <= 0 || p.y > this.canvas.height + 50) {
        this.particles.splice(i, 1);
      }
    }
  }

  render() {
    if (!this.ctx) return;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    for (const p of this.particles) {
      this.ctx.save();
      this.ctx.globalAlpha = p.alpha;

      if (p.type === 'coin') {
        this.ctx.translate(p.x, p.y);
        this.ctx.scale(p.scaleX, 1);
        
        // Gold Coin Drawing
        const grad = this.ctx.createRadialGradient(0, 0, 1, 0, 0, p.radius);
        grad.addColorStop(0, '#fef08a');
        grad.addColorStop(0.6, '#eab308');
        grad.addColorStop(1, '#a16207');

        this.ctx.beginPath();
        this.ctx.arc(0, 0, p.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = grad;
        this.ctx.fill();

        this.ctx.lineWidth = 1.5;
        this.ctx.strokeStyle = '#fff';
        this.ctx.stroke();

        // Inner rim
        this.ctx.beginPath();
        this.ctx.arc(0, 0, p.radius * 0.7, 0, Math.PI * 2);
        this.ctx.strokeStyle = '#713f12';
        this.ctx.stroke();
      } else if (p.type === 'spark') {
        this.ctx.beginPath();
        this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = p.color;
        this.ctx.shadowColor = p.color;
        this.ctx.shadowBlur = 8;
        this.ctx.fill();
      }

      this.ctx.restore();
    }
  }

  // Draw winning paylines overlay
  drawPaylines(lineWins, reelElements, gridContainer) {
    let svg = document.getElementById('payline-overlay');
    if (!svg) {
      svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.id = 'payline-overlay';
      gridContainer.appendChild(svg);
    }
    svg.innerHTML = '';

    const containerRect = gridContainer.getBoundingClientRect();
    const colors = ['#f59e0b', '#ec4899', '#38bdf8', '#10b981', '#a855f7', '#fbbf24', '#f43f5e'];

    lineWins.forEach((win, idx) => {
      const points = [];
      win.positions.forEach(pos => {
        const cell = reelElements[pos.col].children[pos.row];
        if (cell) {
          const rect = cell.getBoundingClientRect();
          const x = rect.left - containerRect.left + rect.width / 2;
          const y = rect.top - containerRect.top + rect.height / 2;
          points.push(`${x},${y}`);
        }
      });

      if (points.length > 1) {
        const polyline = document.createElementNS('http://www.w3.org/2000/svg', 'polyline');
        polyline.setAttribute('points', points.join(' '));
        const color = colors[idx % colors.length];
        polyline.setAttribute('stroke', color);
        polyline.setAttribute('stroke-width', '5');
        polyline.setAttribute('stroke-linecap', 'round');
        polyline.setAttribute('stroke-linejoin', 'round');
        polyline.setAttribute('fill', 'none');
        polyline.classList.add('glowing-payline');
        svg.appendChild(polyline);
      }
    });
  }

  clearPaylines() {
    const svg = document.getElementById('payline-overlay');
    if (svg) svg.innerHTML = '';
  }

  // Draw Hold & Spin energy beam connecting gems sequentially
  async animateEnergyBeam(gemElements, winBoxElement) {
    if (!gemElements || gemElements.length === 0) return;
    
    let beamSvg = document.getElementById('beam-overlay');
    if (!beamSvg) {
      beamSvg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      beamSvg.id = 'beam-overlay';
      document.body.appendChild(beamSvg);
    }
    beamSvg.innerHTML = '';

    for (let i = 0; i < gemElements.length; i++) {
      const curr = gemElements[i];
      const currRect = curr.getBoundingClientRect();
      const currX = currRect.left + currRect.width / 2;
      const currY = currRect.top + currRect.height / 2;

      // Pulse current gem
      curr.classList.add('gem-collecting');
      this.spawnGemSparks(currX, currY, '#38bdf8');
      SOUND.playEnergyBeam(i);

      // Beam to WIN box
      if (winBoxElement) {
        const winRect = winBoxElement.getBoundingClientRect();
        const winX = winRect.left + winRect.width / 2;
        const winY = winRect.top + winRect.height / 2;

        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        const d = `M ${currX} ${currY} Q ${(currX + winX)/2 + 40} ${(currY + winY)/2 - 30} ${winX} ${winY}`;
        path.setAttribute('d', d);
        path.setAttribute('stroke', '#38bdf8');
        path.setAttribute('stroke-width', '4');
        path.setAttribute('stroke-linecap', 'round');
        path.setAttribute('fill', 'none');
        path.classList.add('energy-beam-path');
        beamSvg.appendChild(path);

        this.spawnGemSparks(winX, winY, '#fbbf24');
      }

      await new Promise(r => setTimeout(r, 260));
    }

    setTimeout(() => {
      if (beamSvg) beamSvg.innerHTML = '';
    }, 600);
  }
}

const EFFECTS = new EffectsManager();
