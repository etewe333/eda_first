# detect_env.ps1 - 自动化路径感知版
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 路径初始化 (基于脚本所在位置 .claude/scripts/)
$ScriptDir = $PSScriptRoot
$ProjRoot = Resolve-Path "$ScriptDir\..\.."
$ConfigDir = Join-Path $ProjRoot ".claude"
$LogDir = Join-Path $ProjRoot "agent\logs"
$EnvJsonPath = Join-Path $ConfigDir "env_info.json"
$DiscoveryLog = Join-Path $LogDir "env_discovery.log"

# 确保目录存在
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }

# 定义一个内部函数，同时输出到屏幕和日志文件
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] $Message" | Out-File $DiscoveryLog -Append -Encoding utf8
    Write-Host $Message -ForegroundColor $Color
}

Write-Log "--- 启动环境探测 ---" Cyan
Write-Log "项目根目录: $ProjRoot" Gray

# 2. 探测 MSYS2 安装位置
Write-Log "正在检索注册表以寻找 MSYS2..."
$regInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", 
                            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", 
                            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
           Where-Object { $_.DisplayName -like "*MSYS2*" } | Select-Object -First 1

if (-not $regInfo) {
    Write-Log "错误：在注册表中未发现 MSYS2。请确保已安装并添加到控制面板。" Red
    exit 1
}

$msysRoot = $regInfo.InstallLocation.TrimEnd('\')
$bashPath = "$msysRoot\usr\bin\bash.exe"
Write-Log "发现 MSYS2 根目录: $msysRoot" Green

# 3. 探测 Verilator
Write-Log "正在扫描子系统中的 Verilator..." Cyan
$subsystems = @("mingw64", "ucrt64", "clang64", "mingw32")
$foundEnv = "NOT_FOUND"

foreach ($sub in $subsystems) {
    if (Test-Path "$msysRoot\$sub\bin\verilator") {
        $foundEnv = $sub.ToUpper()
        Write-Log "在子系统 [$foundEnv] 中发现 Verilator。" Green
        break
    }
}

if ($foundEnv -eq "NOT_FOUND") {
    Write-Log "错误：未能在任一子系统中找到 verilator。" Red
    exit 1
}

# 4. 验证环境
Write-Log "正在进行工具链验证..." Cyan
$env:MSYSTEM = $foundEnv
$bashArgs = @(
    "--login", 
    "-c", 
    "export PATH='/$($foundEnv.ToLower())/bin:/usr/bin:`$PATH' && export LC_ALL=C && verilator --version"
)

try {
    # 捕获标准输出和错误输出
    $verOutput = & $bashPath @bashArgs 2>&1
    if ($verOutput -like "*Verilator*") {
        Write-Log "验证成功: $verOutput" Green
        
        # 5. 保存结果至 .claude/env_info.json
        $envDict = [ordered]@{
            msys_root   = $msysRoot
            bash_path   = $bashPath
            msystem     = $foundEnv
            proj_root   = $ProjRoot.ToString()
            last_check  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $envDict | ConvertTo-Json | Out-File $EnvJsonPath -Encoding utf8
        Write-Log "环境配置已持久化至: $EnvJsonPath" Gray
    } else {
        Write-Log "验证失败：Verilator 未响应版本查询。" Red
        exit 1
    }
} catch {
    Write-Log "执行异常: $($_.Exception.Message)" Red
    exit 1
}

Write-Log "--- 探测任务完成 ---" Cyan
$envDict = [ordered]@{
    computer_name = $env:COMPUTERNAME        # 电脑名称
    user_name     = $env:USERNAME            # 当前用户名
    proj_root     = $ProjRoot.ToString()     # 项目绝对路径
    msys_root     = $msysRoot
    bash_path     = $bashPath
    msystem       = $foundEnv
    last_check    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$envDict | ConvertTo-Json | Out-File $EnvJsonPath -Encoding utf8
Write-Log "环境指纹已记录：$($env:COMPUTERNAME)@$($env:USERNAME)" Gray