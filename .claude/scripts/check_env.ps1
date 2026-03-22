$JsonPath = "$PSScriptRoot/../env_info.json"
if (!(Test-Path $JsonPath)) { "INVALID"; exit }

$env_info = Get-Content $JsonPath | ConvertFrom-Json
$is_valid = $true

if ($env_info.computer_name -ne $env:COMPUTERNAME) { $is_valid = $false }
if ($env_info.user_name -ne $env:USERNAME) { $is_valid = $false }
if (!(Test-Path $env_info.msys_root)) { $is_valid = $false }

if ($is_valid) { "VALID" } else { "INVALID" }