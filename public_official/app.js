// ==========================================================================
// IMChat Official Sub-Admin Master 42-Module Realtime Portal Engine
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

// App State
let currentAdmin = null;
let currentActiveView = 'dashboard';
let activeUnsubscribers = [];
let targetUserForAction = null;
let cachedOfficialItems = [];
let targetAssignUser = null;
let liveUsersMap = {}; // Global Cache for instant User Avatar, Name & Short Search ID

// ==========================================================================
// 42 Categorized Master Modules Registry (Exact 1:1 match with Main Admin Panel)
// ==========================================================================
const MASTER_MODULE_CATEGORIES = [
  {
    category: '👥 User & Community Management',
    modules: [
      { key: 'Users Management', icon: 'fa-users', name: 'Users Management' },
      { key: 'User Profiles', icon: 'fa-id-card', name: 'User Profiles' },
      { key: 'Hosts & Agencies', icon: 'fa-user-tie', name: 'Hosts & Agencies' },
      { key: 'Blocked Users', icon: 'fa-user-slash', name: 'Blocked Users' },
      { key: 'Ban Management', icon: 'fa-gavel', name: 'Ban Management' },
      { key: 'Room Ban Management', icon: 'fa-ban', name: 'Room Ban Management' },
      { key: 'Family Management', icon: 'fa-people-roof', name: 'Family Management' },
      { key: 'Family Levels', icon: 'fa-ranking-star', name: 'Family Levels' },
      { key: 'User History & Stats', icon: 'fa-chart-user', name: 'User History & Stats' }
    ]
  },
  {
    category: '💰 Economy, Gifts & Store',
    modules: [
      { key: 'Diamonds Management', icon: 'fa-gem', name: 'Diamonds Management' },
      { key: 'Gifts Management', icon: 'fa-gift', name: 'Gifts Management' },
      { key: 'Gift Transactions', icon: 'fa-receipt', name: 'Gift Transactions' },
      { key: 'Official Items', icon: 'fa-wand-magic-sparkles', name: 'Official Items (Assign)' },
      { key: 'Official Store', icon: 'fa-store', name: 'Official Store' },
      { key: 'Store Management', icon: 'fa-cart-flatbed', name: 'Store Management' },
      { key: 'Market Management', icon: 'fa-shop', name: 'Market Management' },
      { key: 'Emojis Management', icon: 'fa-face-smile', name: 'Emojis Management' },
      { key: 'Daily Check-in', icon: 'fa-calendar-check', name: 'Daily Check-in' },
      { key: 'Withdrawal Management', icon: 'fa-money-bill-transfer', name: 'Withdrawal Management' },
      { key: 'Commission Management', icon: 'fa-percent', name: 'Commission Management' },
      { key: 'Seller Management', icon: 'fa-user-tag', name: 'Seller Management' }
    ]
  },
  {
    category: '🎙️ Rooms, Levels & Agencies',
    modules: [
      { key: 'Rooms Management', icon: 'fa-microphone', name: 'Rooms Management' },
      { key: 'Custom Room IDs', icon: 'fa-key', name: 'Custom Room IDs' },
      { key: 'Host Agency Management', icon: 'fa-building-user', name: 'Host Agency Management' },
      { key: 'Agency Management', icon: 'fa-building', name: 'Agency Management' },
      { key: 'VIP Management', icon: 'fa-crown', name: 'VIP Management' },
      { key: 'SVIP Management', icon: 'fa-shield-heart', name: 'SVIP Management' },
      { key: 'Level System', icon: 'fa-arrow-up-right-dots', name: 'Level System' },
      { key: 'Intimacy Levels', icon: 'fa-heart-circle-bolt', name: 'Intimacy Levels' },
      { key: 'Couple Levels', icon: 'fa-ring', name: 'Couple Levels' }
    ]
  },
  {
    category: '🎮 Games & Events',
    modules: [
      { key: 'Game Management', icon: 'fa-gamepad', name: 'Game Management' },
      { key: 'Game Profit Analysis', icon: 'fa-chart-pie', name: 'Game Profit Analysis' },
      { key: 'Event Management', icon: 'fa-calendar-star', name: 'Event Management' },
      { key: 'Room Event Portal', icon: 'fa-bullhorn', name: 'Room Event Portal' },
      { key: 'Grab the Top', icon: 'fa-chair', name: 'Grab the Top' }
    ]
  },
  {
    category: '📢 Content, Branding & System',
    modules: [
      { key: 'Banner Management', icon: 'fa-images', name: 'Banner Management' },
      { key: 'imChat Moment Management', icon: 'fa-photo-film', name: 'Moment Management' },
      { key: 'Official Channels', icon: 'fa-tower-broadcast', name: 'Official Channels' },
      { key: 'Official Notifications', icon: 'fa-bell', name: 'Official Notifications' },
      { key: 'Reports & Analytics', icon: 'fa-chart-line', name: 'Reports & Analytics' },
      { key: 'Feedback Management', icon: 'fa-comments', name: 'Feedback Management' },
      { key: 'Settings', icon: 'fa-gear', name: 'Settings' },
      { key: 'Invitation Referral Reward', icon: 'fa-share-nodes', name: 'Invitation Referral' },
      { key: 'Website Landing', icon: 'fa-globe', name: 'Website Landing' }
    ]
  }
];

// Flat lookup for fast access
const ALL_MODULES_MAP = {};
MASTER_MODULE_CATEGORIES.forEach(cat => {
  cat.modules.forEach(m => {
    ALL_MODULES_MAP[m.key] = { ...m, category: cat.category };
  });
});

// ==========================================================================
// Authentication & Realtime Initializer
// ==========================================================================
document.addEventListener('DOMContentLoaded', () => {
  initAuthSession();
  setupEventListeners();
  initGlobalUsersCache();
  loadAllOfficialItemsCache();
});

// Global Real-time Cache for all users in the system
function initGlobalUsersCache() {
  db.collection('Users').limit(300).onSnapshot(snapshot => {
    snapshot.forEach(doc => {
      updateUserCache(doc);
    });
    // Re-render if on active table view
    if (currentActiveView === 'Official Items' || currentActiveView === 'Official Store' || currentActiveView === 'Store Management') {
      const tbody = document.getElementById('assigned-items-tbody');
      const searchFilter = document.getElementById('assigned-items-search');
      if (tbody && searchFilter && window._lastAssignedItemsCache) {
        renderAssignedTableRows(tbody, window._lastAssignedItemsCache, searchFilter.value.trim().toLowerCase(), canEdit(currentActiveView));
      }
    }
  });
}

function updateUserCache(doc) {
  const data = doc.data();
  const info = {
    id: doc.id,
    fullname: data.fullname || data.name || '',
    username: data.username || '',
    searchId: data.searchId !== undefined && data.searchId !== null ? data.searchId.toString() : '',
    profileImage: data.profileImage || '',
    diamonds: data.diamonds || data.diamondBalance || 0,
    phone: (data.phone || data.number || '').toString()
  };
  liveUsersMap[doc.id] = info;
  if (info.searchId) {
    liveUsersMap[info.searchId] = info;
  }
}

function fetchUserDocBackground(userId) {
  if (!userId || liveUsersMap[userId]) return;
  db.collection('Users').doc(userId).get().then(doc => {
    if (doc.exists) {
      updateUserCache(doc);
      if (currentActiveView === 'Official Items' || currentActiveView === 'Official Store' || currentActiveView === 'Store Management') {
        const tbody = document.getElementById('assigned-items-tbody');
        const searchFilter = document.getElementById('assigned-items-search');
        if (tbody && searchFilter && window._lastAssignedItemsCache) {
          renderAssignedTableRows(tbody, window._lastAssignedItemsCache, searchFilter.value.trim().toLowerCase(), canEdit(currentActiveView));
        }
      }
    }
  }).catch(() => {});
}

function resolveUserDisplay(userId, userProfileId, defaultName, defaultSearchId, defaultAvatar) {
  const u = liveUsersMap[userId] || liveUsersMap[userProfileId] || {};
  const name = u.fullname || u.name || (u.username ? '@' + u.username : (defaultName || 'User'));
  const avatar = u.profileImage || defaultAvatar || 'https://img.icons8.com/color/96/user-male-circle--v1.png';
  
  let searchId = u.searchId || defaultSearchId || '';
  if (!searchId || searchId.length > 15) {
    if (userProfileId && userProfileId.length <= 10) {
      searchId = userProfileId;
    } else if (userId) {
      fetchUserDocBackground(userId);
      searchId = userId.substring(0, 6);
    }
  }

  return { name, avatar, searchId };
}

let adminDocUnsub = null;

function initAuthSession() {
  const savedSession = localStorage.getItem('sub_admin_session');
  if (savedSession) {
    try {
      currentAdmin = JSON.parse(savedSession);
      if (currentAdmin.role === 'main_admin' || currentAdmin.isSuperAdmin === true || currentAdmin.email === 'admin@imchatapp.com') {
        logoutAdmin('Main Super Admin cannot log in to Sub-Official portal. Please use admin.imchatapp.com');
        return;
      }
      listenToCurrentAdminDoc(currentAdmin.id);
      showAppPortal();
    } catch (e) {
      showLoginScreen();
    }
  } else {
    showLoginScreen();
  }
}

