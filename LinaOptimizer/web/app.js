const tweakGrid = document.getElementById('tweakGrid');
const systemLog = document.getElementById('systemLog');
const hardwareInfo = document.getElementById('hardwareInfo');
const categoryBar = document.getElementById('categoryBar');
const gamesGrid = document.getElementById('gamesGrid');
const langSelect = document.getElementById('langSelect');
const selectedTweaks = new Set();

const translations = {
  'pt-BR': {
    navHome: 'Início',
    navPanel: 'Painel',
    navGames: 'Jogos',
    navSupport: 'Suporte',
    heroTag: 'Localhost',
    heroTitle: 'OTIMIZAÇÃO TOTAL',
    heroSubtitle: 'WINDOWS & GAMES',
    heroDesc: 'Controle todas as otimizações via painel local. Cada tweak com descrição, risco e aplicação segura.',
    community: 'Comunidade',
    applyTweaks: 'Aplicar Tweaks',
    refreshHardware: 'Atualizar Hardware',
    hardwareLoading: 'Carregando hardware...',
    panelTitle: 'Seleção de Tweaks',
    panelLabel: 'PAINEL TÉCNICO',
    gameLabel: 'GAME CENTER',
    gameTitle: 'Otimização de Jogos',
    systemLog: 'Logs aparecerão aqui.',
    footerDesc: 'Painel local para otimizações avançadas. Use com cautela.',
    footerCredits: 'Créditos',
    footerResponsible: 'Uso responsável',
    footerCopyright: '© 2024 LinaOptimizer. Créditos: Lina Tweaks.',
    groups: {
      all: 'Todos',
      cpu: 'CPU',
      gpu: 'GPU',
      games: 'Jogos',
      internet: 'Internet',
      extra: 'Extra',
      kernel: 'Kernel',
      system: 'Sistema',
      debloat: 'Debloat'
    },
    quality: { low: 'Baixo', medium: 'Médio', high: 'Alto', apply: 'Aplicar', revert: 'Reverter' }
  },
  'en-US': {
    navHome: 'Home',
    navPanel: 'Panel',
    navGames: 'Games',
    navSupport: 'Support',
    heroTag: 'Localhost',
    heroTitle: 'TOTAL OPTIMIZATION',
    heroSubtitle: 'WINDOWS & GAMES',
    heroDesc: 'Control all optimizations locally. Each tweak with description, risk and safe apply.',
    community: 'Community',
    applyTweaks: 'Apply Tweaks',
    refreshHardware: 'Refresh Hardware',
    hardwareLoading: 'Loading hardware...',
    panelTitle: 'Tweak Selection',
    panelLabel: 'TECH PANEL',
    gameLabel: 'GAME CENTER',
    gameTitle: 'Game Optimization',
    systemLog: 'Logs will appear here.',
    footerDesc: 'Local panel for advanced optimizations. Use with care.',
    footerCredits: 'Credits',
    footerResponsible: 'Responsible use',
    footerCopyright: '© 2024 LinaOptimizer. Credits: Lina Tweaks.',
    groups: {
      all: 'All',
      cpu: 'CPU',
      gpu: 'GPU',
      games: 'Games',
      internet: 'Internet',
      extra: 'Extra',
      kernel: 'Kernel',
      system: 'System',
      debloat: 'Debloat'
    },
    quality: { low: 'Low', medium: 'Medium', high: 'High', apply: 'Apply', revert: 'Revert' }
  },
  'es-ES': {
    navHome: 'Inicio',
    navPanel: 'Panel',
    navGames: 'Juegos',
    navSupport: 'Soporte',
    heroTag: 'Localhost',
    heroTitle: 'OPTIMIZACIÓN TOTAL',
    heroSubtitle: 'WINDOWS & GAMES',
    heroDesc: 'Controla todas las optimizaciones localmente. Cada ajuste con descripción, riesgo y aplicación segura.',
    community: 'Comunidad',
    applyTweaks: 'Aplicar Tweaks',
    refreshHardware: 'Actualizar Hardware',
    hardwareLoading: 'Cargando hardware...',
    panelTitle: 'Selección de Tweaks',
    panelLabel: 'PANEL TÉCNICO',
    gameLabel: 'GAME CENTER',
    gameTitle: 'Optimización de Juegos',
    systemLog: 'Los logs aparecerán aquí.',
    footerDesc: 'Panel local para optimizaciones avanzadas. Usa con cuidado.',
    footerCredits: 'Créditos',
    footerResponsible: 'Uso responsable',
    footerCopyright: '© 2024 LinaOptimizer. Créditos: Lina Tweaks.',
    groups: {
      all: 'Todos',
      cpu: 'CPU',
      gpu: 'GPU',
      games: 'Juegos',
      internet: 'Internet',
      extra: 'Extra',
      kernel: 'Kernel',
      system: 'Sistema',
      debloat: 'Debloat'
    },
    quality: { low: 'Bajo', medium: 'Medio', high: 'Alto', apply: 'Aplicar', revert: 'Revertir' }
  },
  'de-DE': {
    navHome: 'Start',
    navPanel: 'Panel',
    navGames: 'Spiele',
    navSupport: 'Support',
    heroTag: 'Localhost',
    heroTitle: 'TOTALOPTIMIERUNG',
    heroSubtitle: 'WINDOWS & GAMES',
    heroDesc: 'Steuere alle Optimierungen lokal. Jeder Tweak mit Beschreibung, Risiko und sicherer Anwendung.',
    community: 'Community',
    applyTweaks: 'Tweaks anwenden',
    refreshHardware: 'Hardware aktualisieren',
    hardwareLoading: 'Hardware wird geladen...',
    panelTitle: 'Tweak-Auswahl',
    panelLabel: 'TECH-PANEL',
    gameLabel: 'GAME CENTER',
    gameTitle: 'Spieloptimierung',
    systemLog: 'Logs erscheinen hier.',
    footerDesc: 'Lokales Panel für erweiterte Optimierungen. Mit Vorsicht verwenden.',
    footerCredits: 'Credits',
    footerResponsible: 'Verantwortungsvolle Nutzung',
    footerCopyright: '© 2024 LinaOptimizer. Credits: Lina Tweaks.',
    groups: {
      all: 'Alle',
      cpu: 'CPU',
      gpu: 'GPU',
      games: 'Spiele',
      internet: 'Internet',
      extra: 'Extra',
      kernel: 'Kernel',
      system: 'System',
      debloat: 'Debloat'
    },
    quality: { low: 'Niedrig', medium: 'Mittel', high: 'Hoch', apply: 'Anwenden', revert: 'Zurücksetzen' }
  }
};

