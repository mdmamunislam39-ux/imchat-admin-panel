/**
 * Arabian Nights Gem Spin Slot - Symbol Renderers (Scalable High-End SVGs)
 */

const SYMBOL_RENDERERS = {
  // 1. Palm Tree with coconuts
  palm: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg palm-svg">
      <defs>
        <radialGradient id="sandGlow" cx="50%" cy="80%" r="50%">
          <stop offset="0%" stop-color="#f59e0b" stop-opacity="0.8"/>
          <stop offset="100%" stop-color="#78350f" stop-opacity="0"/>
        </radialGradient>
        <linearGradient id="trunkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#d97706"/>
          <stop offset="50%" stop-color="#92400e"/>
          <stop offset="100%" stop-color="#451a03"/>
        </linearGradient>
        <linearGradient id="leafGrad1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#4ade80"/>
          <stop offset="60%" stop-color="#15803d"/>
          <stop offset="100%" stop-color="#052e16"/>
        </linearGradient>
        <linearGradient id="leafGrad2" x1="100%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#86efac"/>
          <stop offset="50%" stop-color="#22c55e"/>
          <stop offset="100%" stop-color="#14532d"/>
        </linearGradient>
      </defs>
      <!-- Desert mound -->
      <ellipse cx="50" cy="85" rx="35" ry="10" fill="#78350f" opacity="0.6"/>
      <ellipse cx="50" cy="84" rx="28" ry="7" fill="#d97706" opacity="0.8"/>
      <!-- Trunk -->
      <path d="M48,84 Q45,60 49,42 Q53,60 52,84 Z" fill="url(#trunkGrad)"/>
      <path d="M47,75 Q50,73 53,75 M46,67 Q50,65 54,67 M46,58 Q50,56 54,58 M47,50 Q50,48 53,50" stroke="#fcd34d" stroke-width="1.5" fill="none" opacity="0.7"/>
      <!-- Coconuts -->
      <circle cx="47" cy="45" r="4.5" fill="#451a03"/>
      <circle cx="53" cy="45" r="4" fill="#58240c"/>
      <circle cx="50" cy="48" r="4.2" fill="#713f12"/>
      <circle cx="48" cy="44" r="1.5" fill="#a16207" opacity="0.6"/>
      <!-- Palm Fronds -->
      <path d="M50,42 Q25,35 12,50 Q30,30 50,40" fill="url(#leafGrad1)"/>
      <path d="M50,42 Q75,35 88,50 Q70,30 50,40" fill="url(#leafGrad2)"/>
      <path d="M50,42 Q30,20 18,30 Q35,16 50,40" fill="url(#leafGrad2)"/>
      <path d="M50,42 Q70,20 82,30 Q65,16 50,40" fill="url(#leafGrad1)"/>
      <path d="M50,42 Q50,15 50,12 Q45,22 50,42" fill="url(#leafGrad1)"/>
      <path d="M50,42 Q38,28 30,38 Q42,26 50,42" fill="url(#leafGrad2)"/>
      <path d="M50,42 Q62,28 70,38 Q58,26 50,42" fill="url(#leafGrad1)"/>
      <!-- Frond vein highlights -->
      <path d="M50,42 Q30,32 15,48 M50,42 Q70,32 85,48 M50,42 Q50,20 50,14" stroke="#bbf7d0" stroke-width="1" fill="none" opacity="0.8"/>
    </svg>
  `,

  // 2. Ornate Golden Crescent Moon & Star
  moon: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg moon-svg">
      <defs>
        <radialGradient id="goldGlow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="50%" stop-color="#eab308"/>
          <stop offset="85%" stop-color="#a16207"/>
          <stop offset="100%" stop-color="#713f12"/>
        </radialGradient>
        <filter id="glow">
          <feGaussianBlur stdDeviation="2" result="blur" />
          <feComposite in="SourceGraphic" in2="blur" operator="over" />
        </filter>
      </defs>
      <!-- Crescent Moon -->
      <path d="M50,15 C70,15 86,31 86,51 C86,71 70,87 50,87 C40,87 31,83 24,76 C37,79 55,72 61,56 C67,41 57,25 41,20 C44,17 47,15 50,15 Z"
            fill="url(#goldGlow)" filter="url(#glow)" stroke="#fef08a" stroke-width="1.2"/>
      <!-- Filigree pattern dots on moon -->
      <circle cx="56" cy="30" r="1.5" fill="#fef9c3"/>
      <circle cx="66" cy="40" r="1.8" fill="#fef9c3"/>
      <circle cx="71" cy="52" r="2.0" fill="#fef9c3"/>
      <circle cx="67" cy="65" r="1.8" fill="#fef9c3"/>
      <circle cx="57" cy="76" r="1.5" fill="#fef9c3"/>
      <circle cx="44" cy="82" r="1.2" fill="#fef9c3"/>
      <!-- Inner Ornate Star -->
      <g transform="translate(42, 48) scale(0.9)">
        <polygon points="0,-18 5,-5 18,-5 8,4 12,17 0,9 -12,17 -8,4 -18,-5 -5,-5"
                 fill="url(#goldGlow)" stroke="#fff" stroke-width="1" filter="url(#glow)"/>
        <circle cx="0" cy="2" r="3" fill="#ffffff" opacity="0.9"/>
      </g>
    </svg>
  `,

  // 3. Bedouin Tent with Campfire
  tent: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg tent-svg">
      <defs>
        <linearGradient id="tentFabric" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#fef3c7"/>
          <stop offset="40%" stop-color="#f59e0b"/>
          <stop offset="100%" stop-color="#b45309"/>
        </linearGradient>
        <linearGradient id="tentShadow" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#78350f"/>
          <stop offset="100%" stop-color="#3b1503"/>
        </linearGradient>
        <radialGradient id="fireLight" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stop-color="#ffedd5" stop-opacity="1"/>
          <stop offset="40%" stop-color="#f97316" stop-opacity="0.8"/>
          <stop offset="100%" stop-color="#dc2626" stop-opacity="0"/>
        </radialGradient>
      </defs>
      <!-- Base Shadow -->
      <ellipse cx="50" cy="85" rx="36" ry="7" fill="#451a03" opacity="0.7"/>
      <!-- Tent back/interior shadow -->
      <polygon points="50,22 20,80 80,80" fill="url(#tentShadow)"/>
      <!-- Left Fabric Flap -->
      <polygon points="50,22 18,80 44,80 50,45" fill="url(#tentFabric)"/>
      <!-- Right Fabric Flap -->
      <polygon points="50,22 82,80 56,80 50,45" fill="url(#tentFabric)"/>
      <!-- Center Doorway Opening -->
      <polygon points="50,45 42,80 58,80" fill="#260e02"/>
      <!-- Tent Peak Finial & Ropes -->
      <line x1="50" y1="22" x2="10" y2="82" stroke="#d97706" stroke-width="1.2"/>
      <line x1="50" y1="22" x2="90" y2="82" stroke="#d97706" stroke-width="1.2"/>
      <circle cx="50" cy="20" r="3" fill="#fbbf24"/>
      <!-- Ornate Stripes -->
      <path d="M47,28 L28,78" stroke="#dc2626" stroke-width="1.8" opacity="0.9"/>
      <path d="M53,28 L72,78" stroke="#dc2626" stroke-width="1.8" opacity="0.9"/>
      <path d="M49,32 L36,78" stroke="#fef08a" stroke-width="1.2"/>
      <path d="M51,32 L64,78" stroke="#fef08a" stroke-width="1.2"/>
      <!-- Campfire glow -->
      <circle cx="50" cy="78" r="14" fill="url(#fireLight)"/>
      <polygon points="46,80 50,68 54,80" fill="#fef08a"/>
      <polygon points="48,80 50,72 52,80" fill="#f97316"/>
    </svg>
  `,

  // 4. White Falcon (Perched majestic falcon)
  falcon: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg falcon-svg">
      <defs>
        <linearGradient id="falconBody" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="50%" stop-color="#e2e8f0"/>
          <stop offset="100%" stop-color="#94a3b8"/>
        </linearGradient>
        <linearGradient id="rockGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#64748b"/>
          <stop offset="100%" stop-color="#1e293b"/>
        </linearGradient>
      </defs>
      <!-- Perch Rock -->
      <polygon points="35,75 65,75 75,90 25,90" fill="url(#rockGrad)"/>
      <!-- Tail Feathers -->
      <polygon points="44,65 52,88 40,88" fill="#64748b"/>
      <polygon points="47,65 55,87 45,87" fill="#475569"/>
      <!-- Wing -->
      <path d="M44,40 C38,50 38,68 46,78 C52,78 58,68 56,52 C54,42 48,38 44,40 Z" fill="#cbd5e1" stroke="#475569" stroke-width="0.8"/>
      <!-- Wing feather pattern -->
      <path d="M42,50 Q46,60 44,70 M46,48 Q50,58 48,68 M50,46 Q54,55 52,65" stroke="#334155" stroke-width="1.2" stroke-linecap="round"/>
      <!-- Chest / Torso -->
      <path d="M46,35 C42,42 44,60 52,68 C58,68 62,56 60,42 C58,35 52,32 46,35 Z" fill="url(#falconBody)"/>
      <!-- Chest spots -->
      <circle cx="50" cy="46" r="1" fill="#334155"/>
      <circle cx="54" cy="50" r="1.2" fill="#334155"/>
      <circle cx="48" cy="54" r="1" fill="#334155"/>
      <circle cx="52" cy="58" r="1" fill="#334155"/>
      <!-- Head -->
      <circle cx="52" cy="26" r="10" fill="#ffffff"/>
      <path d="M44,24 Q52,16 60,26 Q56,32 48,32 Z" fill="#ffffff"/>
      <!-- Eye -->
      <circle cx="55" cy="24" r="2.8" fill="#eab308"/>
      <circle cx="55" cy="24" r="1.5" fill="#000000"/>
      <circle cx="55.6" cy="23.4" r="0.6" fill="#ffffff"/>
      <!-- Curved Beak -->
      <path d="M61,24 Q68,26 67,31 Q62,31 59,28 Z" fill="#0f172a"/>
      <path d="M60,25 Q64,27 63,30" stroke="#fbbf24" stroke-width="0.8"/>
      <!-- Talons -->
      <path d="M48,74 L46,78 M52,74 L52,78 M56,74 L58,78" stroke="#fbbf24" stroke-width="2" stroke-linecap="round"/>
    </svg>
  `,

  // 5. Arabian Camel with colorful saddle
  camel: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg camel-svg">
      <defs>
        <linearGradient id="camelBody" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#f59e0b"/>
          <stop offset="40%" stop-color="#d97706"/>
          <stop offset="100%" stop-color="#92400e"/>
        </linearGradient>
        <linearGradient id="saddleGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#ec4899"/>
          <stop offset="25%" stop-color="#a855f7"/>
          <stop offset="50%" stop-color="#3b82f6"/>
          <stop offset="75%" stop-color="#10b981"/>
          <stop offset="100%" stop-color="#f59e0b"/>
        </linearGradient>
      </defs>
      <!-- Shadow -->
      <ellipse cx="50" cy="88" rx="32" ry="6" fill="#451a03" opacity="0.6"/>
      <!-- Back Legs -->
      <path d="M36,65 L34,86 M40,65 L41,86" stroke="#b45309" stroke-width="4.5" stroke-linecap="round"/>
      <!-- Front Legs -->
      <path d="M65,65 L66,86 M70,65 L72,86" stroke="#b45309" stroke-width="4.5" stroke-linecap="round"/>
      <!-- Main Body & Hump -->
      <path d="M30,62 C26,50 35,46 42,46 C45,35 55,34 60,45 C68,45 74,52 74,62 C74,72 65,74 50,74 C35,74 30,70 30,62 Z" fill="url(#camelBody)"/>
      <!-- Neck and Head -->
      <path d="M66,58 C72,50 75,35 73,26 C75,22 83,23 85,27 C85,32 80,34 78,40 C76,48 72,58 68,62 Z" fill="url(#camelBody)"/>
      <!-- Ears & Eye -->
      <polygon points="73,22 75,17 77,22" fill="#d97706"/>
      <circle cx="79" cy="26" r="1.8" fill="#1c1917"/>
      <circle cx="79.4" cy="25.6" r="0.6" fill="#ffffff"/>
      <!-- Tail -->
      <path d="M29,56 Q24,65 26,72" stroke="#d97706" stroke-width="2.5" stroke-linecap="round"/>
      <!-- Ceremonial Saddle Blanket -->
      <path d="M42,47 Q52,43 62,47 L64,65 Q52,68 40,65 Z" fill="url(#saddleGrad)"/>
      <!-- Golden Tassels -->
      <circle cx="43" cy="67" r="1.5" fill="#fef08a"/>
      <circle cx="48" cy="68" r="1.5" fill="#fef08a"/>
      <circle cx="53" cy="68" r="1.5" fill="#fef08a"/>
      <circle cx="58" cy="68" r="1.5" fill="#fef08a"/>
      <circle cx="63" cy="67" r="1.5" fill="#fef08a"/>
      <!-- Reins -->
      <path d="M78,30 Q68,42 62,50" stroke="#fef08a" stroke-width="1.2" fill="none"/>
    </svg>
  `,

  // 6. Arabian Dagger (Khanjar) with gold sheath
  dagger: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg dagger-svg">
      <defs>
        <linearGradient id="goldDagger" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#fffbeb"/>
          <stop offset="30%" stop-color="#fcd34d"/>
          <stop offset="70%" stop-color="#d97706"/>
          <stop offset="100%" stop-color="#78350f"/>
        </linearGradient>
        <linearGradient id="steelBlade" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#f8fafc"/>
          <stop offset="50%" stop-color="#cbd5e1"/>
          <stop offset="100%" stop-color="#64748b"/>
        </linearGradient>
      </defs>
      <!-- Shadow -->
      <ellipse cx="50" cy="55" rx="35" ry="30" fill="#000" opacity="0.3"/>
      <!-- Sheath & Hilt Group tilted 35 deg -->
      <g transform="translate(50, 50) rotate(-35) translate(-50, -50)">
        <!-- Pommel -->
        <path d="M42,16 C42,12 58,12 58,16 L54,24 L46,24 Z" fill="url(#goldDagger)" stroke="#fff" stroke-width="0.8"/>
        <circle cx="50" cy="17" r="3" fill="#dc2626"/>
        <circle cx="50" cy="17" r="1" fill="#fecaca"/>
        <!-- Handle Grip -->
        <rect x="46" y="24" width="8" height="18" rx="2" fill="#1c1917"/>
        <line x1="46" y1="28" x2="54" y2="28" stroke="#fcd34d" stroke-width="1.2"/>
        <line x1="46" y1="33" x2="54" y2="33" stroke="#fcd34d" stroke-width="1.2"/>
        <line x1="46" y1="38" x2="54" y2="38" stroke="#fcd34d" stroke-width="1.2"/>
        <!-- Crossguard -->
        <path d="M38,42 C38,39 62,39 62,42 L58,46 L42,46 Z" fill="url(#goldDagger)"/>
        <circle cx="50" cy="43" r="2.2" fill="#059669"/>
        <!-- Curved Sheath with ornate engravings -->
        <path d="M43,46 C43,58 45,70 60,82 C65,85 64,88 60,88 C46,84 37,70 37,46 Z" fill="url(#goldDagger)" stroke="#fef08a" stroke-width="1"/>
        <!-- Filigree rings on sheath -->
        <path d="M40,54 Q48,56 46,54" stroke="#78350f" stroke-width="1.5"/>
        <path d="M40,64 Q49,67 48,64" stroke="#78350f" stroke-width="1.5"/>
        <!-- Ruby inlays on sheath -->
        <circle cx="44" cy="58" r="2" fill="#dc2626"/>
        <circle cx="48" cy="68" r="2" fill="#2563eb"/>
      </g>
    </svg>
  `,

  // 7. Magic Genie Lamp (Golden Lamp with magical smoke)
  lamp: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg lamp-svg">
      <defs>
        <radialGradient id="lampGlow" cx="40%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#fffbeb"/>
          <stop offset="35%" stop-color="#fde047"/>
          <stop offset="70%" stop-color="#ca8a04"/>
          <stop offset="100%" stop-color="#713f12"/>
        </radialGradient>
        <linearGradient id="magicSmoke" x1="0%" y1="100%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.8"/>
          <stop offset="50%" stop-color="#a855f7" stop-opacity="0.6"/>
          <stop offset="100%" stop-color="#ec4899" stop-opacity="0"/>
        </linearGradient>
      </defs>
      <!-- Magical smoke pouring from spout -->
      <path d="M22,46 C16,40 18,28 26,24 C34,20 28,12 36,8" stroke="url(#magicSmoke)" stroke-width="4.5" fill="none" stroke-linecap="round"/>
      <circle cx="36" cy="8" r="2" fill="#e0e7ff"/>
      <circle cx="28" cy="18" r="1.5" fill="#fbcfe8"/>
      <!-- Pedestal / Base -->
      <ellipse cx="54" cy="80" rx="18" ry="6" fill="url(#lampGlow)" stroke="#fef08a" stroke-width="1"/>
      <rect x="50" y="74" width="8" height="6" fill="url(#lampGlow)"/>
      <!-- Lamp Belly -->
      <path d="M34,60 C32,74 76,74 74,60 C74,52 64,48 54,48 C44,48 34,52 34,60 Z" fill="url(#lampGlow)" stroke="#fef08a" stroke-width="1.2"/>
      <!-- Spout extending left and up -->
      <path d="M38,58 C28,56 18,52 20,44 C22,42 26,44 36,50 Z" fill="url(#lampGlow)" stroke="#fef08a" stroke-width="1"/>
      <!-- Handle loop on right -->
      <path d="M72,56 C86,52 88,38 78,34 C70,30 68,44 68,48" stroke="url(#lampGlow)" stroke-width="5" fill="none" stroke-linecap="round"/>
      <!-- Lamp Lid & Finial -->
      <ellipse cx="54" cy="48" rx="10" ry="4" fill="url(#lampGlow)"/>
      <circle cx="54" cy="44" r="3" fill="#dc2626"/>
      <circle cx="54" cy="41" r="1.5" fill="#fef08a"/>
      <!-- Gem jewel on belly -->
      <polygon points="54,58 57,63 54,67 51,63" fill="#06b6d4" stroke="#fff" stroke-width="0.8"/>
    </svg>
  `,

  // 8. Golden Treasure Chest overflowing with loot
  chest: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg chest-svg">
      <defs>
        <linearGradient id="chestWood" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#b45309"/>
          <stop offset="50%" stop-color="#78350f"/>
          <stop offset="100%" stop-color="#451a03"/>
        </linearGradient>
        <linearGradient id="chestGold" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="50%" stop-color="#eab308"/>
          <stop offset="100%" stop-color="#a16207"/>
        </linearGradient>
        <radialGradient id="goldGleam" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="40%" stop-color="#fef08a"/>
          <stop offset="100%" stop-color="#eab308"/>
        </radialGradient>
      </defs>
      <!-- Shadow -->
      <ellipse cx="50" cy="85" rx="36" ry="8" fill="#1c1917" opacity="0.7"/>
      <!-- Chest Lower Box -->
      <polygon points="20,52 80,52 75,82 25,82" fill="url(#chestWood)"/>
      <!-- Gold corner straps and trim -->
      <polygon points="20,52 26,52 29,82 25,82" fill="url(#chestGold)"/>
      <polygon points="80,52 74,52 71,82 75,82" fill="url(#chestGold)"/>
      <polygon points="46,52 54,52 54,82 46,82" fill="url(#chestGold)"/>
      <!-- Keyhole plate -->
      <circle cx="50" cy="62" r="4.5" fill="url(#chestGold)"/>
      <polygon points="49,63 51,63 52,66 48,66" fill="#1c1917"/>
      <!-- Open Lid tilted back -->
      <path d="M16,46 C16,30 84,30 84,46 L78,50 L22,50 Z" fill="url(#chestWood)"/>
      <path d="M16,46 C16,30 84,30 84,46" stroke="url(#chestGold)" stroke-width="4" fill="none"/>
      <!-- Inside Gold Heap & Gems -->
      <ellipse cx="50" cy="50" rx="26" ry="8" fill="#ca8a04"/>
      <!-- Gold coins sparkling -->
      <circle cx="40" cy="48" r="3.5" fill="url(#goldGleam)"/>
      <circle cx="48" cy="46" r="4" fill="url(#goldGleam)"/>
      <circle cx="56" cy="47" r="3.8" fill="url(#goldGleam)"/>
      <circle cx="63" cy="50" r="3.2" fill="url(#goldGleam)"/>
      <circle cx="34" cy="51" r="3" fill="url(#goldGleam)"/>
      <!-- Rubies & Emeralds on pile -->
      <polygon points="44,44 47,41 50,44 47,47" fill="#dc2626" stroke="#fff" stroke-width="0.6"/>
      <polygon points="54,42 57,40 60,42 57,44" fill="#10b981" stroke="#fff" stroke-width="0.6"/>
      <polygon points="38,46 40,44 42,46 40,48" fill="#3b82f6" stroke="#fff" stroke-width="0.6"/>
    </svg>
  `,

  // 9. WILD (20-sided faceted crystal die with metallic WILD)
  wild: () => `
    <svg viewBox="0 0 100 100" class="symbol-svg wild-svg">
      <defs>
        <linearGradient id="wildBg" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#38bdf8"/>
          <stop offset="40%" stop-color="#0284c7"/>
          <stop offset="100%" stop-color="#0c4a6e"/>
        </linearGradient>
        <linearGradient id="facetHighlight" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#e0f2fe" stop-opacity="0.9"/>
          <stop offset="100%" stop-color="#38bdf8" stop-opacity="0.2"/>
        </linearGradient>
        <linearGradient id="chromeText" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="48%" stop-color="#e0f2fe"/>
          <stop offset="52%" stop-color="#38bdf8"/>
          <stop offset="100%" stop-color="#0369a1"/>
        </linearGradient>
        <filter id="wildGlow">
          <feGaussianBlur stdDeviation="3" result="blur"/>
          <feMerge>
            <feMergeNode in="blur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>
      <!-- Outer Icosahedron Diamond Shape -->
      <polygon points="50,6 88,26 88,74 50,94 12,74 12,26" fill="url(#wildBg)" stroke="#38bdf8" stroke-width="2.5" filter="url(#wildGlow)"/>
      <!-- Geometric Facets -->
      <polygon points="50,6 50,42 88,26" fill="url(#facetHighlight)"/>
      <polygon points="50,6 12,26 50,42" fill="#0369a1" opacity="0.6"/>
      <polygon points="12,26 12,74 50,58" fill="#075985" opacity="0.8"/>
      <polygon points="88,26 88,74 50,58" fill="url(#facetHighlight)"/>
      <polygon points="50,94 88,74 50,58" fill="#0c4a6e"/>
      <polygon points="50,94 12,74 50,58" fill="#082f49"/>
      <!-- Inner Die Number "20" small on top -->
      <text x="50" y="28" font-family="'Impact', 'Arial Black', sans-serif" font-size="11" font-weight="900" fill="#bae6fd" text-anchor="middle" letter-spacing="1">20</text>
      <!-- Bold WILD Banner -->
      <g transform="translate(50, 60)">
        <!-- Shadow -->
        <text x="0" y="8" font-family="'Arial Black', 'Impact', sans-serif" font-size="22" font-weight="900" fill="#082f49" text-anchor="middle" letter-spacing="1">WILD</text>
        <!-- Chrome text with stroke -->
        <text x="0" y="7" font-family="'Arial Black', 'Impact', sans-serif" font-size="22" font-weight="900" fill="url(#chromeText)" stroke="#ffffff" stroke-width="1.2" text-anchor="middle" letter-spacing="1">WILD</text>
      </g>
    </svg>
  `,

  // 10. Bonus Ruby Gem (Faceted red gem with cash value e.g. "5", "20k", "40k")
  ruby: (value = "5") => `
    <svg viewBox="0 0 100 100" class="symbol-svg ruby-svg">
      <defs>
        <radialGradient id="rubyGlow" cx="45%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#fca5a5"/>
          <stop offset="35%" stop-color="#ef4444"/>
          <stop offset="75%" stop-color="#b91c1c"/>
          <stop offset="100%" stop-color="#450a0a"/>
        </radialGradient>
        <linearGradient id="rubyShine" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0.9"/>
          <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
        </linearGradient>
        <filter id="rubyAura">
          <feGaussianBlur stdDeviation="3.5" result="blur"/>
          <feMerge>
            <feMergeNode in="blur"/>
            <feMergeNode in="SourceGraphic"/>
          </feMerge>
        </filter>
      </defs>
      <!-- Faceted Ruby Octagon -->
      <polygon points="30,12 70,12 90,32 90,68 70,88 30,88 10,68 10,32"
               fill="url(#rubyGlow)" stroke="#fecaca" stroke-width="2.5" filter="url(#rubyAura)"/>
      <!-- Facet lines -->
      <polygon points="30,12 70,12 60,30 40,30" fill="url(#rubyShine)"/>
      <polygon points="70,12 90,32 72,40 60,30" fill="#991b1b" opacity="0.6"/>
      <polygon points="90,32 90,68 72,60 72,40" fill="#7f1d1d" opacity="0.8"/>
      <polygon points="90,68 70,88 60,70 72,60" fill="#450a0a"/>
      <polygon points="70,88 30,88 40,70 60,70" fill="#7f1d1d"/>
      <polygon points="30,88 10,68 28,60 40,70" fill="#991b1b"/>
      <polygon points="10,68 10,32 28,40 28,60" fill="url(#rubyShine)" opacity="0.5"/>
      <polygon points="10,32 30,12 40,30 28,40" fill="url(#rubyShine)"/>
      <!-- Inner Octagon Face -->
      <polygon points="40,30 60,30 72,40 72,60 60,70 40,70 28,60 28,40" fill="#dc2626" stroke="#fca5a5" stroke-width="1.2"/>
      <!-- Prize Value Text -->
      <text x="50" y="58" font-family="'Arial Black', 'Impact', sans-serif" font-size="${value.length > 3 ? '22' : '28'}" font-weight="900" fill="#ffffff" stroke="#7f1d1d" stroke-width="1.5" text-anchor="middle" filter="drop-shadow(0 2px 4px rgba(0,0,0,0.8))">
        ${value}
      </text>
    </svg>
  `,

  // 11. Emerald Jackpot Gem (Faceted emerald with MINI, MINOR, MAJOR, GRAND)
  emerald: (tier = "MINI") => {
    let tierColor = "#10b981";
    let fontSize = tier === "GRAND" || tier === "MAJOR" ? "18" : "20";
    return `
      <svg viewBox="0 0 100 100" class="symbol-svg emerald-svg emerald-${tier.toLowerCase()}">
        <defs>
          <radialGradient id="emeraldGlow" cx="45%" cy="35%" r="60%">
            <stop offset="0%" stop-color="#a7f3d0"/>
            <stop offset="35%" stop-color="#10b981"/>
            <stop offset="75%" stop-color="#047857"/>
            <stop offset="100%" stop-color="#022c22"/>
          </radialGradient>
          <filter id="emeraldAura">
            <feGaussianBlur stdDeviation="3.5" result="blur"/>
            <feMerge>
              <feMergeNode in="blur"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>
          <linearGradient id="jackpotTextGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stop-color="#ffffff"/>
            <stop offset="100%" stop-color="#fef08a"/>
          </linearGradient>
        </defs>
        <!-- Emerald Cut Rectangle -->
        <polygon points="26,10 74,10 90,26 90,74 74,90 26,90 10,74 10,26"
                 fill="url(#emeraldGlow)" stroke="#fef08a" stroke-width="2.5" filter="url(#emeraldAura)"/>
        <!-- Beveled Facets -->
        <polygon points="26,10 74,10 65,22 35,22" fill="#d1fae5" opacity="0.8"/>
        <polygon points="74,10 90,26 78,35 65,22" fill="#047857"/>
        <polygon points="90,26 90,74 78,65 78,35" fill="#064e3b"/>
        <polygon points="90,74 74,90 65,78 78,65" fill="#022c22"/>
        <polygon points="74,90 26,90 35,78 65,78" fill="#047857"/>
        <polygon points="26,90 10,74 22,65 35,78" fill="#065f46"/>
        <polygon points="10,74 10,26 22,35 22,65" fill="#10b981"/>
        <polygon points="10,26 26,10 35,22 22,35" fill="#d1fae5" opacity="0.9"/>
        <!-- Inner Table Face -->
        <polygon points="35,22 65,22 78,35 78,65 65,78 35,78 22,65 22,35" fill="#059669" stroke="#6ee7b7" stroke-width="1.2"/>
        <!-- Jackpot Text -->
        <text x="50" y="57" font-family="'Arial Black', 'Impact', sans-serif" font-size="${fontSize}" font-weight="900" fill="url(#jackpotTextGrad)" stroke="#064e3b" stroke-width="1.5" text-anchor="middle" letter-spacing="1" filter="drop-shadow(0 2px 4px rgba(0,0,0,0.9))">
          ${tier}
        </text>
      </svg>
    `;
  }
};
