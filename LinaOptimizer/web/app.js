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
  data.forEach(tweak => {
    const card = document.createElement('div');
    card.className = 'tweak-card';
    card.innerHTML = `
      <label style="display:flex; gap:12px; align-items:flex-start;">
        <input type="checkbox" data-key="${tweak.key}" data-type="${tweak.type}" />
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
    tweakGrid.appendChild(card);
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
