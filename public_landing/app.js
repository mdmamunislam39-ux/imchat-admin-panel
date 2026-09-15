// ==========================================================================
// IMChat Landing Web App Logic - Firestore Integration
// ==========================================================================

const firebaseConfig = {
  apiKey: "AIzaSyDPAzlHyBLTU83kZ6jSisEgPOjsuSwKuj0",
  authDomain: "imchat-84519.firebaseapp.com",
  databaseURL: "https://imchat-84519-default-rtdb.firebaseio.com",
  projectId: "imchat-84519",
  storageBucket: "imchat-84519.appspot.com",
  messagingSenderId: "518076067996",
  appId: "1:518076067996:web:174b33c043d49536a3fd59",
  measurementId: "G-XG7W2CHTZH"
};

// Initialize Firebase
if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}
const db = firebase.firestore();

// Default Fallback Config
const defaultConfig = {
  appName: "IMChat",
  tagline: "Connect, Voice Chat & Share Moments",
  description: "IMChat is the ultimate audio room & live entertainment platform. Join high-quality multi-seat voice rooms, play fun games with friends, send stunning gifts, and connect globally!",
  appVersion: "v1.0.0",
  playStoreUrl: "https://play.google.com",
  appStoreUrl: "https://apps.apple.com",
  apkUrl: "",
  logoUrl: "",
  supportEmail: "support@imchatapp.com",
  announcement: "🔥 Welcome to IMChat! Download the latest app version for new voice rooms & features.",
  showAnnouncement: true,
  screenshots: [
    "https://images.unsplash.com/photo-1616469829941-c7200edec809?w=600&auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&auto=format&fit=crop&q=80",
    "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600&auto=format&fit=crop&q=80"
  ],
  features: [
    {
      title: "Audio Voice Rooms",
      desc: "Host multi-mic crystal clear voice rooms with smooth audio and background music.",
      icon: "mic"
    },
    {
      title: "In-Room Mini Games",
      desc: "Play Greedy, Wheel, and Lucky Bag games directly inside voice rooms.",
      icon: "gamepad"
    },
    {
      title: "3D Gifts & Entrances",
      desc: "Express yourself with luxury entrance cars, SVIP frames, and 3D animated gifts.",
      icon: "gift"
    },
    {
      title: "Agencies & Hosts",
      desc: "Become a verified agency host, grow your fanbase, and earn monthly rewards.",
      icon: "users"
    }
  ]
};

// Render Website Data
function renderWebsiteData(data) {
  const config = { ...defaultConfig, ...data };

  // Set Title & Meta Description
  document.getElementById("site-title").innerText = `${config.appName} - ${config.tagline}`;
  document.getElementById("site-meta-desc").content = config.description;
  
  // App Branding
  document.getElementById("hero-appName").innerText = config.appName;
  document.getElementById("app-name-brand").innerText = config.appName;
  document.getElementById("footer-app-name").innerText = config.appName;
  document.getElementById("copyright-name").innerText = config.appName;
  document.getElementById("copyright-year").innerText = new Date().getFullYear();

  const webLogo = config.websiteLogoUrl || config.logoUrl;
  if (webLogo) {
    document.getElementById("app-logo").src = webLogo;
    document.getElementById("footer-app-logo").src = webLogo;
    document.getElementById("site-favicon").href = webLogo;
  }

  // Tagline & Description
  document.getElementById("hero-tagline").innerText = config.tagline;
  document.getElementById("hero-description").innerText = config.description;
  document.getElementById("app-version-badge").innerText = `${config.appVersion} Out Now`;

  // Support Email & Legal Links
  const emailElem = document.getElementById("footer-contact-email");
  emailElem.href = `mailto:${config.supportEmail}`;
  emailElem.innerHTML = `<i class="fa-regular fa-envelope"></i> ${config.supportEmail}`;

  const privacyElem = document.getElementById("footer-privacy-policy");
  if (config.privacyPolicyUrl) {
    privacyElem.href = config.privacyPolicyUrl;
    privacyElem.target = "_blank";
  } else {
    privacyElem.href = "#";
  }

  const termsElem = document.getElementById("footer-terms-of-service");
  if (config.termsOfServiceUrl) {
    termsElem.href = config.termsOfServiceUrl;
    termsElem.target = "_blank";
  } else {
    termsElem.href = "#";
  }

  // Announcement Bar
  const annBar = document.getElementById("announcement-bar");
  const annText = document.getElementById("announcement-text");
  if (config.showAnnouncement && config.announcement) {
    annText.innerText = config.announcement;
    annBar.classList.remove("hidden");
  } else {
    annBar.classList.add("hidden");
  }

  // Download Links
  const playStoreBtn = document.getElementById("btn-playstore");
  if (config.playStoreUrl) {
    playStoreBtn.href = config.playStoreUrl;
    playStoreBtn.style.display = "flex";
  } else {
    playStoreBtn.style.display = "none";
  }

  const appStoreBtn = document.getElementById("btn-appstore");
  if (config.appStoreUrl) {
    appStoreBtn.href = config.appStoreUrl;
    appStoreBtn.style.display = "flex";
  } else {
    appStoreBtn.style.display = "none";
  }

  const apkBtn = document.getElementById("btn-apk");
  if (config.apkUrl) {
    apkBtn.href = config.apkUrl;
    apkBtn.style.display = "flex";
  } else {
    apkBtn.style.display = "none";
  }

  // Screenshots Carousel
  const ssContainer = document.getElementById("screenshots-container");
  const screenshots = config.screenshots && config.screenshots.length > 0 ? config.screenshots : defaultConfig.screenshots;
  
  // Set Hero Mockup Image to first screenshot if available
  if (screenshots.length > 0) {
    document.getElementById("hero-mockup-img").src = screenshots[0];
  }

  ssContainer.innerHTML = screenshots.map((url, idx) => `
    <div class="screenshot-card">
      <img src="${url}" alt="${config.appName} Screenshot ${idx + 1}" loading="lazy">
    </div>
  `).join('');

  // Features Grid
  const featuresContainer = document.getElementById("features-container");
  const features = config.features && config.features.length > 0 ? config.features : defaultConfig.features;
  
  const iconMap = {
    mic: "fa-microphone",
    gamepad: "fa-gamepad",
    gift: "fa-gift",
    card_giftcard: "fa-gift",
    users: "fa-users",
    public: "fa-globe",
    star: "fa-star"
  };

  featuresContainer.innerHTML = features.map(f => {
    const iconClass = iconMap[f.icon] || "fa-star";
    return `
      <div class="feature-card">
        <div class="feature-icon">
          <i class="fa-solid ${iconClass}"></i>
        </div>
        <h3 class="feature-title">${f.title}</h3>
        <p class="feature-desc">${f.desc}</p>
      </div>
    `;
  }).join('');
}

