const tweakGrid = document.getElementById('tweakGrid');
const systemLog = document.getElementById('systemLog');
const hardwareInfo = document.getElementById('hardwareInfo');
const categoryBar = document.getElementById('categoryBar');
const gamesGrid = document.getElementById('gamesGrid');

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
  const groups = [
    { key: 'all', label: 'Todos' },
    { key: 'cpu', label: 'CPU' },
    { key: 'gpu', label: 'GPU' },
    { key: 'games', label: 'Jogos' },
    { key: 'extra', label: 'Extra' },
    { key: 'kernel', label: 'Kernel' },
    { key: 'system', label: 'Sistema' },
    { key: 'debloat', label: 'Debloat' }
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
    const list = filter === 'all' ? data : (grouped[filter] || []);
    list.forEach(tweak => {
      const card = document.createElement('div');
      card.className = 'tweak-card';
      card.innerHTML = `
        <label class="checkbox-wrap">
          <input type="checkbox" data-key="${tweak.key}" data-type="${tweak.type}" />
          <span class="toggle-bar"></span>
          <div>
            <div class="tweak-title">${tweak.title}</div>
            <div class="tweak-desc">${tweak.description}</div>
            <div class="tweak-meta">
              <span class="${riskClass(tweak.risk)}">${tweak.risk}</span>
              <span>${tweak.category}</span>
            </div>
          </div>
        </label>
      `;
      grid.appendChild(card);
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
  hardwareInfo.textContent = Object.entries(data).map(([k,v]) => `${k}: ${v}`).join('\n');
}

async function applyTweaks() {
  const checked = Array.from(document.querySelectorAll('input[type="checkbox"]:checked'));
  const payload = checked.map(input => ({ key: input.dataset.key, type: input.dataset.type, enabled: true }));
  const res = await fetch('/api/apply', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ tweaks: payload })
  });
  const result = await res.json();
  systemLog.textContent = result.log.join('\n');
}

async function fetchGames() {
  const res = await fetch('/api/games');
  const data = await res.json();
  gamesGrid.innerHTML = '';
  data.forEach(game => {
    const card = document.createElement('div');
    card.className = 'tweak-card game-card';
    card.innerHTML = `
      <div class="tweak-title">${game.name}</div>
      <div class="tweak-desc">${game.description}</div>
      <div class="tweak-meta">
        <span>${game.detectLabel}</span>
      </div>
      <div style="display:flex; gap:10px; justify-content:center; margin-top:12px;">
        <select data-game="${game.key}">
          <option value="Low">Baixo</option>
          <option value="Medium">Médio</option>
          <option value="High">Alto</option>
        </select>
        <button class="btn btn-primary apply-game" data-game="${game.key}">Aplicar</button>
      </div>
    `;
    gamesGrid.appendChild(card);
  });

  document.querySelectorAll('.apply-game').forEach(btn => {
    btn.addEventListener('click', async () => {
      const gameKey = btn.dataset.game;
      const select = document.querySelector(`select[data-game=\"${gameKey}\"]`);
      const quality = select ? select.value : 'Low';
      await fetch('/api/games/apply', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ gameKey, quality })
      });
    });
  });
}

fetchTweaks();
fetchHardware();
fetchGames();

const applyBtn = document.getElementById('applyTweaks');
applyBtn.addEventListener('click', applyTweaks);

document.getElementById('refreshHardware').addEventListener('click', fetchHardware);
