$ErrorActionPreference='Stop'
$raiz=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$ruta=Join-Path $raiz 'prueba.html'
$html=[IO.File]::ReadAllText($ruta)
$html=$html.Replace('<link rel="stylesheet" href="catalogo.css">','<link rel="stylesheet" href="catalogo.css"><link rel="stylesheet" href="secciones.css">')
$html=$html.Replace('<script src="catalogo.js" defer></script>','<script src="datos/secciones-web.js" defer></script><script src="catalogo.js" defer></script><script src="secciones.js" defer></script>')
$html=$html.Replace('<nav><a href="#catalogo">Las aves</a><a href="#territorio">El territorio</a><a href="#fuentes">El proyecto ↗</a></nav>','<nav aria-label="Menú principal"><a href="#catalogo">Las aves</a><a href="#territorio">Entornos</a><a href="#exposiciones">Exposiciones</a><a href="#videos">Vídeos y jornadas</a><a href="#proyecto">Quiénes somos</a></nav>')
$entornos=@'
<section class="habitats" aria-labelledby="habitats-title"><span class="eyebrow">EXPLORA EL TERRITORIO</span><h2 id="habitats-title">Cada entorno, una mirada.</h2><div class="habitat-grid" id="habitat-cards"></div></section>
'@
$html=$html.Replace('<section class="catalog" id="catalogo">',$entornos+'<section class="catalog" id="catalogo">')
$selector='<label class="habitat-select" for="habitat-filter">Explorar por entorno <select id="habitat-filter"><option value="Todos">Todos los entornos</option><option value="Monte / Bosque">Monte / Bosque</option><option value="humedal">Humedal</option><option value="Costa / Playas">Costa / Playas</option><option value="Jardines / Zonas urbanas">Jardines / Zonas urbanas</option></select></label>'
$html=$html.Replace('<div id="birds" class="grid"></div>',$selector+'<div id="birds" class="grid"></div>')
$secciones=@'
<section class="exhibitions" id="exposiciones" aria-labelledby="exhibitions-title"><span class="eyebrow">FOTOGRAFÍA PARA COMPARTIR</span><h2 id="exhibitions-title">Nuestras exposiciones.</h2><p>Un recorrido por las muestras fotográficas de la asociación y su archivo audiovisual.</p><div class="exhibition-grid" id="exhibition-cards"></div></section>
<section class="video-section" id="videos" aria-labelledby="videos-title"><span class="eyebrow">NATURALEZA EN MOVIMIENTO</span><h2 id="videos-title">Vídeos y jornadas.</h2><p>Las producciones audiovisuales y las jornadas de fotografía recogidas en la web original.</p><div class="video-grid" id="video-cards"></div><div class="jornadas" id="jornadas-content"></div></section>
<section class="project-section" id="proyecto" aria-labelledby="project-title"><span class="eyebrow">NATURALEZA · FOTOGRAFÍA · AMISTAD</span><h2 id="project-title">La mirada detrás de las imágenes.</h2><div class="project-grid"><article><h3>El proyecto</h3><p id="project-excerpt"></p><button class="section-link" data-section="1363">Leer la presentación <span>↗</span></button></article><article><h3>¿Quiénes somos?</h3><p id="association-excerpt"></p><button class="section-link" data-section="3232">Conocer la asociación <span>↗</span></button></article></div></section>
'@
$html=$html.Replace('<section class="sources" id="fuentes">',$secciones+'<section class="sources" id="fuentes">')
$utf8=New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($ruta,$html,$utf8)
[IO.File]::WriteAllText((Join-Path $raiz 'index.html'),$html,$utf8)