function listenToCurrentAdminDoc(adminId) {
  if (adminDocUnsub) {
    adminDocUnsub();
    adminDocUnsub = null;
  }
  if (!adminId) return;

  adminDocUnsub = db.collection('web_admins').doc(adminId).onSnapshot(doc => {
    if (!doc.exists || doc.data().isActive === false) {
      logoutAdmin('Your sub-admin account is no longer active or has been removed.');
      return;
    }
    const data = doc.data();
    if (data.role === 'main_admin' || data.isSuperAdmin === true || data.email === 'admin@imchatapp.com') {
      logoutAdmin('Main Super Admin cannot log in to Sub-Official portal. Please use admin.imchatapp.com');
      return;
    }
    
    currentAdmin = { id: doc.id, ...data };
    localStorage.setItem('sub_admin_session', JSON.stringify(currentAdmin));
    
    // Live update UI & sidebar permissions
    const avatarEl = document.getElementById('current-user-avatar');
    const nameEl = document.getElementById('current-user-name');
    const emailEl = document.getElementById('current-user-email');
    if (avatarEl) avatarEl.textContent = (currentAdmin.name ? currentAdmin.name[0] : 'A').toUpperCase();
    if (nameEl) nameEl.textContent = currentAdmin.name || 'Sub Official Admin';
    if (emailEl) emailEl.textContent = currentAdmin.email || '';

    renderDynamicSidebar();

    // If active view is no longer permitted, redirect to dashboard
    if (currentActiveView !== 'dashboard' && !canView(currentActiveView)) {
      showToast(`Access to "${currentActiveView}" was updated or removed.`, 'error');
      navigateTo('dashboard');
    }
  }, err => {
    console.error('Error listening to sub admin permissions:', err);
  });
}

function setupEventListeners() {
  // Login Form
  const loginForm = document.getElementById('login-form');
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value.trim().toLowerCase();
      const password = document.getElementById('login-password').value.trim();
      const submitBtn = document.getElementById('btn-login-submit');
      const errorBox = document.getElementById('login-error');
      const errorMsg = document.getElementById('login-error-msg');

      errorBox.style.display = 'none';
      submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Authenticating...';
      submitBtn.disabled = true;

      try {
        const query = await db.collection('web_admins')
          .where('email', '==', email)
          .where('password', '==', password)
          .limit(1)
          .get();

        if (!query.empty) {
          const doc = query.docs[0];
          const data = doc.data();

          if (data.role === 'main_admin' || data.isSuperAdmin === true || data.email === 'admin@imchatapp.com') {
            throw new Error('This portal (official.imchatapp.com) is strictly for Sub Official Admins. Main Super Admin must log in at https://admin.imchatapp.com');
          }

          if (data.isActive === false) {
            throw new Error('This sub-admin account is deactivated. Please contact Main Super Admin.');
          }

          currentAdmin = { id: doc.id, ...data };
          localStorage.setItem('sub_admin_session', JSON.stringify(currentAdmin));
          
          db.collection('web_admins').doc(doc.id).update({
            lastLogin: firebase.firestore.FieldValue.serverTimestamp()
          }).catch(() => {});

          listenToCurrentAdminDoc(doc.id);
          showToast('Welcome, ' + (currentAdmin.name || 'Sub Official Admin') + '!', 'success');
          showAppPortal();
        } else {
          throw new Error('Invalid email or password. Please check your credentials.');
        }
      } catch (err) {
        errorMsg.textContent = err.message || 'Authentication error';
        errorBox.style.display = 'flex';
      } finally {
        submitBtn.innerHTML = '<i class="fa-solid fa-arrow-right-to-bracket"></i> Sign In to Portal';
        submitBtn.disabled = false;
      }
    });
  }

  // Password Visibility Toggle
  const togglePwdBtn = document.getElementById('toggle-pwd-btn');
  if (togglePwdBtn) {
    togglePwdBtn.addEventListener('click', () => {
      const pwdInput = document.getElementById('login-password');
      const icon = document.getElementById('pwd-icon');
      if (pwdInput.type === 'password') {
        pwdInput.type = 'text';
        icon.className = 'fa-regular fa-eye-slash';
      } else {
        pwdInput.type = 'password';
        icon.className = 'fa-regular fa-eye';
      }
    });
  }

  // Logout Button
  const logoutBtn = document.getElementById('btn-logout');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      logoutAdmin('You have successfully signed out.');
    });
  }

  // Mobile Menu Toggle
  const mobileToggle = document.getElementById('mobile-menu-toggle');
  const sidebar = document.getElementById('app-sidebar');
  if (mobileToggle && sidebar) {
    mobileToggle.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });
  }

  // Modals Actions
  const btnSearchAssignUser = document.getElementById('btn-search-assign-user');
  if (btnSearchAssignUser) {
    btnSearchAssignUser.addEventListener('click', handleSearchAssignUser);
  }

  const btnConfirmAssignItem = document.getElementById('btn-confirm-assign-item');
  if (btnConfirmAssignItem) {
    btnConfirmAssignItem.addEventListener('click', handleConfirmAssignItem);
  }

  const btnSaveUserDetails = document.getElementById('btn-confirm-save-user-details');
  if (btnSaveUserDetails) {
    btnSaveUserDetails.addEventListener('click', handleSaveUserDetails);
  }

  const confirmAdjustDiamonds = document.getElementById('btn-confirm-adjust-diamonds');
  if (confirmAdjustDiamonds) {
    confirmAdjustDiamonds.addEventListener('click', handleDiamondAdjustment);
  }

  const confirmAddBanner = document.getElementById('btn-confirm-add-banner');
  if (confirmAddBanner) {
    confirmAddBanner.addEventListener('click', handleAddBannerSubmit);
  }

  const confirmAddGift = document.getElementById('btn-confirm-add-gift');
  if (confirmAddGift) {
    confirmAddGift.addEventListener('click', handleAddGiftSubmit);
  }
}

function showLoginScreen() {
  document.getElementById('login-container').style.display = 'flex';
  document.getElementById('app-container').style.display = 'none';
  clearActiveListeners();
}

function showAppPortal() {
  document.getElementById('login-container').style.display = 'none';
  document.getElementById('app-container').style.display = 'flex';

  // Set user info
  document.getElementById('current-user-avatar').textContent = (currentAdmin.name ? currentAdmin.name[0] : 'A').toUpperCase();
  document.getElementById('current-user-name').textContent = currentAdmin.name || 'Sub Official Admin';
  document.getElementById('current-user-email').textContent = currentAdmin.email || '';

  // Render all assigned modules in the sidebar
  renderDynamicSidebar();

  // Navigate to Dashboard
  navigateTo('dashboard');
}

function logoutAdmin(msg) {
  if (adminDocUnsub) {
    adminDocUnsub();
    adminDocUnsub = null;
  }
  localStorage.removeItem('sub_admin_session');
  currentAdmin = null;
  showLoginScreen();
  if (msg) showToast(msg, 'success');
}

function clearActiveListeners() {
  activeUnsubscribers.forEach(unsub => {
    if (typeof unsub === 'function') unsub();
  });
  activeUnsubscribers = [];
}

// ==========================================================================
// 100% Robust Dynamic Permissions Checking
// ==========================================================================
function getPermissionLevel(moduleKey) {
  if (!currentAdmin) return 'edit';
  if (currentAdmin.role === 'main_admin') return 'edit';
  
  const perms = currentAdmin.permissions;
  if (!perms || Object.keys(perms).length === 0) return 'edit';

  const normalize = s => (s || '').toLowerCase().replace(/[^a-z0-9]/g, '');
  const targetNorm = normalize(moduleKey);

  if (typeof perms === 'object' && !Array.isArray(perms)) {
    for (const [k, v] of Object.entries(perms)) {
      const normK = normalize(k);
      if (normK === targetNorm || normK.includes(targetNorm) || targetNorm.includes(normK)) {
        if (v === 'edit' || v === true) return 'edit';
        if (v === 'view') return 'view';
        if (v === 'none') return 'none';
      }
    }
  } else if (Array.isArray(perms)) {
    for (const item of perms) {
      const normItem = normalize(item);
      if (normItem === targetNorm || normItem.includes(targetNorm) || targetNorm.includes(normItem)) {
        return 'edit';
      }
    }
  }
  return 'none';
}

function canView(moduleKey) {
  const lvl = getPermissionLevel(moduleKey);
  return lvl === 'view' || lvl === 'edit';
}

function canEdit(moduleKey) {
  return getPermissionLevel(moduleKey) === 'edit';
}

// Load Official Items into Cache
async function loadAllOfficialItemsCache() {
  try {
    cachedOfficialItems = [];
    const snapMarket = await db.collection('market_items').get();
    snapMarket.forEach(doc => {
      cachedOfficialItems.push({ id: doc.id, ...doc.data() });
    });

    const snapOfficial = await db.collection('official_items').get();
    snapOfficial.forEach(doc => {
      if (!cachedOfficialItems.some(i => i.id === doc.id)) {
        cachedOfficialItems.push({ id: doc.id, ...doc.data() });
      }
    });

    if (cachedOfficialItems.length === 0) {
      cachedOfficialItems = [
        { id: 'gold_vip_frame', name: '👑 Royal Gold Crown Frame', type: 'avatarFrame', category: 'official' },
        { id: 'super_sports_car', name: '🏎️ Neon Sports Car Ride', type: 'entryEffect', category: 'official' },
        { id: 'top_contributor_badge', name: '🏆 Top Supporter Official Badge', type: 'badge', category: 'official' },
        { id: 'luxury_room_theme', name: '🌌 Galaxy Luxury Room Theme', type: 'backgroundTheme', category: 'official' },
        { id: 'svip_exclusive_skin', name: '💎 SVIP Emerald Profile Skin', type: 'profileSkin', category: 'official' }
      ];
    }

    populateAssignItemDropdown();
  } catch (e) {
    console.error('Error preloading store items:', e);
  }
}

function populateAssignItemDropdown() {
  const select = document.getElementById('assign-item-select');
  if (!select) return;
  select.innerHTML = '<option value="">-- Choose an Official Item --</option>';

  cachedOfficialItems.forEach(item => {
    const opt = document.createElement('option');
    opt.value = item.id;
    const type = item.type || item.category || 'Item';
    opt.textContent = `[${type.toUpperCase()}] ${item.name || item.title || item.id}`;
    select.appendChild(opt);
  });
}

