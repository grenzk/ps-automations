param(
    [Parameter(Mandatory)]
    [string]$originalUrl,

    [Parameter(Mandatory)]
    [string]$modifiedUrl
)

try {
    Write-Host "`n📥 Downloading HTML content..."
    $originalHtml = ConvertFrom-HTML -Url $originalUrl -Engine AngleSharp
    $modifiedHtml = ConvertFrom-HTML -Url $modifiedUrl -Engine AngleSharp
}
catch {
    Write-Error "❌ Failed to download or parse HTML. Error: $_"
    exit 1
}

Write-Host '🔧 Transforming original HTML for diff comparison...'
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

Write-Host '💾 Saving files...'
$originalPath = Join-Path $PSScriptRoot 'original.html'
$originalHtml.InnerHtml | Set-Content -Path $originalPath

$modifiedPath = Join-Path $PSScriptRoot 'modified.html'
$modifiedHtml.InnerHtml | Set-Content -Path $modifiedPath

Write-Host '🎨 Formatting with Prettier...'
prettier --write $originalPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Prettier failed to format $originalPath."
    exit 1
}

prettier --write $modifiedPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Prettier failed to format $modifiedPath."
    exit 1
}

code --diff $originalPath $modifiedPath
Write-Host "✅ Done! Diff window opened.`n"

