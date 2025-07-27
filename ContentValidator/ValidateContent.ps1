$sourceFile = "$PSScriptRoot/source.html"
$targetFile = "$PSScriptRoot/target.html"

$sourceFileExists = Test-Path -Path $sourceFile
$targetFileExists = Test-Path -Path $targetFile


if ($sourceFileExists -and $targetFileExists) {
    & git diff --no-index $sourceFile $targetFile
} else {
  if ($sourceFileExists) {
    Write-Error "Target file does not exist."
  } else {
    Write-Error "Source file does not exist."
  }
}