const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        revealObserver.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }
);

function registerReveal(element) {
  if (!element || element.dataset.revealReady === 'true') return;
  element.dataset.revealReady = 'true';
  revealObserver.observe(element);
}

function registerRevealElements(root = document) {
  root.querySelectorAll('.reveal').forEach(registerReveal);
}

function setGradientTitle(element, text) {
  if (!element) return;
  const words = text.split(' ');
  if (words.length < 2) {
    element.textContent = text;
    return;
  }
  const lastWord = words.pop();
  element.innerHTML = `${words.join(' ')} <span class="gradient-text">${lastWord}</span>`;
}

function setLanguage(lang) {
  const t = translations[lang] || translations['pt-BR'];
  document.querySelectorAll('[data-i18n="navHome"]').forEach(el => el.textContent = t.navHome);
  document.querySelectorAll('[data-i18n="navPanel"]').forEach(el => el.textContent = t.navPanel);
  document.querySelectorAll('[data-i18n="navGames"]').forEach(el => el.textContent = t.navGames);
  document.querySelectorAll('[data-i18n="navSupport"]').forEach(el => el.textContent = t.navSupport);
  document.querySelectorAll('[data-i18n="heroTag"]').forEach(el => el.textContent = t.heroTag);
  document.querySelectorAll('[data-i18n="community"]').forEach(el => el.textContent = t.community);
  document.querySelector('#hero h1 span').textContent = t.heroTitle;
  document.querySelector('#hero h1 .gradient-text').textContent = t.heroSubtitle;
  document.querySelector('#hero p').textContent = t.heroDesc;
  document.getElementById('applyTweaks').textContent = t.applyTweaks;
  document.getElementById('refreshHardware').textContent = t.refreshHardware;
  document.querySelector('#tweaks .section-header p').textContent = t.panelLabel;
  setGradientTitle(document.querySelector('#tweaks .section-header h2'), t.panelTitle);
  document.querySelector('#games .section-header p').textContent = t.gameLabel;
  setGradientTitle(document.querySelector('#games .section-header h2'), t.gameTitle);
  if (systemLog && !systemLog.dataset.locked) {
    systemLog.textContent = t.systemLog;
  }
  if (hardwareInfo && !hardwareInfo.dataset.loaded) {
    hardwareInfo.textContent = t.hardwareLoading;
  }
  document.querySelectorAll('[data-i18n="footerDesc"]').forEach(el => el.textContent = t.footerDesc);
  document.querySelectorAll('[data-i18n="footerCredits"]').forEach(el => el.textContent = t.footerCredits);
  document.querySelectorAll('[data-i18n="footerResponsible"]').forEach(el => el.textContent = t.footerResponsible);
  document.querySelectorAll('[data-i18n="footerCopyright"]').forEach(el => el.textContent = t.footerCopyright);
}

