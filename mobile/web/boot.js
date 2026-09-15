// PERCHÉ (hardening 2.4): script ESTERNO e non inline — consente una CSP
// `script-src 'self'` senza `unsafe-inline` sullo shell HTML. Contiene:
// (1) check di compatibilità (WebGL/WASM), (2) messaggi di progresso sotto il
// loader, (3) fallback d'errore, (4) handler del pulsante "Riprova".
(function () {
  'use strict';

  var loadingEl = document.getElementById('loading');
  var errorEl = document.getElementById('error');
  var hintEl = document.getElementById('loading-hint');
  var errorMsgEl = document.getElementById('error-msg');
  var started = false;

  function fail(msg) {
    loadingEl.style.display = 'none';
    errorEl.style.display = 'block';
    errorMsgEl.textContent = msg;
  }

  // Detect browser issues early
  try {
    var c = document.createElement('canvas');
    var gl = c.getContext('webgl2') || c.getContext('webgl');
    if (!gl) {
      fail(
        "Il tuo browser non supporta WebGL, necessario per eseguire l'app. " +
          'Prova con Chrome, Edge o Firefox aggiornato.'
      );
    }

    if (typeof WebAssembly !== 'object') {
      fail(
        'Il tuo browser non supporta WebAssembly. Aggiorna il browser ' +
          "all'ultima versione."
      );
    }
  } catch (e) {
    fail("Errore durante il controllo di compatibilità del browser: " + e.message);
  }

  // Show progress
  var steps = [
    'Connessione al server…',
    "Preparazione dell'app…",
    'Caricamento in corso…',
  ];
  var stepIdx = 0;
  var interval = setInterval(function () {
    stepIdx = (stepIdx + 1) % steps.length;
    hintEl.textContent = steps[stepIdx];
  }, 2000);

  // Hide loader when Flutter takes over
  var observer = new MutationObserver(function () {
    if (
      document.querySelector('flt-glass-pane') ||
      document.querySelector('flutter-view')
    ) {
      loadingEl.style.display = 'none';
      clearInterval(interval);
      observer.disconnect();
      started = true;
    }
  });
  observer.observe(document.body, {childList: true, subtree: true});

  // Timeout fallback
  setTimeout(function () {
    if (!started) {
      fail(
        'Tempo di caricamento scaduto. Verifica la connessione a internet e ' +
          'riprova. Se il problema persiste, svuota la cache del browser.'
      );
      clearInterval(interval);
    }
  }, 30000);

  // Retry button: prima era un handler onclick inline nel markup HTML.
  var retryBtn = document.getElementById('retry-btn');
  if (retryBtn) {
    retryBtn.addEventListener('click', function () {
      location.reload();
    });
  }
})();