// ==========================================================================
// Complete 42-Module Dynamic Sidebar Generator
// ==========================================================================
function renderDynamicSidebar() {
  const menuContainer = document.getElementById('sidebar-menu-list');
  menuContainer.innerHTML = '';

  // 1. Overview
  const dashboardItem = document.createElement('div');
  dashboardItem.className = 'nav-item active';
  dashboardItem.id = 'nav-dashboard';
  dashboardItem.innerHTML = `<i class="fa-solid fa-gauge"></i> <span>Overview</span>`;
  dashboardItem.onclick = () => navigateTo('dashboard');
  menuContainer.appendChild(dashboardItem);

  // Group all permitted modules by category
  MASTER_MODULE_CATEGORIES.forEach(catGroup => {
    const permittedModulesInCat = catGroup.modules.filter(m => canView(m.key));

    if (permittedModulesInCat.length > 0) {
      const secTitle = document.createElement('div');
      secTitle.className = 'menu-section-title';
      secTitle.textContent = catGroup.category;
      menuContainer.appendChild(secTitle);

      permittedModulesInCat.forEach(item => {
        const isEdit = canEdit(item.key);
        const nav = document.createElement('div');
        nav.className = 'nav-item';
        nav.id = `nav-${sanitizeId(item.key)}`;
        const tagClass = isEdit ? 'tag-edit' : 'tag-view';
        const tagLabel = isEdit ? 'Editor' : 'View';

        nav.innerHTML = `
          <i class="fa-solid ${item.icon}"></i>
          <span>${item.name}</span>
          <span class="permission-tag ${tagClass}">${tagLabel}</span>
        `;
        nav.onclick = () => navigateTo(item.key);
        menuContainer.appendChild(nav);
      });
    }
  });
}

function sanitizeId(str) {
  return str.replace(/[^a-zA-Z0-9]/g, '_');
}

