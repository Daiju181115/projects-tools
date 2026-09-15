# ============================================
# Windows タスクスケジューラに自動同期を登録
# ※ 管理者権限で PowerShell を開いて実行してください
# ============================================

$ScriptPath = "$env:USERPROFILE\projects\_tools\sync\git-auto-sync.ps1"

# 15分ごとの自動同期タスクを登録
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" sync"

$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited

Register-ScheduledTask `
    -TaskName "GitAutoSync" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "PC ↔ Chromebook Git自動同期 (15分ごと)" `
    -Force

Write-Host ""
Write-Host "✅ タスクスケジューラに 'GitAutoSync' を登録しました！"
Write-Host "   実行間隔: 15分ごと"
Write-Host "   スクリプト: $ScriptPath"
Write-Host ""
Write-Host "確認: タスクスケジューラを開いて 'GitAutoSync' を検索してください"

