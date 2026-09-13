#!/bin/bash
# ============================================
# Git Auto-Sync Script
# PC ↔ Chromebook 自動同期スクリプト
# ============================================
#
# 使い方:
#   ~/projects/_tools/sync/git-auto-sync.sh pull     → 全プロジェクトの最新を取得
#   ~/projects/_tools/sync/git-auto-sync.sh push     → 変更があるプロジェクトを自動 commit + push
#   ~/projects/_tools/sync/git-auto-sync.sh sync     → pull → push の両方実行
#   ~/projects/_tools/sync/git-auto-sync.sh status   → 全プロジェクトの状態確認

PROJECTS_DIR="/home/fuuchanpapa/projects"
LOG_FILE="$PROJECTS_DIR/_tools/sync/.git-sync.log"

# Git管理されているプロジェクトのみ対象
get_git_projects() {
  for dir in "$PROJECTS_DIR"/*/; do
    if [ -d "$dir/.git" ]; then
      echo "$dir"
    fi
  done
}

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  echo "[$(timestamp)] $1" | tee -a "$LOG_FILE"
}

# ──────────────────────────────────────
# Pull: 全プロジェクトの最新を取得
# ──────────────────────────────────────
do_pull() {
  log "🔽 === AUTO-PULL 開始 ==="
  local success=0
  local fail=0

  for proj in $(get_git_projects); do
    name=$(basename "$proj")
    cd "$proj" || continue

    # リモートの変更を確認
    git fetch origin main 2>/dev/null
    local_hash=$(git rev-parse HEAD 2>/dev/null)
    remote_hash=$(git rev-parse origin/main 2>/dev/null)

    if [ "$local_hash" = "$remote_hash" ]; then
      log "  ✓ $name: 最新 (変更なし)"
      ((success++))
      continue
    fi

    # ローカルに未コミットの変更がある場合は stash
    local has_changes=false
    if [ -n "$(git status --porcelain)" ]; then
      has_changes=true
      git stash push -m "auto-sync-stash-$(date +%s)" 2>/dev/null
    fi

    # Pull 実行
    if git pull --rebase origin main 2>/dev/null; then
      log "  ✅ $name: 更新を取得しました"
      ((success++))
    else
      log "  ❌ $name: pull失敗 (競合の可能性あり)"
      git rebase --abort 2>/dev/null
      ((fail++))
    fi

    # stash を戻す
    if $has_changes; then
      if ! git stash pop 2>/dev/null; then
        log "  ⚠️  $name: stash pop で競合。手動解決が必要です"
      fi
    fi
  done

  log "🔽 PULL完了: 成功=$success, 失敗=$fail"
}

# ──────────────────────────────────────
# Push: 変更があるプロジェクトを自動 commit + push
# ──────────────────────────────────────
do_push() {
  log "🔼 === AUTO-PUSH 開始 ==="
  local pushed=0
  local skipped=0

  for proj in $(get_git_projects); do
    name=$(basename "$proj")
    cd "$proj" || continue

    # 変更チェック（未追跡ファイルも含む）
    if [ -z "$(git status --porcelain)" ]; then
      ((skipped++))
      continue
    fi

    # 変更の概要を取得
    local added=$(git status --porcelain | grep "^?" | wc -l)
    local modified=$(git status --porcelain | grep -v "^?" | wc -l)
    local summary=""
    [ "$added" -gt 0 ] && summary="${summary}新規${added}件 "
    [ "$modified" -gt 0 ] && summary="${summary}変更${modified}件"

    # 自動コミット
    git add -A
    local device_name="Chromebook"
    [ -f /etc/hostname ] && device_name=$(cat /etc/hostname)
    local msg="🔄 Auto-sync from ${device_name}: ${summary}($(date '+%m/%d %H:%M'))"
    
    git commit -m "$msg" 2>/dev/null

    # Push
    if git push origin main 2>/dev/null; then
      log "  ✅ $name: push完了 ($summary)"
      ((pushed++))
    else
      log "  ❌ $name: push失敗。git pull を先に試してください"
    fi
  done

  if [ "$pushed" -eq 0 ] && [ "$skipped" -gt 0 ]; then
    log "🔼 PUSH: 変更なし (全${skipped}プロジェクト最新)"
  else
    log "🔼 PUSH完了: push=$pushed, スキップ=$skipped"
  fi
}

# ──────────────────────────────────────
# Status: 全プロジェクトの同期状態を表示
# ──────────────────────────────────────
do_status() {
  echo ""
  echo "📊 === プロジェクト同期状態 ==="
  echo ""
  
  for proj in $(get_git_projects); do
    name=$(basename "$proj")
    cd "$proj" || continue
    
    local changes=$(git status --porcelain | wc -l)
    local branch=$(git branch --show-current 2>/dev/null)
    local remote_url=$(git remote get-url origin 2>/dev/null)
    local last_commit=$(git log -1 --format="%h %s" 2>/dev/null)
    
    if [ "$changes" -eq 0 ]; then
      echo "  ✅ $name ($branch) - クリーン"
    else
      echo "  📝 $name ($branch) - 未コミット変更 ${changes}件"
    fi
    echo "     最新: $last_commit"
    echo ""
  done
}

# ──────────────────────────────────────
# Sync: pull → push の両方
# ──────────────────────────────────────
do_sync() {
  do_pull
  echo ""
  do_push
}

# ──────────────────────────────────────
# メイン
# ──────────────────────────────────────
case "${1:-sync}" in
  pull)   do_pull ;;
  push)   do_push ;;
  sync)   do_sync ;;
  status) do_status ;;
  *)
    echo "使い方: $0 {pull|push|sync|status}"
    echo ""
    echo "  pull   - 全プロジェクトの最新を取得"
    echo "  push   - 変更があるプロジェクトを自動commit+push"
    echo "  sync   - pull→pushの両方実行"
    echo "  status - 全プロジェクトの同期状態を表示"
    exit 1
    ;;
esac
