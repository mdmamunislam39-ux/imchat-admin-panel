// ====================================================
// Greedy Cat - Master Visual Assets & Engine (1:1 UI Match)
// ====================================================

const svgToUri = (svgStr) => "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svgStr.trim());

const SVGS = {
  // 1. Whole Barbecue Roasted Chicken (Top - x45)
  chicken: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Golden-brown Honey BBQ Roast Gradient -->
        <radialGradient id="roastSkinGrad" cx="50%" cy="38%" r="62%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="25%" stop-color="#f59e0b"/>
          <stop offset="65%" stop-color="#b45309"/>
          <stop offset="90%" stop-color="#78350f"/>
          <stop offset="100%" stop-color="#451a03"/>
        </radialGradient>
        <!-- Drumstick Roast Gradient -->
        <linearGradient id="drumstickGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#fde047"/>
          <stop offset="40%" stop-color="#d97706"/>
          <stop offset="85%" stop-color="#92400e"/>
          <stop offset="100%" stop-color="#451a03"/>
        </linearGradient>
        <!-- Wing Tip Crisp Gradient -->
        <linearGradient id="wingGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#f59e0b"/>
          <stop offset="70%" stop-color="#9a3412"/>
          <stop offset="100%" stop-color="#451a03"/>
        </linearGradient>
        <!-- White Bone Gradient -->
        <linearGradient id="boneGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="60%" stop-color="#f1f5f9"/>
          <stop offset="100%" stop-color="#cbd5e1"/>
        </linearGradient>
        <!-- Golden Lemon Gradient -->
        <radialGradient id="lemonWedgeGrad" cx="40%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="70%" stop-color="#eab308"/>
          <stop offset="100%" stop-color="#ca8a04"/>
        </radialGradient>
      </defs>

      <!-- Soft Drop Shadow Under Roasted Chicken -->
      <ellipse cx="50" cy="82" rx="38" ry="11" fill="#000000" opacity="0.3"/>

      <!-- Garnishing Lettuce Base Bed -->
      <path d="M20 68 C12 60, 16 78, 28 76 C22 82, 36 84, 46 80 C54 84, 68 82, 64 76 C76 80, 86 66, 76 62 Z" fill="#22c55e" opacity="0.85"/>
      <path d="M26 70 C22 64, 32 62, 36 68 C42 64, 50 64, 54 68 C60 62, 68 64, 66 70 Z" fill="#4ade80" opacity="0.7"/>

      <!-- Roasted Wings (Tucked on sides) -->
      <!-- Left Wing -->
      <path d="M26 36 C14 42, 12 60, 24 68 C28 64, 32 50, 30 40 Z" fill="url(#wingGrad)" stroke="#5c1d0a" stroke-width="1.8"/>
      <path d="M17 50 C19 58, 23 64, 25 66" stroke="#451a03" stroke-width="1.6" fill="none"/>
      <!-- Right Wing -->
      <path d="M74 36 C86 42, 88 60, 76 68 C72 64, 68 50, 70 40 Z" fill="url(#wingGrad)" stroke="#5c1d0a" stroke-width="1.8"/>
      <path d="M83 50 C81 58, 77 64, 75 66" stroke="#451a03" stroke-width="1.6" fill="none"/>

      <!-- Plump Whole Roast Body / Main Breast -->
      <path d="M28 38 C30 20, 40 16, 50 16 C60 16, 70 20, 72 38 C76 54, 74 70, 50 72 C26 70, 24 54, 28 38 Z" fill="url(#roastSkinGrad)" stroke="#5c1d0a" stroke-width="2.2"/>

      <!-- Center Breast Cleavage / Contour Line -->
      <path d="M50 20 Q50 38 50 56" stroke="#78350f" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.75"/>
      <path d="M50 22 Q48 36 49 52" stroke="#fef08a" stroke-width="1.2" stroke-linecap="round" fill="none" opacity="0.8"/>

      <!-- Crispy Golden Glaze Highlights -->
      <ellipse cx="40" cy="34" rx="7" ry="12" fill="#ffffff" opacity="0.32" transform="rotate(-15 40 34)"/>
      <ellipse cx="60" cy="34" rx="7" ry="12" fill="#ffffff" opacity="0.32" transform="rotate(15 60 34)"/>
      <ellipse cx="38" cy="30" rx="3.5" ry="6" fill="#ffffff" opacity="0.5" transform="rotate(-15 38 30)"/>
      <ellipse cx="62" cy="30" rx="3.5" ry="6" fill="#ffffff" opacity="0.5" transform="rotate(15 62 30)"/>

      <!-- Savory Rotisserie Barbecue Char / Sear Marks -->
      <path d="M34 28 Q42 26 47 30" stroke="#451a03" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M53 30 Q58 26 66 28" stroke="#451a03" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M32 40 Q42 38 47 42" stroke="#451a03" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M53 42 Q58 38 68 40" stroke="#451a03" stroke-width="2.2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M34 50 Q42 49 47 52" stroke="#451a03" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.8"/>
      <path d="M53 52 Q58 49 66 50" stroke="#451a03" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.8"/>

      <!-- Plump Juicy Drumsticks (Legs) Folded at Bottom -->
      <!-- Left Drumstick Meat -->
      <path d="M28 52 C22 56, 24 72, 36 74 C42 75, 45 64, 43 56 C39 50, 32 50, 28 52 Z" fill="url(#drumstickGrad)" stroke="#5c1d0a" stroke-width="2"/>
      <ellipse cx="32" cy="62" rx="4" ry="7" fill="#ffffff" opacity="0.35" transform="rotate(-20 32 62)"/>
      <!-- Right Drumstick Meat -->
      <path d="M72 52 C78 56, 76 72, 64 74 C58 75, 55 64, 57 56 C61 50, 68 50, 72 52 Z" fill="url(#drumstickGrad)" stroke="#5c1d0a" stroke-width="2"/>
      <ellipse cx="68" cy="62" rx="4" ry="7" fill="#ffffff" opacity="0.35" transform="rotate(20 68 62)"/>

      <!-- Roasted Leg Char Marks -->
      <path d="M28 62 Q34 64 38 60" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.75"/>
      <path d="M72 62 Q66 64 62 60" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.75"/>

      <!-- Clean Bone Tips (Rotisserie presentation crossed/tied) -->
      <line x1="37" y1="73" x2="42" y2="83" stroke="url(#boneGrad)" stroke-width="4.5" stroke-linecap="round"/>
      <circle cx="41" cy="84" r="2.8" fill="#f8fafc" stroke="#94a3b8" stroke-width="1"/>
      <circle cx="44" cy="82" r="2.8" fill="#ffffff" stroke="#94a3b8" stroke-width="1"/>

      <line x1="63" y1="73" x2="58" y2="83" stroke="url(#boneGrad)" stroke-width="4.5" stroke-linecap="round"/>
      <circle cx="59" cy="84" r="2.8" fill="#f8fafc" stroke="#94a3b8" stroke-width="1"/>
      <circle cx="56" cy="82" r="2.8" fill="#ffffff" stroke="#94a3b8" stroke-width="1"/>

      <!-- Cooking Twine / Tie around Bone Ends -->
      <ellipse cx="50" cy="78" rx="8" ry="3" fill="none" stroke="#fef08a" stroke-width="2.2"/>
      <ellipse cx="50" cy="78" rx="8" ry="3" fill="none" stroke="#78350f" stroke-width="1" stroke-dasharray="2,2"/>

      <!-- Rosemary Garnish Sprig on the Breast -->
      <path d="M50 48 Q55 36 62 30" stroke="#15803d" stroke-width="1.8" fill="none" stroke-linecap="round"/>
      <path d="M53 43 L48 40 M55 38 L60 35 M57 34 L52 30 M60 31 L64 27" stroke="#16a34a" stroke-width="1.8" stroke-linecap="round"/>

      <!-- Fresh Lemon Wedge beside Chicken -->
      <path d="M74 68 C82 66, 90 74, 84 82 Z" fill="url(#lemonWedgeGrad)" stroke="#a16207" stroke-width="1.5"/>
      <path d="M76 70 C81 69, 85 74, 81 79 Z" fill="#fef08a"/>
      <!-- Pepper / Herb Seasoning Flakes on Roasted Chicken -->
      <circle cx="45" cy="26" r="0.9" fill="#1c1917"/>
      <circle cx="56" cy="24" r="0.9" fill="#1c1917"/>
      <circle cx="36" cy="38" r="0.8" fill="#1c1917"/>
      <circle cx="64" cy="46" r="0.9" fill="#1c1917"/>
      <circle cx="48" cy="62" r="0.8" fill="#dc2626"/>
      <circle cx="52" cy="64" r="0.8" fill="#1c1917"/>
    </svg>
  `,

  // 2. Fresh Juicy Vine Tomato (x5)
  tomato: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Luscious 3D Glossy Tomato Radial Gradient -->
        <radialGradient id="realTomatoGrad" cx="38%" cy="36%" r="62%">
          <stop offset="0%" stop-color="#fca5a5"/>
          <stop offset="25%" stop-color="#ef4444"/>
          <stop offset="65%" stop-color="#dc2626"/>
          <stop offset="85%" stop-color="#991b1b"/>
          <stop offset="100%" stop-color="#450a0a"/>
        </radialGradient>
        <!-- Calyx Leaf Gradient -->
        <linearGradient id="calyxLeafGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#86efac"/>
          <stop offset="40%" stop-color="#22c55e"/>
          <stop offset="100%" stop-color="#14532d"/>
        </linearGradient>
      </defs>

      <!-- Soft Drop Shadow Under Tomato -->
      <ellipse cx="50" cy="80" rx="36" ry="10" fill="#000000" opacity="0.3"/>

      <!-- Plump Organic Tomato Body (Slightly lobed heirloom curve) -->
      <path d="M50 28 C34 26, 16 38, 14 56 C12 72, 28 84, 50 84 C72 84, 88 72, 86 56 C84 38, 66 26, 50 28 Z" fill="url(#realTomatoGrad)" stroke="#5f0f0f" stroke-width="2.2"/>

      <!-- Top Dimple Indentation -->
      <path d="M42 28 Q50 34 58 28" stroke="#7f1d1d" stroke-width="2" fill="none"/>

      <!-- Curved Gloss Highlight Reflections -->
      <ellipse cx="34" cy="42" rx="14" ry="7" fill="#ffffff" opacity="0.45" transform="rotate(-30 34 42)"/>
      <ellipse cx="32" cy="39" rx="7" ry="3.5" fill="#ffffff" opacity="0.75" transform="rotate(-30 32 39)"/>
      <ellipse cx="68" cy="46" rx="8" ry="4" fill="#ffffff" opacity="0.25" transform="rotate(25 68 46)"/>
      <!-- Dewy Fresh Water Droplets -->
      <ellipse cx="44" cy="62" rx="2.5" ry="3.2" fill="#ffffff" opacity="0.55"/>
      <ellipse cx="43" cy="61" rx="1" ry="1.2" fill="#ffffff" opacity="0.9"/>
      <ellipse cx="60" cy="58" rx="2" ry="2.5" fill="#ffffff" opacity="0.5"/>

      <!-- Star Calyx Sepals (Curled fresh green leaves) -->
      <path d="M50 30 Q44 14 36 10 Q40 22 46 28 Z" fill="url(#calyxLeafGrad)" stroke="#14532d" stroke-width="1.2"/>
      <path d="M50 30 Q56 14 64 10 Q60 22 54 28 Z" fill="url(#calyxLeafGrad)" stroke="#14532d" stroke-width="1.2"/>
      <path d="M48 30 Q28 24 20 30 Q34 32 46 32 Z" fill="url(#calyxLeafGrad)" stroke="#14532d" stroke-width="1.2"/>
      <path d="M52 30 Q72 24 80 30 Q66 32 54 32 Z" fill="url(#calyxLeafGrad)" stroke="#14532d" stroke-width="1.2"/>
      <path d="M48 30 Q38 42 32 48 Q44 40 50 34 Z" fill="url(#calyxLeafGrad)" stroke="#14532d" stroke-width="1.2"/>
      <path d="M52 30 Q62 42 68 48 Q56 40 50 34 Z" fill="url(#calyxLeafGrad)" stroke="#14532d" stroke-width="1.2"/>

      <!-- Central Calyx Node -->
      <ellipse cx="50" cy="30" rx="4.5" ry="3" fill="#15803d" stroke="#14532d" stroke-width="1.2"/>

      <!-- Fresh Curved Vine Stem -->
      <path d="M50 30 C50 16, 56 12, 53 6 C50 6, 46 12, 48 28 Z" fill="#22c55e" stroke="#14532d" stroke-width="1.4"/>
      <ellipse cx="53" cy="6" rx="2.5" ry="1.5" fill="#86efac" stroke="#15803d" stroke-width="1"/>
    </svg>
  `,

  // 3. Barbecue Leg Piece (x15)
  goat: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Honey Glazed Roast Skin Gradient -->
        <radialGradient id="legSkinGrad" cx="42%" cy="38%" r="60%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="25%" stop-color="#f59e0b"/>
          <stop offset="60%" stop-color="#b45309"/>
          <stop offset="85%" stop-color="#78350f"/>
          <stop offset="100%" stop-color="#451a03"/>
        </radialGradient>
        <!-- Bone Gradient -->
        <linearGradient id="legBoneGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="65%" stop-color="#f1f5f9"/>
          <stop offset="100%" stop-color="#cbd5e1"/>
        </linearGradient>
        <!-- Fresh Lemon Wedge -->
        <radialGradient id="legLemonGrad" cx="40%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="70%" stop-color="#eab308"/>
          <stop offset="100%" stop-color="#ca8a04"/>
        </radialGradient>
      </defs>

      <!-- Soft Shadow -->
      <ellipse cx="50" cy="80" rx="38" ry="10" fill="#000000" opacity="0.3"/>

      <!-- Garnishing Lettuce Base -->
      <path d="M22 68 C14 62, 18 78, 30 76 C36 82, 50 82, 56 76 C64 80, 74 76, 72 68 Z" fill="#22c55e" opacity="0.75"/>
      <path d="M26 70 C32 64, 40 64, 44 70 C50 64, 60 66, 64 70 Z" fill="#4ade80" opacity="0.65"/>

      <!-- Bone Sticking Out (Bottom-Left to Top-Right slant) -->
      <line x1="26" y1="74" x2="38" y2="58" stroke="url(#legBoneGrad)" stroke-width="8" stroke-linecap="round"/>
      <circle cx="23" cy="77" r="4.5" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2"/>
      <circle cx="27" cy="80" r="4.5" fill="#ffffff" stroke="#94a3b8" stroke-width="1.2"/>

      <!-- Clean Bone Foil Wrap / Ribbon Band -->
      <path d="M30 68 L36 60 L40 63 L34 71 Z" fill="#f1f5f9" stroke="#94a3b8" stroke-width="1"/>
      <line x1="32" y1="67" x2="36" y2="62" stroke="#cbd5e1" stroke-width="1"/>

      <!-- Plump, Juicy Roasted Meat Body -->
      <path d="M34 62 C32 50, 40 32, 54 22 C68 14, 82 22, 84 36 C86 52, 78 68, 62 72 C48 76, 36 70, 34 62 Z" fill="url(#legSkinGrad)" stroke="#5c1d0a" stroke-width="2.5"/>

      <!-- Curved Meat Bulk Highlight (Glazed shine) -->
      <ellipse cx="62" cy="34" rx="14" ry="8" fill="#ffffff" opacity="0.32" transform="rotate(-35 62 34)"/>
      <ellipse cx="60" cy="31" rx="8" ry="4" fill="#ffffff" opacity="0.45" transform="rotate(-35 60 31)"/>

      <!-- Barbecue Grill Sear / Char Marks -->
      <path d="M48 28 Q60 32 68 25" stroke="#381305" stroke-width="2.8" stroke-linecap="round" fill="none" opacity="0.9"/>
      <path d="M44 40 Q58 44 74 36" stroke="#381305" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.9"/>
      <path d="M42 52 Q58 56 76 48" stroke="#381305" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.9"/>
      <path d="M46 64 Q60 66 72 60" stroke="#381305" stroke-width="2.5" stroke-linecap="round" fill="none" opacity="0.85"/>

      <!-- Cross-char sear mark -->
      <path d="M54 22 Q58 40 50 62" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.6"/>

      <!-- Fresh Rosemary Sprig over Drumstick -->
      <path d="M50 56 Q62 48 72 38" stroke="#15803d" stroke-width="2" fill="none" stroke-linecap="round"/>
      <path d="M54 53 L50 48 M58 49 L64 45 M62 45 L58 40 M66 41 L72 36" stroke="#16a34a" stroke-width="1.8" stroke-linecap="round"/>

      <!-- Fresh Lemon Wedge on the side -->
      <path d="M68 66 C76 64, 84 72, 78 80 Z" fill="url(#legLemonGrad)" stroke="#a16207" stroke-width="1.4"/>
      <path d="M70 68 C75 67, 79 72, 75 77 Z" fill="#fef08a"/>

      <!-- Seasoning Flakes -->
      <circle cx="56" cy="28" r="0.9" fill="#1c1917"/>
      <circle cx="70" cy="30" r="0.9" fill="#dc2626"/>
      <circle cx="64" cy="46" r="0.9" fill="#1c1917"/>
      <circle cx="52" cy="48" r="0.9" fill="#dc2626"/>
      <circle cx="68" cy="56" r="0.8" fill="#1c1917"/>
    </svg>
  `,

  // 4. Fresh Glossy Red Bell Pepper (x5)
  pepper: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Rich 3D Bell Pepper Red Gradient -->
        <radialGradient id="pepperLobeGrad" cx="42%" cy="38%" r="62%">
          <stop offset="0%" stop-color="#fca5a5"/>
          <stop offset="25%" stop-color="#ef4444"/>
          <stop offset="60%" stop-color="#dc2626"/>
          <stop offset="85%" stop-color="#991b1b"/>
          <stop offset="100%" stop-color="#450a0a"/>
        </radialGradient>
        <!-- Green Capsicum Stem Gradient -->
        <linearGradient id="pepperStemGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#4ade80"/>
          <stop offset="50%" stop-color="#16a34a"/>
          <stop offset="100%" stop-color="#14532d"/>
        </linearGradient>
      </defs>

      <!-- Soft Drop Shadow Under Pepper -->
      <ellipse cx="50" cy="84" rx="34" ry="9" fill="#000000" opacity="0.3"/>

      <!-- Main Bell Pepper Multi-Lobed Body -->
      <!-- Left Lobe -->
      <path d="M30 36 C18 48, 18 72, 34 82 C42 86, 48 84, 48 74 C48 54, 42 36, 30 36 Z" fill="url(#pepperLobeGrad)" stroke="#5f0f0f" stroke-width="2"/>

      <!-- Right Lobe -->
      <path d="M70 36 C82 48, 82 72, 66 82 C58 86, 52 84, 52 74 C52 54, 58 36, 70 36 Z" fill="url(#pepperLobeGrad)" stroke="#5f0f0f" stroke-width="2"/>

      <!-- Center Main Lobe (Full prominent body) -->
      <path d="M34 34 C26 44, 28 72, 38 82 C44 86, 56 86, 62 82 C72 72, 74 44, 66 34 C60 30, 40 30, 34 34 Z" fill="url(#pepperLobeGrad)" stroke="#5f0f0f" stroke-width="2.2"/>

      <!-- Vertical Grooves between Lobes -->
      <path d="M40 35 C36 50, 38 68, 44 80" stroke="#7f1d1d" stroke-width="2" fill="none" opacity="0.85"/>
      <path d="M60 35 C64 50, 62 68, 56 80" stroke="#7f1d1d" stroke-width="2" fill="none" opacity="0.85"/>

      <!-- Glossy Vertical Curvature Highlights -->
      <ellipse cx="46" cy="46" rx="6" ry="16" fill="#ffffff" opacity="0.45" transform="rotate(-10 46 46)"/>
      <ellipse cx="45" cy="42" rx="3" ry="9" fill="#ffffff" opacity="0.75" transform="rotate(-10 45 42)"/>
      <ellipse cx="28" cy="52" rx="4" ry="12" fill="#ffffff" opacity="0.3" transform="rotate(-20 28 52)"/>
      <ellipse cx="72" cy="52" rx="4" ry="12" fill="#ffffff" opacity="0.3" transform="rotate(20 72 52)"/>

      <!-- Recessed Top Calyx Cavity -->
      <path d="M40 34 C44 38, 56 38, 60 34 C58 32, 42 32, 40 34 Z" fill="#7f1d1d"/>

      <!-- Thick Curving Green Stem -->
      <path d="M48 34 C46 22, 54 16, 52 8 C56 8, 58 14, 56 34 Z" fill="url(#pepperStemGrad)" stroke="#14532d" stroke-width="1.8"/>
      <ellipse cx="52" cy="8" rx="3.5" ry="2" fill="#86efac" stroke="#14532d" stroke-width="1.2"/>
      <!-- Star Calyx Attachment Base -->
      <path d="M46 34 Q42 30 46 28 Q49 32 52 34 Z" fill="#15803d"/>
      <path d="M54 34 Q58 30 54 28 Q52 32 50 34 Z" fill="#15803d"/>
    </svg>
  `,

  // 5. Whole Barbecue Grilled Fish (Bottom - x25)
  fish: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Golden Char-Grilled Fish Skin Gradient -->
        <linearGradient id="bbqFishBody" x1="0%" y1="30%" x2="100%" y2="70%">
          <stop offset="0%" stop-color="#b45309"/>
          <stop offset="25%" stop-color="#d97706"/>
          <stop offset="55%" stop-color="#f59e0b"/>
          <stop offset="75%" stop-color="#fed7aa"/>
          <stop offset="90%" stop-color="#ca8a04"/>
          <stop offset="100%" stop-color="#78350f"/>
        </linearGradient>
        <!-- Crispy Grilled Fin Gradient -->
        <linearGradient id="bbqFishFin" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#f59e0b"/>
          <stop offset="60%" stop-color="#b45309"/>
          <stop offset="100%" stop-color="#451a03"/>
        </linearGradient>
        <!-- Lemon Slice Gradient -->
        <radialGradient id="fishLemonGrad" cx="45%" cy="45%" r="55%">
          <stop offset="0%" stop-color="#fef9c3"/>
          <stop offset="60%" stop-color="#facc15"/>
          <stop offset="100%" stop-color="#ca8a04"/>
        </radialGradient>
      </defs>

      <!-- Soft Drop Shadow Under Grilled Fish -->
      <ellipse cx="50" cy="78" rx="42" ry="9" fill="#000000" opacity="0.28"/>

      <!-- Tail Fin (Crisp Grilled Forked Tail) -->
      <path d="M78 50 C84 40, 96 30, 96 24 C92 36, 86 46, 88 50 C86 54, 92 64, 96 76 C96 70, 84 60, 78 50 Z" fill="url(#bbqFishFin)" stroke="#5c1d0a" stroke-width="1.8"/>
      <!-- Tail Fin Rays (Charred rib lines) -->
      <line x1="80" y1="49" x2="94" y2="30" stroke="#78350f" stroke-width="1.2"/>
      <line x1="82" y1="50" x2="95" y2="40" stroke="#78350f" stroke-width="1.2"/>
      <line x1="82" y1="50" x2="95" y2="60" stroke="#78350f" stroke-width="1.2"/>
      <line x1="80" y1="51" x2="94" y2="70" stroke="#78350f" stroke-width="1.2"/>

      <!-- Dorsal (Top) Fin -->
      <path d="M38 34 C44 22, 60 22, 66 32 Z" fill="url(#bbqFishFin)" stroke="#5c1d0a" stroke-width="1.5"/>
      <line x1="44" y1="28" x2="48" y2="34" stroke="#451a03" stroke-width="1.2"/>
      <line x1="52" y1="26" x2="55" y2="33" stroke="#451a03" stroke-width="1.2"/>
      <line x1="60" y1="27" x2="62" y2="33" stroke="#451a03" stroke-width="1.2"/>

      <!-- Ventral (Bottom) Fins -->
      <path d="M42 66 C46 76, 54 74, 52 66 Z" fill="url(#bbqFishFin)" stroke="#5c1d0a" stroke-width="1.5"/>
      <path d="M62 64 C66 73, 72 71, 70 63 Z" fill="url(#bbqFishFin)" stroke="#5c1d0a" stroke-width="1.5"/>

      <!-- Main Whole Fish Body (Streamlined grilled whole fish) -->
      <path d="M12 50 C12 48, 22 36, 40 33 C60 30, 74 42, 80 50 C74 58, 60 70, 40 67 C22 64, 12 52, 12 50 Z" fill="url(#bbqFishBody)" stroke="#5c1d0a" stroke-width="2.2"/>

      <!-- Underbelly Soft Glow (Tender light underside) -->
      <path d="M22 55 C32 63, 55 65, 72 55 C60 67, 34 65, 22 55 Z" fill="#fffbeb" opacity="0.45"/>

      <!-- Head & Gill Details -->
      <!-- Snout / Mouth -->
      <path d="M12 50 Q16 49 18 51" stroke="#451a03" stroke-width="2" fill="none"/>
      <!-- Gill Cover Arc -->
      <path d="M28 37 C34 44, 34 56, 28 63" stroke="#78350f" stroke-width="2" fill="none"/>
      <path d="M29 39 C35 45, 35 55, 29 61" stroke="#fde047" stroke-width="1" fill="none" opacity="0.8"/>
      <!-- Roasted Fish Eye -->
      <circle cx="22" cy="44" r="3.8" fill="#1c1917" stroke="#fbbf24" stroke-width="1.4"/>
      <circle cx="21" cy="42.5" r="1.2" fill="#ffffff"/>

      <!-- Pectoral Fin over Gill -->
      <path d="M30 50 C38 48, 42 56, 34 60 C32 58, 30 54, 30 50 Z" fill="url(#bbqFishFin)" stroke="#5c1d0a" stroke-width="1.5"/>
      <line x1="32" y1="52" x2="38" y2="53" stroke="#451a03" stroke-width="1"/>
      <line x1="32" y1="55" x2="37" y2="57" stroke="#451a03" stroke-width="1"/>

      <!-- Chef's Diagonal Scoring Slits (Showing succulent cooked meat inside) -->
      <path d="M42 38 Q45 49 48 60" stroke="#fef08a" stroke-width="3" stroke-linecap="round" fill="none"/>
      <path d="M42 38 Q45 49 48 60" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M54 36 Q57 49 60 61" stroke="#fef08a" stroke-width="3" stroke-linecap="round" fill="none"/>
      <path d="M54 36 Q57 49 60 61" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M66 39 Q68 48 71 58" stroke="#fef08a" stroke-width="2.8" stroke-linecap="round" fill="none"/>
      <path d="M66 39 Q68 48 71 58" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" fill="none"/>

      <!-- Realistic Barbecue Grill Grate Char Marks -->
      <line x1="34" y1="36" x2="48" y2="65" stroke="#381305" stroke-width="2.8" stroke-linecap="round" opacity="0.9"/>
      <line x1="46" y1="34" x2="60" y2="65" stroke="#381305" stroke-width="2.8" stroke-linecap="round" opacity="0.9"/>
      <line x1="58" y1="35" x2="72" y2="64" stroke="#381305" stroke-width="2.8" stroke-linecap="round" opacity="0.9"/>
      <!-- Cross-char hint for BBQ grid texture -->
      <line x1="48" y1="36" x2="36" y2="64" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" opacity="0.65"/>
      <line x1="60" y1="36" x2="48" y2="64" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" opacity="0.65"/>
      <line x1="72" y1="37" x2="60" y2="63" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" opacity="0.65"/>

      <!-- Fresh Lemon Wheel Slice Placed on Fish -->
      <g transform="translate(48, 48) rotate(-10)">
        <circle cx="0" cy="0" r="10" fill="url(#fishLemonGrad)" stroke="#a16207" stroke-width="1.4"/>
        <circle cx="0" cy="0" r="8.5" fill="#fef08a" stroke="#ca8a04" stroke-width="0.8"/>
        <circle cx="0" cy="0" r="1.5" fill="#ffffff"/>
        <!-- Segments -->
        <line x1="0" y1="-8.5" x2="0" y2="8.5" stroke="#ffffff" stroke-width="0.9"/>
        <line x1="-8.5" y1="0" x2="8.5" y2="0" stroke="#ffffff" stroke-width="0.9"/>
        <line x1="-6" y1="-6" x2="6" y2="6" stroke="#ffffff" stroke-width="0.9"/>
        <line x1="-6" y1="6" x2="6" y2="-6" stroke="#ffffff" stroke-width="0.9"/>
      </g>

      <!-- Fresh Rosemary Sprig Garnish -->
      <path d="M26 62 Q38 60 52 64" stroke="#15803d" stroke-width="2" fill="none" stroke-linecap="round"/>
      <path d="M30 61 L26 57 M36 60 L35 54 M42 61 L43 55 M48 62 L51 57" stroke="#16a34a" stroke-width="1.8" stroke-linecap="round"/>

      <!-- Spices & Chili Flakes -->
      <circle cx="36" cy="42" r="0.9" fill="#dc2626"/>
      <circle cx="40" cy="46" r="0.8" fill="#1c1917"/>
      <circle cx="64" cy="43" r="0.9" fill="#dc2626"/>
      <circle cx="70" cy="51" r="0.8" fill="#1c1917"/>
      <circle cx="58" cy="58" r="0.8" fill="#dc2626"/>
    </svg>
  `,

  // 6. Garden-Fresh Crunchy Carrot (x5)
  carrot: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Rich 3D Carrot Root Gradient -->
        <linearGradient id="realCarrotGrad" x1="20%" y1="0%" x2="80%" y2="100%">
          <stop offset="0%" stop-color="#ffedd5"/>
          <stop offset="25%" stop-color="#fb923c"/>
          <stop offset="60%" stop-color="#f97316"/>
          <stop offset="85%" stop-color="#ea580c"/>
          <stop offset="100%" stop-color="#9a3412"/>
        </linearGradient>
        <!-- Feathery Green Foliage Gradient -->
        <linearGradient id="carrotGreensGrad" x1="0%" y1="100%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#15803d"/>
          <stop offset="50%" stop-color="#22c55e"/>
          <stop offset="100%" stop-color="#86efac"/>
        </linearGradient>
      </defs>

      <!-- Soft Drop Shadow Under Carrot -->
      <ellipse cx="50" cy="80" rx="38" ry="9" fill="#000000" opacity="0.28"/>

      <g transform="rotate(38 50 50)">
        <!-- Feathery Green Leaves -->
        <path d="M50 24 Q50 6 52 2" stroke="#15803d" stroke-width="2.5" stroke-linecap="round" fill="none"/>
        <path d="M48 16 Q38 8 36 2 M52 14 Q62 6 64 2 M49 10 Q42 4 40 1 M51 8 Q58 3 60 1" stroke="url(#carrotGreensGrad)" stroke-width="1.8" stroke-linecap="round" fill="none"/>
        
        <path d="M48 24 Q36 12 30 8" stroke="#16a34a" stroke-width="2.2" stroke-linecap="round" fill="none"/>
        <path d="M44 18 Q34 16 32 12 M40 14 Q30 10 26 8 M46 20 Q40 14 38 10" stroke="url(#carrotGreensGrad)" stroke-width="1.6" stroke-linecap="round" fill="none"/>
        
        <path d="M52 24 Q64 12 70 8" stroke="#16a34a" stroke-width="2.2" stroke-linecap="round" fill="none"/>
        <path d="M56 18 Q66 16 68 12 M60 14 Q70 10 74 8 M54 20 Q60 14 62 10" stroke="url(#carrotGreensGrad)" stroke-width="1.6" stroke-linecap="round" fill="none"/>

        <!-- Root Crown Top Indentation -->
        <ellipse cx="50" cy="24" rx="14" ry="4.5" fill="#c2410c" stroke="#7c2d12" stroke-width="1.5"/>
        <ellipse cx="50" cy="24" rx="8" ry="2.5" fill="#15803d"/>

        <!-- Tapered Root Body -->
        <path d="M36 24 C36 34, 42 66, 48 86 C49 89, 51 89, 52 86 C58 66, 64 34, 64 24 Z" fill="url(#realCarrotGrad)" stroke="#7c2d12" stroke-width="2.2"/>

        <!-- Cylindrical Gloss Highlight along left edge -->
        <path d="M40 26 C41 36, 45 64, 48 78" stroke="#ffffff" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.45"/>
        <path d="M40 28 C41 34, 44 48, 45 54" stroke="#ffffff" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.7"/>

        <!-- Natural Horizontal Root Creases / Lenticel Ridges -->
        <path d="M42 32 Q49 34 56 31" stroke="#9a3412" stroke-width="1.8" stroke-linecap="round" fill="none"/>
        <path d="M43 40 Q50 42 57 39" stroke="#9a3412" stroke-width="1.8" stroke-linecap="round" fill="none"/>
        <path d="M44 48 Q50 50 55 47" stroke="#9a3412" stroke-width="1.8" stroke-linecap="round" fill="none"/>
        <path d="M45 56 Q50 58 54 55" stroke="#9a3412" stroke-width="1.8" stroke-linecap="round" fill="none"/>
        <path d="M46 64 Q50 66 53 63" stroke="#9a3412" stroke-width="1.6" stroke-linecap="round" fill="none"/>
        <path d="M47 72 Q50 74 52 72" stroke="#9a3412" stroke-width="1.4" stroke-linecap="round" fill="none"/>

        <!-- Subtle texture spots -->
        <circle cx="54" cy="36" r="0.8" fill="#7c2d12"/>
        <circle cx="46" cy="44" r="0.8" fill="#7c2d12"/>
        <circle cx="52" cy="52" r="0.8" fill="#7c2d12"/>
      </g>
    </svg>
  `,

  // 7. Barbecue Grilled Jumbo Shrimp (x10)
  shrimp: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Succulent Grilled Shrimp Coral-Red Gradient -->
        <radialGradient id="shrimpMeatGrad" cx="45%" cy="40%" r="58%">
          <stop offset="0%" stop-color="#fed7aa"/>
          <stop offset="25%" stop-color="#fb923c"/>
          <stop offset="65%" stop-color="#ea580c"/>
          <stop offset="90%" stop-color="#c2410c"/>
          <stop offset="100%" stop-color="#7c2d12"/>
        </radialGradient>
        <!-- Tender White Meat Inside Ribs -->
        <linearGradient id="shrimpBellyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="60%" stop-color="#ffedd5"/>
          <stop offset="100%" stop-color="#fed7aa"/>
        </linearGradient>
        <!-- Tail Fin Fan Gradient -->
        <linearGradient id="shrimpTailGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#f97316"/>
          <stop offset="60%" stop-color="#dc2626"/>
          <stop offset="100%" stop-color="#7f1d1d"/>
        </linearGradient>
        <!-- Lime / Lemon Wedge Gradient -->
        <radialGradient id="shrimpLimeGrad" cx="40%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#bef264"/>
          <stop offset="65%" stop-color="#84cc16"/>
          <stop offset="100%" stop-color="#4d7c0f"/>
        </radialGradient>
      </defs>

      <!-- Soft Shadow -->
      <ellipse cx="50" cy="80" rx="38" ry="10" fill="#000000" opacity="0.3"/>

      <!-- Garnishing Green Bed -->
      <path d="M22 72 C16 66, 22 80, 34 78 C42 82, 58 82, 66 76 C74 80, 82 72, 76 66 Z" fill="#22c55e" opacity="0.75"/>

      <!-- Bamboo Skewer Running Diagonally Through Shrimp -->
      <line x1="14" y1="84" x2="88" y2="14" stroke="#d97706" stroke-width="3" stroke-linecap="round"/>
      <line x1="14" y1="84" x2="88" y2="14" stroke="#78350f" stroke-width="1.2" stroke-linecap="round"/>

      <!-- Forked Prawn Tail Fans -->
      <path d="M24 74 C16 78, 12 72, 14 66 C20 68, 24 70, 26 72 Z" fill="url(#shrimpTailGrad)" stroke="#7c2d12" stroke-width="1.4"/>
      <path d="M26 76 C20 84, 14 82, 18 76 C22 76, 24 76, 26 76 Z" fill="url(#shrimpTailGrad)" stroke="#7c2d12" stroke-width="1.4"/>

      <!-- Main Succulent C-Curled Grilled Jumbo Shrimp Body -->
      <path d="M24 70 C18 56, 22 32, 40 20 C60 8, 84 18, 86 40 C88 62, 70 76, 52 74 C40 72, 38 60, 48 56 C58 52, 68 48, 66 38 C64 28, 48 26, 38 36 C32 42, 30 58, 24 70 Z" fill="url(#shrimpMeatGrad)" stroke="#7c2d12" stroke-width="2.4"/>

      <!-- Tender Belly White Highlights along Inside Curve -->
      <path d="M38 38 C44 32, 54 32, 58 38 C56 46, 46 50, 40 52 C36 50, 36 44, 38 38 Z" fill="url(#shrimpBellyGrad)" opacity="0.7"/>

      <!-- Segment Shell Ribs -->
      <path d="M34 26 C38 32, 44 34, 46 36" stroke="#ffffff" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M48 18 C52 26, 58 30, 60 32" stroke="#ffffff" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M64 18 C66 26, 72 32, 74 34" stroke="#ffffff" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M78 26 C76 34, 78 42, 76 46" stroke="#ffffff" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M82 40 C76 46, 74 54, 70 58" stroke="#ffffff" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>
      <path d="M74 54 C66 60, 62 66, 56 68" stroke="#ffffff" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.85"/>

      <!-- Mouth-watering Barbecue Char Grill Marks -->
      <line x1="32" y1="24" x2="44" y2="34" stroke="#381305" stroke-width="2.6" stroke-linecap="round" opacity="0.9"/>
      <line x1="46" y1="16" x2="58" y2="28" stroke="#381305" stroke-width="2.8" stroke-linecap="round" opacity="0.9"/>
      <line x1="62" y1="16" x2="74" y2="30" stroke="#381305" stroke-width="2.8" stroke-linecap="round" opacity="0.9"/>
      <line x1="76" y1="24" x2="82" y2="40" stroke="#381305" stroke-width="2.8" stroke-linecap="round" opacity="0.9"/>
      <line x1="78" y1="42" x2="72" y2="56" stroke="#381305" stroke-width="2.6" stroke-linecap="round" opacity="0.9"/>
      <line x1="68" y1="56" x2="56" y2="68" stroke="#381305" stroke-width="2.4" stroke-linecap="round" opacity="0.9"/>

      <!-- Glaze Shine -->
      <ellipse cx="64" cy="20" rx="8" ry="3.5" fill="#ffffff" opacity="0.5" transform="rotate(10 64 20)"/>
      <ellipse cx="80" cy="34" rx="3.5" ry="8" fill="#ffffff" opacity="0.45"/>

      <!-- Fresh Lime Wedge beside Shrimp -->
      <path d="M68 64 C76 60, 84 68, 80 76 Z" fill="url(#shrimpLimeGrad)" stroke="#3f6212" stroke-width="1.4"/>
      <path d="M70 65 C76 63, 80 68, 77 73 Z" fill="#d9f99d"/>

      <!-- Chopped Herb/Parsley Specks & Red Chili Flakes -->
      <circle cx="42" cy="22" r="1.1" fill="#15803d"/>
      <circle cx="56" cy="18" r="1.1" fill="#dc2626"/>
      <circle cx="70" cy="24" r="1.1" fill="#15803d"/>
      <circle cx="82" cy="30" r="1.1" fill="#dc2626"/>
      <circle cx="76" cy="48" r="1.1" fill="#15803d"/>
      <circle cx="62" cy="62" r="1.1" fill="#dc2626"/>
      <circle cx="50" cy="60" r="0.9" fill="#1c1917"/>
    </svg>
  `,

  // 8. Premium Char-Grilled Sweet Corn on the Cob (x5)
  corn: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <defs>
        <!-- Golden Sweet Corn Kernels Gradient -->
        <linearGradient id="cornCobGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="30%" stop-color="#facc15"/>
          <stop offset="70%" stop-color="#eab308"/>
          <stop offset="100%" stop-color="#ca8a04"/>
        </linearGradient>
        <!-- Fresh Green Husk Leaf Gradient -->
        <linearGradient id="cornHuskGrad1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#86efac"/>
          <stop offset="50%" stop-color="#22c55e"/>
          <stop offset="100%" stop-color="#15803d"/>
        </linearGradient>
        <linearGradient id="cornHuskGrad2" x1="0%" y1="100%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#4ade80"/>
          <stop offset="70%" stop-color="#16a34a"/>
          <stop offset="100%" stop-color="#14532d"/>
        </linearGradient>
        <!-- Melting Golden Butter Pat -->
        <radialGradient id="butterPatGrad" cx="35%" cy="35%" r="65%">
          <stop offset="0%" stop-color="#ffffff"/>
          <stop offset="40%" stop-color="#fef08a"/>
          <stop offset="85%" stop-color="#facc15"/>
          <stop offset="100%" stop-color="#eab308"/>
        </radialGradient>
      </defs>

      <!-- Soft Shadow Under Corn -->
      <ellipse cx="50" cy="80" rx="38" ry="10" fill="#000000" opacity="0.28"/>

      <g transform="rotate(-32 50 50)">
        <!-- Corn Stalk / Stem at bottom -->
        <path d="M47 80 L53 80 L51 90 L49 90 Z" fill="#a16207" stroke="#78350f" stroke-width="1.2"/>

        <!-- Back Husk Leaves -->
        <path d="M38 78 C28 58, 26 40, 24 28 C34 44, 38 64, 44 76 Z" fill="url(#cornHuskGrad2)" stroke="#166534" stroke-width="1.4"/>
        <path d="M62 78 C72 58, 74 40, 76 28 C66 44, 62 64, 56 76 Z" fill="url(#cornHuskGrad2)" stroke="#166534" stroke-width="1.4"/>

        <!-- Main Golden Plump Corn Cob Body -->
        <path d="M40 76 C36 50, 36 26, 44 14 C48 8, 52 8, 56 14 C64 26, 64 50, 60 76 Z" fill="url(#cornCobGrad)" stroke="#a16207" stroke-width="2"/>

        <!-- Kernels Grid Rows & Columns -->
        <path d="M44 14 C42 34, 42 58, 45 76" stroke="#ca8a04" stroke-width="1.1" fill="none" opacity="0.75"/>
        <path d="M48 10 C47 32, 47 58, 49 76" stroke="#ca8a04" stroke-width="1.1" fill="none" opacity="0.75"/>
        <path d="M52 10 C53 32, 53 58, 51 76" stroke="#ca8a04" stroke-width="1.1" fill="none" opacity="0.75"/>
        <path d="M56 14 C58 34, 58 58, 55 76" stroke="#ca8a04" stroke-width="1.1" fill="none" opacity="0.75"/>

        <line x1="43" y1="18" x2="57" y2="18" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="41" y1="24" x2="59" y2="24" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="39" y1="30" x2="61" y2="30" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="38" y1="36" x2="62" y2="36" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="38" y1="42" x2="62" y2="42" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="38" y1="48" x2="62" y2="48" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="39" y1="54" x2="61" y2="54" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="40" y1="60" x2="60" y2="60" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="41" y1="66" x2="59" y2="66" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>
        <line x1="42" y1="72" x2="58" y2="72" stroke="#ca8a04" stroke-width="1" opacity="0.7"/>

        <!-- Individual Plump Kernel Highlights -->
        <ellipse cx="46" cy="21" rx="1.6" ry="1.2" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="50" cy="21" rx="1.6" ry="1.2" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="54" cy="21" rx="1.6" ry="1.2" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="45" cy="27" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="50" cy="27" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="55" cy="27" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="44" cy="33" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="56" cy="33" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="44" cy="45" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="56" cy="45" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="45" cy="57" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>
        <ellipse cx="55" cy="57" rx="1.8" ry="1.3" fill="#ffffff" opacity="0.6"/>

        <!-- Authentic Fire-Roasted Char Marks -->
        <ellipse cx="51" cy="24" rx="2.5" ry="1.6" fill="#451a03" opacity="0.85"/>
        <ellipse cx="43" cy="36" rx="3.2" ry="1.8" fill="#3f1d0b" opacity="0.9"/>
        <ellipse cx="57" cy="39" rx="2.8" ry="1.8" fill="#3f1d0b" opacity="0.9"/>
        <ellipse cx="48" cy="48" rx="3.5" ry="2" fill="#451a03" opacity="0.85"/>
        <ellipse cx="54" cy="52" rx="3" ry="1.8" fill="#3f1d0b" opacity="0.9"/>
        <ellipse cx="44" cy="63" rx="2.8" ry="1.8" fill="#451a03" opacity="0.85"/>
        <!-- Char grill sear stripes -->
        <path d="M40 32 Q50 35 60 32" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.75"/>
        <path d="M39 50 Q50 53 61 50" stroke="#451a03" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.75"/>
        <path d="M41 62 Q50 65 59 62" stroke="#451a03" stroke-width="1.8" stroke-linecap="round" fill="none" opacity="0.7"/>

        <!-- Melting Pat of Golden Butter on Hot Corn -->
        <rect x="44" y="37" width="12" height="9" rx="2.5" fill="url(#butterPatGrad)" stroke="#d97706" stroke-width="1.2"/>
        <ellipse cx="47" cy="40" rx="3.5" ry="1.5" fill="#ffffff" opacity="0.7"/>
        <!-- Melting Butter Drips -->
        <path d="M47 46 Q47 52 49 53 Q51 52 51 46 Z" fill="#facc15" opacity="0.9"/>
        <path d="M53 46 Q54 50 55 51 Q56 50 56 46 Z" fill="#facc15" opacity="0.9"/>

        <!-- Front Curled Husk Leaves Peeled Back -->
        <path d="M34 80 C26 70, 24 54, 34 44 C34 56, 38 68, 44 76 Z" fill="url(#cornHuskGrad1)" stroke="#166534" stroke-width="1.6"/>
        <path d="M66 80 C74 70, 76 54, 66 44 C66 56, 62 68, 56 76 Z" fill="url(#cornHuskGrad1)" stroke="#166534" stroke-width="1.6"/>
        <path d="M42 78 C36 72, 38 64, 46 60 C46 66, 48 72, 48 78 Z" fill="url(#cornHuskGrad1)" stroke="#166534" stroke-width="1.2"/>
        <path d="M58 78 C64 72, 62 64, 54 60 C54 66, 52 72, 52 78 Z" fill="url(#cornHuskGrad1)" stroke="#166534" stroke-width="1.2"/>
      </g>
    </svg>
  `,

  // Salad Bowl Illustration (Authentic Curved Wooden Bowl with Fresh Mixed Salad)
  salad: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 100">
      <defs>
        <linearGradient id="bowlWoodGrad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#b45309"/>
          <stop offset="45%" stop-color="#78350f"/>
          <stop offset="100%" stop-color="#451a03"/>
        </linearGradient>
        <linearGradient id="bowlRimGrad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#d97706"/>
          <stop offset="100%" stop-color="#78350f"/>
        </linearGradient>
        <linearGradient id="lettuceGrad1" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#86efac"/>
          <stop offset="100%" stop-color="#16a34a"/>
        </linearGradient>
        <linearGradient id="lettuceGrad2" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#4ade80"/>
          <stop offset="100%" stop-color="#15803d"/>
        </linearGradient>
        <radialGradient id="tomWedgeGrad" cx="35%" cy="35%" r="65%">
          <stop offset="0%" stop-color="#f87171"/>
          <stop offset="70%" stop-color="#dc2626"/>
          <stop offset="100%" stop-color="#991b1b"/>
        </radialGradient>
        <radialGradient id="yolkGrad" cx="40%" cy="35%" r="65%">
          <stop offset="0%" stop-color="#fef08a"/>
          <stop offset="60%" stop-color="#f59e0b"/>
          <stop offset="100%" stop-color="#d97706"/>
        </radialGradient>
      </defs>
      <!-- Shadow under bowl -->
      <ellipse cx="60" cy="86" rx="46" ry="10" fill="#000000" opacity="0.32"/>
      
      <!-- Back Ruffled Lettuce Leaves -->
      <path d="M20 46 C12 30, 26 14, 42 22 C50 10, 68 12, 78 20 C90 10, 106 22, 100 44 Z" fill="url(#lettuceGrad2)" stroke="#14532d" stroke-width="2.5"/>
      <path d="M28 38 C36 20, 52 22, 58 30 C68 18, 84 20, 88 34 Z" fill="url(#lettuceGrad1)" stroke="#15803d" stroke-width="2"/>
      
      <!-- Deep Wooden Bowl Body -->
      <path d="M8 44 C12 78, 36 88, 60 88 C84 88, 108 78, 112 44 C95 56, 25 56, 8 44 Z" fill="url(#bowlWoodGrad)" stroke="#3b1704" stroke-width="3"/>
      <!-- Wooden Bowl Inner Rim / Cavity Shadow -->
      <ellipse cx="60" cy="45" rx="52" ry="16" fill="#451a03" stroke="#3b1704" stroke-width="2"/>
      <!-- Wooden Bowl Lip Highlight -->
      <ellipse cx="60" cy="44" rx="51" ry="14" fill="none" stroke="url(#bowlRimGrad)" stroke-width="2.5"/>

      <!-- Front Crisp Wavy Lettuce Leaves -->
      <path d="M16 46 C24 38, 36 34, 46 44 C52 36, 68 36, 74 44 C82 36, 96 40, 102 46 C88 54, 30 54, 16 46 Z" fill="url(#lettuceGrad1)" stroke="#16a34a" stroke-width="2"/>
      <path d="M24 45 Q36 36 46 42" stroke="#bbf7d0" stroke-width="1.8" fill="none"/>
      <path d="M54 40 Q64 34 72 40" stroke="#bbf7d0" stroke-width="1.8" fill="none"/>

      <!-- Hard Boiled Egg Slice (Left) -->
      <ellipse cx="36" cy="44" rx="12" ry="9" fill="#ffffff" stroke="#e2e8f0" stroke-width="1.5" transform="rotate(-15 36 44)"/>
      <circle cx="36" cy="44" r="5.5" fill="url(#yolkGrad)"/>

      <!-- Juicy Cherry Tomato Slice (Right) -->
      <circle cx="82" cy="45" r="10" fill="url(#tomWedgeGrad)" stroke="#7f1d1d" stroke-width="2"/>
      <path d="M78 43 C80 39, 86 39, 88 43 C88 49, 78 49, 78 43 Z" fill="#991b1b"/>
      <circle cx="81" cy="43" r="1.5" fill="#fef08a"/>
      <circle cx="85" cy="43" r="1.5" fill="#fef08a"/>
      <ellipse cx="79" cy="39" rx="3" ry="1.5" fill="#ffffff" opacity="0.65" transform="rotate(-30 79 39)"/>

      <!-- Red Cherry Tomato Wedge (Center) -->
      <ellipse cx="58" cy="48" rx="8" ry="6" fill="url(#tomWedgeGrad)" stroke="#7f1d1d" stroke-width="1.5" transform="rotate(10 58 48)"/>
      <ellipse cx="56" cy="46" rx="2.5" ry="1" fill="#ffffff" opacity="0.75"/>

      <!-- Crisp Cucumber Slices -->
      <circle cx="48" cy="37" r="7.5" fill="#86efac" stroke="#15803d" stroke-width="2"/>
      <circle cx="48" cy="37" r="5.5" fill="#dcfce7"/>
      <circle cx="46" cy="36" r="0.9" fill="#15803d" opacity="0.7"/>
      <circle cx="49" cy="35" r="0.9" fill="#15803d" opacity="0.7"/>
      <circle cx="50" cy="38" r="0.9" fill="#15803d" opacity="0.7"/>

      <!-- Golden Sweet Corn Kernels -->
      <ellipse cx="68" cy="37" rx="3" ry="2.2" fill="#fbbf24" stroke="#d97706" stroke-width="0.8"/>
      <ellipse cx="74" cy="37" rx="2.8" ry="2.2" fill="#facc15" stroke="#d97706" stroke-width="0.8"/>
      <ellipse cx="71" cy="41" rx="3" ry="2.2" fill="#eab308" stroke="#d97706" stroke-width="0.8"/>
      <ellipse cx="65" cy="41" rx="2.8" ry="2.2" fill="#fbbf24" stroke="#d97706" stroke-width="0.8"/>
      <ellipse cx="40" cy="52" rx="2.8" ry="2" fill="#facc15" stroke="#d97706" stroke-width="0.8"/>
      <ellipse cx="45" cy="52" rx="3" ry="2" fill="#fbbf24" stroke="#d97706" stroke-width="0.8"/>

      <!-- Purple Cabbage Strips -->
      <path d="M52 45 Q60 41 66 47" stroke="#9333ea" stroke-width="2.5" stroke-linecap="round" fill="none"/>
      <path d="M74 45 Q80 39 84 44" stroke="#a855f7" stroke-width="2" stroke-linecap="round" fill="none"/>

      <!-- Black Olives -->
      <ellipse cx="62" cy="42" rx="4.2" ry="3.2" fill="#1e293b" stroke="#0f172a" stroke-width="1.5"/>
      <ellipse cx="62" cy="42" rx="1.6" ry="1.1" fill="#64748b"/>

      <!-- Bowl Gloss Highlights -->
      <path d="M22 62 C26 77, 44 84, 60 84" stroke="#d97706" stroke-width="2" stroke-linecap="round" fill="none" opacity="0.45"/>
    </svg>
  `,

  // Pizza on Wooden Board Illustration (Mouthwatering Cheesy Pizza with Pepperoni)
  pizza: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 100">
      <defs>
        <radialGradient id="boardWoodGrad" cx="45%" cy="40%" r="60%">
          <stop offset="0%" stop-color="#b45309"/>
          <stop offset="70%" stop-color="#78350f"/>
          <stop offset="100%" stop-color="#451a03"/>
        </radialGradient>
        <radialGradient id="pizzaCrustGrad" cx="45%" cy="40%" r="55%">
          <stop offset="0%" stop-color="#fed7aa"/>
          <stop offset="40%" stop-color="#fba444"/>
          <stop offset="85%" stop-color="#c25e07"/>
          <stop offset="100%" stop-color="#7c2d12"/>
        </radialGradient>
        <radialGradient id="mozzarellaGrad" cx="45%" cy="40%" r="55%">
          <stop offset="0%" stop-color="#fef9c3"/>
          <stop offset="45%" stop-color="#fef08a"/>
          <stop offset="85%" stop-color="#facc15"/>
          <stop offset="100%" stop-color="#ea580c"/>
        </radialGradient>
        <radialGradient id="pepperoniGrad" cx="35%" cy="35%" r="65%">
          <stop offset="0%" stop-color="#f87171"/>
          <stop offset="65%" stop-color="#dc2626"/>
          <stop offset="100%" stop-color="#7f1d1d"/>
        </radialGradient>
      </defs>

      <!-- Soft Drop Shadow -->
      <ellipse cx="60" cy="56" rx="55" ry="40" fill="#000000" opacity="0.32"/>

      <!-- Wooden Peel / Board with Handle -->
      <path d="M12 28 C6 22, 10 16, 18 20 L28 28 Z" fill="#78350f" stroke="#451a03" stroke-width="2"/>
      <ellipse cx="60" cy="52" rx="54" ry="42" fill="url(#boardWoodGrad)" stroke="#451a03" stroke-width="3"/>
      <!-- Board Bevel Edge Highlight -->
      <ellipse cx="60" cy="50" rx="52" ry="40" fill="none" stroke="#d97706" stroke-width="1.8" opacity="0.6"/>

      <!-- Pizza Crust (Baked puffy outer ring) -->
      <ellipse cx="60" cy="50" rx="46" ry="34" fill="url(#pizzaCrustGrad)" stroke="#5c1d0a" stroke-width="2.5"/>
      <!-- Crust Bubbles / Toast Marks -->
      <ellipse cx="36" cy="28" rx="3.5" ry="2" fill="#451a03" opacity="0.5"/>
      <ellipse cx="78" cy="25" rx="4" ry="2.2" fill="#451a03" opacity="0.5"/>
      <ellipse cx="94" cy="40" rx="3" ry="2.5" fill="#451a03" opacity="0.5"/>
      <ellipse cx="22" cy="46" rx="3" ry="2" fill="#451a03" opacity="0.5"/>
      <ellipse cx="50" cy="74" rx="4" ry="2" fill="#451a03" opacity="0.5"/>
      <ellipse cx="80" cy="70" rx="3.5" ry="2.2" fill="#451a03" opacity="0.5"/>

      <!-- Red Marinara Sauce Base -->
      <ellipse cx="60" cy="50" rx="39" ry="28" fill="#b91c1c"/>

      <!-- Golden Melted Mozzarella Cheese Surface -->
      <ellipse cx="60" cy="49" rx="37" ry="26" fill="url(#mozzarellaGrad)"/>
      <!-- Baked Cheese Spots -->
      <ellipse cx="48" cy="42" rx="5" ry="3" fill="#ea580c" opacity="0.35"/>
      <ellipse cx="68" cy="52" rx="6" ry="3.5" fill="#ea580c" opacity="0.35"/>
      <ellipse cx="56" cy="58" rx="5" ry="3" fill="#ea580c" opacity="0.35"/>

      <!-- Slice Cut Marks -->
      <line x1="60" y1="23" x2="60" y2="75" stroke="#c2410c" stroke-width="1.4" opacity="0.7" stroke-dasharray="3,2"/>
      <line x1="24" y1="36" x2="96" y2="62" stroke="#c2410c" stroke-width="1.4" opacity="0.7" stroke-dasharray="3,2"/>
      <line x1="24" y1="62" x2="96" y2="36" stroke="#c2410c" stroke-width="1.4" opacity="0.7" stroke-dasharray="3,2"/>

      <!-- Pepperoni Slices (Plump, seasoned with grease shine) -->
      <!-- Pep 1 (Top Center) -->
      <ellipse cx="60" cy="34" rx="7.5" ry="5.5" fill="url(#pepperoniGrad)" stroke="#5f0f0f" stroke-width="1.5"/>
      <ellipse cx="58" cy="33" rx="3" ry="1.8" fill="#fca5a5" opacity="0.6"/>
      <circle cx="63" cy="36" r="0.8" fill="#450a0a"/>
      <circle cx="58" cy="36" r="0.8" fill="#450a0a"/>

      <!-- Pep 2 (Left) -->
      <ellipse cx="40" cy="44" rx="8" ry="6" fill="url(#pepperoniGrad)" stroke="#5f0f0f" stroke-width="1.5" transform="rotate(-15 40 44)"/>
      <ellipse cx="38" cy="43" rx="3" ry="1.8" fill="#fca5a5" opacity="0.6"/>
      <circle cx="42" cy="46" r="0.8" fill="#450a0a"/>

      <!-- Pep 3 (Right) -->
      <ellipse cx="78" cy="42" rx="8" ry="6" fill="url(#pepperoniGrad)" stroke="#5f0f0f" stroke-width="1.5" transform="rotate(15 78 42)"/>
      <ellipse cx="76" cy="41" rx="3" ry="1.8" fill="#fca5a5" opacity="0.6"/>
      <circle cx="80" cy="44" r="0.8" fill="#450a0a"/>

      <!-- Pep 4 (Center Bottom) -->
      <ellipse cx="50" cy="58" rx="8" ry="6" fill="url(#pepperoniGrad)" stroke="#5f0f0f" stroke-width="1.5" transform="rotate(20 50 58)"/>
      <ellipse cx="48" cy="57" rx="3" ry="1.8" fill="#fca5a5" opacity="0.6"/>

      <!-- Pep 5 (Bottom Right) -->
      <ellipse cx="72" cy="58" rx="7.5" ry="5.5" fill="url(#pepperoniGrad)" stroke="#5f0f0f" stroke-width="1.5" transform="rotate(-10 72 58)"/>
      <ellipse cx="70" cy="57" rx="3" ry="1.8" fill="#fca5a5" opacity="0.6"/>

      <!-- Green Bell Pepper Strips -->
      <path d="M48 30 Q54 28 52 35" stroke="#16a34a" stroke-width="2.5" stroke-linecap="round" fill="none"/>
      <path d="M68 36 Q74 34 72 40" stroke="#15803d" stroke-width="2.5" stroke-linecap="round" fill="none"/>
      <path d="M34 52 Q38 58 44 56" stroke="#16a34a" stroke-width="2.5" stroke-linecap="round" fill="none"/>
      <path d="M58 48 Q64 46 62 52" stroke="#22c55e" stroke-width="2.2" stroke-linecap="round" fill="none"/>
      <path d="M82 52 Q86 58 80 60" stroke="#16a34a" stroke-width="2.5" stroke-linecap="round" fill="none"/>

      <!-- Black Olive Rings -->
      <ellipse cx="52" cy="42" rx="3.5" ry="2.5" fill="#0f172a" stroke="#020617" stroke-width="1.2"/>
      <ellipse cx="52" cy="42" rx="1.5" ry="1" fill="#fef08a"/>
      
      <ellipse cx="64" cy="62" rx="3.5" ry="2.5" fill="#0f172a" stroke="#020617" stroke-width="1.2"/>
      <ellipse cx="64" cy="62" rx="1.5" ry="1" fill="#fef08a"/>

      <ellipse cx="70" cy="46" rx="3" ry="2.2" fill="#0f172a" stroke="#020617" stroke-width="1.2"/>
      <ellipse cx="70" cy="46" rx="1.3" ry="0.9" fill="#fef08a"/>

      <!-- Basil Herb Specks -->
      <circle cx="44" cy="36" r="1.2" fill="#15803d"/>
      <circle cx="62" cy="40" r="1.2" fill="#15803d"/>
      <circle cx="74" cy="48" r="1.2" fill="#15803d"/>
      <circle cx="56" cy="54" r="1.2" fill="#15803d"/>
      <circle cx="44" cy="62" r="1.2" fill="#15803d"/>
    </svg>
  `,

  // Center Cat Mascot with Purple Sunglasses drinking Layered Juice (Exact Match)
  catMascot: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 115">
      <defs>
        <!-- Tropical Juice 3-Layer Gradient -->
        <linearGradient id="juiceLayers" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#84cc16"/>
          <stop offset="36%" stop-color="#a3e635"/>
          <stop offset="40%" stop-color="#facc15"/>
          <stop offset="68%" stop-color="#f97316"/>
          <stop offset="72%" stop-color="#ef4444"/>
          <stop offset="100%" stop-color="#b91c1c"/>
        </linearGradient>
        <!-- Sunglasses Lens Gradient -->
        <linearGradient id="sunglassGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#a855f7"/>
          <stop offset="45%" stop-color="#7e22ce"/>
          <stop offset="100%" stop-color="#4c1d95"/>
        </linearGradient>
      </defs>

      <g transform="rotate(4 60 55)">
        <!-- Left Ear -->
        <path d="M 28 42 C 22 28, 26 12, 38 8 C 45 15, 48 26, 46 36 Z" fill="#ffffff" stroke="#3b1523" stroke-width="3" stroke-linejoin="round"/>
        <path d="M 31 35 C 28 26, 31 16, 38 12 C 42 17, 44 26, 41 32 Z" fill="#f472b6" opacity="0.85"/>

        <!-- Right Ear -->
        <path d="M 76 34 C 74 24, 76 14, 84 8 C 96 12, 98 28, 94 42 Z" fill="#ffffff" stroke="#3b1523" stroke-width="3" stroke-linejoin="round"/>
        <path d="M 80 30 C 78 24, 79 16, 84 12 C 90 16, 92 26, 89 36 Z" fill="#f472b6" opacity="0.85"/>

        <!-- Chubby Cat Head -->
        <path d="M 32 38 C 16 46, 16 78, 38 86 C 48 90, 72 90, 84 86 C 104 78, 104 46, 88 38 C 80 30, 40 30, 32 38 Z" fill="#ffffff" stroke="#3b1523" stroke-width="3.5" stroke-linejoin="round"/>

        <!-- Purple Sunglasses on Head (Tilted stylishly) -->
        <g transform="rotate(-6 60 25)">
          <!-- Left Frame & Lens -->
          <rect x="25" y="14" width="30" height="22" rx="7" fill="#3b0764" stroke="#2e0550" stroke-width="1.5"/>
          <rect x="28" y="17" width="24" height="16" rx="5" fill="url(#sunglassGrad)"/>
          <ellipse cx="34" cy="22" rx="6" ry="3" fill="#e9d5ff" opacity="0.75" transform="rotate(-15 34 22)"/>

          <!-- Bridge -->
          <path d="M 54 23 Q 60 20 66 23" stroke="#3b0764" stroke-width="5" stroke-linecap="round" fill="none"/>

          <!-- Right Frame & Lens -->
          <rect x="65" y="14" width="30" height="22" rx="7" fill="#3b0764" stroke="#2e0550" stroke-width="1.5"/>
          <rect x="68" y="17" width="24" height="16" rx="5" fill="url(#sunglassGrad)"/>
          <ellipse cx="74" cy="22" rx="6" ry="3" fill="#e9d5ff" opacity="0.75" transform="rotate(-15 74 22)"/>
        </g>

        <!-- Whiskers Left (3 dark burgundy lines) -->
        <path d="M 28 62 Q 18 61 11 58" stroke="#3b1523" stroke-width="2.8" stroke-linecap="round" fill="none"/>
        <path d="M 26 68 Q 16 69 10 72" stroke="#3b1523" stroke-width="2.8" stroke-linecap="round" fill="none"/>
        <path d="M 28 74 Q 20 78 13 83" stroke="#3b1523" stroke-width="2.8" stroke-linecap="round" fill="none"/>

        <!-- Whiskers Right (3 dark burgundy lines) -->
        <path d="M 90 58 Q 100 56 108 53" stroke="#3b1523" stroke-width="2.8" stroke-linecap="round" fill="none"/>
        <path d="M 92 64 Q 102 64 109 66" stroke="#3b1523" stroke-width="2.8" stroke-linecap="round" fill="none"/>
        <path d="M 90 70 Q 100 73 107 77" stroke="#3b1523" stroke-width="2.8" stroke-linecap="round" fill="none"/>

        <!-- Soft Pink Blush -->
        <ellipse cx="32" cy="65" rx="7.5" ry="4.5" fill="#f472b6" opacity="0.8"/>
        <ellipse cx="88" cy="61" rx="7.5" ry="4.5" fill="#f472b6" opacity="0.8"/>

        <!-- Big Sparkling Anime Cat Eyes -->
        <!-- Left Eye -->
        <ellipse cx="44" cy="55" rx="9.5" ry="12.5" fill="#4a0e2e"/>
        <ellipse cx="41" cy="51" rx="4.5" ry="5.5" fill="#ffffff"/>
        <circle cx="47" cy="61" r="2.8" fill="#ffffff"/>

        <!-- Right Eye -->
        <ellipse cx="76" cy="51" rx="9.5" ry="12.5" fill="#4a0e2e"/>
        <ellipse cx="73" cy="47" rx="4.5" ry="5.5" fill="#ffffff"/>
        <circle cx="79" cy="57" r="2.8" fill="#ffffff"/>

        <!-- Snout: Pink Nose -->
        <polygon points="58,58 62,58 60,61" fill="#f472b6"/>

        <!-- Mouth Curve with Tongue -->
        <path d="M 54 62 Q 57 65 60 62 Q 63 65 66 62" stroke="#3b1523" stroke-width="2.5" stroke-linecap="round" fill="none"/>
        <!-- Cute Red Tongue -->
        <path d="M 57.5 63 C 57.5 63, 57.5 71, 60 71 C 62.5 71, 62.5 63, 62.5 63 Z" fill="#ef4444" stroke="#b91c1c" stroke-width="1"/>

        <!-- Cyan / Turquoise Shirt Body -->
        <path d="M 38 84 C 38 76, 50 74, 66 74 C 76 74, 82 78, 86 84 L 86 110 L 36 110 Z" fill="#22d3ee" stroke="#0891b2" stroke-width="2.5"/>
        <path d="M 38 84 C 48 88, 62 88, 70 84" stroke="#67e8f9" stroke-width="2" fill="none"/>

        <!-- Tropical Juice Glass & Accessories -->
        <!-- Blue Straw -->
        <path d="M 68 51 L 74 74" stroke="#0284c7" stroke-width="4.5" stroke-linecap="round"/>
        <path d="M 69 52 L 73 73" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>

        <!-- Glass Outline & Layered Drink -->
        <g>
          <!-- Glass Body -->
          <polygon points="68,68 89,68 86,96 71,96" fill="#f8fafc" opacity="0.6"/>
          <!-- Layered Juice (Green -> Yellow -> Red) -->
          <polygon points="69,70 88,70 85.5,95 71.5,95" fill="url(#juiceLayers)"/>
          <!-- Glass Rim & Side Highlights -->
          <polygon points="68,68 89,68 86,96 71,96" fill="none" stroke="#64748b" stroke-width="1.8" stroke-linejoin="round"/>
          <ellipse cx="78.5" cy="68" rx="10.5" ry="2.2" fill="#ffffff" opacity="0.5" stroke="#94a3b8" stroke-width="1.2"/>
          <path d="M 70.5 72 L 72.5 93" stroke="#ffffff" stroke-width="1.8" opacity="0.85" stroke-linecap="round"/>
        </g>

        <!-- Orange Flower / Citrus Wheel on Glass Rim -->
        <g transform="translate(87, 65)">
          <circle cx="0" cy="0" r="6" fill="#ea580c"/>
          <circle cx="0" cy="0" r="4.5" fill="#f97316"/>
          <circle cx="0" cy="0" r="2.2" fill="#fef08a"/>
          <!-- Flower Petal Cuts -->
          <circle cx="-3" cy="-3" r="1.8" fill="#fb923c"/>
          <circle cx="3" cy="-3" r="1.8" fill="#fb923c"/>
          <circle cx="4" cy="2" r="1.8" fill="#fb923c"/>
          <circle cx="-1" cy="4" r="1.8" fill="#fb923c"/>
          <circle cx="-4" cy="1" r="1.8" fill="#fb923c"/>
        </g>

        <!-- White Chubby Paws Holding Glass -->
        <!-- Left Paw -->
        <ellipse cx="65" cy="84" rx="8" ry="7" fill="#ffffff" stroke="#3b1523" stroke-width="2.5"/>
        <path d="M 67 80 C 69 82, 69 86, 67 88" stroke="#cbd5e1" stroke-width="1.5" fill="none"/>
        
        <!-- Right Paw -->
        <ellipse cx="91" cy="87" rx="8" ry="7" fill="#ffffff" stroke="#3b1523" stroke-width="2.5"/>
        <path d="M 89 83 C 87 85, 87 89, 89 91" stroke="#cbd5e1" stroke-width="1.5" fill="none"/>
      </g>
    </svg>
  `,

  // Gummy Cat Chip SVGs (Cute Translucent Jellies with Glasses)
  gummyBlue: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60">
      <path d="M12 18 L18 8 L26 16 L34 16 L42 8 L48 18 C54 26, 52 46, 46 52 C40 56, 20 56, 14 52 C8 46, 6 26, 12 18 Z" fill="#38bdf8" stroke="#0284c7" stroke-width="2.5"/>
      <path d="M16 26 C16 22, 28 22, 28 26 C28 30, 16 30, 16 26 Z" fill="#ffffff" opacity="0.85"/>
      <path d="M32 26 C32 22, 44 22, 44 26 C44 30, 32 30, 32 26 Z" fill="#ffffff" opacity="0.85"/>
      <line x1="28" y1="26" x2="32" y2="26" stroke="#ffffff" stroke-width="2"/>
      <circle cx="20" cy="26" r="2.5" fill="#0369a1"/>
      <circle cx="36" cy="26" r="2.5" fill="#0369a1"/>
      <ellipse cx="20" cy="38" rx="4" ry="2" fill="#ffffff" opacity="0.5"/>
    </svg>
  `,
  gummyGreen: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60">
      <path d="M12 18 L18 8 L26 16 L34 16 L42 8 L48 18 C54 26, 52 46, 46 52 C40 56, 20 56, 14 52 C8 46, 6 26, 12 18 Z" fill="#4ade80" stroke="#16a34a" stroke-width="2.5"/>
      <path d="M16 26 C16 22, 28 22, 28 26 C28 30, 16 30, 16 26 Z" fill="#ffffff" opacity="0.85"/>
      <path d="M32 26 C32 22, 44 22, 44 26 C44 30, 32 30, 32 26 Z" fill="#ffffff" opacity="0.85"/>
      <line x1="28" y1="26" x2="32" y2="26" stroke="#ffffff" stroke-width="2"/>
      <circle cx="20" cy="26" r="2.5" fill="#15803d"/>
      <circle cx="36" cy="26" r="2.5" fill="#15803d"/>
      <ellipse cx="20" cy="38" rx="4" ry="2" fill="#ffffff" opacity="0.5"/>
    </svg>
  `,
  gummyOrange: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60">
      <path d="M12 18 L18 8 L26 16 L34 16 L42 8 L48 18 C54 26, 52 46, 46 52 C40 56, 20 56, 14 52 C8 46, 6 26, 12 18 Z" fill="#fb923c" stroke="#ea580c" stroke-width="2.5"/>
      <path d="M16 26 C16 22, 28 22, 28 26 C28 30, 16 30, 16 26 Z" fill="#ffffff" opacity="0.85"/>
      <path d="M32 26 C32 22, 44 22, 44 26 C44 30, 32 30, 32 26 Z" fill="#ffffff" opacity="0.85"/>
      <line x1="28" y1="26" x2="32" y2="26" stroke="#ffffff" stroke-width="2"/>
      <circle cx="20" cy="26" r="2.5" fill="#9a3412"/>
      <circle cx="36" cy="26" r="2.5" fill="#9a3412"/>
      <ellipse cx="20" cy="38" rx="4" ry="2" fill="#ffffff" opacity="0.5"/>
    </svg>
  `,
  gummyPurple: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60">
      <path d="M12 18 L18 8 L26 16 L34 16 L42 8 L48 18 C54 26, 52 46, 46 52 C40 56, 20 56, 14 52 C8 46, 6 26, 12 18 Z" fill="#c084fc" stroke="#9333ea" stroke-width="2.5"/>
      <path d="M16 26 C16 22, 28 22, 28 26 C28 30, 16 30, 16 26 Z" fill="#ffffff" opacity="0.85"/>
      <path d="M32 26 C32 22, 44 22, 44 26 C44 30, 32 30, 32 26 Z" fill="#ffffff" opacity="0.85"/>
      <line x1="28" y1="26" x2="32" y2="26" stroke="#ffffff" stroke-width="2"/>
      <circle cx="20" cy="26" r="2.5" fill="#6b21a8"/>
      <circle cx="36" cy="26" r="2.5" fill="#6b21a8"/>
      <ellipse cx="20" cy="38" rx="4" ry="2" fill="#ffffff" opacity="0.5"/>
    </svg>
  `,
  gummyRed: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60">
      <path d="M12 18 L18 8 L26 16 L34 16 L42 8 L48 18 C54 26, 52 46, 46 52 C40 56, 20 56, 14 52 C8 46, 6 26, 12 18 Z" fill="#f87171" stroke="#dc2626" stroke-width="2.5"/>
      <path d="M16 26 C16 22, 28 22, 28 26 C28 30, 16 30, 16 26 Z" fill="#ffffff" opacity="0.85"/>
      <path d="M32 26 C32 22, 44 22, 44 26 C44 30, 32 30, 32 26 Z" fill="#ffffff" opacity="0.85"/>
      <line x1="28" y1="26" x2="32" y2="26" stroke="#ffffff" stroke-width="2"/>
      <circle cx="20" cy="26" r="2.5" fill="#991b1b"/>
      <circle cx="36" cy="26" r="2.5" fill="#991b1b"/>
      <ellipse cx="20" cy="38" rx="4" ry="2" fill="#ffffff" opacity="0.5"/>
    </svg>
  `,

  // Blue Drink Cup Icon
  drinkCup: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">
      <path d="M8 8 L32 8 L28 34 L12 34 Z" fill="#38bdf8" stroke="#0284c7" stroke-width="3"/>
      <circle cx="16" cy="18" r="2" fill="#ffffff"/>
      <circle cx="24" cy="18" r="2" fill="#ffffff"/>
      <path d="M18 22 Q20 24 22 22" stroke="#ffffff" stroke-width="1.5" fill="none"/>
      <line x1="12" y1="2" x2="20" y2="10" stroke="#f43f5e" stroke-width="3" stroke-linecap="round"/>
    </svg>
  `,

  // Gold Coin Icon
  goldCoin: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">
      <circle cx="20" cy="20" r="18" fill="#f59e0b" stroke="#ffffff" stroke-width="2.5"/>
      <circle cx="20" cy="20" r="13" fill="#fbbf24" stroke="#d97706" stroke-width="2"/>
      <polygon points="20,11 22,17 28,17 23,21 25,27 20,23 15,27 17,21 12,17 18,17" fill="#ffffff"/>
    </svg>
  `,

  // Sparkling Diamond Gem Icon
  diamondIcon: `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40">
      <defs>
        <linearGradient id="diaFacet1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#e0f2fe"/>
          <stop offset="35%" stop-color="#38bdf8"/>
          <stop offset="100%" stop-color="#0284c7"/>
        </linearGradient>
        <linearGradient id="diaFacet2" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#7dd3fc"/>
          <stop offset="100%" stop-color="#0369a1"/>
        </linearGradient>
      </defs>
      <polygon points="12,10 28,10 36,18 4,18" fill="url(#diaFacet1)" stroke="#0284c7" stroke-width="1.2"/>
      <polygon points="4,18 36,18 20,34" fill="url(#diaFacet2)" stroke="#0284c7" stroke-width="1.2"/>
      <polygon points="12,10 20,18 4,18" fill="#ffffff" opacity="0.45"/>
      <polygon points="28,10 36,18 20,18" fill="#0284c7" opacity="0.35"/>
      <polygon points="12,10 28,10 20,18" fill="#ffffff" opacity="0.7"/>
      <polygon points="4,18 20,34 20,18" fill="#38bdf8" opacity="0.8"/>
      <polygon points="36,18 20,34 20,18" fill="#0369a1" opacity="0.85"/>
      <circle cx="14" cy="14" r="1.8" fill="#ffffff"/>
      <line x1="14" y1="10" x2="14" y2="18" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>
      <line x1="10" y1="14" x2="18" y2="14" stroke="#ffffff" stroke-width="1.2" stroke-linecap="round"/>
    </svg>
  `,

  // Avatars
  avatarNada: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60"><circle cx="30" cy="30" r="28" fill="#a7f3d0"/><circle cx="30" cy="24" r="13" fill="#059669"/><path d="M12 52 Q30 38 48 52 Z" fill="#047857"/></svg>`,
  avatarAva: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60"><circle cx="30" cy="30" r="28" fill="#fed7aa"/><circle cx="30" cy="24" r="13" fill="#ea580c"/><path d="M12 52 Q30 38 48 52 Z" fill="#c2410c"/></svg>`,
  avatarEmily: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60"><circle cx="30" cy="30" r="28" fill="#fbcfe8"/><circle cx="30" cy="24" r="13" fill="#db2777"/><path d="M12 52 Q30 38 48 52 Z" fill="#be185d"/></svg>`,
  avatarNoUser: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60"><circle cx="30" cy="30" r="28" fill="#e0f2fe"/><circle cx="30" cy="24" r="12" fill="#38bdf8"/><path d="M14 50 Q30 38 46 50 Z" fill="#0284c7"/></svg>`
};

