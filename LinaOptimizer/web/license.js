const licenseKeyInput = document.getElementById('licenseKey');
const licenseSubmit = document.getElementById('licenseSubmit');
const licenseStatus = document.getElementById('licenseStatus');

function setStatus(message, state) {
  licenseStatus.textContent = message;
  licenseStatus.className = `status ${state || ''}`.trim();
}

async function validateKey() {
  const key = licenseKeyInput.value.trim();
  if (!key) {
    setStatus('Digite a chave para continuar.', 'error');
    return;
  }
  licenseSubmit.disabled = true;
  setStatus('Validando licença...', '');
  try {
    const res = await fetch('/api/license/validate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key })
    });
    const result = await res.json();
    if (result.valid) {
      setStatus('Licença validada! Redirecionando...', 'success');
      setTimeout(() => {
        window.location.href = '/';
      }, 800);
    } else {
      setStatus(result.message || 'Licença inválida.', 'error');
    }
  } catch (error) {
    setStatus('Falha ao validar licença.', 'error');
  } finally {
    licenseSubmit.disabled = false;
  }
}

licenseSubmit.addEventListener('click', validateKey);
licenseKeyInput.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') {
    validateKey();
  }
});
