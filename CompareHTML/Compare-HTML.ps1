param([string]$OriginalUrl)

$originalPath = Join-Path -Path $PSScriptRoot -ChildPath 'original.html'
$modifiedPath = Join-Path -Path $PSScriptRoot -ChildPath 'modified.html'

if ([string]::IsNullOrWhiteSpace((Get-Content -Raw -Path $originalPath)) -and
    [string]::IsNullOrWhiteSpace((Get-Content -Raw -Path $modifiedPath))) {
    try {
        Write-Host "`n📥 Downloading HTML content..."
        $originalHtml = ConvertFrom-HTML -Url $OriginalUrl -Engine AngleSharp
        $modifiedHtml = Get-Clipboard
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
    $originalHtml.InnerHtml | Set-Content -Path $originalPath
    $modifiedHtml | Set-Content -Path $modifiedPath
}
else {
    Write-Host "`n📄 Both files already have content."
}

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
Write-Host "✅ Diff ready in VS Code.`n"

