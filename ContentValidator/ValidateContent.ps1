param(
    [Parameter(Mandatory)]
    [string]$originalUrl,

    [Parameter(Mandatory)]
    [string]$modifiedUrl
)

$originalHtml = ConvertFrom-HTML -Url $originalUrl -Engine AngleSharp
$modifiedHtml = ConvertFrom-HTML -Url $modifiedUrl -Engine AngleSharp

$head = $originalHtml.QuerySelector('head')
$body = $originalHtml.QuerySelector('body')

$newDiv = ("<div id='custom-article-div' title='fLoadTKOTheme'></div>" |
        ConvertFrom-HTML -Engine AngleSharp).QuerySelector('div')

$headComment = "<!-- $($head.OuterHtml) -->"
$commentNode = ("<span>$headComment</span>" |
        ConvertFrom-HTML -Engine AngleSharp).QuerySelector('span').FirstChild

while ($body.FirstChild) {
    [void]$newDiv.AppendChild($body.FirstChild)
}

$body.Remove()
[void]$originalHtml.ReplaceChild($commentNode, $head)
[void]$originalHtml.AppendChild($newDiv)

$originalPath = Join-Path $PSScriptRoot 'original.html'
$originalHtml.InnerHtml | Set-Content -Path $originalPath

$modifiedPath = Join-Path $PSScriptRoot 'modified.html'
$modifiedHtml.InnerHtml | Set-Content -Path $modifiedPath

prettier --write $originalPath
prettier --write $modifiedPath

code --diff $originalPath $modifiedPath

