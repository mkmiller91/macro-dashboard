$ErrorActionPreference = "Stop"
$key = $env:FRED_API_KEY
if (-not $key) { throw "Set FRED_API_KEY first" }

$ids = "FEDFUNDS","UNRATE","CPIAUCSL","T10Y2Y","DGS10"
New-Item -ItemType Directory -Force -Path data | Out-Null
$out = [ordered]@{}

foreach ($id in $ids) {
  $meta = (Invoke-RestMethod "https://api.stlouisfed.org/fred/series?series_id=$id&api_key=$key&file_type=json").seriess[0]
  if ($meta.notes -match "(?i)copyright") {
    throw "$id has a copyright notice. Remove it or get the owner's permission."
  }
  $r = Invoke-RestMethod "https://api.stlouisfed.org/fred/series/observations?series_id=$id&api_key=$key&file_type=json&observation_start=2015-01-01"
  $obs = @($r.observations | Where-Object { $_.value -ne "." } |
    ForEach-Object { [pscustomobject]@{ date = $_.date; value = [double]$_.value } })
  $out[$id] = [ordered]@{ title = $meta.title; units = $meta.units; notes = $meta.notes; observations = $obs }
}

$out["updated"] = (Get-Date).ToUniversalTime().ToString("u")
$out | ConvertTo-Json -Depth 5 -Compress | Set-Content data/series.json -Encoding utf8