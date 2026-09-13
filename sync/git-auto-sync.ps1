# ============================================
# Git Auto-Sync Script (Windows版)
# PC ↔ Chromebook 自動同期スクリプト
# ============================================
#
# 使い方 (PowerShell):
#   .\git-auto-sync.ps1 pull     → 全プロジェクトの最新を取得
#   .\git-auto-sync.ps1 push     → 変更があるプロジェクトを自動 commit + push
#   .\git-auto-sync.ps1 sync     → pull → push の両方実行
#   .\git-auto-sync.ps1 status   → 全プロジェクトの状態確認

param(
    [Parameter(Position=0)]
    [ValidateSet("pull", "push", "sync", "status")]
    [string]$Action = "sync"
)

# ── 設定 ──────────────────────────────────
# ※ PC側のプロジェクトディレクトリに合わせて変更してください
$ProjectsDir = "$env:USERPROFILE\projects"
$LogFile = "$ProjectsDir\_tools\sync\.git-sync.log"

# ── ユーティリティ ────────────────────────
function Get-GitProjects {
    Get-ChildItem -Path $ProjectsDir -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName ".git")
    }
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

# ── Pull ──────────────────────────────────
function Invoke-Pull {
    Write-Log "🔽 === AUTO-PULL 開始 ==="
    $success = 0; $fail = 0

    foreach ($proj in Get-GitProjects) {
        $name = $proj.Name
        Push-Location $proj.FullName

        try {
            git fetch origin main 2>$null
            $localHash = git rev-parse HEAD 2>$null
            $remoteHash = git rev-parse origin/main 2>$null

            if ($localHash -eq $remoteHash) {
                Write-Log "  ✓ ${name}: 最新 (変更なし)"
                $success++
                continue
            }

            # ローカル変更があればstash
            $hasChanges = $false
            $status = git status --porcelain
            if ($status) {
                $hasChanges = $true
                git stash push -m "auto-sync-stash-$(Get-Date -Format 'yyyyMMddHHmmss')" 2>$null
            }

            # Pull
            $result = git pull --rebase origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "  ✅ ${name}: 更新を取得しました"
                $success++
            } else {
                Write-Log "  ❌ ${name}: pull失敗 (競合の可能性あり)"
                git rebase --abort 2>$null
                $fail++
            }

            # stash復元
            if ($hasChanges) {
                $popResult = git stash pop 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Log "  ⚠️  ${name}: stash pop で競合。手動解決が必要です"
                }
            }
        } finally {
            Pop-Location
        }
    }
    Write-Log "🔽 PULL完了: 成功=$success, 失敗=$fail"
}

# ── Push ──────────────────────────────────
function Invoke-Push {
    Write-Log "🔼 === AUTO-PUSH 開始 ==="
    $pushed = 0; $skipped = 0

    foreach ($proj in Get-GitProjects) {
        $name = $proj.Name
        Push-Location $proj.FullName

        try {
            $status = git status --porcelain
            if (-not $status) {
                $skipped++
                continue
            }

            # 変更の概要
            $added = ($status | Where-Object { $_ -match '^\?' }).Count
            $modified = ($status | Where-Object { $_ -notmatch '^\?' }).Count
            $summary = ""
            if ($added -gt 0) { $summary += "新規${added}件 " }
            if ($modified -gt 0) { $summary += "変更${modified}件" }

            # 自動コミット
            git add -A
            $deviceName = $env:COMPUTERNAME
            $dateStr = Get-Date -Format "MM/dd HH:mm"
            $msg = "🔄 Auto-sync from ${deviceName}: ${summary}($dateStr)"
            git commit -m $msg 2>$null

            # Push
            $pushResult = git push origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "  ✅ ${name}: push完了 ($summary)"
                $pushed++
            } else {
                Write-Log "  ❌ ${name}: push失敗。git pull を先に試してください"
            }
        } finally {
            Pop-Location
        }
    }

    if ($pushed -eq 0 -and $skipped -gt 0) {
        Write-Log "🔼 PUSH: 変更なし (全${skipped}プロジェクト最新)"
    } else {
        Write-Log "🔼 PUSH完了: push=$pushed, スキップ=$skipped"
    }
}

# ── Status ────────────────────────────────
function Show-Status {
    Write-Host ""
    Write-Host "📊 === プロジェクト同期状態 ==="
    Write-Host ""

    foreach ($proj in Get-GitProjects) {
        $name = $proj.Name
        Push-Location $proj.FullName

        try {
            $changes = (git status --porcelain | Measure-Object).Count
            $branch = git branch --show-current 2>$null
            $lastCommit = git log -1 --format="%h %s" 2>$null

            if ($changes -eq 0) {
                Write-Host "  ✅ $name ($branch) - クリーン"
            } else {
                Write-Host "  📝 $name ($branch) - 未コミット変更 ${changes}件"
            }
            Write-Host "     最新: $lastCommit"
            Write-Host ""
        } finally {
            Pop-Location
        }
    }
}

# ── メイン ────────────────────────────────
switch ($Action) {
    "pull"   { Invoke-Pull }
    "push"   { Invoke-Push }
    "sync"   { Invoke-Pull; Write-Host ""; Invoke-Push }
    "status" { Show-Status }
}
