'use strict';
const birds = window.AVES_CEUTA || [];
const search = document.querySelector('#search');
const grid = document.querySelector('#birds');
const dialog = document.querySelector('#detail');
let filter = 'Todas', shown = 24, habitat = 'Todos';
function esc(value) { return String(value || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function placeText(value) { return esc(String(value || '').replace(/\bceuta\b(?!\s*\(España\))/gi, match => `${match} (España)`)); }
function imageUrl(path) { return path.split('/').map(encodeURIComponent).join('/'); }
function normalized(v) { return v.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('es'); }
function matches() { const q = normalized(search.value.trim()); return birds.filter(b => (filter === 'Todas' || b.group === filter) && (habitat === 'Todos' || b.habitats.includes(habitat)) && normalized(`${b.name} ${b.latin}`).includes(q)); }
function render() {
  const items = matches();
  document.querySelector('#count').textContent = `${items.length} fichas de aves`;
  document.querySelector('#empty').hidden = items.length > 0;
  grid.innerHTML = items.slice(0, shown).map(b => `<article class="card"><button class="photo-card" data-bird="${esc(b.id)}" aria-label="Abrir galería de ${esc(b.name)}"><img src="${imageUrl(b.photos[0])}" alt="${esc(b.name)}" loading="lazy" decoding="async"><span class="photo-count">${b.photos.length} fotos</span></button><h3>${esc(b.name)}</h3><span class="latin">${esc(b.latin)}</span><button data-bird="${esc(b.id)}">Ver fotografías <span>↗</span></button></article>`).join('');
  const more = document.querySelector('#load-more'); more.hidden = shown >= items.length;
  more.textContent = `Ver más aves (${Math.max(0, items.length - shown)})`;
}
document.querySelectorAll('[data-filter]').forEach(button => button.addEventListener('click', () => {
  filter = button.dataset.filter; shown = 24;
  document.querySelectorAll('[data-filter]').forEach(el => { el.classList.toggle('active', el === button); el.setAttribute('aria-pressed', String(el === button)); }); render();
}));
search.addEventListener('input', () => { shown = 24; render(); });
document.querySelector('#habitat-filter').addEventListener('change', e => { habitat = e.target.value; shown = 24; render(); });
document.addEventListener('click', e => {
  const card = e.target.closest('[data-habitat]');
  if (!card) return;
  habitat = card.dataset.habitat; filter = 'Todas'; shown = 24; search.value = '';
  document.querySelector('#habitat-filter').value = habitat;
  document.querySelectorAll('[data-filter]').forEach(button => {const active=button.dataset.filter === 'Todas';button.classList.toggle('active',active);button.setAttribute('aria-pressed',String(active));});
  render();
});
document.querySelector('#load-more').addEventListener('click', () => { const next = shown; shown += 24; render(); grid.children[next]?.querySelector('button').focus({preventScroll:true}); });
function openBird(b) {
  document.querySelector('#detail-content').innerHTML = `
    <div class="species-intro">
      <span class="eyebrow">AVES DE CEUTA (España) · GALERÍA FOTOGRÁFICA</span>
      <h2 id="detail-title">${esc(b.name)}</h2>
      <div class="species-meta"><span class="latin">${esc(b.latin)}</span><span>${b.photos.length} fotografías</span></div>
      <details class="bird-text"><summary>Conocer esta ave</summary>
        ${b.measurements.map(t => `<p class="measurements">${placeText(t)}</p>`).join('')}
        ${b.paragraphs.length ? b.paragraphs.map(t => `<p>${placeText(t)}</p>`).join('') : '<p>La descripción de esta especie está pendiente.</p>'}
        ${b.habitats.length ? `<p>Entornos del catálogo original: ${b.habitats.map(esc).join(' · ')}</p>` : ''}
        <p class="source-note">Texto recuperado de la web anterior; pendiente de revisión.</p>
        <a href="${esc(b.source)}" target="_blank" rel="noopener">Consultar la ficha original ↗</a>
      </details>
    </div>
    <div class="photo-stream" aria-label="Fotografías de ${esc(b.name)}">
      ${b.photos.map((photo, i) => `<figure>
        <img src="${imageUrl(photo)}" alt="${esc(b.name)}, fotografía ${i + 1}" loading="${i === 0 ? 'eager' : 'lazy'}" decoding="async">
        <figcaption><span>${String(i + 1).padStart(2, '0')} / ${String(b.photos.length).padStart(2, '0')}</span><span>${esc(b.name)}</span></figcaption>
      </figure>`).join('')}
    </div>
    <div class="gallery-end"><p>Has visto las ${b.photos.length} fotografías de esta galería.</p><button class="button" data-close-gallery>Volver al catálogo ↑</button></div>`;
  document.body.classList.add('gallery-open');
  dialog.showModal();
  dialog.scrollTop = 0;
  document.querySelector('.close').focus({preventScroll:true});
}
grid.addEventListener('click', e => { const button = e.target.closest('[data-bird]'); if (!button) return; const b = birds.find(b => b.id === button.dataset.bird); if (b) openBird(b); });
dialog.addEventListener('click', e => {
  if (e.target.closest('[data-close-gallery]')) dialog.close();
});
dialog.addEventListener('close', () => document.body.classList.remove('gallery-open'));
document.querySelector('.close').addEventListener('click', () => dialog.close());
render();
