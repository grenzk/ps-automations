[CmdletBinding()]
param(
    [string]$ReferenceUrl
)

$referencePath = Join-Path -Path $PSScriptRoot -ChildPath 'reference.html'
$modifiedPath = Join-Path -Path $PSScriptRoot -ChildPath 'modified.html'

if ([string]::IsNullOrWhiteSpace((Get-Content -Raw -Path $referencePath)) -and
    [string]::IsNullOrWhiteSpace((Get-Content -Raw -Path $modifiedPath))) {
    try {
        Write-Host "`n📥 Downloading reference content from: $ReferenceUrl"
        $referenceHtml = ConvertFrom-HTML -Url $ReferenceUrl -Engine AngleSharp
        Write-Host "✅ Reference content downloaded successfully`n"
    }
    catch {
        throw "❌ Failed to download or parse HTML. $($_.Exception.Message)"
    }

    Write-Host '📋 Now copy the MODIFIED HTML content, then press Enter...'
    Read-Host
    $modifiedHtml = Get-Clipboard -Raw

    if ([string]::IsNullOrWhiteSpace($modifiedHtml)) {
        throw '❌ No content found in clipboard. Please copy the modified HTML and try again.'
    }

    Write-Host "✅ Modified content captured ($($modifiedHtml.Length) characters)`n"

    Write-Host '🔧 Transforming reference HTML for diff comparison...'
    $head = $referenceHtml.QuerySelector('head')
    $body = $referenceHtml.QuerySelector('body')

    $newDiv = ("<div id='custom-article-div' title='fLoadTKOTheme'></div>" |
            ConvertFrom-HTML -Engine AngleSharp).QuerySelector('div')

    $headComment = "<!-- $($head.OuterHtml) -->"
    $commentNode = ("<span>$headComment</span>" |
            ConvertFrom-HTML -Engine AngleSharp).QuerySelector('span').FirstChild

    while ($body.FirstChild) {
        [void]$newDiv.AppendChild($body.FirstChild)
    }

    $body.Remove()
    [void]$referenceHtml.ReplaceChild($commentNode, $head)
    [void]$referenceHtml.AppendChild($newDiv)

    Write-Host '💾 Saving files...'
    $referenceHtml.InnerHtml | Set-Content -Path $referencePath
    $modifiedHtml | Set-Content -Path $modifiedPath
}
else {
    Write-Host "`n📄 Both files already have content"
}

Write-Host '🎨 Formatting with Prettier...'
prettier --write $referencePath
if ($LASTEXITCODE -ne 0) {
    Write-Warning "⚠️ Prettier failed to format $referencePath."
}

prettier --write $modifiedPath
if ($LASTEXITCODE -ne 0) {
    Write-Warning "⚠️ Prettier failed to format $modifiedPath."
}

code --diff $referencePath $modifiedPath
Write-Host "`n✅ Diff ready in VS Code`n"
