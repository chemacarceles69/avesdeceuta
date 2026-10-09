'use strict';
const sections = window.SECCIONES_CEUTA;

function sectionPhoto(photo, title, index) {
  return `<figure><img src="${imageUrl(photo)}" alt="${placeText(title)}, fotografía ${index + 1}" loading="${index === 0 ? 'eager' : 'lazy'}" decoding="async"><figcaption><span>${String(index + 1).padStart(2, '0')}</span><span>${placeText(title)}</span></figcaption></figure>`;
}
function videoPanel(id, label) {
  return `<div class="video-panel"><button class="video-play" data-video="${esc(id)}" aria-label="Reproducir ${placeText(label)}"><span class="play-icon" aria-hidden="true">▶</span><span>${placeText(label)}</span><small>Reproducir vídeo</small></button></div><a class="video-external" href="https://www.youtube.com/watch?v=${esc(id)}" target="_blank" rel="noopener">Ver en YouTube ↗</a>`;
}
function openSection(section, label) {
  const lines = section.text.filter(line => line !== section.title && line !== 'Naturaleza por descubrir');
  document.querySelector('#detail-content').innerHTML = `<div class="species-intro"><span class="eyebrow">AVES DE CEUTA (España) · ${esc(label.toUpperCase())}</span><h2 id="detail-title">${placeText(section.title)}</h2><div class="section-reading">${lines.map(line => `<p>${placeText(line)}</p>`).join('')}</div></div>${section.videos.map((id, i) => `<div class="section-video">${videoPanel(id, section.videos.length === 1 ? section.title : `${section.title} · ${i + 1}`)}</div>`).join('')}<div class="photo-stream">${section.photos.map((photo, i) => sectionPhoto(photo, section.title, i)).join('')}</div><div class="gallery-end"><a href="${esc(section.source)}" target="_blank" rel="noopener">Consultar la página original ↗</a><br><button class="button" data-close-gallery>Volver a la web ↑</button></div>`;
  document.body.classList.add('gallery-open');
  dialog.showModal();
  dialog.scrollTop = 0;
  document.querySelector('.close').focus({preventScroll:true});
}
function renderSections() {
  if (!sections) return;
  document.querySelector('#exhibition-cards').innerHTML = sections.exposiciones.map(section => `<article class="exhibition-card"><button class="exhibition-photo" data-section="${esc(section.id)}" aria-label="Ver ${placeText(section.title)}"><img src="${imageUrl(section.cover || section.photos[0])}" alt="${placeText(section.title)}" loading="lazy" decoding="async"></button><span class="eyebrow">EXPOSICIÓN FOTOGRÁFICA · ${section.photos.length} IMÁGENES</span><h3>${placeText(section.title)}</h3><button class="section-link" data-section="${esc(section.id)}">Visitar la exposición <span>↗</span></button></article>`).join('');
  if (sections.indiceExposiciones.videos.length) {
    document.querySelector('#exhibition-cards').insertAdjacentHTML('beforeend', `<article class="exhibition-card exhibition-film"><span class="eyebrow">ARCHIVO AUDIOVISUAL · 2008</span><h3>Exposición Facultad 2008</h3><p>El vídeo enlazado en la sección de exposiciones de la web original.</p>${videoPanel(sections.indiceExposiciones.videos[0], 'Exposición Facultad 2008')}</article>`);
  }
  document.querySelector('#video-cards').innerHTML = sections.videos.videos.map((id, i) => `<article class="video-card"><span class="eyebrow">AVES EN MOVIMIENTO · ${String(i + 1).padStart(2, '0')}</span>${videoPanel(id, `Vídeo de aves ${i + 1}`)}</article>`).join('');
  document.querySelector('#jornadas-content').innerHTML = `<h3>${placeText(sections.jornadas.title)}</h3>${sections.jornadas.videos.map(id => videoPanel(id, sections.jornadas.title)).join('')}`;
  document.querySelector('#project-excerpt').textContent = sections.proyecto.text.find(line => line.length > 100)?.replace(/\bceuta\b(?!\s*\(España\))/gi, match => `${match} (España)`) || '';
  document.querySelector('#association-excerpt').textContent = sections.asociacion.text[0].replace(/\bceuta\b(?!\s*\(España\))/gi, match => `${match} (España)`);
  const environmentNames = ['Monte / Bosque', 'humedal', 'Costa / Playas', 'Jardines / Zonas urbanas'];
  if (sections.proyecto.photos.length) {
    document.querySelector('#territorio').insertAdjacentHTML('afterend', `<figure class="territory-panorama"><img src="${imageUrl(sections.proyecto.photos[0])}" alt="Panorámica de Ceuta (España), imagen de la presentación original" loading="lazy" decoding="async"><figcaption>Ceuta (España) · Una ciudad entre dos continentes</figcaption></figure>`);
  }
  document.querySelector('#habitat-cards').innerHTML = environmentNames.map(name => {
    const bird = birds.find(b => b.habitats.includes(name));
    const label = name === 'humedal' ? 'Humedal' : name;
    return `<a class="habitat-card" href="#catalogo" data-habitat="${esc(name)}">${bird ? `<img src="${imageUrl(bird.photos[0])}" alt="${esc(bird.name)}" loading="lazy" decoding="async">` : ''}<span>${esc(label)} <span aria-hidden="true">↗</span></span></a>`;
  }).join('');
}
document.addEventListener('click', e => {
  const sectionButton = e.target.closest('[data-section]');
  if (sectionButton && sections) {
    const id = sectionButton.dataset.section;
    const section = [sections.proyecto, sections.asociacion, ...sections.exposiciones].find(s => s.id === id);
    if (section) openSection(section, sections.exposiciones.includes(section) ? 'Exposiciones' : 'El proyecto');
  }
  const play = e.target.closest('[data-video]');
  if (play) {
    const id = play.dataset.video;
    if (!/^[A-Za-z0-9_-]{11}$/.test(id)) return;
    const iframe = document.createElement('iframe');
    iframe.src = `https://www.youtube-nocookie.com/embed/${id}?autoplay=1`;
    iframe.title = play.getAttribute('aria-label').replace(/^Reproducir /, '');
    iframe.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
    iframe.allowFullscreen = true;
    iframe.referrerPolicy = 'strict-origin-when-cross-origin';
    play.replaceWith(iframe);
  }
});
dialog.addEventListener('close', () => {
  document.querySelectorAll('#detail-content iframe').forEach(frame => frame.remove());
});
renderSections();
