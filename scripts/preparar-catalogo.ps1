$ErrorActionPreference = 'Stop'
$raiz = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$catalogo = Get-Content -LiteralPath (Join-Path $raiz 'datos\catalogo-wordpress.json') -Raw | ConvertFrom-Json
$adjuntos = @(Get-Content -LiteralPath (Join-Path $raiz 'datos\imagenes-wordpress.json') -Raw | ConvertFrom-Json)
$archivos = @(Get-ChildItem -LiteralPath (Join-Path $raiz 'uploads') -File -Recurse)
$indice = @{}
foreach ($archivo in $archivos) {
    $ruta = $archivo.FullName.Substring($raiz.Length + 1).Replace('\','/')
    $indice[$ruta] = $ruta
}
$faltan = New-Object 'System.Collections.Generic.HashSet[string]'
function Local($url) {
    if (-not $url) { return '' }
    $marca = '/wp-content/uploads/'
    $pos = $url.IndexOf($marca)
    if ($pos -lt 0) { return '' }
    $ruta = 'uploads/' + [Uri]::UnescapeDataString(($url.Substring($pos + $marca.Length) -split '[?#]')[0])
    if ($indice.ContainsKey($ruta)) { return $indice[$ruta] }
    [void]$faltan.Add($ruta)
    return ''
}
$aves = @($catalogo.fichas | Where-Object { $_.estadoWordpress -eq 'publish' -and $_.nombreComun -notmatch '^Exposici' } | ForEach-Object {
    $ficha = $_
    $fotos = @(@($ficha.imagenDestacadaUrl) + @($ficha.imagenesReferenciadas) | ForEach-Object {
        $local = Local $_
        if ($local) {
            $original = [regex]::Replace($local, '-\d+x\d+(?=\.[^.]+$)', '')
            if ($indice.ContainsKey($original)) { $indice[$original] } else { $local }
        }
    } | Select-Object -Unique)
    $grupo = 'Otras'
    if ($ficha.categorias.slug -contains 'rapaces') { $grupo = 'Rapaces' }
    elseif ($ficha.categorias.slug -contains 'marinas') { $grupo = 'Marinas y acuáticas' }
    elseif ($ficha.categorias.slug -contains 'pajaritos') { $grupo = 'Pájaros' }
    $nombre = $ficha.nombreComun
    $parrafos = @($ficha.parrafosOriginales | Where-Object { $_ -ne $ficha.nombreCientificoOriginal -and $_ -ne $nombre -and $_ -notmatch 'Longitud|Envergadura' })
    [pscustomobject][ordered]@{
        id = $ficha.id
        name = $nombre
        latin = $ficha.nombreCientificoOriginal
        group = $grupo
        habitats = @($ficha.categorias | Where-Object { $_.slug -in @('bosque','humedal','playas','jardines','urbanas') } | ForEach-Object { $_.nombre })
        measurements = @($ficha.medidasOriginales)
        paragraphs = $parrafos
        source = $ficha.fuente
        photos = $fotos
        reviewPending = $true
    }
} | Sort-Object name)
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $raiz 'datos\catalogo-web.js'), 'window.AVES_CEUTA = ' + (ConvertTo-Json -InputObject $aves -Depth 8) + ';', $utf8)
$adjuntosEncontrados = @($adjuntos | Where-Object { $_.archivo -and $indice.ContainsKey('uploads/' + $_.archivo.Replace('\','/')) }).Count
$resumen = [ordered]@{
    entradasAves = $aves.Count
    archivosLocales = $archivos.Count
    registrosAdjuntos = $adjuntos.Count
    registrosAdjuntosConArchivoLocal = $adjuntosEncontrados
    fotografiasEnCatalogo = @($aves | ForEach-Object { $_.photos } | Select-Object -Unique).Count
    fichasSinFotos = @($aves | Where-Object { $_.photos.Count -eq 0 } | ForEach-Object { $_.name })
    rutasReferenciadasNoEncontradas = @($faltan | Sort-Object)
}
[IO.File]::WriteAllText((Join-Path $raiz 'datos\comprobacion-fotografias.json'), (ConvertTo-Json -InputObject $resumen -Depth 8), $utf8)
[pscustomobject]$resumen | Select-Object entradasAves,archivosLocales,registrosAdjuntos,registrosAdjuntosConArchivoLocal,fotografiasEnCatalogo,fichasSinFotos | ConvertTo-Json -Depth 5
Write-Output ('Rutas referenciadas no encontradas: ' + $faltan.Count)
