# $html = ConvertFrom-Html -Url "https://www.scrapethissite.com/pages/simple/" -Engine AngleSharp
$html = Get-Content -Path "$PSScriptRoot/modified.html" -Raw | ConvertFrom-Html -Engine AngleSharp

$head = $html.QuerySelector("head")
$body = $html.QuerySelector("body")
$divDoc = "<div id='custom-article-div' title='fLoadTKOTheme'></div>" | ConvertFrom-HTML -Engine AngleSharp
$newDiv = $divDoc.QuerySelector("#custom-article-div")

$comment = "<!-- $($head.OuterHtml) -->"
$commentFragment = "<span id='temp'>$comment</span>" | ConvertFrom-Html -Engine AngleSharp
$commentNode = $commentFragment.QuerySelector("#temp").FirstChild

while ($body.FirstChild) {
  [void]$newDiv.AppendChild($body.FirstChild)
}

$body.Remove()

[void]$html.ReplaceChild($commentNode, $head)
[void]$html.AppendChild($newDiv)
$html.InnerHtml | Set-Content -Path "$PSScriptRoot/original.html"

# code --diff "$PSScriptRoot/original.html" "$PSScriptRoot/modified.html"

