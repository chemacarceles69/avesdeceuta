param([string]$Archivo = 'E:\avesdeceuta.wordpress.2026-10-08.xml')
$ErrorActionPreference = 'Stop'
$raiz = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$doc = New-Object System.Xml.XmlDocument
$doc.XmlResolver = $null
$doc.Load($Archivo)
$ns = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
$ns.AddNamespace('wp','http://wordpress.org/export/1.2/')
$ns.AddNamespace('content','http://purl.org/rss/1.0/modules/content/')
function Campo($nodo,$ruta) { $v=$nodo.SelectSingleNode($ruta,$ns); if($null -ne $v){return $v.InnerText}; return '' }
function Texto($html) {
    $s=[regex]::Replace($html,'(?is)<(script|style)\b[^>]*>.*?</\1>','')
    $s=[regex]::Replace($s,'(?i)<br\s*/?>|</p>|</h[1-6]>|</li>',"`n")
    $s=[regex]::Replace($s,'<[^>]+>','')
    return [Net.WebUtility]::HtmlDecode($s)
}
$items=$doc.SelectNodes('/rss/channel/item')
$medios=@{}
foreach($i in $items) {if((Campo $i 'wp:post_type') -eq 'attachment'){$medios[(Campo $i 'wp:post_id')]=Campo $i 'wp:attachment_url'}}
$faltantes=New-Object 'System.Collections.Generic.HashSet[string]'
function Local($url) {
    $marca='/wp-content/uploads/'
    if(-not $url -or -not $url.Contains($marca)){return ''}
    $ruta='uploads/'+[Uri]::UnescapeDataString(($url.Substring($url.IndexOf($marca)+$marca.Length) -split '[?#]')[0])
    $original=[regex]::Replace($ruta,'-\d+x\d+(?=\.[^.]+$)','')
    if(Test-Path -LiteralPath (Join-Path $raiz $original) -PathType Leaf){return $original}
    if(Test-Path -LiteralPath (Join-Path $raiz $ruta) -PathType Leaf){return $ruta}
    [void]$faltantes.Add($ruta);return ''
}
function Extraer($i) {
    $html=Campo $i 'content:encoded'
    $activos=New-Object 'System.Collections.Generic.List[string]'
    $order=Campo $i "wp:postmeta[wp:meta_key='ppb_form_data_order']/wp:meta_value"
    foreach($key in $order.Split(',')){
        $json=Campo $i ("wp:postmeta[wp:meta_key='"+$key+"_data']/wp:meta_value")
        if(-not $json){continue}
        try{$bloque=$json|ConvertFrom-Json}catch{continue}
        foreach($prop in $bloque.psobject.Properties){
            if($prop.Name -match '_content$|_image$|_video_url$'){
                $activos.Add([Uri]::UnescapeDataString([string]$prop.Value))
            }
        }
    }
    $textos=New-Object 'System.Collections.Generic.List[string]'
    foreach($fragmento in @($html)+@($activos)){
        foreach($linea in ((Texto $fragmento) -split '[\r\n]+')){
            $limpio=[regex]::Replace($linea,'\s+',' ').Trim()
            if($limpio -and -not $textos.Contains($limpio)){$textos.Add($limpio)}
        }
    }
    $todo=$html+"`n"+($activos -join "`n")
    $urls=@([regex]::Matches($todo,'(?is)(?:href|src)\s*=\s*["'']([^"'']+/wp-content/uploads/[^"'']+)["'']')|ForEach-Object{[Net.WebUtility]::HtmlDecode($_.Groups[1].Value)})
    $urls+=@($activos|Where-Object{$_ -match '^https?://[^\s<>]+/wp-content/uploads/[^\s<>]+$'})
    $thumb=Campo $i "wp:postmeta[wp:meta_key='_thumbnail_id']/wp:meta_value"
    $cover='';if($medios.ContainsKey($thumb)){$cover=Local $medios[$thumb]}
    $photos=@($urls|ForEach-Object{Local $_}|Where-Object{$_}|Select-Object -Unique)
    $videos=@([regex]::Matches($todo,'(?:youtube\.com/(?:embed/|watch\?v=)|youtu\.be/)([A-Za-z0-9_-]{11})')|ForEach-Object{$_.Groups[1].Value}|Select-Object -Unique)
    return [pscustomobject][ordered]@{
        id=Campo $i 'wp:post_id';type=Campo $i 'wp:post_type';status=Campo $i 'wp:status';title=[string]$i.title
        slug=Campo $i 'wp:post_name';source=[string]$i.link;text=@($textos);photos=$photos;cover=$cover;videos=$videos
        originalHtml=$html
    }
}
$paginas=@($items|Where-Object{(Campo $_ 'wp:post_type') -eq 'page'}|ForEach-Object{Extraer $_})
$expos=@($items|Where-Object{(Campo $_ 'wp:post_type') -eq 'portfolios' -and $_.title -match '^Exposici' -and (Campo $_ 'wp:status') -eq 'publish'}|ForEach-Object{Extraer $_})
$archivo=[ordered]@{paginas=$paginas;exposiciones=$expos}
$utf8=New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $raiz 'datos\secciones-wordpress.json'),(ConvertTo-Json -InputObject $archivo -Depth 12),$utf8)
function Publico($id) { $p=$paginas|Where-Object{$_.id -eq $id -and $_.status -eq 'publish'};return $p|Select-Object id,title,source,text,photos,cover,videos }
$web=[ordered]@{
    proyecto=Publico '1363';asociacion=Publico '3232';exposiciones=@($expos|Select-Object id,title,source,text,photos,cover,videos)
    videos=Publico '4009';jornadas=Publico '4118';indiceExposiciones=Publico '2376'
}
[IO.File]::WriteAllText((Join-Path $raiz 'datos\secciones-web.js'),'window.SECCIONES_CEUTA = '+(ConvertTo-Json -InputObject $web -Depth 12)+';',$utf8)
[ordered]@{paginasArchivadas=$paginas.Count;exposiciones=@($expos|Select-Object title,@{n='fotos';e={$_.photos.Count}},@{n='textos';e={$_.text.Count}});videosAves=$web.videos.videos.Count;videosJornadas=$web.jornadas.videos.Count;videosExposiciones=$web.indiceExposiciones.videos.Count;imagenesFaltantes=@($faltantes)}|ConvertTo-Json -Depth 6
