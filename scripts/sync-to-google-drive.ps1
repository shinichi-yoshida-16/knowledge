$src = Join-Path (git rev-parse --show-toplevel) "docs"
$dst = "H:\マイドライブ\_knowledge"

robocopy $src $dst *.md /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Error "Drive sync failed (robocopy code $LASTEXITCODE)" }
