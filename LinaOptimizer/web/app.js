const tweakGrid = document.getElementById('tweakGrid');
const systemLog = document.getElementById('systemLog');
const hardwareInfo = document.getElementById('hardwareInfo');
const categoryBar = document.getElementById('categoryBar');
const gamesGrid = document.getElementById('gamesGrid');
const programsGrid = document.getElementById('programsGrid');
const tweakSearch = document.getElementById('tweakSearch');
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
    restorePoint: 'Criar Ponto',
    restoreTitle: 'Criar ponto de restauração',
    restoreDesc: 'Digite um nome para o ponto de restauração.',
    restoreApply: 'Aplicar',
    restoreClose: 'Fechar',
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
    programs: {
      title: 'Ferramentas Essenciais',
      label: 'PROGRAMAS',
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
    restorePoint: 'Create Restore Point',
    restoreTitle: 'Create restore point',
    restoreDesc: 'Enter a name for the restore point.',
    restoreApply: 'Apply',
    restoreClose: 'Close',
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
    programs: {
      title: 'Essential Tools',
      label: 'PROGRAMS',
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
    restorePoint: 'Crear punto',
    restoreTitle: 'Crear punto de restauración',
    restoreDesc: 'Introduce un nombre para el punto de restauración.',
    restoreApply: 'Aplicar',
    restoreClose: 'Cerrar',
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
    programs: {
      title: 'Herramientas esenciales',
      label: 'PROGRAMAS',
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
    restorePoint: 'Wiederherstellungspunkt',
    restoreTitle: 'Wiederherstellungspunkt erstellen',
    restoreDesc: 'Geben Sie einen Namen für den Wiederherstellungspunkt ein.',
    restoreApply: 'Anwenden',
    restoreClose: 'Schließen',
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
    programs: {
      title: 'Essenzielle Tools',
      label: 'PROGRAMME',
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
  const restoreBtn = document.getElementById('restorePointBtn');
  if (restoreBtn) restoreBtn.textContent = t.restorePoint;
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
  const modalTitle = document.getElementById('restoreModalTitle');
  const modalDesc = document.getElementById('restoreModalDesc');
  const modalApply = document.getElementById('restoreApply');
  const modalClose = document.getElementById('restoreClose');
  if (modalTitle) modalTitle.textContent = t.restoreTitle;
  if (modalDesc) modalDesc.textContent = t.restoreDesc;
  if (modalApply) modalApply.textContent = t.restoreApply;
  if (modalClose) modalClose.textContent = t.restoreClose;
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
  if (value.includes('alto') || value.includes('high')) return 'risk-high';
  if (value.includes('médio') || value.includes('medium')) return 'risk-medium';
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
    filtered.forEach(tweak => {
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
  { name: 'Process Lasso', desc: 'Gerencia prioridades e energia do sistema para reduzir stutter.', how: 'Abra e aplique o perfil “Bitsum Highest Performance” ao jogo.', url: 'https://bitsum.com/download-process-lasso/' },
  { name: 'ISLC', desc: 'Limpa standby list para reduzir travamentos em jogos.', how: 'Configure 1024MB e inicie antes de jogar.', url: 'https://www.wagnardsoft.com/ISLCw' },
  { name: 'MSI Afterburner', desc: 'Controle de GPU, fan curve e overlay.', how: 'Aplique fan curve e limites seguros.', url: 'https://www.msi.com/Landing/afterburner/graphics-cards' },
  { name: 'RivaTuner Statistics Server', desc: 'Overlay de FPS e limitador de frame.', how: 'Defina limite FPS estável e OSD.', url: 'https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html' },
  { name: 'DDU', desc: 'Remove drivers de vídeo por completo.', how: 'Execute em modo seguro antes de reinstalar o driver.', url: 'https://www.wagnardsoft.com/' },
  { name: 'NVCleanstall', desc: 'Instala drivers NVIDIA sem bloat.', how: 'Escolha componentes mínimos e instale.', url: 'https://www.techpowerup.com/nvcleanstall/' },
  { name: 'NVIDIA Profile Inspector', desc: 'Ajuste profundo de perfis NVIDIA.', how: 'Abra e aplique perfil específico do jogo.', url: 'https://github.com/Orbmu2k/nvidiaProfileInspector/releases' },
  { name: 'HWiNFO', desc: 'Monitoramento completo de hardware.', how: 'Use sensores para checar temperaturas.', url: 'https://www.hwinfo.com/download/' },
  { name: 'CPU-Z', desc: 'Informações de CPU/placa-mãe.', how: 'Valide clocks e memória.', url: 'https://www.cpuid.com/softwares/cpu-z.html' },
  { name: 'GPU-Z', desc: 'Detalhes de GPU e sensores.', how: 'Verifique clocks e VRAM.', url: 'https://www.techpowerup.com/gpuz/' },
  { name: 'CrystalDiskInfo', desc: 'Saúde de SSD/HDD.', how: 'Verifique S.M.A.R.T e temperatura.', url: 'https://crystalmark.info/en/software/crystaldiskinfo/' },
  { name: 'CrystalDiskMark', desc: 'Benchmark de armazenamento.', how: 'Teste velocidades antes/depois de tweaks.', url: 'https://crystalmark.info/en/software/crystaldiskmark/' },
  { name: 'LatencyMon', desc: 'Diagnóstico de latência DPC.', how: 'Rode por 5-10 min e analise drivers.', url: 'https://www.resplendence.com/latencymon' },
  { name: 'CapFrameX', desc: 'Medição de frametime e FPS.', how: 'Grave sessões e compare resultados.', url: 'https://www.capframex.com/' },
  { name: 'HWMonitor', desc: 'Monitor simples de sensores.', how: 'Use para checar temperaturas rápidas.', url: 'https://www.cpuid.com/softwares/hwmonitor.html' },
  { name: 'Autoruns', desc: 'Controle de inicialização do Windows.', how: 'Desative entradas não essenciais.', url: 'https://learn.microsoft.com/sysinternals/downloads/autoruns' },
  { name: 'Process Explorer', desc: 'Visão avançada de processos.', how: 'Identifique processos com alto uso.', url: 'https://learn.microsoft.com/sysinternals/downloads/process-explorer' },
  { name: 'ParkControl', desc: 'Gerencie core parking e energia.', how: 'Aplique perfil de performance.', url: 'https://bitsum.com/parkcontrol/' },
  { name: 'O&O ShutUp10', desc: 'Controle de privacidade Windows.', how: 'Aplicar recomendações seguras.', url: 'https://www.oo-software.com/en/shutup10' },
  { name: 'TCP Optimizer', desc: 'Ajustes simples de rede.', how: 'Use “Optimal” e reinicie.', url: 'https://www.speedguide.net/downloads.php' }
];

function renderPrograms() {
  if (!programsGrid) return;
  programsGrid.innerHTML = '';
  programs.forEach(program => {
    const card = document.createElement('div');
    card.className = 'tweak-card reveal';
    card.innerHTML = `
      <div class="tweak-body">
        <div class="tweak-title">${program.name}</div>
        <div class="tweak-desc">${program.desc}</div>
        <div class="tweak-meta">
          <span>${program.how}</span>
        </div>
        <div class="game-actions">
          <button class="btn btn-primary program-open" data-program="${program.name}">${t.programs.download}</button>
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
  });
}

setLanguage(langSelect ? langSelect.value : 'pt-BR');
fetchTweaks();
fetchHardware();
fetchGames();
renderPrograms();
registerRevealElements();

const applyBtn = document.getElementById('applyTweaks');
applyBtn.addEventListener('click', applyTweaks);

document.getElementById('refreshHardware')?.addEventListener('click', fetchHardware);

const restoreModal = document.getElementById('restoreModal');
const restorePointBtn = document.getElementById('restorePointBtn');
const restoreClose = document.getElementById('restoreClose');
const restoreApply = document.getElementById('restoreApply');
const restorePointName = document.getElementById('restorePointName');

function openRestoreModal() {
  if (!restoreModal) return;
  restoreModal.classList.add('active');
  restoreModal.setAttribute('aria-hidden', 'false');
  if (restorePointName) {
    restorePointName.value = '';
    restorePointName.focus();
  }
}

function closeRestoreModal() {
  if (!restoreModal) return;
  restoreModal.classList.remove('active');
  restoreModal.setAttribute('aria-hidden', 'true');
}

restorePointBtn?.addEventListener('click', openRestoreModal);
restoreClose?.addEventListener('click', closeRestoreModal);
restoreModal?.addEventListener('click', (event) => {
  if (event.target === restoreModal) {
    closeRestoreModal();
  }
});

restoreApply?.addEventListener('click', async () => {
  const name = restorePointName?.value?.trim() || 'Lina Optimizer Restore Point';
  const res = await fetch('/api/restorepoint', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name })
  });
  const result = await res.json();
  if (systemLog) {
    systemLog.dataset.locked = 'true';
    systemLog.textContent = result.message || 'Restore point processado.';
  }
  closeRestoreModal();
});

const programModal = document.getElementById('programModal');
const programModalTitle = document.getElementById('programModalTitle');
const programModalDesc = document.getElementById('programModalDesc');
const programModalHow = document.getElementById('programModalHow');
const programDownload = document.getElementById('programDownload');
const programClose = document.getElementById('programClose');

function openProgramModal(program) {
  if (!programModal) return;
  programModalTitle.textContent = program.name;
  programModalDesc.textContent = program.desc;
  programModalHow.textContent = program.how;
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
  const name = button.dataset.program;
  const program = programs.find(item => item.name === name);
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
          particleCtx.strokeStyle = `rgba(0, 243, 255, ${alpha})`;
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
      particleCtx.fillStyle = `rgba(0, 243, 255, ${alpha})`;
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
