(function () {
  // Pricing toggle: monthly / annual / perpetual
  var toggle = document.querySelector('[data-pricing-toggle]');
  if (toggle) {
    var buttons = toggle.querySelectorAll('button');
    function select(mode) {
      buttons.forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.mode === mode)); });
      document.querySelectorAll('[data-price]').forEach(function (el) {
        var v = el.getAttribute('data-price-' + mode);
        if (v === null) { el.hidden = true; return; }
        el.hidden = false;
        el.querySelector('.amount').textContent = v;
        el.querySelector('.period').textContent = el.getAttribute('data-period-' + mode) || '';
      });
      document.querySelectorAll('[data-only]').forEach(function (el) { el.hidden = el.getAttribute('data-only') !== mode; });
      try { localStorage.setItem('mz-pricing-mode', mode); } catch (e) {}
    }
    buttons.forEach(function (b) { b.addEventListener('click', function () { select(b.dataset.mode); }); });
    var saved = null; try { saved = localStorage.getItem('mz-pricing-mode'); } catch (e) {}
    select(saved || 'annual');
  }
  // Compatibility filter
  var list = document.querySelector('[data-compat-list]');
  if (list) {
    var q = document.querySelector('[data-compat-q]');
    var cat = document.querySelector('[data-compat-category]');
    var rt = document.querySelector('[data-compat-runtime]');
    var items = Array.prototype.slice.call(list.querySelectorAll('[data-app]'));
    var count = document.querySelector('[data-compat-count]');
    function apply() {
      var needle = (q.value || '').trim().toLowerCase();
      var shown = 0;
      items.forEach(function (it) {
        var ok = true;
        if (needle && it.getAttribute('data-search').indexOf(needle) < 0) ok = false;
        if (cat.value && it.getAttribute('data-category') !== cat.value) ok = false;
        if (rt.value && it.getAttribute('data-runtime') !== rt.value && it.getAttribute('data-runtime') !== 'either') ok = false;
        it.hidden = !ok; if (ok) shown++;
      });
      if (count) count.textContent = shown + ' of ' + items.length + ' apps';
    }
    [q, cat, rt].forEach(function (el) { el.addEventListener('input', apply); el.addEventListener('change', apply); });
    apply();
  }
})();
