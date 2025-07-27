$sourceFile = './source.html'
$targetFile = './target.html'

$sourceFileExists = Test-Path $sourceFile
$targetFileExists = Test-Path $targetFile


if ($sourceFileExists -and $targetFileExists) {
    & git diff --no-index $sourceFile $targetFile
} else {
  if ($sourceFileExists) {
    Write-Error "Target file does not exist."
  } else {
    Write-Error "Source file does not exist."
  }
}