function riskClass(risk) {
  const value = (risk || '').toLowerCase();
  if (value.includes('alto') || value.includes('high')) return 'risk-high';
  if (value.includes('médio') || value.includes('medium')) return 'risk-medium';
  return 'risk-low';
}

async function fetchTweaks() {
  const res = await fetch('/api/tweaks');
  const data = await res.json();
  tweakGrid.innerHTML = '';
  const lang = langSelect ? langSelect.value : 'pt-BR';
  const t = translations[lang] || translations['pt-BR'];
  const groups = [
    { key: 'all', label: t.groups.all },
    { key: 'cpu', label: t.groups.cpu },
    { key: 'gpu', label: t.groups.gpu },
    { key: 'games', label: t.groups.games },
    { key: 'internet', label: t.groups.internet },
    { key: 'extra', label: t.groups.extra },
    { key: 'kernel', label: t.groups.kernel },
    { key: 'system', label: t.groups.system },
    { key: 'debloat', label: t.groups.debloat }
  ];

  categoryBar.innerHTML = '';
  groups.forEach((group, index) => {
    const button = document.createElement('button');
    button.className = `category-btn ${index === 0 ? 'active' : ''}`;
    button.textContent = group.label;
    button.dataset.filter = group.key;
    categoryBar.appendChild(button);
  });

  const grouped = data.reduce((acc, tweak) => {
    const key = tweak.group || 'extra';
    if (!acc[key]) acc[key] = [];
    acc[key].push(tweak);
    return acc;
  }, {});

  const grid = document.createElement('div');
  grid.className = 'tweak-grid';
  tweakGrid.appendChild(grid);

  const renderCards = (filter) => {
    grid.innerHTML = '';
    if (filter === 'games') {
      document.getElementById('games').scrollIntoView({ behavior: 'smooth' });
      return;
    }
    const list = filter === 'all' ? data : (grouped[filter] || []);
    list.forEach(tweak => {
      const card = document.createElement('div');
      card.className = 'tweak-card reveal';
      card.dataset.key = tweak.key;
      card.dataset.type = tweak.type;
      if (isTweakApplied(tweak.key)) {
        card.classList.add('applied');
      } else if (selectedTweaks.has(tweak.key)) {
        card.classList.add('selected');
      }
      card.innerHTML = `
        <div class="toggle-bar"></div>
        <div class="tweak-body">
          <div class="tweak-title">${tweak.title}</div>
          <div class="tweak-desc">${tweak.description}</div>
          <div class="tweak-meta">
            <span class="${riskClass(tweak.risk)}">${tweak.risk}</span>
            <span>${tweak.category}</span>
          </div>
        </div>
      `;
      grid.appendChild(card);
      registerReveal(card);
      card.addEventListener('click', () => {
        if (isTweakApplied(tweak.key)) {
          return;
        }
        if (selectedTweaks.has(tweak.key)) {
          selectedTweaks.delete(tweak.key);
          card.classList.remove('selected');
        } else {
          selectedTweaks.add(tweak.key);
          card.classList.add('selected');
        }
      });
    });
  };

  renderCards('all');

  categoryBar.querySelectorAll('.category-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      categoryBar.querySelectorAll('.category-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      renderCards(btn.dataset.filter);
    });
  });
}

async function fetchHardware() {
  const res = await fetch('/api/hardware');
  const data = await res.json();
  hardwareInfo.dataset.loaded = 'true';
  hardwareInfo.textContent = Object.entries(data).map(([k,v]) => `${k}: ${v}`).join('\n');
}

