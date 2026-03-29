/**
 * Searchable dial-code and nationality pickers for check-in forms.
 */
(function () {
  'use strict';

  const DIAL = [
    { code: '+966', name: 'Saudi Arabia' },
    { code: '+962', name: 'Jordan' },
    { code: '+971', name: 'United Arab Emirates' },
    { code: '+965', name: 'Kuwait' },
    { code: '+973', name: 'Bahrain' },
    { code: '+968', name: 'Oman' },
    { code: '+974', name: 'Qatar' },
    { code: '+20', name: 'Egypt' },
    { code: '+212', name: 'Morocco' },
    { code: '+213', name: 'Algeria' },
    { code: '+216', name: 'Tunisia' },
    { code: '+218', name: 'Libya' },
    { code: '+249', name: 'Sudan' },
    { code: '+964', name: 'Iraq' },
    { code: '+963', name: 'Syria' },
    { code: '+961', name: 'Lebanon' },
    { code: '+970', name: 'Palestine' },
    { code: '+972', name: 'Israel' },
    { code: '+90', name: 'Turkey' },
    { code: '+98', name: 'Iran' },
    { code: '+1', name: 'United States / Canada' },
    { code: '+44', name: 'United Kingdom' },
    { code: '+33', name: 'France' },
    { code: '+49', name: 'Germany' },
    { code: '+39', name: 'Italy' },
    { code: '+34', name: 'Spain' },
    { code: '+31', name: 'Netherlands' },
    { code: '+32', name: 'Belgium' },
    { code: '+41', name: 'Switzerland' },
    { code: '+43', name: 'Austria' },
    { code: '+46', name: 'Sweden' },
    { code: '+47', name: 'Norway' },
    { code: '+45', name: 'Denmark' },
    { code: '+358', name: 'Finland' },
    { code: '+353', name: 'Ireland' },
    { code: '+351', name: 'Portugal' },
    { code: '+30', name: 'Greece' },
    { code: '+7', name: 'Russia / Kazakhstan' },
    { code: '+380', name: 'Ukraine' },
    { code: '+48', name: 'Poland' },
    { code: '+420', name: 'Czech Republic' },
    { code: '+36', name: 'Hungary' },
    { code: '+40', name: 'Romania' },
    { code: '+91', name: 'India' },
    { code: '+92', name: 'Pakistan' },
    { code: '+880', name: 'Bangladesh' },
    { code: '+94', name: 'Sri Lanka' },
    { code: '+977', name: 'Nepal' },
    { code: '+86', name: 'China' },
    { code: '+852', name: 'Hong Kong' },
    { code: '+886', name: 'Taiwan' },
    { code: '+81', name: 'Japan' },
    { code: '+82', name: 'South Korea' },
    { code: '+65', name: 'Singapore' },
    { code: '+60', name: 'Malaysia' },
    { code: '+66', name: 'Thailand' },
    { code: '+84', name: 'Vietnam' },
    { code: '+63', name: 'Philippines' },
    { code: '+62', name: 'Indonesia' },
    { code: '+61', name: 'Australia' },
    { code: '+64', name: 'New Zealand' },
    { code: '+27', name: 'South Africa' },
    { code: '+234', name: 'Nigeria' },
    { code: '+254', name: 'Kenya' },
    { code: '+256', name: 'Uganda' },
    { code: '+255', name: 'Tanzania' },
    { code: '+55', name: 'Brazil' },
    { code: '+52', name: 'Mexico' },
    { code: '+54', name: 'Argentina' },
    { code: '+57', name: 'Colombia' },
    { code: '+56', name: 'Chile' },
    { code: '+51', name: 'Peru' },
  ];

  const NATIONALITIES = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia', 'Austria', 'Bahrain', 'Bangladesh',
    'Belgium', 'Brazil', 'Canada', 'China', 'Colombia', 'Denmark', 'Egypt', 'Finland', 'France', 'Germany',
    'Greece', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Italy', 'Japan', 'Jordan', 'Kuwait',
    'Lebanon', 'Libya', 'Malaysia', 'Mexico', 'Morocco', 'Netherlands', 'New Zealand', 'Norway', 'Oman',
    'Pakistan', 'Palestine', 'Philippines', 'Poland', 'Portugal', 'Qatar', 'Russia', 'Saudi Arabia',
    'Singapore', 'South Africa', 'South Korea', 'Spain', 'Sudan', 'Sweden', 'Switzerland', 'Syria',
    'Thailand', 'Tunisia', 'Turkey', 'UAE', 'UK', 'USA', 'Vietnam', 'Yemen',
  ];

  const natUnique = [...new Set(NATIONALITIES)].sort((a, b) => a.localeCompare(b));

  function norm(s) {
    return (s || '').toLowerCase().trim();
  }

  function closeAllPanels() {
    document.querySelectorAll('.chk-combo-panel').forEach((p) => {
      p.hidden = true;
      p.setAttribute('aria-hidden', 'true');
      const w = p.closest('.chk-combo');
      const b = w && w.querySelector('.chk-combo-btn');
      if (b) b.setAttribute('aria-expanded', 'false');
    });
  }

  let docCloseBound = false;
  function ensureDocClose() {
    if (docCloseBound) return;
    docCloseBound = true;
    document.addEventListener('click', () => closeAllPanels());
  }

  function bindDialCombo(root) {
    const wrap = root.closest('.chk-combo-dial');
    if (!wrap) return;
    const name = wrap.dataset.name || 'countryCode';
    const initial = wrap.dataset.value || '+966';
    let hidden = wrap.querySelector('input[type="hidden"][data-chk-combo-hidden]');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = name;
      hidden.setAttribute('data-chk-combo-hidden', '1');
      wrap.appendChild(hidden);
    }
    hidden.value = initial;

    const btn = wrap.querySelector('.chk-combo-btn');
    const panel = wrap.querySelector('.chk-combo-panel');
    const search = wrap.querySelector('.chk-combo-search');
    const list = wrap.querySelector('.chk-combo-list');

    function labelFor(code) {
      const row = DIAL.find((d) => d.code === code);
      return row ? row.name + ' ' + row.code : code;
    }

    function setValue(code) {
      hidden.value = code;
      btn.querySelector('.chk-combo-btn-text').textContent = labelFor(code);
      panel.hidden = true;
      panel.setAttribute('aria-hidden', 'true');
      btn.setAttribute('aria-expanded', 'false');
    }

    function render(filter) {
      const q = norm(filter);
      list.innerHTML = '';
      const rows = DIAL.filter(
        (d) => !q || norm(d.name).includes(q) || d.code.replace('+', '').includes(q) || norm(d.code).includes(q)
      );
      rows.forEach((d) => {
        const li = document.createElement('li');
        li.setAttribute('role', 'option');
        li.className = 'chk-combo-option';
        li.textContent = d.name + ' ' + d.code;
        li.addEventListener('mousedown', (e) => e.preventDefault());
        li.addEventListener('click', () => setValue(d.code));
        list.appendChild(li);
      });
      if (!rows.length) {
        const li = document.createElement('li');
        li.className = 'chk-combo-empty';
        li.textContent = 'No matches';
        list.appendChild(li);
      }
    }

    setValue(initial);
    render('');

    ensureDocClose();

    panel.addEventListener('click', (e) => e.stopPropagation());

    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const willOpen = panel.hidden;
      closeAllPanels();
      if (willOpen) {
        panel.hidden = false;
        panel.setAttribute('aria-hidden', 'false');
        btn.setAttribute('aria-expanded', 'true');
        search.value = '';
        render('');
        search.focus();
      }
    });

    search.addEventListener('click', (e) => e.stopPropagation());

    search.addEventListener('input', () => render(search.value));
    search.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        closeAllPanels();
        btn.focus();
      }
    });
  }

  function bindNationalityCombo(root) {
    const wrap = root.closest('.chk-combo-nationality');
    if (!wrap) return;
    const name = wrap.dataset.name || 'nationality';
    const initial = wrap.dataset.value || '';
    let hidden = wrap.querySelector('input[type="hidden"][data-chk-combo-hidden]');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = name;
      hidden.required = wrap.hasAttribute('data-required');
      hidden.setAttribute('data-chk-combo-hidden', '1');
      wrap.appendChild(hidden);
    }
    if (initial) hidden.value = initial;

    const btn = wrap.querySelector('.chk-combo-btn');
    const panel = wrap.querySelector('.chk-combo-panel');
    const search = wrap.querySelector('.chk-combo-search');
    const list = wrap.querySelector('.chk-combo-list');

    function setValue(val) {
      hidden.value = val;
      btn.querySelector('.chk-combo-btn-text').textContent = val || 'Select country';
      panel.hidden = true;
      panel.setAttribute('aria-hidden', 'true');
      btn.setAttribute('aria-expanded', 'false');
    }

    function render(filter) {
      const q = norm(filter);
      list.innerHTML = '';
      natUnique
        .filter((c) => !q || norm(c).includes(q))
        .forEach((c) => {
          const li = document.createElement('li');
          li.setAttribute('role', 'option');
          li.className = 'chk-combo-option';
          li.textContent = c;
          li.addEventListener('mousedown', (e) => e.preventDefault());
          li.addEventListener('click', () => setValue(c));
          list.appendChild(li);
        });
    }

    if (initial) setValue(initial);
    else btn.querySelector('.chk-combo-btn-text').textContent = 'Select country';
    render('');

    ensureDocClose();

    panel.addEventListener('click', (e) => e.stopPropagation());

    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const willOpen = panel.hidden;
      closeAllPanels();
      if (willOpen) {
        panel.hidden = false;
        panel.setAttribute('aria-hidden', 'false');
        btn.setAttribute('aria-expanded', 'true');
        search.value = '';
        render('');
        search.focus();
      }
    });

    search.addEventListener('click', (e) => e.stopPropagation());

    search.addEventListener('input', () => render(search.value));
    search.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        closeAllPanels();
        btn.focus();
      }
    });
  }

  window.initCheckinCombos = function (scope) {
    const root = scope || document;
    root.querySelectorAll('.chk-combo-dial').forEach((el) => {
      if (!el.dataset.chkComboBound) {
        el.dataset.chkComboBound = '1';
        bindDialCombo(el);
      }
    });
    root.querySelectorAll('.chk-combo-nationality').forEach((el) => {
      if (!el.dataset.chkComboBound) {
        el.dataset.chkComboBound = '1';
        bindNationalityCombo(el);
      }
    });
  };

  document.addEventListener('DOMContentLoaded', function () {
    window.initCheckinCombos(document);
  });
})();
