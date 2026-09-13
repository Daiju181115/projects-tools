#!/bin/bash
# Project Hub 起動スクリプト

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/project-hub" && pwd)"
cd "$DIR"

echo "=========================================="
echo "🚀 Project Hub (開発ポータル) を起動中..."
echo "=========================================="
echo "ブラウザで以下のURLを開いてください:"
echo "👉 http://localhost:5173"
echo "=========================================="
echo "終了するには Ctrl + C を押してください。"
echo ""

npm run dev -- --host 0.0.0.0