async function applyTweaks() {
  const payload = Array.from(selectedTweaks).map(key => {
    const card = document.querySelector(`.tweak-card[data-key="${key}"]`);
    if (!card || card.classList.contains('applied')) {
      return null;
    }
    return { key, type: card.dataset.type, enabled: true };
  }).filter(Boolean);
  if (payload.length === 0) {
    return;
  }
  const res = await fetch('/api/apply', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ tweaks: payload })
  });
  const result = await res.json();
  systemLog.textContent = result.log.join('\n');
  systemLog.dataset.locked = 'true';
  markTweaksApplied(payload.map(item => item.key));
  selectedTweaks.clear();
  fetchTweaks();
}

async function fetchGames() {
  const lang = langSelect ? langSelect.value : 'pt-BR';
  const t = translations[lang] || translations['pt-BR'];
  const res = await fetch('/api/games');
  const data = await res.json();
  gamesGrid.innerHTML = '';
  data.forEach(game => {
    const card = document.createElement('div');
    card.className = 'tweak-card game-card reveal';
    card.innerHTML = `
      <div class="tweak-title">${game.name}</div>
      <div class="tweak-desc">${game.description}</div>
      <div class="tweak-meta">
        <span>${game.detectLabel}</span>
      </div>
      <div style="display:flex; gap:10px; justify-content:center; margin-top:12px; flex-wrap: wrap;">
        <select data-game="${game.key}">
          <option value="Low">${t.quality.low}</option>
          <option value="Medium">${t.quality.medium}</option>
          <option value="High">${t.quality.high}</option>
        </select>
        <button class="btn btn-primary apply-game" data-game="${game.key}">${t.quality.apply}</button>
        <button class="btn apply-game-reset" data-game="${game.key}">${t.quality.revert}</button>
      </div>
    `;
    gamesGrid.appendChild(card);
    registerReveal(card);
  });

  document.querySelectorAll('.apply-game').forEach(btn => {
    btn.addEventListener('click', async () => {
      const gameKey = btn.dataset.game;
      const select = document.querySelector(`select[data-game="${gameKey}"]`);
      const quality = select ? select.value : 'Low';
      await fetch('/api/games/apply', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ gameKey, quality })
      });
    });
  });

  document.querySelectorAll('.apply-game-reset').forEach(btn => {
    btn.addEventListener('click', async () => {
      const gameKey = btn.dataset.game;
      await fetch('/api/games/reset', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ gameKey })
      });
    });
  });
}

if (langSelect) {
  langSelect.addEventListener('change', () => {
    setLanguage(langSelect.value);
    fetchTweaks();
    fetchGames();
  });
}

setLanguage(langSelect ? langSelect.value : 'pt-BR');
fetchTweaks();
fetchHardware();
fetchGames();
registerRevealElements();

const applyBtn = document.getElementById('applyTweaks');
applyBtn.addEventListener('click', applyTweaks);

document.getElementById('refreshHardware').addEventListener('click', fetchHardware);

let clickAudioContext;
function playClickSound() {
  try {
    if (!clickAudioContext) {
      clickAudioContext = new (window.AudioContext || window.webkitAudioContext)();
    }
    const ctx = clickAudioContext;
    if (ctx.state === 'suspended') {
      ctx.resume();
    }
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(520, ctx.currentTime);
    gain.gain.setValueAtTime(0.0001, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.08, ctx.currentTime + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.08);
    osc.connect(gain).connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.09);
  } catch {
    // ignore audio failures
  }
}

document.addEventListener('click', (event) => {
  const target = event.target;
  if (!target) return;
  const match = target.closest('button, a, .category-btn, .tweak-card, select');
  if (match) {
    playClickSound();
  }
});

function getAppliedTweaks() {
  try {
    return JSON.parse(localStorage.getItem('linaAppliedTweaks') || '[]');
  } catch {
    return [];
  }
}

function isTweakApplied(key) {
  return getAppliedTweaks().includes(key);
}

function markTweaksApplied(keys) {
  const current = new Set(getAppliedTweaks());
  keys.forEach(key => current.add(key));
  localStorage.setItem('linaAppliedTweaks', JSON.stringify(Array.from(current)));
}
