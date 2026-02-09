const tweakGrid = document.getElementById('tweakGrid');
const systemLog = document.getElementById('systemLog');
const hardwareInfo = document.getElementById('hardwareInfo');
const categoryBar = document.getElementById('categoryBar');
const gamesGrid = document.getElementById('gamesGrid');
const programsGrid = document.getElementById('programsGrid');
const tweakSearch = document.getElementById('tweakSearch');
const langSelect = document.getElementById('langSelect');
const selectedTweaks = new Set();
const programModal = document.getElementById('programModal');
const programModalTitle = document.getElementById('programModalTitle');
const programModalDesc = document.getElementById('programModalDesc');
const programModalHow = document.getElementById('programModalHow');
const programModalWarn = document.getElementById('programModalWarn');
const programDownload = document.getElementById('programDownload');
const programClose = document.getElementById('programClose');
let applyBtn;

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
    quality: { low: 'Baixo', medium: 'Médio', high: 'Alto', apply: 'Aplicar', revert: 'Reverter' },
    appliedLabel: 'Ativo',
    revertTweak: 'Reverter',
    programs: {
      title: 'Programas Essenciais',
      label: 'PROGRAMAS ESSENCIAIS',
      download: 'Download',
      close: 'Fechar',
      how: 'Como usar',
      search: 'Buscar tweaks'
    }
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
    quality: { low: 'Low', medium: 'Medium', high: 'High', apply: 'Apply', revert: 'Revert' },
    appliedLabel: 'Active',
    revertTweak: 'Revert',
    programs: {
      title: 'Essential Programs',
      label: 'ESSENTIAL PROGRAMS',
      download: 'Download',
      close: 'Close',
      how: 'How to use',
      search: 'Search tweaks'
    }
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
    quality: { low: 'Bajo', medium: 'Medio', high: 'Alto', apply: 'Aplicar', revert: 'Revertir' },
    appliedLabel: 'Activo',
    revertTweak: 'Revertir',
    programs: {
      title: 'Programas esenciales',
      label: 'PROGRAMAS ESENCIALES',
      download: 'Descargar',
      close: 'Cerrar',
      how: 'Cómo usar',
      search: 'Buscar tweaks'
    }
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
    quality: { low: 'Niedrig', medium: 'Mittel', high: 'Hoch', apply: 'Anwenden', revert: 'Zurücksetzen' },
    appliedLabel: 'Aktiv',
    revertTweak: 'Zurücksetzen',
    programs: {
      title: 'Essenzielle Programme',
      label: 'ESSENZIELLE PROGRAMME',
      download: 'Download',
      close: 'Schließen',
      how: 'Anleitung',
      search: 'Tweaks suchen'
    }
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
  const programsSection = document.querySelector('#programs .section-header h2');
  const programsLabel = document.querySelector('#programs .section-header p');
  if (programsLabel) programsLabel.textContent = t.programs.label;
  setGradientTitle(programsSection, t.programs.title);
  if (programDownload) programDownload.textContent = t.programs.download;
  if (programClose) programClose.textContent = t.programs.close;
  if (tweakSearch) tweakSearch.placeholder = t.programs.search;
}

function riskClass(risk) {
  const value = (risk || '').toLowerCase();
  if (value.includes('alto') || value.includes('high') || value.includes('hoch')) return 'risk-high';
  if (value.includes('médio') || value.includes('medio') || value.includes('medium') || value.includes('mittel')) return 'risk-medium';
  return 'risk-low';
}

