[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$File,

    [Parameter(Mandatory)]
    [ValidateLength(1, 50)]
    [string]$Pattern
)

function Test-WebpageContent {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$Domain,
        [string]$Path
    )

    try {
        $baseUrl = $Domain.TrimEnd('/')
        $normalizedPath = ([string]::IsNullOrWhiteSpace($Path)) ? '' : '/' + $Path.TrimStart('/')
        $url = $baseUrl + $normalizedPath

        $response = Invoke-WebRequest -OperationTimeoutSeconds 10 -Uri $url -ErrorAction Stop
        $hasMatch = $response.Content | Select-String -Quiet -Pattern $Pattern

        $status = $hasMatch ? '✅ Match' : '❌ No match'
        $color = $hasMatch ? 'Green' : 'Red'

        Write-Host "Checked: $url - $status" -ForegroundColor $color

        $hasMatch
    }
    catch {
        Write-Error "Failed to check $url. $_"
        $false
    }
}

$OutputFile = "$HOME/Downloads/data-updated.xlsx"

Write-Host "`n🔍 Initializing content scan..."

if (-not (Test-Path $File)) {
    throw "File not found: $File"
}

Write-Host "Reading Excel file: $File"
$data = Import-Excel -DataOnly -Path $File
$data | ForEach-Object -Process {
    $_ | Add-Member -NotePropertyName 'HasMatch' -NotePropertyValue $false
}
$totalItems = $data.Count

if ($totalItems -eq 0) {
    throw 'No data found in the Excel file.'
}

Write-Host "Found $($totalItems) HTML files to check`n"

$currentItem = 0

foreach ($row in $data) {
    $currentItem++

    $percentComplete = [math]::Round(($currentItem / $totalItems) * 100, 2)
    Write-Progress -Id 1 -Activity 'Scanning content' `
        -Status "Processing $currentItem of $totalItems ($percentComplete%)" `
        -PercentComplete $percentComplete

    if ([string]::IsNullOrWhiteSpace($row.Domain)) {
        Write-Warning "Row ${currentItem}: Empty domain, skipping..."
        continue
    }

    $row.HasMatch = Test-WebpageContent -Domain $row.Domain -Path $row.Path

    Start-Sleep -Milliseconds 500
}

Write-Progress -Id 1 -Activity 'Scanning content' -Completed

Write-Host "Exporting results to: $OutputFile"
$data | Export-Excel -AutoSize -FreezeTopRow -BoldTopRow -Path $OutputFile

$matchCount = ($data | Where-Object { $_.HasMatch }).Count

Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host ('Pattern     : {0}' -f $Pattern)
Write-Host ('Checked     : {0}' -f $totalItems)
Write-Host ('Matches     : {0}' -f $matchCount) -ForegroundColor Green
Write-Host ('No matches  : {0}' -f ($totalItems - $matchCount)) -ForegroundColor Red
Write-Host ('Output file : {0}' -f $OutputFile)
Write-Host "`n✅ Script completed successfully`n"