const ASSETS = {};
for (const k in SVGS) {
  ASSETS[k] = svgToUri(SVGS[k]);
}
// Ultra-fidelity transparent PNG matching user reference 1:1
ASSETS.catMascot = 'cat_mascot.png';

const FOOD_CONFIG = [
  { index: 0, id: 'chicken', name: 'BBQ Chicken', mult: 45, category: 'meat' },
  { index: 1, id: 'tomato', name: 'Tomato', mult: 5, category: 'veg' },
  { index: 2, id: 'goat', name: 'BBQ Leg Piece', mult: 15, category: 'meat' },
  { index: 3, id: 'pepper', name: 'Pepper', mult: 5, category: 'veg' },
  { index: 4, id: 'fish', name: 'BBQ Fish', mult: 25, category: 'meat' },
  { index: 5, id: 'carrot', name: 'Carrot', mult: 5, category: 'veg' },
  { index: 6, id: 'shrimp', name: 'BBQ Shrimp', mult: 10, category: 'meat' },
  { index: 7, id: 'corn', name: 'Grilled Corn', mult: 5, category: 'veg' }
];

// --- Audio Synthesizer ---
class SoundController {
  constructor() {
    this.ctx = null;
    this.soundEnabled = true;
    this.musicEnabled = true;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  playTone(freq, type = 'sine', duration = 0.12, gainVal = 0.15) {
    if (!this.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = type;
      osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
      gain.gain.setValueAtTime(gainVal, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start();
      osc.stop(this.ctx.currentTime + duration);
    } catch (e) {}
  }

  chipClick() {
    this.playTone(850, 'sine', 0.08, 0.22);
  }

  chaserTick() {
    this.playTone(950, 'triangle', 0.04, 0.15);
  }

  winFanfare() {
    if (!this.soundEnabled) return;
    const notes = [523.25, 659.25, 783.99, 1046.50];
    notes.forEach((freq, i) => {
      setTimeout(() => this.playTone(freq, 'triangle', 0.22, 0.25), i * 110);
    });
  }

  readyGo() {
    if (!this.soundEnabled) return;
    this.playTone(520, 'sine', 0.12, 0.2);
    setTimeout(() => this.playTone(880, 'sine', 0.22, 0.25), 160);
  }

  toastAlert() {
    this.playTone(320, 'square', 0.15, 0.12);
  }
}

const sounds = new SoundController();

// --- Greedy Cat Game Engine ---
class GreedyCatGame {
  constructor() {
    const urlParams = new URLSearchParams(window.location.search);
    this.userId = urlParams.get('userId') || urlParams.get('uid') || null;
    this.userName = urlParams.get('name') || urlParams.get('userName') || 'Player';
    this.userAvatar = urlParams.get('avatar') || '';
    this.roomId = urlParams.get('roomId') || '';

    const initialDiamonds = urlParams.get('diamonds') || urlParams.get('coins') || urlParams.get('balance');
    if (initialDiamonds !== null && !isNaN(Number(initialDiamonds))) {
      this.balance = Number(initialDiamonds);
    } else {
      this.balance = 50000;
    }

    this.todayWinning = 0;
    this.currentBet = 10;
    this.userBets = {};
    this.realtimeUsers = [];
    this.lastRoundWinners = [];
    this.recentResults = ['carrot', 'pepper', 'carrot', 'carrot', 'pepper', 'pepper', 'tomato'];
    try {
      const savedRecs = JSON.parse(localStorage.getItem('greedy_cat_my_records') || '[]');
      this.records = Array.isArray(savedRecs) ? savedRecs.filter(r => r && r.betVal > 0) : [];
    } catch (e) {
      this.records = [];
    }

    this.phase = 'SELECT_TIME';
    this.timerSeconds = 25;
    this.timerInterval = null;
    this.chaserTimeout = null;
    this.activePodIndex = 0;
    this.hotIndex = 3;
    this.pendingSpecialPrize = null; // 'pizza' | 'salad' | null
    this.activeSpecialPrize = null;
    this.specialPrizeRoundCounter = 0;
    this.isServerConnected = false;
    this.roundId = 1001;
    this.remoteConfig = null;

    this.initDailyWinningReset();
    this.setupRealtimeBridge();
    this.cacheDOM();
    this.injectStaticAssets();
    this.bindEvents();
    this.updateUI();
    this.renderRankingTable();
    this.initFirebaseSync();
    this.initRealtimeSync();
    this.startBettingPhase();
  }

  cacheDOM() {
    this.hubPhaseLabel = document.getElementById('hub-phase-label');
    this.hubCountdown = document.getElementById('hub-countdown');
    this.txtCatsLeft = document.getElementById('txt-cats-left');
    this.txtTodayWinning = document.getElementById('txt-today-winning');
    this.resultTokensList = document.getElementById('result-tokens-list');
    this.hotTag = document.getElementById('hot-tag');
    this.gameToast = document.getElementById('game-toast');

    // Modals
    this.modalResult = document.getElementById('modal-result');
    this.modalRules = document.getElementById('modal-rules');
    this.modalRecords = document.getElementById('modal-records');
    this.modalSettings = document.getElementById('modal-settings');
    this.modalRanking = document.getElementById('modal-ranking');
    this.modalPrizeInfo = document.getElementById('modal-prize-info');
    this.resultTitleText = document.getElementById('result-title-text');
    this.resultSubtitleText = document.getElementById('result-subtitle-text');
  }

  injectStaticAssets() {
    // 1. Food Pods
    FOOD_CONFIG.forEach(f => {
      const wrap = document.querySelector(`.${f.id}-img`);
      if (wrap) wrap.style.backgroundImage = `url("${ASSETS[f.id]}")`;
    });

    // 2. Center Cat Mascot
    const catEl = document.querySelector('.cat-illustration');
    if (catEl) catEl.style.backgroundImage = `url("${ASSETS.catMascot}")`;

    // 3. Salad & Pizza Dishes
    const saladEl = document.querySelector('.salad-illustration');
    if (saladEl) saladEl.style.backgroundImage = `url("${ASSETS.salad}")`;
    const pizzaEl = document.querySelector('.pizza-illustration');
    if (pizzaEl) pizzaEl.style.backgroundImage = `url("${ASSETS.pizza}")`;

    // 4. Gummy Cats on Chips Board
    const chipGummies = {
      '10': ASSETS.gummyBlue,
      '100': ASSETS.gummyGreen,
      '1000': ASSETS.gummyOrange,
      '10000': ASSETS.gummyPurple,
      '100000': ASSETS.gummyRed
    };
    for (const val in chipGummies) {
      const chipEl = document.querySelector(`.gummy-chip-wrap[data-val="${val}"] .gummy-cat`);
      if (chipEl) {
        chipEl.style.backgroundImage = `url("${chipGummies[val]}")`;
        chipEl.style.backgroundSize = 'contain';
        chipEl.style.backgroundRepeat = 'no-repeat';
        chipEl.style.backgroundPosition = 'center';
      }
    }

    // 5. Drink cup icons on badges and Cats Left pill
    document.querySelectorAll('.drink-cat-icon').forEach(icon => {
      icon.style.backgroundImage = `url("${ASSETS.drinkCup}")`;
      icon.style.backgroundSize = 'contain';
      icon.style.backgroundRepeat = 'no-repeat';
      icon.style.backgroundPosition = 'center';
    });

    // 6. Gold coin icons
    document.querySelectorAll('.gold-coin-icon').forEach(icon => {
      icon.style.backgroundImage = `url("${ASSETS.goldCoin}")`;
      icon.style.backgroundSize = 'contain';
      icon.style.backgroundRepeat = 'no-repeat';
      icon.style.backgroundPosition = 'center';
    });

    // 7. Diamond icons
    document.querySelectorAll('.diamond-icon').forEach(icon => {
      icon.style.backgroundImage = `url("${ASSETS.diamondIcon}")`;
      icon.style.backgroundSize = 'contain';
      icon.style.backgroundRepeat = 'no-repeat';
      icon.style.backgroundPosition = 'center';
    });

    // 7. Avatars
    const userAv = document.getElementById('strip-user-avatar');
    if (userAv) userAv.style.backgroundImage = `url("${ASSETS.avatarNada}")`;

    const playerResAv = document.querySelector('.player-cat-avatar');
    if (playerResAv) playerResAv.style.backgroundImage = `url("${ASSETS.catMascot}")`;

    const avWinner = document.getElementById('podium-avatar-1');
    if (avWinner) avWinner.style.backgroundImage = `url("${ASSETS.avatarNada}")`;
    const av2 = document.querySelector('.avatar-ava');
    if (av2) av2.style.backgroundImage = `url("${ASSETS.avatarAva}")`;
    const av3 = document.querySelector('.avatar-no-user');
    if (av3) av3.style.backgroundImage = `url("${ASSETS.avatarNoUser}")`;
  }

  bindEvents() {
    // Unlock Audio Context on any user touch/click
    window.addEventListener('pointerdown', () => sounds.init(), { once: true });

    // Chip selection
    document.querySelectorAll('.gummy-chip-wrap').forEach(el => {
      el.addEventListener('click', () => {
        document.querySelectorAll('.gummy-chip-wrap').forEach(c => c.classList.remove('active'));
        el.classList.add('active');
        this.currentBet = parseInt(el.dataset.val, 10);
        sounds.chipClick();
      });
    });

    // Food pod betting
    document.querySelectorAll('.food-pod').forEach(pod => {
      pod.addEventListener('click', () => {
        const id = pod.dataset.id;
        this.handlePlaceBet(id);
      });
    });

    // Salad & Pizza Prize Info (Direct betting disabled as requested)
    document.getElementById('btn-salad').addEventListener('click', () => {
      this.openPrizeInfoModal('salad');
    });

    document.getElementById('btn-pizza').addEventListener('click', () => {
      this.openPrizeInfoModal('pizza');
    });

    // Header & Ranking buttons (both top trophy & bottom strip open Today's Ranking)
    document.getElementById('btn-rules').addEventListener('click', () => this.openModal(this.modalRules));
    document.getElementById('btn-help').addEventListener('click', () => this.openModal(this.modalRules));
    document.getElementById('btn-setting').addEventListener('click', () => this.openModal(this.modalSettings));
    document.getElementById('btn-ranking').addEventListener('click', () => {
      this.renderRankingTable();
      this.openModal(this.modalRanking);
    });
    document.getElementById('btn-today-ranking').addEventListener('click', () => {
      this.renderRankingTable();
      this.openModal(this.modalRanking);
    });
    document.getElementById('btn-my-records').addEventListener('click', () => {
      this.renderRecordsTable();
      this.openModal(this.modalRecords);
    });

    // Close buttons
    document.querySelectorAll('.modal-close-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.game-modal-overlay').forEach(m => m.classList.remove('open'));
      });
    });

    // Toggles
    const togMusic = document.getElementById('toggle-music');
    if (togMusic) {
      togMusic.addEventListener('change', (e) => {
        sounds.musicEnabled = e.target.checked;
      });
    }
    const togSound = document.getElementById('toggle-sound');
    if (togSound) {
      togSound.addEventListener('change', (e) => {
        sounds.soundEnabled = e.target.checked;
      });
    }

    const btnWinClose = document.getElementById('btn-window-close');
    if (btnWinClose) {
      btnWinClose.addEventListener('click', () => {
        this.showToast('Game session active');
      });
    }
    const btnExit = document.getElementById('btn-exit');
    if (btnExit) {
      btnExit.addEventListener('click', () => {
        this.exitGame();
      });
    }
  }

  exitGame() {
    try {
      if (window.FlutterBridge && window.FlutterBridge.postMessage) {
        window.FlutterBridge.postMessage(JSON.stringify({ type: 'CLOSE_GAME' }));
        return;
      }
    } catch (_) {}
    try {
      if (window.FlutterApp && window.FlutterApp.postMessage) {
        window.FlutterApp.postMessage('close');
        return;
      }
    } catch (_) {}
    try {
      if (window.imChat && typeof window.imChat.exit === 'function') {
        window.imChat.exit();
        return;
      }
    } catch (_) {}
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage({ type: 'CLOSE_GAME', action: 'exit' }, '*');
        window.parent.postMessage('close', '*');
      }
    } catch (_) {}
    try {
      if (window.history.length > 1) {
        window.history.back();
      } else {
        window.close();
      }
    } catch (_) {}
  }

  formatNumber(num) {
    if (num >= 1000000000) return (num / 1000000000).toFixed(2) + 'B';
    if (num >= 1000000) return (num / 1000000).toFixed(2) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(num >= 10000 ? 0 : 2) + 'K';
    return num.toLocaleString();
  }

  updateUI() {
    this.checkDailyPeriod();
    this.txtCatsLeft.textContent = this.formatNumber(this.balance);
    this.txtTodayWinning.textContent = this.formatNumber(this.todayWinning);
    this.updateBottomRankingStrip();

    // Render result tokens cleanly
    this.resultTokensList.innerHTML = '';
    this.recentResults.forEach((foodId, idx) => {
      const circle = document.createElement('div');
      circle.className = 'res-token-circle';
      const imgDiv = document.createElement('div');
      imgDiv.className = 'res-token-img';
      imgDiv.style.backgroundImage = `url("${ASSETS[foodId]}")`;
      circle.appendChild(imgDiv);

      if (idx === 0) {
        const badge = document.createElement('span');
        badge.className = 'badge-new';
        badge.textContent = 'NEW';
        circle.appendChild(badge);
      }
      this.resultTokensList.appendChild(circle);
    });

    // Update Pod Bet Bubbles
    FOOD_CONFIG.forEach(food => {
      const bubble = document.getElementById(`bet-bubble-${food.index}`);
      const betAmt = this.userBets[food.id] || 0;
      if (betAmt > 0) {
        bubble.textContent = `YOU: ${this.formatNumber(betAmt)}`;
        bubble.classList.add('active');
      } else {
        bubble.classList.remove('active');
      }
    });
  }

  showToast(msg) {
    sounds.toastAlert();
    this.gameToast.textContent = msg;
    this.gameToast.classList.add('show');
    clearTimeout(this.toastTimeout);
    this.toastTimeout = setTimeout(() => {
      this.gameToast.classList.remove('show');
    }, 1800);
  }

  openModal(modal) {
    if (modal) modal.classList.add('open');
  }

  openPrizeInfoModal(type) {
    const titleEl = document.getElementById('prize-modal-title');
    const bodyEl = document.getElementById('prize-modal-body');
    if (!titleEl || !bodyEl) return;

    if (type === 'pizza') {
      titleEl.textContent = '🍕 Pizza Prize';
      bodyEl.innerHTML = `
        <div style="text-align: center; margin-bottom: 8px;">
          <p style="color: #f1f5f9; font-size: 13.5px; line-height: 1.55; margin: 0 0 12px 0;">
            When the Pizza Prize is opened, all players who selected any meat ingredient will win a share of the prize pool.
          </p>
          <div style="background: rgba(239, 68, 68, 0.22); border: 1.5px solid #f87171; border-radius: 12px; padding: 10px 12px; text-align: left;">
            <div style="font-size: 14px; font-weight: 900; color: #fef08a; margin-bottom: 2px;">🍕 Pizza Winner</div>
            <div style="font-size: 12.5px; color: #ffffff; font-weight: 700;">All meat selections win.</div>
            <div style="font-size: 11px; color: #fca5a5; margin-top: 4px;">(BBQ Chicken 45x, BBQ Leg Piece 15x, BBQ Fish 25x, BBQ Shrimp 10x)</div>
          </div>
        </div>
      `;
    } else {
      titleEl.textContent = '🥗 Salad Prize';
      bodyEl.innerHTML = `
        <div style="text-align: center; margin-bottom: 8px;">
          <p style="color: #f1f5f9; font-size: 13.5px; line-height: 1.55; margin: 0 0 12px 0;">
            When the Salad Prize is opened, all players who selected any vegetable ingredient will win a share of the prize pool.
          </p>
          <div style="background: rgba(34, 197, 94, 0.22); border: 1.5px solid #4ade80; border-radius: 12px; padding: 10px 12px; text-align: left;">
            <div style="font-size: 14px; font-weight: 900; color: #86efac; margin-bottom: 2px;">🥗 Salad Winner</div>
            <div style="font-size: 12.5px; color: #ffffff; font-weight: 700;">All vegetable selections win.</div>
            <div style="font-size: 11px; color: #bbf7d0; margin-top: 4px;">(Tomato 5x, Pepper 5x, Carrot 5x, Grilled Corn 5x)</div>
          </div>
        </div>
      `;
    }
    this.openModal(this.modalPrizeInfo);
  }

  handlePlaceBet(foodId) {
    if (this.phase !== 'SELECT_TIME') {
      this.showToast('Please Bet Next round');
      return;
    }

    const currentBetTypes = Object.keys(this.userBets).filter(k => this.userBets[k] > 0);
    if (!this.userBets[foodId] && currentBetTypes.length >= 6) {
      this.showToast('The maximum number of types you can bet is 6');
      return;
    }

    if (this.balance < this.currentBet) {
      this.showToast('Not enough balance!');
      return;
    }

    this.balance -= this.currentBet;
    this.userBets[foodId] = (this.userBets[foodId] || 0) + this.currentBet;
    sounds.chipClick();
    this.updateUI();

    // Deduct from Firestore Users/{userId} in real-time
    if (this.userId && this.db && typeof firebase !== 'undefined') {
      this.db.collection('Users').doc(this.userId).update({
        diamonds: firebase.firestore.FieldValue.increment(-this.currentBet)
      }).catch(err => console.warn('Deduct balance error:', err));

      this.db.collection('game_bets').add({
        userId: this.userId,
        userName: this.userName || 'Player',
        gameId: 'html5_greedy_cat',
        gameCode: 'html5_greedy_cat',
        foodId: foodId,
        betAmount: this.currentBet,
        roundId: this.roundId,
        roomId: this.roomId || '',
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      }).catch(() => {});

      this.db.collection('game_history').add({
        userId: this.userId,
        userName: this.userName || 'Player',
        gameId: 'greedy_cat',
        gameCode: 'html5_greedy_cat',
        gameName: 'Greedy Cat',
        type: 'BET',
        betAmount: this.currentBet,
        roundNumber: this.roundId,
        winningEmoji: '🐱',
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        timestamp: firebase.firestore.FieldValue.serverTimestamp()
      }).catch(() => {});
    }

    // Broadcast bet to room pool for central house edge & payout calculation
    if (this.isServerConnected) {
      fetch('/api/bet', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ foodId, amount: this.currentBet })
      }).catch(() => {});
    }
  }

  // --- Real-Time Multiplayer Room Synchronization Engine ---
  initRealtimeSync() {
    try {
      const evtSource = new EventSource('/events');

      evtSource.addEventListener('STATE_SYNC', (e) => {
        try {
          const packet = JSON.parse(e.data);
          const data = packet.data;
          this.isServerConnected = true;
          this.roundId = data.roundId;
          this.hotIndex = data.hotIndex;
          this.shiftHotTag(this.hotIndex);

          if (Array.isArray(data.recentResults) && data.recentResults.length > 0) {
            this.recentResults = data.recentResults;
          }

          if (data.phase === 'SELECT_TIME') {
            this.phase = 'SELECT_TIME';
            this.timerSeconds = data.timerSeconds;
            this.hubPhaseLabel.textContent = 'Select Time';
            this.hubCountdown.textContent = `${this.timerSeconds}s`;
          }
          this.updateUI();
        } catch (err) {}
      });

      evtSource.addEventListener('TICK', (e) => {
        try {
          const packet = JSON.parse(e.data);
          const data = packet.data;
          this.isServerConnected = true;
          this.roundId = data.roundId;
          this.timerSeconds = data.timerSeconds;

          if (data.hotIndex !== undefined && data.hotIndex !== this.hotIndex) {
            this.shiftHotTag(data.hotIndex);
          }

          if (this.phase === 'SELECT_TIME') {
            this.hubCountdown.textContent = `${this.timerSeconds}s`;
            if (this.timerSeconds <= 3 && this.timerSeconds > 0) {
              sounds.chaserTick();
            }
          } else if (this.phase === 'SPINNING') {
            this.hubCountdown.textContent = `${this.timerSeconds}s`;
          }
        } catch (err) {}
      });

      evtSource.addEventListener('SPIN_START', (e) => {
        try {
          const packet = JSON.parse(e.data);
          const data = packet.data;
          this.isServerConnected = true;
          this.roundId = data.roundId;
          this.winningIndex = data.winningIndex;
          this.activeSpecialPrize = data.activeSpecialPrize;
          this.startSynchronizedSpin(data.winningIndex, data.activeSpecialPrize, data.winningFood);
        } catch (err) {}
      });

      evtSource.addEventListener('SHOW_TIME', (e) => {
        try {
          const packet = JSON.parse(e.data);
          const data = packet.data;
          this.startShowTimePhase(data.winningFood);
        } catch (err) {}
      });

      evtSource.addEventListener('ROUND_RESULT', (e) => {
        try {
          const packet = JSON.parse(e.data);
          const data = packet.data;
          if (Array.isArray(data.recentResults)) {
            this.recentResults = data.recentResults;
          }
          this.startResultPhase(data.winningFood);
        } catch (err) {}
      });

      evtSource.addEventListener('ROUND_START', (e) => {
        try {
          const packet = JSON.parse(e.data);
          const data = packet.data;
          this.isServerConnected = true;
          this.roundId = data.roundId;
          this.startBettingPhaseFromServer(data.timerSeconds, data.hotIndex, data.recentResults);
        } catch (err) {}
      });

      evtSource.onerror = () => {
        this.isServerConnected = false;
      };
    } catch (err) {
      this.isServerConnected = false;
    }
  }

  // --- Dynamic Hot Tag Shifter ---
  shiftHotTag(forcedIndex) {
    if (forcedIndex !== undefined) {
      this.hotIndex = forcedIndex;
    } else {
      const available = [0, 1, 2, 3, 4, 5, 6, 7].filter(i => i !== this.hotIndex);
      this.hotIndex = available[Math.floor(Math.random() * available.length)];
    }
    const hotPod = document.querySelector(`.food-pod[data-index="${this.hotIndex}"]`);
    if (hotPod && this.hotTag) {
      this.hotTag.classList.remove('popping');
      hotPod.appendChild(this.hotTag);
      void this.hotTag.offsetWidth;
      this.hotTag.classList.add('popping');
    }
  }

  // --- Server-Triggered New Round Start ---
  startBettingPhaseFromServer(timerSec, serverHotIndex, serverRecentResults) {
    if (this.modalResult) this.modalResult.classList.remove('open');
    this.lastRoundWinners = [];
    this.activeSpecialPrize = null;
    this.phase = 'SELECT_TIME';
    this.timerSeconds = timerSec || 25;
    this.userBets = {};
    document.querySelectorAll('.food-pod').forEach(p => p.classList.remove('highlighted'));

    if (serverHotIndex !== undefined) {
      this.shiftHotTag(serverHotIndex);
    }
    if (Array.isArray(serverRecentResults)) {
      this.recentResults = serverRecentResults;
    }

    this.updateUI();
    this.hubPhaseLabel.textContent = 'Select Time';
    this.hubCountdown.textContent = `${this.timerSeconds}s`;
    sounds.readyGo();
  }

  // --- Standalone Fallback Phase 1: Betting ---
  startBettingPhase() {
    this.phase = 'SELECT_TIME';
    this.timerSeconds = 25;
    this.userBets = {};
    document.querySelectorAll('.food-pod').forEach(p => p.classList.remove('highlighted'));
    this.updateUI();

    this.shiftHotTag();
    this.hubPhaseLabel.textContent = 'Select Time';
    this.hubCountdown.textContent = `${this.timerSeconds}s`;
    sounds.readyGo();

    clearInterval(this.timerInterval);
    this.timerInterval = setInterval(() => {
      if (this.isServerConnected) {
        // If server is active, server TICK controls countdown
        return;
      }
      this.timerSeconds--;
      if (this.timerSeconds > 0) {
        this.hubCountdown.textContent = `${this.timerSeconds}s`;
        if (this.timerSeconds <= 3) sounds.chaserTick();
      } else {
        clearInterval(this.timerInterval);
        this.startSpinningPhase();
      }
    }, 1000);
  }

  // --- Standalone Payout Algorithm: Win Ratio < 75% | App Profit > 25% ---
  calculateLocalOutcome() {
    // Admin Override: forced winner index
    if (this.remoteConfig && this.remoteConfig.forceWinnerIndex !== undefined && Number(this.remoteConfig.forceWinnerIndex) >= 0) {
      const forced = Number(this.remoteConfig.forceWinnerIndex);
      if (forced < 8) return forced;
    }

    const totalBets = Object.values(this.userBets).reduce((a, b) => a + b, 0);
    const candidates = FOOD_CONFIG.map(food => {
      const betOnItem = this.userBets[food.id] || 0;
      const payout = betOnItem * food.mult;
      const payoutRatio = totalBets > 0 ? (payout / totalBets) : 0;
      return { index: food.index, food, payout, payoutRatio };
    });

    // Payout ratio <= maxRatio ensures configured RTP (default <= 70% payout)
    const maxRatio = (this.remoteConfig && this.remoteConfig.winRatio) ? (Number(this.remoteConfig.winRatio) / 100) : 0.70;
    let safe = candidates.filter(c => c.payoutRatio <= maxRatio);
    if (safe.length === 0) {
      safe = [...candidates].sort((a, b) => a.payout - b.payout).slice(0, 2);
    }

    const weights = safe.map(c => {
      const baseMultWeight = 50 / c.food.mult;
      const marginBonus = Math.max(0.2, 1 - c.payoutRatio);
      return baseMultWeight * marginBonus;
    });

    const totalWeight = weights.reduce((a, b) => a + b, 0);
    let r = Math.random() * totalWeight;
    let chosen = safe[0];
    for (let i = 0; i < safe.length; i++) {
      if (r < weights[i]) {
        chosen = safe[i];
        break;
      }
      r -= weights[i];
    }
    return chosen.index;
  }

  // --- Synchronized Real-Time Spin ---
  startSynchronizedSpin(serverWinningIndex, serverSpecialPrize, winningFood) {
    this.phase = 'SPINNING';
    this.timerSeconds = 5;
    this.winningIndex = serverWinningIndex !== undefined ? serverWinningIndex : 0;
    this.activeSpecialPrize = serverSpecialPrize || null;

    const isSpecial = !!this.activeSpecialPrize;
    const specialType = this.activeSpecialPrize;
    const targetMeatIndices = [0, 2, 4, 6];
    const targetVegIndices = [1, 3, 5, 7];
    const specialTargetIndices = specialType === 'pizza' ? targetMeatIndices : targetVegIndices;

    if (isSpecial) {
      this.hubPhaseLabel.textContent = specialType === 'pizza' ? '🍕 Pizza Prize!' : '🥗 Salad Prize!';
    } else {
      this.hubPhaseLabel.textContent = 'The result is coming';
    }
    this.hubCountdown.textContent = `${this.timerSeconds}s`;

    let currentPos = this.activePodIndex || 0;
    let diff = (this.winningIndex - currentPos + 8) % 8;
    if (diff === 0) diff = 8;
    const totalSteps = 24 + diff;

    const delays = [];
    const decelSteps = 8;
    const fastSteps = totalSteps - decelSteps;
    for (let i = 0; i < fastSteps; i++) delays.push(75);
    const decelDelays = [100, 140, 190, 260, 350, 480, 620, 800];
    for (let i = 0; i < decelSteps; i++) delays.push(decelDelays[i]);

    clearTimeout(this.chaserTimeout);
    let stepCount = 0;
    const executeStep = () => {
      document.querySelectorAll('.food-pod').forEach(p => p.classList.remove('highlighted'));
      currentPos = (currentPos + 1) % 8;
      this.activePodIndex = currentPos;

      const podEl = document.querySelector(`.food-pod[data-index="${currentPos}"]`);
      if (podEl) podEl.classList.add('highlighted');
      sounds.chaserTick();

      stepCount++;
      if (stepCount < totalSteps) {
        this.chaserTimeout = setTimeout(executeStep, delays[stepCount] || 100);
      } else {
        if (isSpecial) {
          document.querySelectorAll('.food-pod').forEach(p => {
            const idx = parseInt(p.dataset.index, 10);
            if (specialTargetIndices.includes(idx)) p.classList.add('highlighted');
            else p.classList.remove('highlighted');
          });
        } else {
          this.activePodIndex = this.winningIndex;
        }
      }
    };
    executeStep();
  }

  // --- Standalone Fallback Phase 2: Spinning ---
  startSpinningPhase() {
    this.phase = 'SPINNING';
    this.timerSeconds = 5;

    // Use guaranteed <75% win ratio outcome algorithm
    this.winningIndex = this.calculateLocalOutcome();
    const winningFood = FOOD_CONFIG[this.winningIndex];

    this.startSynchronizedSpin(this.winningIndex, this.pendingSpecialPrize, winningFood);
    this.pendingSpecialPrize = null;

    clearInterval(this.timerInterval);
    this.timerInterval = setInterval(() => {
      this.timerSeconds--;
      if (this.timerSeconds > 0) {
        this.hubCountdown.textContent = `${this.timerSeconds}s`;
      } else {
        clearInterval(this.timerInterval);
        this.startShowTimePhase(winningFood);
      }
    }, 1000);
  }

  // --- Phase 3: Show Time ---
  startShowTimePhase(winningFood) {
    this.phase = 'SHOW_TIME';

    if (this.activeSpecialPrize === 'pizza') {
      this.hubPhaseLabel.textContent = '🍕 Pizza Winner!';
      this.hubCountdown.textContent = '🍕';
      document.querySelectorAll('.food-pod').forEach(p => {
        const idx = parseInt(p.dataset.index, 10);
        if ([0, 2, 4, 6].includes(idx)) p.classList.add('highlighted');
        else p.classList.remove('highlighted');
      });
      sounds.winFanfare();
    } else if (this.activeSpecialPrize === 'salad') {
      this.hubPhaseLabel.textContent = '🥗 Salad Winner!';
      this.hubCountdown.textContent = '🥗';
      document.querySelectorAll('.food-pod').forEach(p => {
        const idx = parseInt(p.dataset.index, 10);
        if ([1, 3, 5, 7].includes(idx)) p.classList.add('highlighted');
        else p.classList.remove('highlighted');
      });
      sounds.winFanfare();
    } else {
      this.hubPhaseLabel.textContent = 'Show Time';
      this.hubCountdown.textContent = '🌟';
      const winPod = document.querySelector(`.food-pod[data-index="${this.winningIndex}"]`);
      if (winPod) winPod.classList.add('highlighted');
      sounds.winFanfare();
    }

    if (!this.isServerConnected) {
      setTimeout(() => {
        this.startResultPhase(winningFood);
      }, 1400);
    }
  }

  // --- Phase 4: Result Dialog & Payout ---
  startResultPhase(winningFood) {
    this.phase = 'RESULT';
    const totalBet = Object.values(this.userBets).reduce((a, b) => a + b, 0);
    let reward = 0;
    let winningItemKey = winningFood ? winningFood.id : 'chicken';
    let resultTitle = 'Result';
    let resultSub = '';

    if (this.activeSpecialPrize === 'pizza') {
      const meats = FOOD_CONFIG.filter(f => f.category === 'meat');
      reward = meats.reduce((sum, f) => sum + (this.userBets[f.id] || 0) * f.mult, 0);
      winningItemKey = 'pizza';
      resultTitle = '🍕 Pizza Winner';
      resultSub = 'All meat selections win.';
    } else if (this.activeSpecialPrize === 'salad') {
      const vegs = FOOD_CONFIG.filter(f => f.category === 'veg');
      reward = vegs.reduce((sum, f) => sum + (this.userBets[f.id] || 0) * f.mult, 0);
      winningItemKey = 'salad';
      resultTitle = '🥗 Salad Winner';
      resultSub = 'All vegetable selections win.';
    } else {
      const winBet = this.userBets[winningFood.id] || 0;
      reward = winBet * winningFood.mult;
      winningItemKey = winningFood.id;
    }

    if (this.resultTitleText) this.resultTitleText.textContent = resultTitle;
    if (this.resultSubtitleText) {
      this.resultSubtitleText.textContent = resultSub;
      this.resultSubtitleText.style.display = resultSub ? 'block' : 'none';
    }

    if (reward > 0) {
      this.recordWin(reward);
      if (this.userId && this.db && typeof firebase !== 'undefined') {
        this.db.collection('Users').doc(this.userId).update({
          diamonds: firebase.firestore.FieldValue.increment(reward),
          totalDiamonds: firebase.firestore.FieldValue.increment(reward)
        }).catch(err => console.warn('Win credit error:', err));

        const cycleKey = this.getCurrentDayPeriodKey ? this.getCurrentDayPeriodKey() : new Date().toISOString().slice(0, 10);
        this.db.collection('daily_game_leaderboard')
          .doc(`html5_greedy_cat_${cycleKey}_${this.userId}`)
          .set({
            userId: this.userId,
            name: this.userName || 'Winner',
            avatar: this.userAvatar || '',
            winAmount: firebase.firestore.FieldValue.increment(reward),
            gameId: 'html5_greedy_cat',
            cycleKey: cycleKey,
            lastWinAt: firebase.firestore.FieldValue.serverTimestamp()
          }, { merge: true }).catch(() => {});

        this.db.collection('game_wins').add({
          userId: this.userId,
          userName: this.userName || 'Winner',
          gameId: 'html5_greedy_cat',
          gameCode: 'html5_greedy_cat',
          winAmount: reward,
          foodId: winningItemKey,
          roundId: this.roundId,
          roomId: this.roomId || '',
          cycleKey: cycleKey,
          createdAt: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});

        this.db.collection('game_history').add({
          userId: this.userId,
          userName: this.userName || 'Winner',
          gameId: 'greedy_cat',
          gameCode: 'html5_greedy_cat',
          gameName: 'Greedy Cat',
          type: 'WIN',
          winAmount: reward,
          roundNumber: this.roundId,
          winningEmoji: '🏆',
          createdAt: firebase.firestore.FieldValue.serverTimestamp(),
          timestamp: firebase.firestore.FieldValue.serverTimestamp()
        }).catch(() => {});
      }
    } else {
      this.checkDailyPeriod();
    }

    this.recentResults.unshift(winningItemKey);
    if (this.recentResults.length > 8) this.recentResults.pop();

    // ONLY record history if player actually placed a bet in this round!
    if (totalBet > 0) {
      const placedBets = Object.entries(this.userBets).map(([foodId, val]) => ({ foodId, val }));
      const isWin = reward > 0;
      this.records.unshift({
        time: new Date().toISOString().replace('T', ' ').substring(0, 19),
        betVal: totalBet,
        placedBets: placedBets,
        betFood: winningItemKey,
        resVal: reward,
        resFood: winningItemKey,
        isWin: isWin
      });
      if (this.records.length > 30) this.records.pop();
      try {
        localStorage.setItem('greedy_cat_my_records', JSON.stringify(this.records));
      } catch (e) {}
    }

    document.getElementById('res-my-bet').textContent = this.formatNumber(totalBet);
    document.getElementById('res-reward').textContent = this.formatNumber(reward);

    const winFoodCircle = document.getElementById('result-winning-food');
    winFoodCircle.innerHTML = '';
    const winImg = document.createElement('div');
    winImg.className = 'food-img-wrap';
    winImg.style.backgroundImage = `url("${ASSETS[winningItemKey]}")`;
    winFoodCircle.appendChild(winImg);

    // Update Top 3 podium (only displays if real app users / current player won; otherwise empty)
    this.updateResultPodium(reward);

    this.updateUI();
    this.renderRankingTable();
    this.openModal(this.modalResult);

    if (!this.isServerConnected) {
      setTimeout(() => {
        this.modalResult.classList.remove('open');
        this.lastRoundWinners = [];
        this.activeSpecialPrize = null;
        this.startBettingPhase();
      }, 4000);
    }
  }

  // --- Real-time App Users Bridge & Ranking Methods ---
  setupRealtimeBridge() {
    window.setRankingData = (users) => this.setRankingData(users);
    window.setRoundWinners = (winners) => this.setRoundWinners(winners);
    window.triggerDailyReset = () => this.triggerDailyReset();
    window.triggerPizzaPrize = () => {
      this.pendingSpecialPrize = 'pizza';
      this.showToast('🍕 Pizza Prize Scheduled Next Spin!');
      return true;
    };
    window.triggerSaladPrize = () => {
      this.pendingSpecialPrize = 'salad';
      this.showToast('🥗 Salad Prize Scheduled Next Spin!');
      return true;
    };
    window.greedyCat = this;

    window.addEventListener('message', (e) => {
      try {
        const msg = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
        if (!msg) return;
        if (msg.type === 'SET_RANKING' && Array.isArray(msg.users)) {
          this.setRankingData(msg.users);
        }
        if (msg.type === 'SET_ROUND_WINNERS' && Array.isArray(msg.winners)) {
          this.setRoundWinners(msg.winners);
        }
        if (msg.type === 'RESET_WINNING') {
          this.triggerDailyReset();
        }
        if (msg.type === 'TRIGGER_PIZZA_PRIZE' || (msg.type === 'TRIGGER_SPECIAL_PRIZE' && msg.prize === 'pizza')) {
          this.pendingSpecialPrize = 'pizza';
          this.showToast('🍕 Pizza Prize Scheduled Next Spin!');
        }
        if (msg.type === 'TRIGGER_SALAD_PRIZE' || (msg.type === 'TRIGGER_SPECIAL_PRIZE' && msg.prize === 'salad')) {
          this.pendingSpecialPrize = 'salad';
          this.showToast('🥗 Salad Prize Scheduled Next Spin!');
        }
        if (msg.type === 'SET_USER_PROFILE') {
          if (window.setUserProfile) window.setUserProfile(msg.profile || msg.user);
        }
        if (msg.type === 'UPDATE_BALANCE' || msg.type === 'RECHARGE_DIAMONDS') {
          const amt = Number(msg.diamonds ?? msg.coins ?? msg.amount ?? 0);
          if (!isNaN(amt)) {
            this.balance = amt;
            this.updateUI();
          }
        }
        if (msg.type === 'SET_CONFIG' && msg.config) {
          this.applyRemoteConfig(msg.config);
        }
      } catch (err) {}
    });
  }

  // --- Real-time Firebase Firestore Sync & Live Diamond Wallet ---
  initFirebaseSync() {
    if (typeof firebase !== 'undefined') {
      try {
        if (firebase.apps.length === 0) {
          firebase.initializeApp({ projectId: 'imchat-84519' });
        }
        this.db = firebase.firestore();

        // 1. Live Admin Configuration Listener (RTP, food multipliers, active status, chips, background)
        this.db.collection('config').doc('html5_greedy_cat')
          .onSnapshot((doc) => {
            if (doc && doc.exists) {
              const data = doc.data();
              this.applyRemoteConfig(data);
            }
          }, (err) => console.warn('Config sync note:', err.message));

        // 2. Real-time User Diamond Wallet Listener on Users/{userId}
        this.initUserWalletSync();

        // 3. Real-time Daily Leaderboard Listener from daily_game_leaderboard
        this.initLeaderboardSync();

        // 4. Real-time Global App Theme Diamond Icon Listener from global_settings/app_theme
        try {
          this.db.collection('global_settings').doc('app_theme')
            .onSnapshot((doc) => {
              if (doc && doc.exists) {
                const themeData = doc.data() || {};
                const appDiamond = themeData.diamondIconUrl || themeData.diamondIcon;
                if (appDiamond && appDiamond.trim() !== '') {
                  this.updateAllDiamondIcons(appDiamond.trim());
                }
              }
            }, () => {});
        } catch (e) {}
      } catch (e) {
        console.warn('Firebase init note:', e);
      }
    }

    // Direct Flutter Javascript Bridge: window.setUserProfile({ userId, name, avatar, diamonds, coins })
    window.setUserProfile = (profile) => {
      try {
        const data = typeof profile === 'string' ? JSON.parse(profile) : profile;
        if (data.userId || data.uid) {
          this.userId = data.userId || data.uid;
        }
        if (data.name || data.fullname || data.username) this.userName = data.name || data.fullname || data.username;
        if (data.avatar || data.photoUrl) this.userAvatar = data.avatar || data.photoUrl;
        const dIcon = data.diamondIcon || data.diamondIconUrl || data.diamond_icon;
        if (dIcon && dIcon.trim() !== '') {
          this.updateAllDiamondIcons(dIcon.trim());
        }
        const coins = data.diamonds ?? data.coins ?? data.balance;
        if (coins !== undefined && coins !== null && !isNaN(Number(coins))) {
          this.balance = Number(coins);
          this.updateUI();
        }
        this.initUserWalletSync();
      } catch (e) {}
    };
  }

  initUserWalletSync() {
    if (!this.userId || !this.db) return;
    try {
      if (this.walletUnsubscribe) this.walletUnsubscribe();
      this.walletUnsubscribe = this.db.collection('Users').doc(this.userId)
        .onSnapshot((doc) => {
          if (doc && doc.exists) {
            const data = doc.data() || {};
            const coins = data.diamonds ?? data.coins ?? data.balance;
            if (coins !== undefined && coins !== null && !isNaN(Number(coins))) {
              this.balance = Number(coins);
              this.updateUI();
            }
            if (data.name || data.fullname) this.userName = data.name || data.fullname;
            if (data.avatar || data.photoUrl) this.userAvatar = data.avatar || data.photoUrl;
          }
        }, (err) => console.warn('Wallet listener note:', err));
    } catch (e) {
      console.warn('Wallet sync error:', e);
    }
  }

  initLeaderboardSync() {
    if (!this.db) return;
    try {
      const cycleKey = this.getCurrentDayPeriodKey ? this.getCurrentDayPeriodKey() : new Date().toISOString().slice(0, 10);
      this.db.collection('daily_game_leaderboard')
        .where('gameId', '==', 'html5_greedy_cat')
        .where('cycleKey', '==', cycleKey)
        .orderBy('winAmount', 'desc')
        .limit(10)
        .onSnapshot((snapshot) => {
          if (snapshot && !snapshot.empty) {
            const users = [];
            snapshot.docs.forEach((doc, idx) => {
              const d = doc.data();
              users.push({
                rank: idx + 1,
                name: d.name || 'Winner',
                coins: this.formatNumber(d.winAmount || 0),
                rawCoins: d.winAmount || 0,
                avatar: d.avatar || ''
              });
            });
            this.setRankingData(users);
          }
        }, () => {});
    } catch (e) {}
  }

  applyRemoteConfig(data) {
    if (!data) return;
    this.remoteConfig = data;
    if (data.winRatio !== undefined) {
      this.targetRtp = Number(data.winRatio);
    }
    if (data.forceWinnerIndex !== undefined) {
      this.forceWinnerIndex = Number(data.forceWinnerIndex);
    }
    if (Array.isArray(data.items)) {
      data.items.forEach(item => {
        const target = FOOD_CONFIG.find(f => f.index === item.id || f.id === item.id || f.name === item.name);
        if (target) {
          if (item.multiplier !== undefined) target.mult = Number(item.multiplier);
          if (item.name) target.name = item.name;
          const podBadge = document.querySelector(`.food-pod[data-index="${target.index}"] .mult-text`);
          if (podBadge) podBadge.textContent = `x${target.mult}`;
        }
      });
    }
    if (Array.isArray(data.regularChips)) {
      const chipEls = document.querySelectorAll('.gummy-chip-wrap');
      data.regularChips.forEach((val, idx) => {
        if (chipEls[idx]) {
          chipEls[idx].dataset.val = val;
          const pill = chipEls[idx].querySelector('.chip-val-pill');
          if (pill) pill.textContent = this.formatNumber(Number(val));
        }
      });
    }
    if (data.gameBackgroundUrl && data.gameBackgroundUrl.trim()) {
      const wrapper = document.getElementById('game-wrapper');
      if (wrapper) wrapper.style.backgroundImage = `url("${data.gameBackgroundUrl.trim()}")`;
    }
    if (data.diamondIcon && data.diamondIcon.trim()) {
      this.updateAllDiamondIcons(data.diamondIcon.trim());
    }
  }

  updateAllDiamondIcons(url) {
    document.querySelectorAll('.diamond-icon').forEach(icon => {
      icon.style.backgroundImage = `url("${url}")`;
      icon.style.backgroundSize = 'contain';
      icon.style.backgroundRepeat = 'no-repeat';
      icon.style.backgroundPosition = 'center';
    });
  }

  setRankingData(users) {
    if (Array.isArray(users)) {
      this.realtimeUsers = users;
      this.updateBottomRankingStrip();
      this.renderRankingTable();
    }
  }

  setRoundWinners(winners) {
    if (Array.isArray(winners)) {
      this.lastRoundWinners = winners;
    }
  }

  // --- Daily 10:00 PM Auto-Reset Logic ---
  getCurrentDayPeriodKey() {
    const now = new Date();
    const d = new Date(now);
    if (d.getHours() < 22) {
      d.setDate(d.getDate() - 1);
    }
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}@22:00`;
  }

  initDailyWinningReset() {
    const currentPeriod = this.getCurrentDayPeriodKey();
    const storedPeriod = localStorage.getItem('greedy_cat_period_key');
    if (storedPeriod !== currentPeriod) {
      this.todayWinning = 0;
      localStorage.setItem('greedy_cat_today_winning', '0');
      localStorage.setItem('greedy_cat_period_key', currentPeriod);
    } else {
      this.todayWinning = parseInt(localStorage.getItem('greedy_cat_today_winning') || '0', 10);
    }
    this.scheduleDailyReset();
  }

  scheduleDailyReset() {
    const now = new Date();
    const nextReset = new Date(now);
    if (now.getHours() >= 22) {
      nextReset.setDate(nextReset.getDate() + 1);
    }
    nextReset.setHours(22, 0, 0, 0);
    const msUntilReset = nextReset.getTime() - now.getTime();
    setTimeout(() => {
      this.triggerDailyReset();
      this.scheduleDailyReset();
    }, Math.max(1000, msUntilReset));
  }

  checkDailyPeriod() {
    const currentPeriod = this.getCurrentDayPeriodKey();
    if (localStorage.getItem('greedy_cat_period_key') !== currentPeriod) {
      this.triggerDailyReset();
    }
  }

  triggerDailyReset() {
    this.todayWinning = 0;
    localStorage.setItem('greedy_cat_today_winning', '0');
    localStorage.setItem('greedy_cat_period_key', this.getCurrentDayPeriodKey());
    this.realtimeUsers = [];
    this.updateUI();
    this.renderRankingTable();
    this.showToast("Today's winning has reset (10:00 PM)");
  }

  recordWin(reward) {
    this.checkDailyPeriod();
    this.balance += reward;
    this.todayWinning += reward;
    localStorage.setItem('greedy_cat_today_winning', String(this.todayWinning));
    localStorage.setItem('greedy_cat_period_key', this.getCurrentDayPeriodKey());
  }

  // --- Render Dynamic Top 10 Ranking Table (Only Real-Time Users) ---
  renderRankingTable() {
    const tbody = document.getElementById('ranking-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';

    const list = [...this.realtimeUsers];
    if (this.todayWinning > 0 && !list.some(u => u.isCurrentPlayer || u.id === 'me')) {
      list.push({ id: 'me', name: 'You (Me)', winning: this.todayWinning, isCurrentPlayer: true });
    }
    list.sort((a, b) => b.winning - a.winning);
    const top10 = list.slice(0, 10);

    if (top10.length === 0) {
      // Just show ranks 1, 2, 3 as clean empty placeholders without fake bots/data
      for (let i = 1; i <= 3; i++) {
        const medal = i === 1 ? '🥇' : i === 2 ? '🥈' : '🥉';
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td><span class="rank-trophy">${medal}</span> ${i}</td>
          <td style="color:rgba(255,255,255,0.6);">-</td>
          <td style="color:rgba(255,255,255,0.6);">-</td>
        `;
        tbody.appendChild(tr);
      }
      return;
    }

    top10.forEach((user, idx) => {
      const rank = idx + 1;
      const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : '';
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${medal ? `<span class="rank-trophy">${medal}</span> ` : ''}${rank}</td>
        <td>${user.name || '-'}</td>
        <td><span class="gold-coin-icon sm"></span> ${this.formatNumber(user.winning || 0)}</td>
      `;
      tbody.appendChild(tr);
    });
  }

  // --- Update Bottom Ranking Strip (Top 1 Real-time User) ---
  updateBottomRankingStrip() {
    const list = [...this.realtimeUsers];
    if (this.todayWinning > 0 && !list.some(u => u.isCurrentPlayer || u.id === 'me')) {
      list.push({ id: 'me', name: 'You (Me)', winning: this.todayWinning });
    }
    list.sort((a, b) => b.winning - a.winning);

    const top1 = list[0];
    const avatarEl = document.getElementById('strip-user-avatar');
    const nameEl = document.getElementById('strip-username');
    const scoreEl = document.getElementById('strip-score');

    if (top1 && top1.winning > 0) {
      if (avatarEl) avatarEl.textContent = (top1.name || 'U').substring(0, 1).toUpperCase();
      if (nameEl) nameEl.textContent = top1.name;
      if (scoreEl) scoreEl.textContent = this.formatNumber(top1.winning);
    } else {
      if (avatarEl) avatarEl.textContent = '-';
      if (nameEl) nameEl.textContent = '--';
      if (scoreEl) scoreEl.textContent = '0';
    }
  }

  // --- Update Result Modal TOP 3 Podium ---
  updateResultPodium(reward) {
    const roundWinners = [...this.lastRoundWinners];
    if (reward > 0) {
      roundWinners.push({ name: 'You (Me)', score: reward });
    }
    roundWinners.sort((a, b) => b.score - a.score);

    for (let r = 1; r <= 3; r++) {
      const winner = roundWinners[r - 1];
      const nameEl = document.getElementById(`podium-name-${r}`);
      const scoreEl = document.getElementById(`podium-score-${r}`);
      const avatarEl = document.getElementById(`podium-avatar-${r}`);

      if (winner && winner.score > 0) {
        if (nameEl) nameEl.textContent = winner.name;
        if (scoreEl) scoreEl.textContent = this.formatNumber(winner.score);
        if (avatarEl) {
          avatarEl.classList.remove('avatar-empty');
          avatarEl.textContent = (winner.name || 'U').substring(0, 1).toUpperCase();
        }
      } else {
        if (nameEl) nameEl.textContent = '-';
        if (scoreEl) scoreEl.textContent = '-';
        if (avatarEl) {
          avatarEl.classList.add('avatar-empty');
          avatarEl.textContent = '';
        }
      }
    }
  }

  renderRecordsTable() {
    const tbody = document.getElementById('records-table-body');
    if (!tbody) return;
    tbody.innerHTML = '';

    // Filter strictly to rounds where player actually placed a bet
    const validRecords = this.records.filter(r => r && r.betVal > 0);

    if (validRecords.length === 0) {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td colspan="3" style="text-align:center;padding:24px 8px;color:rgba(255,255,255,0.7);font-weight:700;">
          No bet records yet. Place bets in a round to view history!
        </td>
      `;
      tbody.appendChild(tr);
      return;
    }

    validRecords.slice(0, 25).forEach(rec => {
      const tr = document.createElement('tr');
      const isWin = rec.resVal > 0 || rec.isWin;

      // Bet details (Only bet amount, no item icons)
      const betHtml = `<span style="font-weight:900;color:#ffffff;font-size:13px;">${this.formatNumber(rec.betVal)}</span>`;

      // Result details (WIN / LOSS + Amount + Winning Food)
      const resHtml = isWin ? `
        <div style="display:flex;align-items:center;gap:4px;">
          <span style="background:#16a34a;color:#ffffff;font-size:9.5px;font-weight:900;padding:1px 5px;border-radius:4px;box-shadow:0 1px 2px rgba(0,0,0,0.3);">WIN</span>
          <span style="color:#fef08a;font-weight:900;">+${this.formatNumber(rec.resVal)}</span>
          <img src="${ASSETS[rec.resFood]}" width="18" height="18">
        </div>
      ` : `
        <div style="display:flex;align-items:center;gap:4px;">
          <span style="background:#dc2626;color:#ffffff;font-size:9.5px;font-weight:900;padding:1px 5px;border-radius:4px;box-shadow:0 1px 2px rgba(0,0,0,0.3);">LOSS</span>
          <span style="color:rgba(255,255,255,0.7);font-weight:800;">0</span>
          <img src="${ASSETS[rec.resFood]}" width="18" height="18">
        </div>
      `;

      tr.innerHTML = `
        <td style="font-size:11px;color:rgba(255,255,255,0.9);white-space:nowrap;">${rec.time.substring(11, 19)}</td>
        <td>${betHtml}</td>
        <td>${resHtml}</td>
      `;
      tbody.appendChild(tr);
    });
  }
}

window.addEventListener('DOMContentLoaded', () => {
  window.gameInstance = new GreedyCatGame();
});
