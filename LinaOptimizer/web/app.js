const tweakGrid = document.getElementById('tweakGrid');
const systemLog = document.getElementById('systemLog');
const hardwareInfo = document.getElementById('hardwareInfo');

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
  const groups = {
    cpu: 'CPU',
    gpu: 'GPU',
    system: 'Sistema',
    general: 'Geral',
    internet: 'Internet',
    debloat: 'Debloat'
  };

  const grouped = data.reduce((acc, tweak) => {
    const key = tweak.group || 'general';
    if (!acc[key]) acc[key] = [];
    acc[key].push(tweak);
    return acc;
  }, {});

  Object.keys(groups).forEach(groupKey => {
    const items = grouped[groupKey] || [];
    if (!items.length) return;
    const section = document.createElement('div');
    section.className = 'tweak-section';
    section.innerHTML = `<h3>${groups[groupKey]}</h3><div class="tweak-grid" id="grid-${groupKey}"></div>`;
    tweakGrid.appendChild(section);
    const grid = section.querySelector('.tweak-grid');
    items.forEach(tweak => {
      const card = document.createElement('div');
      card.className = 'tweak-card';
      card.innerHTML = `
        <label class="checkbox-wrap">
          <input type="checkbox" data-key="${tweak.key}" data-type="${tweak.type}" />
          <span class="check-box"></span>
          <div>
            <div class="tweak-title">${tweak.title}</div>
            <div class="tweak-desc">${tweak.description}</div>
            <div class="tweak-meta">
              <span>${tweak.category}</span>
              <span class="${riskClass(tweak.risk)}">${tweak.risk}</span>
            </div>
          </div>
        </label>
      `;
      grid.appendChild(card);
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

fetchTweaks();
fetchHardware();

const applyBtn = document.getElementById('applyTweaks');
applyBtn.addEventListener('click', applyTweaks);

document.getElementById('refreshHardware').addEventListener('click', fetchHardware);
