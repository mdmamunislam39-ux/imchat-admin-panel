/**
 * Asset Manager & Texture Slicer for "King of the Castle" Slot Game
 * Slices high-resolution textures directly from k0ab_b4uq_160921.jpg
 */
class AssetManager {
  constructor() {
    this.sourceImage = null;
    this.symbols = {};
    this.reelBackground = null;
    this.loaded = false;
  }

  load() {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.src = 'k0ab_b4uq_160921.jpg';
      img.onload = () => {
        this.sourceImage = img;
        this.sliceSymbols();
        this.createWildSymbol();
        this.createReelBackground();
        this.loaded = true;
        resolve();
      };
      img.onerror = (err) => {
        console.error('Failed to load base asset image:', err);
        reject(err);
      };
    });
  }

  sliceSymbols() {
    const img = this.sourceImage;
    const cellW = 868;
    const cellH = 780;
    const startX = 590;
    const startY = 660;
    const cropSize = 720;
    const targetSize = 250; // Output symbol canvas size

    // Exact grid mappings from the high-res artwork
    const gridDefinitions = {
      'nine':   { col: 0, row: 0, name: 'Nine', payout: 80, isHigh: false },
      'ten':    { col: 1, row: 0, name: 'Ten', payout: 100, isHigh: false },
      'k':      { col: 2, row: 0, name: 'King Letter', payout: 250, isHigh: false },
      'king':   { col: 3, row: 0, name: 'King', payout: 1000, isHigh: true },
      'castle': { col: 4, row: 0, name: 'Castle', payout: 500, isHigh: true, isScatter: true },
      'queen':  { col: 0, row: 1, name: 'Queen', payout: 600, isHigh: true },
      'q':      { col: 2, row: 1, name: 'Queen Letter', payout: 200, isHigh: false },
      'j':      { col: 4, row: 1, name: 'Jack', payout: 150, isHigh: false },
      'knight': { col: 0, row: 2, name: 'Knight', payout: 400, isHigh: true }
    };

    for (const [key, def] of Object.entries(gridDefinitions)) {
      const sx = startX + def.col * cellW;
      const sy = startY + def.row * cellH;
      const cx = sx + cellW / 2;
      const cy = sy + cellH / 2;

      const canvas = document.createElement('canvas');
      canvas.width = targetSize;
      canvas.height = targetSize;
      const ctx = canvas.getContext('2d');

      // High quality smoothing
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';

      // Draw cropped symbol
      ctx.drawImage(
        img,
        cx - cropSize / 2, cy - cropSize / 2, cropSize, cropSize,
        0, 0, targetSize, targetSize
      );

      this.symbols[key] = {
        id: key,
        canvas: canvas,
        ...def
      };
    }
  }

  // Create a stunning Royal Wild Crown symbol
  createWildSymbol() {
    const targetSize = 250;
    const canvas = document.createElement('canvas');
    canvas.width = targetSize;
    canvas.height = targetSize;
    const ctx = canvas.getContext('2d');

    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';

    const cx = targetSize / 2;
    const cy = targetSize / 2;
    const radius = targetSize * 0.42;

    // Glowing cyan / gold sphere background matching royal badges
    const grad = ctx.createRadialGradient(cx - 25, cy - 25, 10, cx, cy, radius);
    grad.addColorStop(0, '#75e6ff');
    grad.addColorStop(0.4, '#1b8dc2');
    grad.addColorStop(0.85, '#0d4a75');
    grad.addColorStop(1, '#082542');

    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fillStyle = grad;
    ctx.fill();

    // Outer golden bevel rim
    ctx.lineWidth = 10;
    const rimGrad = ctx.createLinearGradient(cx - radius, cy - radius, cx + radius, cy + radius);
    rimGrad.addColorStop(0, '#ffeeaa');
    rimGrad.addColorStop(0.5, '#d4af37');
    rimGrad.addColorStop(1, '#8a6510');
    ctx.strokeStyle = rimGrad;
    ctx.stroke();

    // Inner highlight ring
    ctx.beginPath();
    ctx.arc(cx, cy, radius - 6, 0, Math.PI * 2);
    ctx.lineWidth = 2;
    ctx.strokeStyle = 'rgba(255,255,255,0.4)';
    ctx.stroke();

    // Draw Royal Crown
    ctx.fillStyle = '#ffcf26';
    ctx.beginPath();
    const crownTop = cy - 45;
    const crownBottom = cy + 18;
    const crownW = 90;

    ctx.moveTo(cx - crownW/2, crownBottom);
    ctx.lineTo(cx + crownW/2, crownBottom);
    ctx.lineTo(cx + crownW/2 + 5, crownTop + 5);
    ctx.lineTo(cx + crownW/4, crownTop + 25);
    ctx.lineTo(cx, crownTop - 10);
    ctx.lineTo(cx - crownW/4, crownTop + 25);
    ctx.lineTo(cx - crownW/2 - 5, crownTop + 5);
    ctx.closePath();
    ctx.fill();

    ctx.lineWidth = 4;
    ctx.strokeStyle = '#946604';
    ctx.stroke();

    // Crown jewels (rubies & emeralds)
    const jewels = [
      { x: cx, y: crownTop - 10, color: '#ff2222', r: 5 },
      { x: cx - crownW/2 - 5, y: crownTop + 5, color: '#00e676', r: 4.5 },
      { x: cx + crownW/2 + 5, y: crownTop + 5, color: '#00e676', r: 4.5 },
      { x: cx - 20, y: crownBottom - 10, color: '#ff2222', r: 4 },
      { x: cx, y: crownBottom - 10, color: '#00e5ff', r: 5 },
      { x: cx + 20, y: crownBottom - 10, color: '#ff2222', r: 4 }
    ];
    jewels.forEach(j => {
      ctx.beginPath();
      ctx.arc(j.x, j.y, j.r, 0, Math.PI * 2);
      ctx.fillStyle = j.color;
      ctx.fill();
      ctx.lineWidth = 1.5;
      ctx.strokeStyle = '#fff';
      ctx.stroke();
    });

    // Crown base band
    ctx.beginPath();
    ctx.rect(cx - crownW/2, crownBottom - 6, crownW, 10);
    ctx.fillStyle = '#f5b000';
    ctx.fill();
    ctx.stroke();

    // Royal Banner "WILD"
    ctx.save();
    const bannerW = 140;
    const bannerH = 40;
    const bannerY = cy + 22;

    const bGrad = ctx.createLinearGradient(cx, bannerY, cx, bannerY + bannerH);
    bGrad.addColorStop(0, '#c41c1c');
    bGrad.addColorStop(0.5, '#e52d27');
    bGrad.addColorStop(1, '#820b0b');

    ctx.shadowColor = 'rgba(0,0,0,0.8)';
    ctx.shadowBlur = 10;
    ctx.shadowOffsetY = 4;

    ctx.fillStyle = bGrad;
    ctx.beginPath();
    ctx.roundRect(cx - bannerW/2, bannerY, bannerW, bannerH, 8);
    ctx.fill();

    ctx.lineWidth = 3;
    ctx.strokeStyle = '#ffd700';
    ctx.stroke();

    // WILD text
    ctx.shadowColor = 'rgba(0,0,0,0.9)';
    ctx.shadowBlur = 4;
    ctx.shadowOffsetY = 2;
    ctx.fillStyle = '#ffffff';
    ctx.font = '900 24px "Cinzel", "Times New Roman", serif, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('WILD', cx, bannerY + bannerH/2 + 2);
    ctx.restore();

    ctx.restore();

    this.symbols['wild'] = {
      id: 'wild',
      canvas: canvas,
      name: 'Royal Wild',
      payout: 2500,
      isHigh: true,
      isWild: true
    };
  }

  // Create crisp dark metallic reel background column texture
  createReelBackground() {
    const w = 200;
    const h = 600;
    const canvas = document.createElement('canvas');
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext('2d');

    // Base dark metallic gradient matching original artwork
    const grad = ctx.createLinearGradient(0, 0, w, 0);
    grad.addColorStop(0, '#151515');
    grad.addColorStop(0.08, '#262626');
    grad.addColorStop(0.5, '#2f2e2e');
    grad.addColorStop(0.92, '#262626');
    grad.addColorStop(1, '#151515');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, w, h);

    // Silver sheen across the top 35% like the original slot machine
    const shineGrad = ctx.createLinearGradient(0, 0, 0, h * 0.35);
    shineGrad.addColorStop(0, 'rgba(255, 255, 255, 0.45)');
    shineGrad.addColorStop(0.4, 'rgba(255, 255, 255, 0.25)');
    shineGrad.addColorStop(0.95, 'rgba(255, 255, 255, 0.05)');
    shineGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
    ctx.fillStyle = shineGrad;
    ctx.fillRect(0, 0, w, h * 0.35);

    // Side separator lines
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(0, 0, 3, h);
    ctx.fillRect(w - 3, 0, 3, h);

    this.reelBackground = canvas;
  }
}

window.assetManager = new AssetManager();