// ==========================================================================
// Routing & Views Controller for all 42 Modules
// ==========================================================================
function navigateTo(viewKey) {
  clearActiveListeners();
  currentActiveView = viewKey;

  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  const activeNav = document.getElementById(viewKey === 'dashboard' ? 'nav-dashboard' : `nav-${sanitizeId(viewKey)}`);
  if (activeNav) activeNav.classList.add('active');

  const sidebar = document.getElementById('app-sidebar');
  if (sidebar) sidebar.classList.remove('open');

  const contentArea = document.getElementById('content-view-area');
  const titleEl = document.getElementById('current-page-title');
  const subtitleEl = document.getElementById('current-page-subtitle');
  const isEditable = canEdit(viewKey);

  if (viewKey === 'dashboard') {
    titleEl.textContent = 'Dashboard Overview';
    subtitleEl.textContent = 'Real-time overview of assigned modules & quick actions';
    renderDashboardView(contentArea);
  }
  // Store & Privileges (Official Items, Store, Market, SVIP)
  else if (['Official Items', 'Official Store', 'Store Management', 'Market Management', 'SVIP Management', 'VIP Management'].includes(viewKey)) {
    titleEl.textContent = `${viewKey} - Assign & Privileges Hub`;
    subtitleEl.textContent = isEditable ? 'Assign official items, badges, frames & SVIP in real-time' : 'View assigned store items (View Only)';
    renderAssignItemsView(contentArea, viewKey);
  }
  // Users & Profiles
  else if (['Users Management', 'User Profiles', 'User History & Stats', 'Family Management', 'Family Levels'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Real-time user editing, balance adjustments & profile control' : 'Real-time user inspection (View Only)';
    renderUsersView(contentArea, viewKey);
  }
  // Diamonds & Financials
  else if (['Diamonds Management', 'Gift Transactions', 'Withdrawal Management', 'Commission Management', 'Seller Management', 'Daily Check-in'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Manage diamond balances, seller accounts & transaction logs' : 'View balances & financial logs (View Only)';
    renderDiamondsView(contentArea, viewKey);
  }
  // Gifts & Emojis
  else if (['Gifts Management', 'Emojis Management'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Create, edit & manage virtual gifts and prices' : 'View virtual gifts catalog (View Only)';
    renderGiftsView(contentArea, viewKey);
  }
  // Rooms & Audio
  else if (['Rooms Management', 'Custom Room IDs', 'Room Ban Management', 'Grab the Top', 'Room Event Portal'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Live audio room status, custom IDs & moderation' : 'Monitor live audio rooms (View Only)';
    renderRoomsView(contentArea, viewKey);
  }
  // Blocked & Bans
  else if (['Blocked Users', 'Ban Management'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Active user bans & 1-click unban operations' : 'View banned user records (View Only)';
    renderBannedUsersView(contentArea, viewKey);
  }
  // Banners & Content
  else if (['Banner Management', 'imChat Moment Management', 'Official Channels', 'Official Notifications', 'Website Landing'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Manage banners, moments & official broadcasts' : 'View promotional content (View Only)';
    renderBannersView(contentArea, viewKey);
  }
  // Agencies & Hosts
  else if (['Agency Management', 'Host Agency Management', 'Hosts & Agencies'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'Agency registrations, commissions & host rosters' : 'View agency partnerships (View Only)';
    renderAgencyView(contentArea, viewKey);
  }
  // Levels
  else if (['Level System', 'Intimacy Levels', 'Couple Levels'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = isEditable ? 'User & couple level progression system' : 'View level parameters (View Only)';
    renderLevelsView(contentArea, viewKey);
  }
  // Games
  else if (['Game Management', 'Game Profit Analysis'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = 'Platform game analytics & settings';
    renderGamesView(contentArea, viewKey);
  }
  // Feedback
  else if (viewKey === 'Feedback Management') {
    titleEl.textContent = 'User Feedbacks';
    subtitleEl.textContent = 'In-app user inquiries & support tickets';
    renderFeedbackView(contentArea, viewKey);
  }
  // Audit Logs & History
  else if (['Reports & Analytics', 'Invitation Referral Reward', 'Settings'].includes(viewKey)) {
    titleEl.textContent = `${viewKey}`;
    subtitleEl.textContent = 'Real-time assignment logs & platform analytics';
    renderAssignHistoryView(contentArea, viewKey);
  }
  else {
    titleEl.textContent = viewKey;
    subtitleEl.textContent = 'Assigned Module View';
    contentArea.innerHTML = `
      <div class="panel-card" style="padding: 40px; text-align: center;">
        <i class="fa-solid fa-circle-check" style="font-size: 48px; color: var(--primary); margin-bottom: 16px;"></i>
        <h3>${viewKey}</h3>
        <p style="color: var(--text-muted); margin-top: 8px;">Permission Mode: <strong>${isEditable ? 'FULL EDITOR' : 'VIEW ONLY'}</strong></p>
      </div>
    `;
  }
}

// ==========================================================================
// 1. Dashboard View
// ==========================================================================
function renderDashboardView(container) {
  let totalAssignedCount = 0;
  MASTER_MODULE_CATEGORIES.forEach(cat => {
    cat.modules.forEach(m => {
      if (canView(m.key)) totalAssignedCount++;
    });
  });

  container.innerHTML = `
    <!-- Stats Row -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon blue"><i class="fa-solid fa-users"></i></div>
        <div>
          <div class="stat-val" id="dash-total-users">--</div>
          <div class="stat-label">Total Users</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon green"><i class="fa-solid fa-microphone"></i></div>
        <div>
          <div class="stat-val" id="dash-active-rooms">--</div>
          <div class="stat-label">Live Voice Rooms</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon amber"><i class="fa-solid fa-wand-magic-sparkles"></i></div>
        <div>
          <div class="stat-val" id="dash-items-count">${cachedOfficialItems.length || '--'}</div>
          <div class="stat-label">Official Store Items</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon purple"><i class="fa-solid fa-shield-halved"></i></div>
        <div>
          <div class="stat-val">${totalAssignedCount}</div>
          <div class="stat-label">Assigned Modules</div>
        </div>
      </div>
    </div>

    <!-- Quick Action / Assigned Modules Grid -->
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-shapes" style="color: var(--primary);"></i> Your Assigned Tools & Modules (${totalAssignedCount})</h3>
        </div>
      </div>
      <div style="padding: 24px;">
        <div id="quick-modules-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 16px;"></div>
      </div>
    </div>
  `;

  // Real-time counter listeners
  const unsubUsers = db.collection('Users').limit(1).onSnapshot(() => {
    db.collection('Users').get().then(snap => {
      const el = document.getElementById('dash-total-users');
      if (el) el.textContent = snap.size.toLocaleString();
    });
  });
  activeUnsubscribers.push(unsubUsers);

  const unsubRooms = db.collection('Rooms').limit(1).onSnapshot(() => {
    db.collection('Rooms').get().then(snap => {
      const el = document.getElementById('dash-active-rooms');
      if (el) el.textContent = snap.size.toLocaleString();
    });
  });
  activeUnsubscribers.push(unsubRooms);

  // Populate Quick Launch Grid with all permitted modules
  const grid = document.getElementById('quick-modules-grid');
  MASTER_MODULE_CATEGORIES.forEach(cat => {
    cat.modules.forEach(m => {
      if (canView(m.key)) {
        const isEdit = canEdit(m.key);
        const card = document.createElement('div');
        card.className = 'stat-card';
        card.style.cursor = 'pointer';
        card.innerHTML = `
          <div class="stat-icon ${isEdit ? 'amber' : 'blue'}">
            <i class="fa-solid ${m.icon}"></i>
          </div>
          <div style="flex: 1;">
            <div style="font-weight: 700; font-size: 14.5px;">${m.name}</div>
            <div style="font-size: 11.5px; color: ${isEdit ? 'var(--accent-amber)' : 'var(--accent-cyan)'};">
              ${isEdit ? '✏️ Full Editor Access' : '👁️ View Only Access'}
            </div>
          </div>
          <i class="fa-solid fa-chevron-right" style="color: var(--text-dim); font-size: 13px;"></i>
        `;
        card.onclick = () => navigateTo(m.key);
        grid.appendChild(card);
      }
    });
  });
}

// ==========================================================================
// 2. Assign Official Items View (Dedicated Real-time Assign Hub)
// ==========================================================================
function renderAssignItemsView(container, moduleKey) {
  const isEditable = canEdit(moduleKey);

  container.innerHTML = `
    <!-- Top Action Card: Assign Item to User -->
    <div class="panel-card" style="margin-bottom: 24px;">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-wand-magic-sparkles" style="color: var(--accent-cyan);"></i> Assign Store Item to User</h3>
          <span class="badge-status ${isEditable ? 'badge-active' : 'badge-locked'}">
            ${isEditable ? '✏️ Assign Enabled' : '👁️ View Only'}
          </span>
        </div>
      </div>
      <div style="padding: 24px;">
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; align-items: flex-end;">
          <div>
            <label style="display: block; font-size: 12px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px;">Target User Profile ID / Search ID</label>
            <div style="display: flex; gap: 8px;">
              <input type="text" id="direct-assign-searchid" placeholder="Enter Search ID (e.g. 10001)..." style="flex: 1; padding: 11px; background: var(--bg-input); border: 1px solid var(--border-color); border-radius: var(--radius-sm); color: #fff;">
              <button class="action-btn btn-sm-primary" id="btn-lookup-direct-user"><i class="fa-solid fa-search"></i> Verify User</button>
            </div>
          </div>
          <div>
            <label style="display: block; font-size: 12px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px;">Select Official Item</label>
            <select id="direct-assign-item-select" style="width: 100%; padding: 11px; background: var(--bg-input); border: 1px solid var(--border-color); border-radius: var(--radius-sm); color: #fff;">
              <option value="">-- Choose Item --</option>
            </select>
          </div>
          <div>
            <label style="display: block; font-size: 12px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px;">Validity Days</label>
            <select id="direct-assign-duration-select" style="width: 100%; padding: 11px; background: var(--bg-input); border: 1px solid var(--border-color); border-radius: var(--radius-sm); color: #fff;">
              <option value="1">1 Day</option>
              <option value="7" selected>7 Days</option>
              <option value="15">15 Days</option>
              <option value="30">30 Days (1 Month)</option>
              <option value="90">90 Days</option>
              <option value="365">365 Days</option>
              <option value="0">Permanent</option>
            </select>
          </div>
          <div>
            <button class="btn-primary ${isEditable ? '' : 'btn-disabled'}" id="btn-submit-direct-assign" style="width: 100%; padding: 11px;">
              <i class="fa-solid fa-gift"></i> Assign Item Now
            </button>
          </div>
        </div>

        <!-- Verified Target User Preview -->
        <div id="direct-verified-user-box" style="display: none; margin-top: 16px; padding: 12px 18px; background: rgba(6, 182, 212, 0.1); border: 1px solid rgba(6, 182, 212, 0.3); border-radius: var(--radius-sm);">
          <div style="display: flex; align-items: center; gap: 12px;">
            <img id="direct-verified-avatar" src="" style="width: 42px; height: 42px; border-radius: 50%; object-fit: cover;">
            <div style="flex: 1;">
              <div style="font-weight: 700; color: #fff; font-size: 15px;" id="direct-verified-name">-</div>
              <div style="font-size: 12px; color: var(--text-muted);">
                Search ID: <strong id="direct-verified-searchid" style="color: var(--accent-cyan); font-family: monospace;">-</strong> | 
                Diamonds: <strong id="direct-verified-diamonds" style="color: #60a5fa;">0</strong> | 
                UID: <span id="direct-verified-uid" style="font-family: monospace;">-</span>
              </div>
            </div>
            <span class="badge-status badge-active">Target Verified ✅</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Real-time Assigned Items Live Table -->
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-list-check" style="color: var(--accent-emerald);"></i> Real-time User Assigned Items (${isEditable ? 'Full Revoke Control' : 'View Only'})</h3>
        </div>
        <div class="panel-actions">
          <div class="search-box">
            <i class="fa-solid fa-search"></i>
            <input type="text" id="assigned-items-search" placeholder="Filter by User Name, Search ID or Item...">
          </div>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>User</th>
              <th>Assigned Item</th>
              <th>Type</th>
              <th>Assigned Date</th>
              <th>Expires At</th>
              <th>Status</th>
              <th style="text-align: right;">Action</th>
            </tr>
          </thead>
          <tbody id="assigned-items-tbody">
            <tr><td colspan="7" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Streaming real-time assignments...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  // Populate direct items dropdown
  const directSelect = document.getElementById('direct-assign-item-select');
  cachedOfficialItems.forEach(item => {
    const opt = document.createElement('option');
    opt.value = item.id;
    const type = item.type || item.category || 'Item';
    opt.textContent = `[${type.toUpperCase()}] ${item.name || item.title || item.id}`;
    directSelect.appendChild(opt);
  });

  // Verify User Listener
  let verifiedDirectUser = null;
  document.getElementById('btn-lookup-direct-user').onclick = async () => {
    const searchId = document.getElementById('direct-assign-searchid').value.trim();
    if (!searchId) {
      showToast('Please enter a Search ID or User ID', 'error');
      return;
    }

    try {
      const user = await searchUserInDb(searchId);
      if (user) {
        verifiedDirectUser = user;
        document.getElementById('direct-verified-avatar').src = user.profileImage || 'https://img.icons8.com/color/96/user-male-circle--v1.png';
        document.getElementById('direct-verified-name').textContent = user.fullname || user.name || 'Unnamed User';
        document.getElementById('direct-verified-searchid').textContent = user.searchId || user.id;
        document.getElementById('direct-verified-diamonds').textContent = (user.diamonds || user.diamondBalance || 0).toLocaleString();
        document.getElementById('direct-verified-uid').textContent = user.id;
        document.getElementById('direct-verified-user-box').style.display = 'block';
        showToast('User verified successfully!', 'success');
      } else {
        showToast('User not found with Search ID: ' + searchId, 'error');
        document.getElementById('direct-verified-user-box').style.display = 'none';
        verifiedDirectUser = null;
      }
    } catch (e) {
      showToast('Search error: ' + e.message, 'error');
    }
  };

  // Submit Direct Assign Button
  document.getElementById('btn-submit-direct-assign').onclick = async () => {
    if (!isEditable) {
      showToast('View Only Mode: Assigning items is disabled for your role.', 'error');
      return;
    }
    if (!verifiedDirectUser) {
      showToast('Please search and verify a target user first.', 'error');
      return;
    }

    const itemId = document.getElementById('direct-assign-item-select').value;
    if (!itemId) {
      showToast('Please select an item to assign.', 'error');
      return;
    }

    const selectedItem = cachedOfficialItems.find(i => i.id === itemId);
    if (!selectedItem) {
      showToast('Item not found.', 'error');
      return;
    }

    const durationDays = parseInt(document.getElementById('direct-assign-duration-select').value);
    const btn = document.getElementById('btn-submit-direct-assign');
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Assigning...';

    try {
      await executeItemAssignment(verifiedDirectUser, selectedItem, durationDays);
      showToast(`Assigned "${selectedItem.name || selectedItem.title}" to ${verifiedDirectUser.fullname || verifiedDirectUser.name} successfully!`, 'success');
    } catch (e) {
      showToast('Assignment error: ' + e.message, 'error');
    } finally {
      btn.disabled = false;
      btn.innerHTML = '<i class="fa-solid fa-gift"></i> Assign Item Now';
    }
  };

  // Live Stream Assigned Items
  const tbody = document.getElementById('assigned-items-tbody');
  const searchFilter = document.getElementById('assigned-items-search');

  const unsub = db.collection('user_store_items').limit(200).onSnapshot(snap => {
    window._lastAssignedItemsCache = [];
    snap.forEach(doc => {
      window._lastAssignedItemsCache.push({ id: doc.id, ...doc.data() });
    });
    renderAssignedTableRows(tbody, window._lastAssignedItemsCache, searchFilter.value.trim().toLowerCase(), isEditable);
  }, err => {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading assignments: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);

  searchFilter.addEventListener('input', (e) => {
    if (window._lastAssignedItemsCache) {
      renderAssignedTableRows(tbody, window._lastAssignedItemsCache, e.target.value.trim().toLowerCase(), isEditable);
    }
  });
}

function renderAssignedTableRows(tbody, items, query, isEditable) {
  const filtered = items.filter(i => {
    const userDisplay = resolveUserDisplay(i.userId, i.userProfileId, i.userName, i.userSearchId, i.userAvatar);
    const searchId = (userDisplay.searchId || i.userProfileId || i.userId || '').toString().toLowerCase();
    const userName = (userDisplay.name || i.userName || '').toLowerCase();
    const itemName = (i.storeItemName || i.itemName || '').toLowerCase();
    return searchId.includes(query) || userName.includes(query) || itemName.includes(query);
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding: 30px; color: var(--text-muted);">No assigned store items found.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(i => {
    const isExpired = i.expiresAt ? (new Date() > new Date(i.expiresAt.toDate ? i.expiresAt.toDate() : i.expiresAt)) : false;
    const assignedDate = i.assignedAt ? new Date(i.assignedAt.toDate ? i.assignedAt.toDate() : i.assignedAt).toLocaleDateString() : 'N/A';
    const expireDate = i.expiresAt ? new Date(i.expiresAt.toDate ? i.expiresAt.toDate() : i.expiresAt).toLocaleDateString() : 'Permanent';
    
    const userDisplay = resolveUserDisplay(i.userId, i.userProfileId, i.userName, i.userSearchId, i.userAvatar);

    return `
      <tr>
        <td>
          <div style="display: flex; align-items: center; gap: 10px;">
            <img src="${userDisplay.avatar}" style="width: 38px; height: 38px; border-radius: 50%; object-fit: cover;" onerror="this.src='https://img.icons8.com/color/96/user-male-circle--v1.png'">
            <div>
              <div style="font-weight: 700; color: #fff; font-size: 13.5px;">${userDisplay.name}</div>
              <div style="font-size: 11px; font-weight: 700; color: var(--accent-cyan); font-family: monospace;">
                ID: ${userDisplay.searchId}
              </div>
            </div>
          </div>
        </td>
        <td><strong>${i.storeItemName || i.itemName || 'Store Item'}</strong></td>
        <td><span class="permission-tag tag-view">${(i.itemType || 'item').toUpperCase()}</span></td>
        <td style="color: var(--text-muted);">${assignedDate}</td>
        <td style="color: ${expireDate === 'Permanent' ? 'var(--accent-emerald)' : 'var(--text-main)'}; font-weight: 600;">${expireDate}</td>
        <td><span class="badge-status ${isExpired ? 'badge-banned' : 'badge-active'}">${isExpired ? 'Expired' : 'Active'}</span></td>
        <td style="text-align: right;">
          <button class="action-btn btn-sm-danger ${isEditable ? '' : 'btn-disabled'}" onclick="${isEditable ? `revokeAssignedItem('${i.id}')` : `showToast('View Only Mode', 'error')`}" title="Revoke Item">
            <i class="fa-solid fa-trash"></i> Remove
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

async function revokeAssignedItem(userStoreItemId) {
  if (!confirm('Are you sure you want to REVOKE and remove this item from the user?')) return;
  try {
    await db.collection('user_store_items').doc(userStoreItemId).delete();
    showToast('Store item removed from user successfully.', 'success');
  } catch (e) {
    showToast('Error removing item: ' + e.message, 'error');
  }
}

// Search user in DB
async function searchUserInDb(query) {
  if (!query) return null;
  const qStr = query.toString().trim();
  const qNum = parseInt(qStr);

  if (liveUsersMap[qStr]) return liveUsersMap[qStr];

  let qSnap = await db.collection('Users').where('searchId', '==', qStr).limit(1).get();
  if (!qSnap.empty) {
    updateUserCache(qSnap.docs[0]);
    return { id: qSnap.docs[0].id, ...qSnap.docs[0].data() };
  }

  if (!isNaN(qNum)) {
    qSnap = await db.collection('Users').where('searchId', '==', qNum).limit(1).get();
    if (!qSnap.empty) {
      updateUserCache(qSnap.docs[0]);
      return { id: qSnap.docs[0].id, ...qSnap.docs[0].data() };
    }
  }

  const doc = await db.collection('Users').doc(qStr).get();
  if (doc.exists) {
    updateUserCache(doc);
    return { id: doc.id, ...doc.data() };
  }

  qSnap = await db.collection('Users').where('phone', '==', qStr).limit(1).get();
  if (!qSnap.empty) {
    updateUserCache(qSnap.docs[0]);
    return { id: qSnap.docs[0].id, ...qSnap.docs[0].data() };
  }

  qSnap = await db.collection('Users').where('number', '==', qStr).limit(1).get();
  if (!qSnap.empty) {
    updateUserCache(qSnap.docs[0]);
    return { id: qSnap.docs[0].id, ...qSnap.docs[0].data() };
  }

  return null;
}

// Execute item assignment in Firestore
async function executeItemAssignment(user, item, durationDays) {
  const now = new Date();
  const expiresAt = durationDays === 0 ? null : new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
  const userStoreItemRef = db.collection('user_store_items').doc();

  const shortSearchId = (user.searchId || user.id).toString();
  const userName = user.fullname || user.name || 'User';
  const userAvatar = user.profileImage || '';

  const itemData = {
    userId: user.id,
    userProfileId: shortSearchId,
    userSearchId: shortSearchId,
    userName: userName,
    userAvatar: userAvatar,
    storeItemId: item.id,
    storeItemName: item.name || item.title || 'Official Item',
    itemType: item.type || item.category || 'avatarFrame',
    assignedAt: firebase.firestore.FieldValue.serverTimestamp(),
    expiresAt: expiresAt ? firebase.firestore.Timestamp.fromDate(expiresAt) : null,
    isActive: true,
    assignedBy: currentAdmin.name || currentAdmin.email
  };

  await userStoreItemRef.set(itemData);

  // Log to super_admin_assign_history
  await db.collection('super_admin_assign_history').add({
    actionType: 'Assigned Store Item (' + (item.type || 'Item') + ')',
    assignedByAdminId: currentAdmin.id || 'official_admin',
    assignedByAdminName: currentAdmin.name || currentAdmin.email || 'Sub Official Admin',
    assignedItems: [item.name || item.title || 'Item'],
    dateString: new Date().toISOString(),
    details: `Assigned ${(item.type || 'Item')}: "${item.name || item.title}" for ${durationDays === 0 ? 'Permanent' : durationDays + ' days'} to ${userName} (ID: ${shortSearchId})`,
    targetPhone: (user.phone || user.number || '').toString(),
    targetUserId: user.id,
    targetUserName: userName,
    timestamp: firebase.firestore.FieldValue.serverTimestamp()
  }).catch(() => {});
}

// ==========================================================================
// 3. Users Management View (Full Real-time List & Controls)
// ==========================================================================
function renderUsersView(container, moduleKey) {
  const isEditable = canEdit(moduleKey);

  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-users" style="color: var(--primary);"></i> Live Users Database</h3>
          <span class="badge-status ${isEditable ? 'badge-active' : 'badge-locked'}">
            ${isEditable ? '✏️ Editor Mode' : '👁️ View Only Mode'}
          </span>
        </div>
        <div class="panel-actions">
          <div class="search-box">
            <i class="fa-solid fa-search"></i>
            <input type="text" id="user-search-input" placeholder="Search by name, searchId or phone...">
          </div>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>User</th>
              <th>Search ID</th>
              <th>Diamonds Balance</th>
              <th>User Type</th>
              <th>Status</th>
              <th style="text-align: right;">Actions</th>
            </tr>
          </thead>
          <tbody id="users-table-body">
            <tr><td colspan="6" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Streaming real-time users...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  const tbody = document.getElementById('users-table-body');
  const searchInput = document.getElementById('user-search-input');
  let allUsersCache = [];

  const unsub = db.collection('Users').limit(150).onSnapshot(snapshot => {
    allUsersCache = [];
    snapshot.forEach(doc => {
      updateUserCache(doc);
      allUsersCache.push({ id: doc.id, ...doc.data() });
    });
    filterAndRenderUsers(searchInput.value.trim().toLowerCase(), tbody, isEditable, allUsersCache);
  }, err => {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading users: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);

  searchInput.addEventListener('input', (e) => {
    filterAndRenderUsers(e.target.value.trim().toLowerCase(), tbody, isEditable, allUsersCache);
  });
}

function filterAndRenderUsers(query, tbody, isEditable, users) {
  const filtered = users.filter(u => {
    const name = (u.fullname || u.name || '').toLowerCase();
    const searchId = (u.searchId || '').toString().toLowerCase();
    const phone = (u.phoneNumber || u.phone || u.number || '').toString().toLowerCase();
    const uid = (u.id || '').toLowerCase();
    return name.includes(query) || searchId.includes(query) || phone.includes(query) || uid.includes(query);
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding: 30px; color: var(--text-muted);">No users found matching query.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered.map(u => {
    const name = u.fullname || u.name || 'Unnamed User';
    const avatar = u.profileImage || 'https://img.icons8.com/color/96/user-male-circle--v1.png';
    const searchId = u.searchId || u.id.substring(0, 8);
    const diamonds = (u.diamonds || u.diamondBalance || 0).toLocaleString();
    const isBanned = u.isBanned === true;
    const userType = (u.userType || 'regular').toUpperCase();

    return `
      <tr>
        <td>
          <div style="display: flex; align-items: center; gap: 10px;">
            <img src="${avatar}" style="width: 36px; height: 36px; border-radius: 50%; object-fit: cover;" onerror="this.src='https://img.icons8.com/color/96/user-male-circle--v1.png'">
            <div>
              <div style="font-weight: 600;">${name}</div>
              <div style="font-size: 11px; color: var(--text-dim);">${u.id}</div>
            </div>
          </div>
        </td>
        <td><span style="font-family: monospace; font-weight: 700; color: var(--accent-cyan);">ID: ${searchId}</span></td>
        <td><strong style="color: #60a5fa;"><i class="fa-solid fa-gem" style="font-size: 11px; margin-right: 4px;"></i>${diamonds}</strong></td>
        <td><span class="permission-tag tag-view">${userType}</span></td>
        <td><span class="badge-status ${isBanned ? 'badge-banned' : 'badge-active'}">${isBanned ? 'Banned' : 'Active'}</span></td>
        <td style="text-align: right;">
          <div style="display: inline-flex; gap: 6px;">
            <button class="action-btn btn-sm-primary" onclick="openAssignModalForUser('${u.id}', '${escapeQuotes(name)}', '${searchId}', '${u.profileImage || ''}')" title="Assign Official Item">
              <i class="fa-solid fa-wand-magic-sparkles"></i> Assign
            </button>
            <button class="action-btn btn-sm-emerald ${isEditable ? '' : 'btn-disabled'}" onclick="${isEditable ? `openEditUserModal('${u.id}')` : `showToast('View Only Mode', 'error')`}" title="Edit Profile Details">
              <i class="fa-solid fa-user-pen"></i> Edit
            </button>
            <button class="action-btn btn-sm-primary ${isEditable ? '' : 'btn-disabled'}" onclick="${isEditable ? `openAdjustDiamondsModal('${u.id}', '${escapeQuotes(name)}', ${u.diamonds || 0})` : `showToast('View Only Mode', 'error')`}" title="Recharge/Deduct Diamonds">
              <i class="fa-solid fa-gem"></i>
            </button>
            <button class="action-btn ${isBanned ? 'btn-sm-emerald' : 'btn-sm-danger'} ${isEditable ? '' : 'btn-disabled'}" onclick="${isEditable ? `toggleUserBan('${u.id}', ${isBanned})` : `showToast('View Only Mode', 'error')`}" title="${isBanned ? 'Unban' : 'Ban'}">
              <i class="fa-solid ${isBanned ? 'fa-unlock' : 'fa-ban'}"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

function escapeQuotes(str) {
  return (str || '').replace(/'/g, "\\'").replace(/"/g, '&quot;');
}

// Quick assign modal open pre-filled with user
function openAssignModalForUser(uid, name, searchId, avatar) {
  targetAssignUser = { id: uid, fullname: name, name: name, searchId: searchId, profileImage: avatar };
  document.getElementById('assign-user-search-input').value = searchId || uid;
  document.getElementById('assign-found-user-avatar').src = avatar || 'https://img.icons8.com/color/96/user-male-circle--v1.png';
  document.getElementById('assign-found-user-name').textContent = name;
  document.getElementById('assign-found-user-searchid').textContent = searchId;
  document.getElementById('assign-found-user-uid').textContent = uid;
  document.getElementById('assign-found-user-card').style.display = 'block';

  loadUserCurrentItemsInModal(uid);
  openModal('modal-assign-item');
}

async function handleSearchAssignUser() {
  const query = document.getElementById('assign-user-search-input').value.trim();
  if (!query) {
    showToast('Enter a Search ID or User UID', 'error');
    return;
  }

  try {
    const user = await searchUserInDb(query);
    if (user) {
      targetAssignUser = user;
      document.getElementById('assign-found-user-avatar').src = user.profileImage || 'https://img.icons8.com/color/96/user-male-circle--v1.png';
      document.getElementById('assign-found-user-name').textContent = user.fullname || user.name || 'User';
      document.getElementById('assign-found-user-searchid').textContent = user.searchId || user.id;
      document.getElementById('assign-found-user-uid').textContent = user.id;
      document.getElementById('assign-found-user-card').style.display = 'block';
      loadUserCurrentItemsInModal(user.id);
      showToast('User found!', 'success');
    } else {
      showToast('No user found matching: ' + query, 'error');
      document.getElementById('assign-found-user-card').style.display = 'none';
      targetAssignUser = null;
    }
  } catch (e) {
    showToast('Search error: ' + e.message, 'error');
  }
}

async function loadUserCurrentItemsInModal(userId) {
  const box = document.getElementById('user-current-items-box');
  const list = document.getElementById('user-current-items-list');
  box.style.display = 'block';
  list.innerHTML = '<div style="font-size: 12px; color: var(--text-muted);"><i class="fa-solid fa-spinner fa-spin"></i> Loading user items...</div>';

  try {
    const snap = await db.collection('user_store_items').where('userId', '==', userId).get();
    if (snap.empty) {
      list.innerHTML = '<div style="font-size: 12px; color: var(--text-muted);">No active items equipped by this user.</div>';
      return;
    }

    list.innerHTML = snap.docs.map(doc => {
      const itm = doc.data();
      const exp = itm.expiresAt ? new Date(itm.expiresAt.toDate ? itm.expiresAt.toDate() : itm.expiresAt).toLocaleDateString() : 'Permanent';
      return `
        <div style="display: flex; align-items: center; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid var(--border-color); font-size: 12px;">
          <div>
            <strong>${itm.storeItemName || 'Item'}</strong> (${itm.itemType || 'Frame'})
            <span style="color: var(--text-dim); margin-left: 8px;">Expires: ${exp}</span>
          </div>
          <button class="action-btn btn-sm-danger" style="padding: 2px 8px; font-size: 10px;" onclick="revokeAssignedItem('${doc.id}'); loadUserCurrentItemsInModal('${userId}');">
            Revoke
          </button>
        </div>
      `;
    }).join('');
  } catch (e) {
    list.innerHTML = '<div style="font-size: 12px; color: var(--accent-rose);">Failed to load user items.</div>';
  }
}

async function handleConfirmAssignItem() {
  if (!targetAssignUser) {
    showToast('Please find and select a target user first.', 'error');
    return;
  }

  const itemId = document.getElementById('assign-item-select').value;
  if (!itemId) {
    showToast('Please choose an item to assign.', 'error');
    return;
  }

  const item = cachedOfficialItems.find(i => i.id === itemId);
  if (!item) {
    showToast('Item not found.', 'error');
    return;
  }

  const duration = parseInt(document.getElementById('assign-duration-select').value);
  const btn = document.getElementById('btn-confirm-assign-item');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Assigning...';

  try {
    await executeItemAssignment(targetAssignUser, item, duration);
    showToast(`Assigned ${item.name || item.title} successfully!`, 'success');
    closeModal('modal-assign-item');
  } catch (e) {
    showToast('Error: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-gift"></i> Confirm & Assign Item';
  }
}

// Edit User Details
async function openEditUserModal(userId) {
  try {
    const doc = await db.collection('Users').doc(userId).get();
    if (!doc.exists) {
      showToast('User not found.', 'error');
      return;
    }
    const data = doc.data();
    document.getElementById('edit-user-uid').value = doc.id;
    document.getElementById('edit-user-fullname').value = data.fullname || data.name || '';
    document.getElementById('edit-user-username').value = data.username || '';
    document.getElementById('edit-user-searchid').value = data.searchId !== undefined ? data.searchId : '';
    document.getElementById('edit-user-phone').value = data.phone || data.number || '';
    document.getElementById('edit-user-usertype').value = data.userType || 'regular';
    document.getElementById('edit-user-banstatus').value = data.isBanned === true ? 'banned' : 'active';
    openModal('modal-edit-user');
  } catch (e) {
    showToast('Error loading user: ' + e.message, 'error');
  }
}

async function handleSaveUserDetails() {
  const uid = document.getElementById('edit-user-uid').value;
  if (!uid) return;

  const fullname = document.getElementById('edit-user-fullname').value.trim();
  const username = document.getElementById('edit-user-username').value.trim();
  const searchId = document.getElementById('edit-user-searchid').value.trim();
  const phone = document.getElementById('edit-user-phone').value.trim();
  const userType = document.getElementById('edit-user-usertype').value;
  const isBanned = document.getElementById('edit-user-banstatus').value === 'banned';

  const btn = document.getElementById('btn-confirm-save-user-details');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';

  try {
    await db.collection('Users').doc(uid).update({
      fullname: fullname,
      username: username,
      searchId: searchId,
      phone: phone,
      number: phone,
      userType: userType,
      isBanned: isBanned,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    showToast('User details updated successfully!', 'success');
    closeModal('modal-edit-user');
  } catch (e) {
    showToast('Error saving user: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = 'Save Changes';
  }
}

// ==========================================================================
// 4. Voice Rooms Moderation View
// ==========================================================================
function renderRoomsView(container, moduleKey) {
  const isEditable = canEdit(moduleKey);

  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-microphone" style="color: var(--accent-emerald);"></i> Live Voice Rooms</h3>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>Room</th>
              <th>Host ID</th>
              <th>Active Members</th>
              <th>Status</th>
              <th style="text-align: right;">Moderation</th>
            </tr>
          </thead>
          <tbody id="rooms-table-body">
            <tr><td colspan="5" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Listening to live rooms...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  const tbody = document.getElementById('rooms-table-body');
  const unsub = db.collection('Rooms').onSnapshot(snapshot => {
    if (snapshot.empty) {
      tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 30px; color: var(--text-muted);">No active voice rooms found in database.</td></tr>`;
      return;
    }

    tbody.innerHTML = snapshot.docs.map(doc => {
      const r = doc.data();
      const title = r.roomName || r.title || 'Voice Room';
      const host = r.hostId || r.ownerId || 'N/A';
      const members = r.memberCount || r.activeMembers || 0;
      const isLocked = r.isLocked === true || r.isBanned === true;

      return `
        <tr>
          <td>
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 36px; height: 36px; background: rgba(16, 185, 129, 0.15); border-radius: 8px; display: flex; align-items: center; justify-content: center; color: var(--accent-emerald);">
                <i class="fa-solid fa-microphone-lines"></i>
              </div>
              <div>
                <div style="font-weight: 600;">${title}</div>
                <div style="font-size: 11px; color: var(--text-dim);">${doc.id}</div>
              </div>
            </div>
          </td>
          <td><span style="font-family: monospace;">${host}</span></td>
          <td><span class="badge-status badge-active"><i class="fa-solid fa-user-group"></i> ${members}</span></td>
          <td><span class="badge-status ${isLocked ? 'badge-locked' : 'badge-active'}">${isLocked ? 'Locked / Banned' : 'Live'}</span></td>
          <td style="text-align: right;">
            <button class="action-btn ${isLocked ? 'btn-sm-emerald' : 'btn-sm-danger'} ${isEditable ? '' : 'btn-disabled'}" onclick="${isEditable ? `toggleRoomLock('${doc.id}', ${isLocked})` : `showToast('View Only Mode', 'error')`}">
              <i class="fa-solid ${isLocked ? 'fa-lock-open' : 'fa-lock'}"></i> ${isLocked ? 'Unlock Room' : 'Lock / Terminate'}
            </button>
          </td>
        </tr>
      `;
    }).join('');
  }, err => {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading rooms: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// 5. Gifts & Store View
// ==========================================================================
function renderGiftsView(container, moduleKey) {
  const isEditable = canEdit(moduleKey);

  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-gift" style="color: var(--accent-amber);"></i> Virtual Gifts Catalog</h3>
        </div>
        <div class="panel-actions">
          ${isEditable ? `<button class="action-btn btn-sm-primary" onclick="openModal('modal-add-gift')"><i class="fa-solid fa-plus"></i> Add New Gift</button>` : ''}
        </div>
      </div>
      <div style="padding: 24px;">
        <div id="gifts-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 16px;">
          <div><i class="fa-solid fa-spinner fa-spin"></i> Loading gifts...</div>
        </div>
      </div>
    </div>
  `;

  const grid = document.getElementById('gifts-grid');
  const unsub = db.collection('Gifts').onSnapshot(snapshot => {
    if (snapshot.empty) {
      grid.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 30px;">No gifts found in catalog.</div>`;
      return;
    }

    grid.innerHTML = snapshot.docs.map(doc => {
      const g = doc.data();
      const img = g.image || g.icon || g.fileUrl || 'https://img.icons8.com/color/96/gift--v1.png';
      const price = (g.price || g.diamondPrice || 0).toLocaleString();

      return `
        <div style="background: var(--bg-input); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 16px; text-align: center;">
          <img src="${img}" style="width: 60px; height: 60px; object-fit: contain; margin: 0 auto 10px;" onerror="this.src='https://img.icons8.com/color/96/gift--v1.png'">
          <div style="font-weight: 700; font-size: 14px; margin-bottom: 4px;">${g.name || g.title || 'Gift'}</div>
          <div style="color: #60a5fa; font-weight: 700; font-size: 13px; margin-bottom: 12px;"><i class="fa-solid fa-gem"></i> ${price}</div>
          <div style="display: flex; justify-content: center; gap: 6px;">
            <span class="permission-tag tag-view">${(g.category || 'Popular').toUpperCase()}</span>
            ${isEditable ? `<button class="action-btn btn-sm-danger" style="padding: 2px 8px;" onclick="deleteGift('${doc.id}')"><i class="fa-solid fa-trash"></i></button>` : ''}
          </div>
        </div>
      `;
    }).join('');
  }, err => {
    grid.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--accent-rose); padding: 30px;">Error loading gifts: ${err.message}</div>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// 6. Diamonds Management View
// ==========================================================================
function renderDiamondsView(container, moduleKey) {
  renderUsersView(container, moduleKey);
}

// ==========================================================================
// 7. Banners Management View
// ==========================================================================
function renderBannersView(container, moduleKey) {
  const isEditable = canEdit(moduleKey);

  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-images" style="color: var(--accent-cyan);"></i> In-App Promotional Banners</h3>
        </div>
        <div class="panel-actions">
          ${isEditable ? `<button class="action-btn btn-sm-primary" onclick="openModal('modal-add-banner')"><i class="fa-solid fa-plus"></i> Add New Banner</button>` : ''}
        </div>
      </div>
      <div style="padding: 24px;">
        <div id="banners-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 18px;">
          <div><i class="fa-solid fa-spinner fa-spin"></i> Loading banners...</div>
        </div>
      </div>
    </div>
  `;

  const grid = document.getElementById('banners-grid');
  const unsub = db.collection('banners').onSnapshot(snapshot => {
    if (snapshot.empty) {
      grid.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 30px;">No promotional banners found.</div>`;
      return;
    }

    grid.innerHTML = snapshot.docs.map(doc => {
      const b = doc.data();
      const img = b.imageUrl || b.bannerUrl || 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500';
      const title = b.title || 'In-App Banner';
      const isActive = b.isActive !== false;

      return `
        <div style="background: var(--bg-input); border: 1px solid var(--border-color); border-radius: var(--radius-md); overflow: hidden;">
          <img src="${img}" style="width: 100%; height: 140px; object-fit: cover;" onerror="this.src='https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500'">
          <div style="padding: 14px;">
            <div style="font-weight: 600; margin-bottom: 8px;">${title}</div>
            <div style="display: flex; align-items: center; justify-content: space-between;">
              <span class="badge-status ${isActive ? 'badge-active' : 'badge-banned'}">${isActive ? 'Active' : 'Inactive'}</span>
              ${isEditable ? `
                <button class="action-btn btn-sm-danger" onclick="deleteBanner('${doc.id}')" title="Delete"><i class="fa-solid fa-trash"></i></button>
              ` : ''}
            </div>
          </div>
        </div>
      `;
    }).join('');
  }, err => {
    grid.innerHTML = `<div style="grid-column: 1/-1; text-align: center; color: var(--accent-rose); padding: 30px;">Error loading banners: ${err.message}</div>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// 8. Banned Users View
// ==========================================================================
function renderBannedUsersView(container, moduleKey) {
  const isEditable = canEdit(moduleKey);

  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-user-slash" style="color: var(--accent-rose);"></i> Banned Users Database</h3>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>User</th>
              <th>Search ID</th>
              <th>Status</th>
              <th style="text-align: right;">Action</th>
            </tr>
          </thead>
          <tbody id="banned-table-body">
            <tr><td colspan="4" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Loading banned list...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  const tbody = document.getElementById('banned-table-body');
  const unsub = db.collection('Users').where('isBanned', '==', true).onSnapshot(snapshot => {
    if (snapshot.empty) {
      tbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--text-muted);">No banned users currently in system.</td></tr>`;
      return;
    }

    tbody.innerHTML = snapshot.docs.map(doc => {
      const u = doc.data();
      const name = u.fullname || u.name || 'User';
      const avatar = u.profileImage || 'https://img.icons8.com/color/96/user-male-circle--v1.png';
      const searchId = u.searchId || doc.id.substring(0, 8);

      return `
        <tr>
          <td>
            <div style="display: flex; align-items: center; gap: 10px;">
              <img src="${avatar}" style="width: 36px; height: 36px; border-radius: 50%; object-fit: cover;" onerror="this.src='https://img.icons8.com/color/96/user-male-circle--v1.png'">
              <div>
                <div style="font-weight: 700; color: #fff;">${name}</div>
                <div style="font-size: 11px; color: var(--text-dim);">${doc.id}</div>
              </div>
            </div>
          </td>
          <td><strong style="color: var(--accent-cyan); font-family: monospace;">ID: ${searchId}</strong></td>
          <td><span class="badge-status badge-banned">Banned</span></td>
          <td style="text-align: right;">
            <button class="action-btn btn-sm-emerald ${isEditable ? '' : 'btn-disabled'}" onclick="${isEditable ? `toggleUserBan('${doc.id}', true)` : `showToast('View Only Mode', 'error')`}">
              <i class="fa-solid fa-unlock"></i> Unban User
            </button>
          </td>
        </tr>
      `;
    }).join('');
  }, err => {
    tbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading banned list: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// 9. Agencies View
// ==========================================================================
function renderAgencyView(container, moduleKey) {
  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-building" style="color: var(--primary);"></i> Live Agencies</h3>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>Agency Name</th>
              <th>Owner ID</th>
              <th>Commission Rate</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody id="agency-table-body">
            <tr><td colspan="4" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Loading agencies...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  const tbody = document.getElementById('agency-table-body');
  const unsub = db.collection('agency').onSnapshot(snapshot => {
    if (snapshot.empty) {
      tbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--text-muted);">No agencies registered yet.</td></tr>`;
      return;
    }

    tbody.innerHTML = snapshot.docs.map(doc => {
      const a = doc.data();
      return `
        <tr>
          <td><strong>${a.name || a.agencyName || 'Agency'}</strong></td>
          <td><span style="font-family: monospace;">${a.ownerId || a.userId || '-'}</span></td>
          <td><span class="permission-tag tag-view">${a.commissionRate || a.commission || '10'}%</span></td>
          <td><span class="badge-status badge-active">Approved</span></td>
        </tr>
      `;
    }).join('');
  }, err => {
    tbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading agencies: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// 10. Levels View
// ==========================================================================
function renderLevelsView(container, moduleKey) {
  container.innerHTML = `
    <div class="panel-card" style="padding: 28px;">
      <h3><i class="fa-solid fa-ranking-star" style="color: var(--accent-amber); margin-right: 8px;"></i> ${moduleKey} Control Hub</h3>
      <p style="color: var(--text-muted); margin-top: 8px;">Active user level calculation, experience multipliers & rewards configuration.</p>
      <div style="margin-top: 24px; display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px;">
        <div class="stat-card"><div class="stat-icon blue"><i class="fa-solid fa-layer-group"></i></div><div><div class="stat-val">Level 1 - 100</div><div class="stat-label">User Levels</div></div></div>
        <div class="stat-card"><div class="stat-icon amber"><i class="fa-solid fa-crown"></i></div><div><div class="stat-val">VIP 1 - 10</div><div class="stat-label">VIP Tiers</div></div></div>
        <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-heart"></i></div><div><div class="stat-val">1 - 50</div><div class="stat-label">Intimacy Levels</div></div></div>
      </div>
    </div>
  `;
}

// ==========================================================================
// 11. Games View
// ==========================================================================
function renderGamesView(container, moduleKey) {
  container.innerHTML = `
    <div class="panel-card" style="padding: 28px;">
      <h3><i class="fa-solid fa-gamepad" style="color: var(--accent-purple); margin-right: 8px;"></i> ${moduleKey}</h3>
      <p style="color: var(--text-muted); margin-top: 8px;">Real-time room games, lucky wheel, fruit slot & profit distributions.</p>
      <div style="margin-top: 24px; display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px;">
        <div class="stat-card"><div class="stat-icon purple"><i class="fa-solid fa-dice"></i></div><div><div class="stat-val">Greedy Slot</div><div class="stat-label">Active Game</div></div></div>
        <div class="stat-card"><div class="stat-icon green"><i class="fa-solid fa-chart-line"></i></div><div><div class="stat-val">95.5%</div><div class="stat-label">RTP Margin</div></div></div>
      </div>
    </div>
  `;
}

// ==========================================================================
// 12. Assignment History View (Audit Log)
// ==========================================================================
function renderAssignHistoryView(container) {
  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-clock-rotate-left" style="color: var(--accent-purple);"></i> Real-time Assignment & Action Audit History</h3>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>Action Type</th>
              <th>Target User</th>
              <th>Assigned Items / Details</th>
              <th>Assigned By</th>
              <th>Timestamp</th>
            </tr>
          </thead>
          <tbody id="history-table-body">
            <tr><td colspan="5" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Streaming audit logs...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  const tbody = document.getElementById('history-table-body');
  const unsub = db.collection('super_admin_assign_history').limit(50).onSnapshot(snapshot => {
    if (snapshot.empty) {
      tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 30px; color: var(--text-muted);">No assignment audit records yet.</td></tr>`;
      return;
    }

    tbody.innerHTML = snapshot.docs.map(doc => {
      const h = doc.data();
      const date = h.timestamp ? new Date(h.timestamp.toDate ? h.timestamp.toDate() : h.timestamp).toLocaleString() : (h.dateString || 'N/A');
      const userDisplay = resolveUserDisplay(h.targetUserId, null, h.targetUserName, null);

      return `
        <tr>
          <td><strong style="color: var(--accent-cyan);">${h.actionType || 'Item Assignment'}</strong></td>
          <td>
            <div style="display: flex; align-items: center; gap: 8px;">
              <img src="${userDisplay.avatar}" style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover;" onerror="this.src='https://img.icons8.com/color/96/user-male-circle--v1.png'">
              <div>
                <strong>${userDisplay.name}</strong> <span style="font-size: 11px; color: var(--accent-cyan); font-family: monospace;">(ID: ${userDisplay.searchId})</span>
              </div>
            </div>
          </td>
          <td style="max-width: 320px;">${h.details || (h.assignedItems || []).join(', ') || '-'}</td>
          <td><span class="permission-tag tag-view">${h.assignedByAdminName || 'Sub Admin'}</span></td>
          <td style="color: var(--text-dim);">${date}</td>
        </tr>
      `;
    }).join('');
  }, err => {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading audit logs: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// 13. User Feedbacks View
// ==========================================================================
function renderFeedbackView(container) {
  container.innerHTML = `
    <div class="panel-card">
      <div class="panel-header">
        <div class="panel-title-group">
          <h3><i class="fa-solid fa-comments" style="color: var(--accent-purple);"></i> User Feedback Reports</h3>
        </div>
      </div>
      <div class="data-table-container">
        <table class="data-table">
          <thead>
            <tr>
              <th>User</th>
              <th>Category</th>
              <th>Message</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody id="feedback-table-body">
            <tr><td colspan="4" style="text-align:center; padding: 30px;"><i class="fa-solid fa-spinner fa-spin"></i> Loading feedbacks...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  `;

  const tbody = document.getElementById('feedback-table-body');
  const unsub = db.collection('Feedback').limit(50).onSnapshot(snapshot => {
    if (snapshot.empty) {
      tbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--text-muted);">No feedback records found.</td></tr>`;
      return;
    }

    tbody.innerHTML = snapshot.docs.map(doc => {
      const f = doc.data();
      const userDisplay = resolveUserDisplay(f.userId, null, null, null);

      return `
        <tr>
          <td>
            <div style="display: flex; align-items: center; gap: 8px;">
              <img src="${userDisplay.avatar}" style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover;" onerror="this.src='https://img.icons8.com/color/96/user-male-circle--v1.png'">
              <div>
                <strong>${userDisplay.name}</strong> <span style="font-size: 11px; color: var(--accent-cyan); font-family: monospace;">(ID: ${userDisplay.searchId})</span>
              </div>
            </div>
          </td>
          <td><strong style="color: var(--accent-cyan);">${f.category || f.subject || 'General'}</strong></td>
          <td style="max-width: 350px;">${f.message || f.feedback || 'No content'}</td>
          <td style="color: var(--text-dim);">${f.timestamp ? new Date(f.timestamp.toDate ? f.timestamp.toDate() : f.timestamp).toLocaleString() : 'N/A'}</td>
        </tr>
      `;
    }).join('');
  }, err => {
    tbody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 30px; color: var(--accent-rose);">Error loading feedbacks: ${err.message}</td></tr>`;
  });
  activeUnsubscribers.push(unsub);
}

// ==========================================================================
// Action Operations (Real-time Firestore updates)
// ==========================================================================
function openAdjustDiamondsModal(userId, userName, currentBalance) {
  targetUserForAction = { userId, userName, currentBalance };
  document.getElementById('modal-target-username').textContent = userName;
  document.getElementById('modal-target-userid').textContent = userId;
  document.getElementById('modal-diamond-amount').value = '';
  document.getElementById('modal-diamond-note').value = '';
  openModal('modal-adjust-diamonds');
}

async function handleDiamondAdjustment() {
  if (!targetUserForAction) return;

  const type = document.getElementById('modal-diamond-action-type').value;
  const amount = parseInt(document.getElementById('modal-diamond-amount').value.trim());
  const note = document.getElementById('modal-diamond-note').value.trim() || 'Sub-Admin Adjustment';

  if (isNaN(amount) || amount <= 0) {
    showToast('Please enter a valid diamond amount.', 'error');
    return;
  }

  const btn = document.getElementById('btn-confirm-adjust-diamonds');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Updating...';

  try {
    const userRef = db.collection('Users').doc(targetUserForAction.userId);
    const doc = await userRef.get();
    if (!doc.exists) throw new Error('User document does not exist.');

    const currentDiamonds = doc.data().diamonds || doc.data().diamondBalance || 0;
    const newDiamonds = type === 'add' ? (currentDiamonds + amount) : Math.max(0, currentDiamonds - amount);

    await userRef.update({
      diamonds: newDiamonds,
      diamondBalance: newDiamonds,
      lastDiamondUpdated: firebase.firestore.FieldValue.serverTimestamp()
    });

    await db.collection('DiamondTransactions').add({
      userId: targetUserForAction.userId,
      amount: type === 'add' ? amount : -amount,
      type: type === 'add' ? 'Admin_Recharge' : 'Admin_Deduction',
      performedBy: currentAdmin.name || currentAdmin.email,
      note: note,
      timestamp: firebase.firestore.FieldValue.serverTimestamp()
    });

    showToast(`Diamonds ${type === 'add' ? 'added' : 'deducted'} successfully! (New Balance: ${newDiamonds.toLocaleString()})`, 'success');
    closeModal('modal-adjust-diamonds');
  } catch (e) {
    showToast('Error updating diamonds: ' + e.message, 'error');
  } finally {
    btn.disabled = false;
    btn.innerHTML = 'Save & Update';
  }
}

async function toggleUserBan(userId, currentBanned) {
  const newStatus = !currentBanned;
  const confirmMsg = newStatus ? 'Are you sure you want to BAN this user?' : 'Are you sure you want to UNBAN this user?';
  if (!confirm(confirmMsg)) return;

  try {
    await db.collection('Users').doc(userId).update({
      isBanned: newStatus,
      bannedAt: newStatus ? firebase.firestore.FieldValue.serverTimestamp() : null,
      bannedBy: newStatus ? (currentAdmin.name || currentAdmin.email) : null
    });
    showToast(`User ${newStatus ? 'BANNED' : 'UNBANNED'} successfully.`, 'success');
  } catch (e) {
    showToast('Error updating ban status: ' + e.message, 'error');
  }
}

async function toggleRoomLock(roomId, currentLocked) {
  const newStatus = !currentLocked;
  try {
    await db.collection('Rooms').doc(roomId).update({
      isLocked: newStatus,
      isBanned: newStatus,
      moderatedBy: currentAdmin.name || currentAdmin.email
    });
    showToast(`Room ${newStatus ? 'LOCKED' : 'UNLOCKED'} successfully.`, 'success');
  } catch (e) {
    showToast('Error moderating room: ' + e.message, 'error');
  }
}

async function handleAddBannerSubmit() {
  const title = document.getElementById('modal-banner-title').value.trim();
  const imageUrl = document.getElementById('modal-banner-image-url').value.trim();
  const actionUrl = document.getElementById('modal-banner-action-url').value.trim();

  if (!title || !imageUrl) {
    showToast('Please provide both a title and an image URL.', 'error');
    return;
  }

  try {
    await db.collection('banners').add({
      title: title,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      isActive: true,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      createdBy: currentAdmin.name || currentAdmin.email
    });
    showToast('Banner created successfully!', 'success');
    closeModal('modal-add-banner');
  } catch (e) {
    showToast('Error adding banner: ' + e.message, 'error');
  }
}

async function deleteBanner(bannerId) {
  if (!confirm('Are you sure you want to delete this banner?')) return;
  try {
    await db.collection('banners').doc(bannerId).delete();
    showToast('Banner deleted successfully.', 'success');
  } catch (e) {
    showToast('Error deleting banner: ' + e.message, 'error');
  }
}

async function handleAddGiftSubmit() {
  const name = document.getElementById('modal-gift-name').value.trim();
  const price = parseInt(document.getElementById('modal-gift-price').value.trim());
  const icon = document.getElementById('modal-gift-icon-url').value.trim();
  const category = document.getElementById('modal-gift-category').value;

  if (!name || isNaN(price)) {
    showToast('Please enter a gift name and price.', 'error');
    return;
  }

  try {
    await db.collection('Gifts').add({
      name: name,
      price: price,
      diamondPrice: price,
      image: icon || 'https://img.icons8.com/color/96/gift--v1.png',
      icon: icon || 'https://img.icons8.com/color/96/gift--v1.png',
      category: category,
      isActive: true,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    showToast('New gift created successfully!', 'success');
    closeModal('modal-add-gift');
  } catch (e) {
    showToast('Error creating gift: ' + e.message, 'error');
  }
}

async function deleteGift(giftId) {
  if (!confirm('Are you sure you want to delete this gift?')) return;
  try {
    await db.collection('Gifts').doc(giftId).delete();
    showToast('Gift deleted successfully.', 'success');
  } catch (e) {
    showToast('Error deleting gift: ' + e.message, 'error');
  }
}

// Helpers
function openModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.add('active');
}

function closeModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove('active');
}

function showToast(msg, type = 'success') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <i class="fa-solid ${type === 'success' ? 'fa-circle-check' : 'fa-circle-exclamation'}"></i>
    <span>${msg}</span>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}
