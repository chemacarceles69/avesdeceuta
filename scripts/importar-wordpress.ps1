param([string]$Archivo = 'E:\avesdeceuta.wordpress.2026-10-08.xml')
$ErrorActionPreference = 'Stop'
$destino = Join-Path $PSScriptRoot '..\datos'
[void][IO.Directory]::CreateDirectory($destino)
$doc = New-Object System.Xml.XmlDocument
$doc.XmlResolver = $null
$doc.Load($Archivo)
$ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
$ns.AddNamespace('wp', 'http://wordpress.org/export/1.2/')
$ns.AddNamespace('content', 'http://purl.org/rss/1.0/modules/content/')
function Campo($nodo, $ruta) {
    $valor = $nodo.SelectSingleNode($ruta, $ns)
    if ($null -ne $valor) { return $valor.InnerText }
    return ''
}
function Texto($html) {
    $limpio = [regex]::Replace($html, '(?is)<(script|style)\b[^>]*>.*?</\1>', '')
    $limpio = [regex]::Replace($limpio, '(?is)<[^>]+>', ' ')
    return [regex]::Replace([Net.WebUtility]::HtmlDecode($limpio), '\s+', ' ').Trim()
}
$items = $doc.SelectNodes('/rss/channel/item')
$adjuntos = @($items | Where-Object { (Campo $_ 'wp:post_type') -eq 'attachment' } | ForEach-Object {
    [pscustomobject][ordered]@{
        id = Campo $_ 'wp:post_id'
        titulo = [string]$_.title
        url = Campo $_ 'wp:attachment_url'
        archivo = Campo $_ "wp:postmeta[wp:meta_key='_wp_attached_file']/wp:meta_value"
        fichaPadreId = Campo $_ 'wp:post_parent'
        leyenda = Campo $_ "*[local-name()='encoded' and namespace-uri()='http://wordpress.org/export/1.2/excerpt/']"
    }
})
$porId = @{}
foreach ($adjunto in $adjuntos) { $porId[$adjunto.id] = $adjunto }
$fichas = @($items | Where-Object { (Campo $_ 'wp:post_type') -eq 'portfolios' } | ForEach-Object {
    $html = Campo $_ 'content:encoded'
    $parrafos = @([regex]::Matches($html, '(?is)<p\b[^>]*>(.*?)</p>') | ForEach-Object { Texto $_.Groups[1].Value } | Where-Object { $_ })
    $cientifico = @($parrafos | Where-Object { $_ -match '^[A-Z][a-z]+\s+[a-z]+(?:\s+[a-z]+)?$' } | Select-Object -First 1)
    $medidas = @($parrafos | Where-Object { $_ -match 'Longitud|Envergadura' })
    $urls = @([regex]::Matches($html, '(?is)(?:href|src)\s*=\s*["'']([^"'']+/wp-content/uploads/[^"'']+)["'']') | ForEach-Object { [Net.WebUtility]::HtmlDecode($_.Groups[1].Value) } | Select-Object -Unique)
    $miniaturaId = Campo $_ "wp:postmeta[wp:meta_key='_thumbnail_id']/wp:meta_value"
    $notas = @('Contenido heredado; pendiente de revisión de exactitud y taxonomía.')
    if ($cientifico.Count -eq 0) { $notas += 'Nombre científico no extraído automáticamente.' }
    if ($medidas.Count -eq 0) { $notas += 'Sin medidas reconocidas; revisar si es una ficha de especie.' }
    [pscustomobject][ordered]@{
        id = Campo $_ 'wp:post_id'
        nombreComun = [string]$_.title
        slug = Campo $_ 'wp:post_name'
        estadoWordpress = Campo $_ 'wp:status'
        fuente = [string]$_.link
        nombreCientificoOriginal = $(if ($cientifico.Count) { $cientifico[0] } else { '' })
        medidasOriginales = $medidas
        parrafosOriginales = $parrafos
        textoOriginal = Texto $html
        categorias = @($_.SelectNodes('category') | ForEach-Object { [ordered]@{ taxonomia = $_.GetAttribute('domain'); nombre = $_.InnerText; slug = $_.GetAttribute('nicename') } })
        imagenDestacadaId = $miniaturaId
        imagenDestacadaUrl = $(if ($porId.ContainsKey($miniaturaId)) { $porId[$miniaturaId].url } else { '' })
        imagenesReferenciadas = $urls
        revision = $notas
    }
})
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $destino 'catalogo-wordpress.json'), (ConvertTo-Json -InputObject ([ordered]@{ origen = [IO.Path]::GetFileName($Archivo); fichas = $fichas }) -Depth 12), $utf8)
[IO.File]::WriteAllText((Join-Path $destino 'imagenes-wordpress.json'), (ConvertTo-Json -InputObject $adjuntos -Depth 6), $utf8)
$resumen = [ordered]@{
    fichas = $fichas.Count
    estados = @($fichas | Group-Object estadoWordpress | Select-Object Name, Count)
    sinNombreExtraido = @($fichas | Where-Object { -not $_.nombreCientificoOriginal } | ForEach-Object { $_.nombreComun })
    sinMedidas = @($fichas | Where-Object { $_.medidasOriginales.Count -eq 0 } | ForEach-Object { $_.nombreComun })
    adjuntos = $adjuntos.Count
    urlsImagenesEnFichas = @($fichas | ForEach-Object { $_.imagenesReferenciadas } | Select-Object -Unique).Count
    paginas = @($items | Where-Object { (Campo $_ 'wp:post_type') -eq 'page' }).Count
    galerias = @($items | Where-Object { (Campo $_ 'wp:post_type') -eq 'galleries' }).Count
}
[IO.File]::WriteAllText((Join-Path $destino 'resumen-importacion.json'), (ConvertTo-Json -InputObject $resumen -Depth 6), $utf8)
$resumen | ConvertTo-Json -Depth 6