async function fetchTweaks() {
  const lang = langSelect ? langSelect.value : 'pt-BR';
  const res = await fetch(`/api/tweaks?lang=${encodeURIComponent(lang)}`);
  const data = await res.json();
  tweakGrid.innerHTML = '';
  const t = translations[lang] || translations['pt-BR'];
  const groups = [
    { key: 'all', label: t.groups.all },
    { key: 'cpu', label: t.groups.cpu },
    { key: 'gpu', label: t.groups.gpu },
    { key: 'games', label: t.groups.games },
    { key: 'programs', label: t.programs.label },
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
    if (filter === 'programs') {
      document.getElementById('programs').scrollIntoView({ behavior: 'smooth' });
      return;
    }
    const list = filter === 'all' ? data : (grouped[filter] || []);
    const term = (tweakSearch?.value || '').trim().toLowerCase();
    const filtered = term
      ? list.filter(item => `${item.title} ${item.description}`.toLowerCase().includes(term))
      : list;
    filtered.forEach((tweak, index) => {
      const card = document.createElement('div');
      card.className = 'tweak-card reveal';
      card.dataset.key = tweak.key;
      card.dataset.type = tweak.type;
      card.style.setProperty('--reveal-delay', `${Math.min(index, 6) * 0.05}s`);
      const applied = isTweakApplied(tweak.key);
      if (applied) {
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
            ${applied ? `<span class="applied-badge">${t.appliedLabel}</span>` : ''}
          </div>
          ${applied && tweak.type !== 'debloat'
            ? `<div class="tweak-actions"><button class="btn btn-secondary tweak-revert" data-key="${tweak.key}" data-type="${tweak.type}">${t.revertTweak}</button></div>`
            : ''}
        </div>
      `;
      grid.appendChild(card);
      registerReveal(card);
      const revertBtn = card.querySelector('.tweak-revert');
      if (revertBtn) {
        revertBtn.addEventListener('click', async (event) => {
          event.stopPropagation();
          await revertTweak(revertBtn.dataset.key, revertBtn.dataset.type);
        });
      }
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

  tweakSearch?.addEventListener('input', () => {
    const active = categoryBar.querySelector('.category-btn.active');
    renderCards(active ? active.dataset.filter : 'all');
  });
}

async function fetchHardware() {
  try {
    const res = await fetch('/api/hardware');
    if (!res.ok) {
      throw new Error('Falha ao carregar hardware');
    }
    const data = await res.json();
    hardwareInfo.dataset.loaded = 'true';
    hardwareInfo.textContent = Object.entries(data).map(([k,v]) => `${k}: ${v}`).join('\n');
  } catch (error) {
    hardwareInfo.dataset.loaded = 'true';
    hardwareInfo.textContent = 'Falha ao carregar hardware. Verifique o servidor.';
  }
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

async function revertTweak(key, type) {
  if (!key || !type) return;
  const res = await fetch('/api/revert', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ tweaks: [{ key, type }] })
  });
  const result = await res.json();
  if (systemLog && result.log) {
    systemLog.dataset.locked = 'true';
    systemLog.textContent = result.log.join('\n');
  }
  markTweaksReverted([key]);
  fetchTweaks();
}

async function fetchGames() {
  const lang = langSelect ? langSelect.value : 'pt-BR';
  const t = translations[lang] || translations['pt-BR'];
  const res = await fetch(`/api/games?lang=${encodeURIComponent(lang)}`);
  const data = await res.json();
  gamesGrid.innerHTML = '';
  data.forEach((game, index) => {
    const card = document.createElement('div');
    card.className = 'tweak-card game-card reveal';
    card.style.setProperty('--reveal-delay', `${Math.min(index, 6) * 0.05}s`);
    card.innerHTML = `
      <div class="game-info">
        <div class="tweak-title">${game.name}</div>
        <div class="tweak-desc">${game.description}</div>
        <div class="tweak-meta">
          <span>${game.detectLabel}</span>
        </div>
      </div>
      <div class="game-actions">
        <select data-game="${game.key}">
          <option value="Low">${t.quality.low}</option>
          <option value="Medium">${t.quality.medium}</option>
          <option value="High">${t.quality.high}</option>
        </select>
        <button class="btn btn-primary apply-game" data-game="${game.key}">${t.quality.apply}</button>
        <button class="btn btn-secondary apply-game-reset" data-game="${game.key}">${t.quality.revert}</button>
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

const programs = [
  {
    id: 'ddu',
    url: 'https://www.wagnardsoft.com/',
    content: {
      'pt-BR': {
        name: 'DDU (Display Driver Uninstaller)',
        category: 'Drivers / Limpeza',
        desc: 'Remove drivers de GPU por completo para reinstalação limpa.',
        how: '1) Baixe o DDU.\n2) Reinicie em modo de segurança.\n3) Execute e selecione a GPU.\n4) Clique em “Clean and restart”.\n5) Instale o driver novo após reiniciar.',
        warn: 'Use apenas quando houver problemas com driver/instalação.'
      },
      'en-US': {
        name: 'DDU (Display Driver Uninstaller)',
        category: 'Drivers / Cleanup',
        desc: 'Completely removes GPU drivers for a clean reinstall.',
        how: '1) Download DDU.\n2) Reboot into Safe Mode.\n3) Run it and select the GPU.\n4) Click “Clean and restart”.\n5) Install the new driver after reboot.',
        warn: 'Use only when you have driver/install issues.'
      },
      'es-ES': {
        name: 'DDU (Display Driver Uninstaller)',
        category: 'Drivers / Limpieza',
        desc: 'Elimina por completo los drivers de la GPU para una reinstalación limpia.',
        how: '1) Descarga DDU.\n2) Reinicia en Modo seguro.\n3) Ejecútalo y selecciona la GPU.\n4) Haz clic en “Clean and restart”.\n5) Instala el driver nuevo tras reiniciar.',
        warn: 'Úsalo solo cuando haya problemas con el driver/instalación.'
      },
      'de-DE': {
        name: 'DDU (Display Driver Uninstaller)',
        category: 'Treiber / Reinigung',
        desc: 'Entfernt GPU-Treiber vollständig für eine saubere Neuinstallation.',
        how: '1) DDU herunterladen.\n2) Im abgesicherten Modus neu starten.\n3) Ausführen und GPU auswählen.\n4) Auf „Clean and restart“ klicken.\n5) Nach dem Neustart den Treiber installieren.',
        warn: 'Nur bei Treiber-/Installationsproblemen verwenden.'
      }
    }
  },
  {
    id: 'islc',
    url: 'https://www.wagnardsoft.com/ISLCw',
    content: {
      'pt-BR': {
        name: 'ISLC (Intelligent Standby List Cleaner)',
        category: 'Memória / Stutter',
        desc: 'Limpa standby list para reduzir travamentos e stutter.',
        how: '1) Abra o ISLC.\n2) Defina “Free memory is lower than” (ex: 1024MB).\n3) Defina “Wanted timer resolution” (ex: 0.5).\n4) Ative “Start ISLC minimized”.\n5) Clique em Start.',
        warn: 'Ajuda em stutter, não é milagre.'
      },
      'en-US': {
        name: 'ISLC (Intelligent Standby List Cleaner)',
        category: 'Memory / Stutter',
        desc: 'Cleans the standby list to reduce stutter and hiccups.',
        how: '1) Open ISLC.\n2) Set “Free memory is lower than” (e.g. 1024MB).\n3) Set “Wanted timer resolution” (e.g. 0.5).\n4) Enable “Start ISLC minimized”.\n5) Click Start.',
        warn: 'Helps with stutter, but it is not magic.'
      },
      'es-ES': {
        name: 'ISLC (Intelligent Standby List Cleaner)',
        category: 'Memoria / Stutter',
        desc: 'Limpia la standby list para reducir tirones y stutter.',
        how: '1) Abre ISLC.\n2) Configura “Free memory is lower than” (p. ej. 1024MB).\n3) Configura “Wanted timer resolution” (p. ej. 0.5).\n4) Activa “Start ISLC minimized”.\n5) Haz clic en Start.',
        warn: 'Ayuda con el stutter, no es magia.'
      },
      'de-DE': {
        name: 'ISLC (Intelligent Standby List Cleaner)',
        category: 'Speicher / Stutter',
        desc: 'Leert die Standby-Liste, um Ruckler zu reduzieren.',
        how: '1) ISLC öffnen.\n2) „Free memory is lower than“ setzen (z. B. 1024MB).\n3) „Wanted timer resolution“ setzen (z. B. 0.5).\n4) „Start ISLC minimized“ aktivieren.\n5) Auf Start klicken.',
        warn: 'Hilft gegen Stutter, ist aber kein Wundermittel.'
      }
    }
  },
  {
    id: 'afterburner',
    url: 'https://www.msi.com/Landing/afterburner/graphics-cards',
    content: {
      'pt-BR': {
        name: 'MSI Afterburner',
        category: 'GPU Tuning',
        desc: 'Monitoramento de GPU com ajuste de fan curve e limites.',
        how: '1) Instale e abra.\n2) Ajuste fan curve leve.\n3) Se necessário, limite power/voltage.\n4) Evite OC agressivo.\n5) Salve o perfil.'
      },
      'en-US': {
        name: 'MSI Afterburner',
        category: 'GPU Tuning',
        desc: 'GPU monitoring with fan curve and limit control.',
        how: '1) Install and open it.\n2) Set a gentle fan curve.\n3) If needed, limit power/voltage.\n4) Avoid aggressive OC.\n5) Save the profile.'
      },
      'es-ES': {
        name: 'MSI Afterburner',
        category: 'Ajuste de GPU',
        desc: 'Monitorización de GPU con curva de ventilador y límites.',
        how: '1) Instálalo y ábrelo.\n2) Ajusta una curva de ventilador suave.\n3) Si hace falta, limita potencia/voltaje.\n4) Evita OC agresivo.\n5) Guarda el perfil.'
      },
      'de-DE': {
        name: 'MSI Afterburner',
        category: 'GPU-Tuning',
        desc: 'GPU-Monitoring mit Lüfterkurve und Limits.',
        how: '1) Installieren und öffnen.\n2) Eine sanfte Lüfterkurve einstellen.\n3) Bei Bedarf Power/Voltage begrenzen.\n4) Aggressives OC vermeiden.\n5) Profil speichern.'
      }
    }
  },
  {
    id: 'rtss',
    url: 'https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html',
    content: {
      'pt-BR': {
        name: 'RivaTuner Statistics Server (RTSS)',
        category: 'Frame Cap / Frametime',
        desc: 'Limita FPS e exibe OSD estável.',
        how: '1) Abra o RTSS.\n2) Defina o FPS limit (ex: 141 para 144Hz).\n3) Ative OSD.\n4) Teste frametime no jogo.\n5) Ajuste conforme necessário.'
      },
      'en-US': {
        name: 'RivaTuner Statistics Server (RTSS)',
        category: 'Frame Cap / Frametime',
        desc: 'Caps FPS and shows a stable OSD.',
        how: '1) Open RTSS.\n2) Set the FPS limit (e.g. 141 for 144Hz).\n3) Enable OSD.\n4) Test frametime in-game.\n5) Adjust as needed.'
      },
      'es-ES': {
        name: 'RivaTuner Statistics Server (RTSS)',
        category: 'Límite FPS / Frametime',
        desc: 'Limita FPS y muestra un OSD estable.',
        how: '1) Abre RTSS.\n2) Define el límite de FPS (p. ej. 141 para 144Hz).\n3) Activa el OSD.\n4) Prueba el frametime en el juego.\n5) Ajusta según sea necesario.'
      },
      'de-DE': {
        name: 'RivaTuner Statistics Server (RTSS)',
        category: 'FPS-Limit / Frametime',
        desc: 'Begrenzt FPS und zeigt ein stabiles OSD.',
        how: '1) RTSS öffnen.\n2) FPS-Limit setzen (z. B. 141 für 144Hz).\n3) OSD aktivieren.\n4) Frametime im Spiel testen.\n5) Bei Bedarf anpassen.'
      }
    }
  },
  {
    id: 'hwinfo',
    url: 'https://www.hwinfo.com/download/',
    content: {
      'pt-BR': {
        name: 'HWiNFO',
        category: 'Monitoramento',
        desc: 'Sensores detalhados para identificar throttling e temperaturas.',
        how: '1) Abra em “Sensors-only”.\n2) Monitore CPU/GPU/VRM.\n3) Faça log durante o jogo.\n4) Identifique picos de temperatura.\n5) Ajuste cooling/power.'
      },
      'en-US': {
        name: 'HWiNFO',
        category: 'Monitoring',
        desc: 'Detailed sensors to spot throttling and temperatures.',
        how: '1) Open in “Sensors-only”.\n2) Monitor CPU/GPU/VRM.\n3) Log during gameplay.\n4) Identify temperature spikes.\n5) Adjust cooling/power.'
      },
      'es-ES': {
        name: 'HWiNFO',
        category: 'Monitorización',
        desc: 'Sensores detallados para detectar throttling y temperaturas.',
        how: '1) Abre en “Sensors-only”.\n2) Monitorea CPU/GPU/VRM.\n3) Registra durante el juego.\n4) Identifica picos de temperatura.\n5) Ajusta refrigeración/potencia.'
      },
      'de-DE': {
        name: 'HWiNFO',
        category: 'Monitoring',
        desc: 'Detaillierte Sensoren zur Erkennung von Throttling und Temperaturen.',
        how: '1) Im Modus „Sensors-only“ öffnen.\n2) CPU/GPU/VRM überwachen.\n3) Während des Spiels loggen.\n4) Temperatursprünge erkennen.\n5) Kühlung/Power anpassen.'
      }
    }
  },
  {
    id: 'capframex',
    url: 'https://www.capframex.com/',
    content: {
      'pt-BR': {
        name: 'CapFrameX',
        category: 'Benchmark / FPS',
        desc: 'Mede FPS e frametime (1% low).',
        how: '1) Abra o CapFrameX.\n2) Inicie captura.\n3) Jogue 3-5 minutos.\n4) Analise 1% low.\n5) Compare antes/depois.'
      },
      'en-US': {
        name: 'CapFrameX',
        category: 'Benchmark / FPS',
        desc: 'Measures FPS and frametime (1% low).',
        how: '1) Open CapFrameX.\n2) Start a capture.\n3) Play 3-5 minutes.\n4) Analyze 1% low.\n5) Compare before/after.'
      },
      'es-ES': {
        name: 'CapFrameX',
        category: 'Benchmark / FPS',
        desc: 'Mide FPS y frametime (1% low).',
        how: '1) Abre CapFrameX.\n2) Inicia una captura.\n3) Juega 3-5 minutos.\n4) Analiza el 1% low.\n5) Compara antes/después.'
      },
      'de-DE': {
        name: 'CapFrameX',
        category: 'Benchmark / FPS',
        desc: 'Misst FPS und Frametime (1% low).',
        how: '1) CapFrameX öffnen.\n2) Aufzeichnung starten.\n3) 3-5 Minuten spielen.\n4) 1% low analysieren.\n5) Vorher/Nachher vergleichen.'
      }
    }
  },
  {
    id: 'process-lasso',
    url: 'https://bitsum.com/download-process-lasso/',
    content: {
      'pt-BR': {
        name: 'Process Lasso',
        category: 'CPU Scheduling',
        desc: 'Gerencia prioridades e afinidade de CPU por processo.',
        how: '1) Instale e abra.\n2) Ative “Performance Mode” no jogo.\n3) Não altere o sistema todo.\n4) Crie regra só para o executável.\n5) Teste estabilidade.',
        warn: 'Mudanças exageradas podem piorar desempenho.'
      },
      'en-US': {
        name: 'Process Lasso',
        category: 'CPU Scheduling',
        desc: 'Manages per-process CPU priority and affinity.',
        how: '1) Install and open it.\n2) Enable “Performance Mode” for the game.\n3) Avoid changing the whole system.\n4) Create a rule only for the executable.\n5) Test stability.',
        warn: 'Excessive changes can reduce performance.'
      },
      'es-ES': {
        name: 'Process Lasso',
        category: 'Planificación de CPU',
        desc: 'Gestiona prioridad y afinidad de CPU por proceso.',
        how: '1) Instálalo y ábrelo.\n2) Activa “Performance Mode” en el juego.\n3) No cambies todo el sistema.\n4) Crea una regla solo para el ejecutable.\n5) Prueba la estabilidad.',
        warn: 'Cambios excesivos pueden empeorar el rendimiento.'
      },
      'de-DE': {
        name: 'Process Lasso',
        category: 'CPU-Planung',
        desc: 'Verwaltet CPU-Priorität und Affinität pro Prozess.',
        how: '1) Installieren und öffnen.\n2) „Performance Mode“ fürs Spiel aktivieren.\n3) Nicht das ganze System ändern.\n4) Regel nur für die EXE anlegen.\n5) Stabilität testen.',
        warn: 'Zu starke Änderungen können die Leistung senken.'
      }
    }
  },
  {
    id: 'autoruns',
    url: 'https://learn.microsoft.com/sysinternals/downloads/autoruns',
    content: {
      'pt-BR': {
        name: 'Autoruns (Sysinternals)',
        category: 'Startup / Serviços',
        desc: 'Desativa entradas de inicialização desnecessárias.',
        how: '1) Abra como admin.\n2) Aguarde o scan.\n3) Desmarque entradas inúteis.\n4) Crie um backup antes.\n5) Reinicie e valide.'
      },
      'en-US': {
        name: 'Autoruns (Sysinternals)',
        category: 'Startup / Services',
        desc: 'Disables unnecessary startup entries.',
        how: '1) Run as admin.\n2) Wait for the scan.\n3) Uncheck unneeded entries.\n4) Create a backup first.\n5) Reboot and verify.'
      },
      'es-ES': {
        name: 'Autoruns (Sysinternals)',
        category: 'Inicio / Servicios',
        desc: 'Desactiva entradas de inicio innecesarias.',
        how: '1) Ábrelo como admin.\n2) Espera el escaneo.\n3) Desmarca entradas innecesarias.\n4) Crea un backup antes.\n5) Reinicia y verifica.'
      },
      'de-DE': {
        name: 'Autoruns (Sysinternals)',
        category: 'Autostart / Dienste',
        desc: 'Deaktiviert unnötige Autostart-Einträge.',
        how: '1) Als Admin starten.\n2) Scan abwarten.\n3) Unnötige Einträge abwählen.\n4) Vorher ein Backup erstellen.\n5) Neustarten und prüfen.'
      }
    }
  },
  {
    id: 'latencymon',
    url: 'https://www.resplendence.com/latencymon',
    content: {
      'pt-BR': {
        name: 'LatencyMon',
        category: 'Latência DPC',
        desc: 'Diagnostica drivers que causam latência.',
        how: '1) Inicie o LatencyMon.\n2) Rode durante jogo/uso.\n3) Verifique drivers listados.\n4) Atualize drivers críticos.\n5) Refaça o teste.'
      },
      'en-US': {
        name: 'LatencyMon',
        category: 'DPC Latency',
        desc: 'Diagnoses drivers that cause latency spikes.',
        how: '1) Start LatencyMon.\n2) Run while gaming/using the PC.\n3) Check listed drivers.\n4) Update critical drivers.\n5) Re-test.'
      },
      'es-ES': {
        name: 'LatencyMon',
        category: 'Latencia DPC',
        desc: 'Diagnostica drivers que causan picos de latencia.',
        how: '1) Inicia LatencyMon.\n2) Úsalo mientras juegas/usas el PC.\n3) Revisa los drivers listados.\n4) Actualiza drivers críticos.\n5) Repite la prueba.'
      },
      'de-DE': {
        name: 'LatencyMon',
        category: 'DPC-Latenz',
        desc: 'Diagnostiziert Treiber mit Latenzspitzen.',
        how: '1) LatencyMon starten.\n2) Während Spiel/Nutzung laufen lassen.\n3) Aufgelistete Treiber prüfen.\n4) Kritische Treiber aktualisieren.\n5) Erneut testen.'
      }
    }
  },
  {
    id: 'nvcleanstall',
    url: 'https://www.techpowerup.com/nvcleanstall/',
    content: {
      'pt-BR': {
        name: 'NVCleanstall (NVIDIA)',
        category: 'Driver Slim',
        desc: 'Instala driver NVIDIA sem bloat.',
        how: '1) Abra o NVCleanstall.\n2) Selecione driver recomendado.\n3) Mantenha só componentes essenciais.\n4) Instale e reinicie.\n5) Teste estabilidade.',
        warn: 'Não recomendado para iniciantes.'
      },
      'en-US': {
        name: 'NVCleanstall (NVIDIA)',
        category: 'Driver Slim',
        desc: 'Installs NVIDIA drivers without bloat.',
        how: '1) Open NVCleanstall.\n2) Select the recommended driver.\n3) Keep only essential components.\n4) Install and reboot.\n5) Test stability.',
        warn: 'Not recommended for beginners.'
      },
      'es-ES': {
        name: 'NVCleanstall (NVIDIA)',
        category: 'Driver Slim',
        desc: 'Instala drivers NVIDIA sin bloat.',
        how: '1) Abre NVCleanstall.\n2) Selecciona el driver recomendado.\n3) Mantén solo componentes esenciales.\n4) Instala y reinicia.\n5) Prueba la estabilidad.',
        warn: 'No recomendado para principiantes.'
      },
      'de-DE': {
        name: 'NVCleanstall (NVIDIA)',
        category: 'Treiber Slim',
        desc: 'Installiert NVIDIA-Treiber ohne Bloat.',
        how: '1) NVCleanstall öffnen.\n2) Empfohlenen Treiber wählen.\n3) Nur essentielle Komponenten behalten.\n4) Installieren und neu starten.\n5) Stabilität testen.',
        warn: 'Nicht für Einsteiger empfohlen.'
      }
    }
  },
  {
    id: 'shutup10',
    url: 'https://www.oo-software.com/en/shutup10',
    content: {
      'pt-BR': {
        name: 'O&O ShutUp10++',
        category: 'Privacidade',
        desc: 'Desativa telemetria com perfil seguro.',
        how: '1) Abra o ShutUp10++.\n2) Aplique recomendações “Safe”.\n3) Evite modo agressivo.\n4) Reinicie o PC.\n5) Valide mudanças.'
      },
      'en-US': {
        name: 'O&O ShutUp10++',
        category: 'Privacy',
        desc: 'Disables telemetry with a safe profile.',
        how: '1) Open ShutUp10++.\n2) Apply “Safe” recommendations.\n3) Avoid aggressive mode.\n4) Reboot the PC.\n5) Validate changes.'
      },
      'es-ES': {
        name: 'O&O ShutUp10++',
        category: 'Privacidad',
        desc: 'Desactiva telemetría con un perfil seguro.',
        how: '1) Abre ShutUp10++.\n2) Aplica recomendaciones “Safe”.\n3) Evita el modo agresivo.\n4) Reinicia el PC.\n5) Valida los cambios.'
      },
      'de-DE': {
        name: 'O&O ShutUp10++',
        category: 'Datenschutz',
        desc: 'Deaktiviert Telemetrie mit einem sicheren Profil.',
        how: '1) ShutUp10++ öffnen.\n2) „Safe“-Empfehlungen anwenden.\n3) Aggressiven Modus vermeiden.\n4) PC neu starten.\n5) Änderungen prüfen.'
      }
    }
  },
  {
    id: 'crystaldiskinfo',
    url: 'https://crystalmark.info/en/software/crystaldiskinfo/',
    content: {
      'pt-BR': {
        name: 'CrystalDiskInfo',
        category: 'Saúde de Disco',
        desc: 'Verifica SMART, temperatura e alertas.',
        how: '1) Abra o CrystalDiskInfo.\n2) Verifique saúde.\n3) Observe temperatura.\n4) Faça backup se estiver em “Caution”.\n5) Monitore periodicamente.'
      },
      'en-US': {
        name: 'CrystalDiskInfo',
        category: 'Disk Health',
        desc: 'Checks SMART, temperature, and alerts.',
        how: '1) Open CrystalDiskInfo.\n2) Check drive health.\n3) Watch temperatures.\n4) Back up if it shows “Caution”.\n5) Monitor periodically.'
      },
      'es-ES': {
        name: 'CrystalDiskInfo',
        category: 'Salud del disco',
        desc: 'Revisa SMART, temperatura y alertas.',
        how: '1) Abre CrystalDiskInfo.\n2) Revisa el estado.\n3) Observa la temperatura.\n4) Haz backup si marca “Caution”.\n5) Supervisa periódicamente.'
      },
      'de-DE': {
        name: 'CrystalDiskInfo',
        category: 'Festplattenzustand',
        desc: 'Prüft SMART, Temperatur und Warnungen.',
        how: '1) CrystalDiskInfo öffnen.\n2) Zustand prüfen.\n3) Temperatur beobachten.\n4) Bei „Caution“ Backup erstellen.\n5) Regelmäßig prüfen.'
      }
    }
  },
  {
    id: '7zip',
    url: 'https://www.7-zip.org/',
    content: {
      'pt-BR': {
        name: '7-Zip',
        category: 'Utilitário',
        desc: 'Extrai e compacta mods/packs rapidamente.',
        how: '1) Instale e associe formatos.\n2) Use para zip/rar/7z.\n3) Extraia configs e mods.\n4) Compacte backups.\n5) Mantenha atualizado.'
      },
      'en-US': {
        name: '7-Zip',
        category: 'Utility',
        desc: 'Extracts and compresses mods/packs quickly.',
        how: '1) Install and associate formats.\n2) Use for zip/rar/7z.\n3) Extract configs and mods.\n4) Compress backups.\n5) Keep it updated.'
      },
      'es-ES': {
        name: '7-Zip',
        category: 'Utilidad',
        desc: 'Extrae y comprime mods/packs rápidamente.',
        how: '1) Instálalo y asocia formatos.\n2) Úsalo para zip/rar/7z.\n3) Extrae configs y mods.\n4) Comprime backups.\n5) Manténlo actualizado.'
      },
      'de-DE': {
        name: '7-Zip',
        category: 'Tool',
        desc: 'Entpackt und komprimiert Mods/Packs schnell.',
        how: '1) Installieren und Formate zuordnen.\n2) Für zip/rar/7z nutzen.\n3) Configs und Mods entpacken.\n4) Backups komprimieren.\n5) Aktuell halten.'
      }
    }
  },
  {
    id: 'everything',
    url: 'https://www.voidtools.com/',
    content: {
      'pt-BR': {
        name: 'Everything (Voidtools)',
        category: 'Busca rápida',
        desc: 'Busca instantânea para configs/logs.',
        how: '1) Instale e abra.\n2) Aguarde indexar.\n3) Pesquise configs do jogo.\n4) Use filtros por extensão.\n5) Organize arquivos.'
      },
      'en-US': {
        name: 'Everything (Voidtools)',
        category: 'Fast Search',
        desc: 'Instant search for configs/logs.',
        how: '1) Install and open.\n2) Wait for indexing.\n3) Search game configs.\n4) Use extension filters.\n5) Organize files.'
      },
      'es-ES': {
        name: 'Everything (Voidtools)',
        category: 'Búsqueda rápida',
        desc: 'Búsqueda instantánea de configs/logs.',
        how: '1) Instálalo y ábrelo.\n2) Espera la indexación.\n3) Busca configs del juego.\n4) Usa filtros por extensión.\n5) Organiza archivos.'
      },
      'de-DE': {
        name: 'Everything (Voidtools)',
        category: 'Schnellsuche',
        desc: 'Sofortsuche für Configs/Logs.',
        how: '1) Installieren und öffnen.\n2) Indexierung abwarten.\n3) Spiel-Configs suchen.\n4) Nach Dateiendung filtern.\n5) Dateien organisieren.'
      }
    }
  },
  {
    id: 'runtimes',
    url: 'https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist',
    content: {
      'pt-BR': {
        name: 'DirectX / VC++ Runtimes',
        category: 'Dependências',
        desc: 'Corrige erros de DLL e dependências de jogos.',
        how: '1) Baixe do site Microsoft.\n2) Instale os runtimes necessários.\n3) Reinicie o PC.\n4) Abra o jogo.\n5) Repita se houver erro de DLL.'
      },
      'en-US': {
        name: 'DirectX / VC++ Runtimes',
        category: 'Dependencies',
        desc: 'Fixes DLL errors and game dependencies.',
        how: '1) Download from Microsoft.\n2) Install required runtimes.\n3) Reboot the PC.\n4) Launch the game.\n5) Repeat if DLL errors remain.'
      },
      'es-ES': {
        name: 'DirectX / VC++ Runtimes',
        category: 'Dependencias',
        desc: 'Corrige errores de DLL y dependencias de juegos.',
        how: '1) Descarga desde Microsoft.\n2) Instala los runtimes necesarios.\n3) Reinicia el PC.\n4) Abre el juego.\n5) Repite si sigue el error de DLL.'
      },
      'de-DE': {
        name: 'DirectX / VC++ Runtimes',
        category: 'Abhängigkeiten',
        desc: 'Behebt DLL-Fehler und Spiel-Abhängigkeiten.',
        how: '1) Von Microsoft herunterladen.\n2) Benötigte Runtimes installieren.\n3) PC neu starten.\n4) Spiel starten.\n5) Wiederholen, falls DLL-Fehler bleiben.'
      }
    }
  }
];

function getProgramCopy(program, lang) {
  if (!program || !program.content) return null;
  return program.content[lang] || program.content['pt-BR'] || program.content['en-US'];
}

function renderPrograms() {
  if (!programsGrid) return;
  const lang = langSelect ? langSelect.value : 'pt-BR';
  const t = translations[lang] || translations['pt-BR'];
  programsGrid.innerHTML = '';
  programs.forEach((program, index) => {
    const copy = getProgramCopy(program, lang);
    if (!copy) return;
    const card = document.createElement('div');
    card.className = 'tweak-card reveal';
    card.style.setProperty('--reveal-delay', `${Math.min(index, 6) * 0.05}s`);
    card.innerHTML = `
      <div class="tweak-body">
        <div class="tweak-title">${copy.name}</div>
        <div class="tweak-desc">${copy.desc}</div>
        <div class="tweak-meta">
          <span>${copy.category}</span>
        </div>
        <div class="game-actions">
          <button class="btn btn-primary program-open" data-program-id="${program.id}">${t.programs.download}</button>
        </div>
      </div>
    `;
    programsGrid.appendChild(card);
    registerReveal(card);
  });
}

if (langSelect) {
  langSelect.addEventListener('change', () => {
    setLanguage(langSelect.value);
    fetchTweaks();
    fetchGames();
    renderPrograms();
  });
}

setLanguage(langSelect ? langSelect.value : 'pt-BR');
fetchTweaks();
fetchHardware();
fetchGames();
renderPrograms();
registerRevealElements();

applyBtn = document.getElementById('applyTweaks');
applyBtn.addEventListener('click', applyTweaks);

document.getElementById('refreshHardware')?.addEventListener('click', fetchHardware);


function openProgramModal(program) {
  if (!programModal) return;
  const lang = langSelect ? langSelect.value : 'pt-BR';
  const t = translations[lang] || translations['pt-BR'];
  const copy = getProgramCopy(program, lang);
  if (!copy) return;
  programModalTitle.textContent = copy.name;
  programModalDesc.textContent = copy.desc;
  programModalHow.textContent = `${t.programs.how}:\n${copy.how}`;
  if (copy.warn) {
    programModalWarn.style.display = 'block';
    programModalWarn.textContent = copy.warn;
  } else {
    programModalWarn.style.display = 'none';
    programModalWarn.textContent = '';
  }
  programDownload.href = program.url;
  programModal.classList.add('active');
  programModal.setAttribute('aria-hidden', 'false');
}

function closeProgramModal() {
  if (!programModal) return;
  programModal.classList.remove('active');
  programModal.setAttribute('aria-hidden', 'true');
}

programClose?.addEventListener('click', closeProgramModal);
programModal?.addEventListener('click', (event) => {
  if (event.target === programModal) closeProgramModal();
});

document.addEventListener('click', (event) => {
  const target = event.target;
  if (!(target instanceof HTMLElement)) return;
  const button = target.closest('.program-open');
  if (!button) return;
  const id = button.dataset.programId;
  const program = programs.find(item => item.id === id);
  if (program) openProgramModal(program);
});

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

function markTweaksReverted(keys) {
  const current = new Set(getAppliedTweaks());
  keys.forEach(key => current.delete(key));
  localStorage.setItem('linaAppliedTweaks', JSON.stringify(Array.from(current)));
}

const particleCanvas = document.getElementById('particleCanvas');
const particleCtx = particleCanvas?.getContext('2d');
const particles = [];
const particleSettings = {
  count: 40,
  radius: 2,
  speed: 0.2,
  repelRadius: 120,
  repelStrength: 0.6,
  linkDistance: 140
};
let pointer = { x: -9999, y: -9999 };

function resizeParticles() {
  if (!particleCanvas) return;
  particleCanvas.width = window.innerWidth;
  particleCanvas.height = window.innerHeight;
}

function initParticles() {
  if (!particleCanvas || !particleCtx) return;
  particles.length = 0;
  for (let i = 0; i < particleSettings.count; i += 1) {
    particles.push({
      x: Math.random() * particleCanvas.width,
      y: Math.random() * particleCanvas.height,
      vx: (Math.random() - 0.5) * particleSettings.speed,
      vy: (Math.random() - 0.5) * particleSettings.speed
    });
  }
}

function drawParticles() {
  if (!particleCanvas || !particleCtx) return;
  particleCtx.clearRect(0, 0, particleCanvas.width, particleCanvas.height);
  particles.forEach(p => {
    const dx = p.x - pointer.x;
    const dy = p.y - pointer.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist < particleSettings.repelRadius) {
      const force = (1 - dist / particleSettings.repelRadius) * particleSettings.repelStrength;
      p.vx += (dx / (dist || 1)) * force;
      p.vy += (dy / (dist || 1)) * force;
    }
    p.x += p.vx;
    p.y += p.vy;
    if (p.x < 0 || p.x > particleCanvas.width) p.vx *= -1;
    if (p.y < 0 || p.y > particleCanvas.height) p.vy *= -1;
  });

  for (let i = 0; i < particles.length; i += 1) {
    for (let j = i + 1; j < particles.length; j += 1) {
      const a = particles[i];
      const b = particles[j];
      const dx = a.x - b.x;
      const dy = a.y - b.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < particleSettings.linkDistance) {
        const pointerDistA = Math.sqrt((a.x - pointer.x) ** 2 + (a.y - pointer.y) ** 2);
        const pointerDistB = Math.sqrt((b.x - pointer.x) ** 2 + (b.y - pointer.y) ** 2);
        const pointerFactor = Math.min(pointerDistA, pointerDistB) < particleSettings.repelRadius
          ? 0
          : 1;
        const alpha = (1 - dist / particleSettings.linkDistance) * 0.4 * pointerFactor;
        if (alpha > 0) {
          particleCtx.strokeStyle = `rgba(205, 127, 50, ${alpha})`;
          particleCtx.beginPath();
          particleCtx.moveTo(a.x, a.y);
          particleCtx.lineTo(b.x, b.y);
          particleCtx.stroke();
        }
      }
    }
  }

  particles.forEach(p => {
    const dist = Math.sqrt((p.x - pointer.x) ** 2 + (p.y - pointer.y) ** 2);
    const alpha = dist < particleSettings.repelRadius ? 0 : 0.5;
    if (alpha > 0) {
      particleCtx.fillStyle = `rgba(205, 127, 50, ${alpha})`;
      particleCtx.beginPath();
      particleCtx.arc(p.x, p.y, particleSettings.radius, 0, Math.PI * 2);
      particleCtx.fill();
    }
  });
  requestAnimationFrame(drawParticles);
}

if (particleCanvas) {
  resizeParticles();
  initParticles();
  drawParticles();
  window.addEventListener('resize', () => {
    resizeParticles();
    initParticles();
  });
  window.addEventListener('mousemove', (event) => {
    pointer = { x: event.clientX, y: event.clientY };
  });
  window.addEventListener('mouseleave', () => {
    pointer = { x: -9999, y: -9999 };
  });
}