// Initial default render
renderWebsiteData(defaultConfig);

// Listen to Firestore real-time updates
db.collection("settings").doc("website_landing")
  .onSnapshot((doc) => {
    if (doc.exists && doc.data()) {
      renderWebsiteData(doc.data());
    }
  }, (error) => {
    console.warn("Using default config due to Firestore fetch error:", error);
  });

// Close Announcement Bar Event
document.getElementById("close-announcement-btn").addEventListener("click", () => {
  document.getElementById("announcement-bar").classList.add("hidden");
});

// ==========================================================================
// Deep Link Handler (Voice Room & Post Share Links)
// Handles URLs like:
// - https://imchatapp.com/room?id=1001 or https://imchatapp.com?room=1001
// - https://imchatapp.com/post?id=2002 or https://imchatapp.com?post=2002
// ==========================================================================
function handleDeepLink() {
  const urlParams = new URLSearchParams(window.location.search);
  const pathname = window.location.pathname.toLowerCase();

  // Extract Room ID or Post ID from Query Parameters or Path
  let roomId = urlParams.get('room') || urlParams.get('roomId') || urlParams.get('room_id');
  let postId = urlParams.get('post') || urlParams.get('postId') || urlParams.get('post_id');

  if (!roomId && pathname.includes('/room')) {
    const pathParts = pathname.split('/').filter(p => p.length > 0);
    if (pathParts.length > 1) {
      roomId = pathParts[1];
    } else if (urlParams.get('id')) {
      roomId = urlParams.get('id');
    }
  }

  if (!postId && pathname.includes('/post')) {
    const pathParts = pathname.split('/').filter(p => p.length > 0);
    if (pathParts.length > 1) {
      postId = pathParts[1];
    } else if (urlParams.get('id')) {
      postId = urlParams.get('id');
    }
  }

  const deeplinkBanner = document.getElementById("deeplink-banner");
  const deeplinkIcon = document.getElementById("deeplink-icon");
  const deeplinkTitle = document.getElementById("deeplink-title");
  const deeplinkSubtitle = document.getElementById("deeplink-subtitle");
  const deeplinkOpenBtn = document.getElementById("deeplink-open-btn");
  const closeDeeplinkBtn = document.getElementById("close-deeplink-btn");

  if (closeDeeplinkBtn && deeplinkBanner) {
    closeDeeplinkBtn.addEventListener("click", () => {
      deeplinkBanner.classList.add("hidden");
    });
  }

  if (roomId && deeplinkBanner) {
    deeplinkIcon.innerHTML = `<i class="fa-solid fa-microphone"></i>`;
    deeplinkTitle.innerText = `🎙️ Voice Room #${roomId}`;
    deeplinkSubtitle.innerText = `You are invited to join Voice Room #${roomId} in IMChat.`;
    
    const appUrl = `imchat://room?id=${roomId}`;
    deeplinkOpenBtn.href = appUrl;

    deeplinkOpenBtn.addEventListener("click", (e) => {
      e.preventDefault();
      // Try opening app scheme
      window.location.href = appUrl;

      // Fallback timer: If app isn't opened within 1.5s, scroll to download
      setTimeout(() => {
        document.getElementById("download").scrollIntoView({ behavior: "smooth" });
      }, 1500);
    });

    deeplinkBanner.classList.remove("hidden");
  } else if (postId && deeplinkBanner) {
    deeplinkIcon.innerHTML = `<i class="fa-solid fa-newspaper"></i>`;
    deeplinkTitle.innerText = `📝 Shared Post #${postId}`;
    deeplinkSubtitle.innerText = `View shared post #${postId} in IMChat.`;

    const appUrl = `imchat://post?id=${postId}`;
    deeplinkOpenBtn.href = appUrl;

    deeplinkOpenBtn.addEventListener("click", (e) => {
      e.preventDefault();
      // Try opening app scheme
      window.location.href = appUrl;

      // Fallback timer: If app isn't opened within 1.5s, scroll to download
      setTimeout(() => {
        document.getElementById("download").scrollIntoView({ behavior: "smooth" });
      }, 1500);
    });

    deeplinkBanner.classList.remove("hidden");
  }
}

// Call Deep Link Handler on Load
document.addEventListener("DOMContentLoaded", () => {
  handleDeepLink();
});
