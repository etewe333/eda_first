# .claude/scripts/build_and_lint.ps1
param (
    [string]$ModuleName = "ALU" # 默认模块名，可由 Claude 传入
)

# 1. 加载环境配置 (从之前步骤生成的 env_info.json)
$config = Get-Content ".claude/env_info.json" | ConvertFrom-Json
$msys_bash = "$($config.msys_root)\usr\bin\bash.exe"
$msystem = $config.msystem.ToLower()

Write-Host "--- [HOOK START] RTL Build & Lint for $ModuleName ---" -ForegroundColor Cyan

# 2. 执行 sbt 构建 RTL
Write-Host "Step 1: Running sbt to generate Verilog..." -ForegroundColor Yellow
sbt "runMain $($ModuleName)Gen"

if ($LASTEXITCODE -ne 0) {
    Write-Error "SBT Build Failed!"
    exit 1
}

# 3. 寻找生成的 Verilog 文件 (通常在 generated/ 目录下)
$verilogFile = "generated/$ModuleName.sv"
if (-not (Test-Path $verilogFile)) {
    $verilogFile = "generated/$ModuleName.v"
}

if (-not (Test-Path $verilogFile)) {
    Write-Error "Verilog file not found in generated/ directory!"
    exit 1
}

# 4. 执行 Verilator Lint 检查
Write-Host "Step 2: Running Verilator Lint..." -ForegroundColor Yellow
$lintCmd = "export PATH='/$msystem/bin:/usr/bin:`$PATH' && export LC_ALL=C && verilator --lint-only -Igenerated $verilogFile --top-module $ModuleName"

& $msys_bash -c $lintCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "Lint Failed! Please fix the Chisel code based on the errors above." -ForegroundColor Red
    exit 1
}

Write-Host "--- [HOOK SUCCESS] RTL is clean and ready! ---" -ForegroundColor Green
exit 0