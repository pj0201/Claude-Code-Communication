# A2A System Startup Script
# エージェント間通信システム起動スクリプト

param(
    [string]$Mode = "all"  # all, broker, workers, test
)

$ErrorActionPreference = "Stop"

# 色付き出力関数
function Write-ColorOutput {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

# プロセスチェック関数
function Test-ProcessRunning {
    param([string]$ProcessName)
    $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    return $null -ne $process
}

# 環境変数をロード
function Load-Environment {
    Write-ColorOutput "`n📦 Loading environment variables..." "Cyan"
    
    $envFile = "$PSScriptRoot\..\\.env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^#=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
                Write-ColorOutput "  ✅ $key loaded" "Green"
            }
        }
    }
    else {
        Write-ColorOutput "  ⚠️ .env file not found!" "Yellow"
        Write-ColorOutput "  Please run SET-REAL-API-KEYS.ps1 first" "Yellow"
        exit 1
    }
}

# ブローカー起動
function Start-Broker {
    Write-ColorOutput "`n🌐 Starting ZeroMQ Message Broker..." "Cyan"
    
    $brokerScript = "$PSScriptRoot\zmq_broker\broker.py"
    if (Test-Path $brokerScript) {
        Start-Process -FilePath "C:\Python313\python.exe" `
                     -ArgumentList $brokerScript `
                     -WorkingDirectory "$PSScriptRoot\zmq_broker" `
                     -NoNewWindow
        
        Start-Sleep -Seconds 2
        Write-ColorOutput "  ✅ Broker started on ports 5555-5557" "Green"
    }
    else {
        Write-ColorOutput "  ❌ Broker script not found!" "Red"
        exit 1
    }
}

# オーケストレーター起動
function Start-Orchestrator {
    Write-ColorOutput "`n🎭 Starting Orchestrator..." "Cyan"
    
    $orchestratorScript = "$PSScriptRoot\orchestrator\orchestrator.py"
    if (Test-Path $orchestratorScript) {
        Start-Process -FilePath "C:\Python313\python.exe" `
                     -ArgumentList $orchestratorScript `
                     -WorkingDirectory "$PSScriptRoot\orchestrator" `
                     -NoNewWindow
        
        Start-Sleep -Seconds 2
        Write-ColorOutput "  ✅ Orchestrator started on port 5558" "Green"
    }
    else {
        Write-ColorOutput "  ❌ Orchestrator script not found!" "Red"
        exit 1
    }
}

# ワーカー起動
function Start-Workers {
    Write-ColorOutput "`n🤖 Starting AI Workers..." "Cyan"
    
    # GPT-5 Worker
    $gpt5Script = "$PSScriptRoot\workers\gpt5_worker.py"
    if (Test-Path $gpt5Script) {
        Start-Process -FilePath "C:\Python313\python.exe" `
                     -ArgumentList $gpt5Script `
                     -WorkingDirectory "$PSScriptRoot\workers" `
                     -NoNewWindow
        
        Start-Sleep -Seconds 1
        Write-ColorOutput "  ✅ GPT-5 Worker started" "Green"
    }
    else {
        Write-ColorOutput "  ⚠️ GPT-5 Worker script not found" "Yellow"
    }
    
    # Grok4 Worker
    $grok4Script = "$PSScriptRoot\workers\grok4_worker.py"
    if (Test-Path $grok4Script) {
        Start-Process -FilePath "C:\Python313\python.exe" `
                     -ArgumentList $grok4Script `
                     -WorkingDirectory "$PSScriptRoot\workers" `
                     -NoNewWindow
        
        Start-Sleep -Seconds 1
        Write-ColorOutput "  ✅ Grok4 Worker started" "Green"
    }
    else {
        Write-ColorOutput "  ⚠️ Grok4 Worker script not found" "Yellow"
    }
}

# Claudeブリッジ起動
function Start-ClaudeBridge {
    Write-ColorOutput "`n🌉 Starting Claude Bridge..." "Cyan"
    
    $bridgeScript = "$PSScriptRoot\bridges\claude_bridge.py"
    if (Test-Path $bridgeScript) {
        Start-Process -FilePath "C:\Python313\python.exe" `
                     -ArgumentList $bridgeScript `
                     -WorkingDirectory "$PSScriptRoot\bridges" `
                     -NoNewWindow
        
        Start-Sleep -Seconds 1
        Write-ColorOutput "  ✅ Claude Bridge started" "Green"
        Write-ColorOutput "  📥 Inbox: $PSScriptRoot\shared\claude_inbox" "Gray"
        Write-ColorOutput "  📤 Outbox: $PSScriptRoot\shared\claude_outbox" "Gray"
    }
    else {
        Write-ColorOutput "  ⚠️ Claude Bridge script not found" "Yellow"
    }
}

# テストメッセージ送信
function Send-TestMessage {
    Write-ColorOutput "`n🧪 Sending test message..." "Cyan"
    
    $testMessage = @{
        type = "QUESTION"
        sender = "test_client"
        target = "any"
        question = "A2Aシステムは正常に動作していますか？"
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json -Depth 10
    
    $inboxDir = "$PSScriptRoot\shared\claude_inbox"
    if (-not (Test-Path $inboxDir)) {
        New-Item -ItemType Directory -Path $inboxDir -Force | Out-Null
    }
    
    $testFile = "$inboxDir\test_message_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $testMessage | Out-File -FilePath $testFile -Encoding UTF8
    
    Write-ColorOutput "  ✅ Test message sent to: $testFile" "Green"
    Write-ColorOutput "  👀 Check outbox for responses" "Yellow"
}

# システム状態表示
function Show-SystemStatus {
    Write-ColorOutput "`n📊 System Status:" "Cyan"
    Write-ColorOutput "=================================" "Gray"
    
    # Pythonプロセスをチェック
    $pythonProcesses = Get-Process -Name "python*" -ErrorAction SilentlyContinue
    
    if ($pythonProcesses) {
        Write-ColorOutput "  ✅ Python processes running: $($pythonProcesses.Count)" "Green"
        $pythonProcesses | ForEach-Object {
            Write-ColorOutput "    - PID: $($_.Id) | CPU: $($_.CPU)" "Gray"
        }
    }
    else {
        Write-ColorOutput "  ⚠️ No Python processes found" "Yellow"
    }
    
    Write-ColorOutput "`n📁 Log Files:" "Cyan"
    Get-ChildItem -Path $PSScriptRoot -Filter "*.log" -Recurse | ForEach-Object {
        Write-ColorOutput "  - $($_.Name)" "Gray"
    }
}

# メイン処理
function Main {
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan -NoNewline
    Write-ColorOutput "=" -ForegroundColor Cyan
    
    Write-ColorOutput "🚀 A2A System Launcher" "White"
    Write-ColorOutput "Agent-to-Agent Communication System" "Gray"
    Write-ColorOutput "=================================" "Cyan"
    Write-ColorOutput "Mode: $Mode" "Yellow"
    
    # 環境変数をロード
    Load-Environment
    
    switch ($Mode) {
        "all" {
            Start-Broker
            Start-Sleep -Seconds 2
            Start-Orchestrator
            Start-Sleep -Seconds 2
            Start-Workers
            Start-Sleep -Seconds 2
            Start-ClaudeBridge
            Start-Sleep -Seconds 3
            Send-TestMessage
            Show-SystemStatus
        }
        "broker" {
            Start-Broker
            Show-SystemStatus
        }
        "workers" {
            Start-Workers
            Show-SystemStatus
        }
        "test" {
            Send-TestMessage
            Show-SystemStatus
        }
        default {
            Write-ColorOutput "Unknown mode: $Mode" "Red"
            Write-ColorOutput "Available modes: all, broker, workers, test" "Yellow"
            exit 1
        }
    }
    
    Write-ColorOutput "`n✅ A2A System startup complete!" "Green"
    Write-ColorOutput "Press Ctrl+C to stop all processes" "Yellow"
    
    # プロセス監視ループ
    if ($Mode -eq "all") {
        while ($true) {
            Start-Sleep -Seconds 5
            # 簡易的なヘルスチェック
            $pythonCount = (Get-Process -Name "python*" -ErrorAction SilentlyContinue).Count
            if ($pythonCount -lt 3) {
                Write-ColorOutput "`n⚠️ Warning: Expected at least 3 Python processes, found $pythonCount" "Yellow"
            }
        }
    }
}

# スクリプト実行
try {
    Main
}
catch {
    Write-ColorOutput "`n❌ Error: $_" "Red"
    exit 1
}
finally {
    # クリーンアップ
    Write-ColorOutput "`n🛑 Shutting down A2A System..." "Yellow"
    Get-Process -Name "python*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-ColorOutput "Goodbye!" "Cyan"
}