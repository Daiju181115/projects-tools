#!/bin/bash
# SunoBeat Studio 起動スクリプト

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/suno-beat-studio" && pwd)"
cd "$DIR"

echo "=========================================="
echo "🎵 SunoBeat Studio (音楽AI制作アシスタント) を起動中..."
echo "=========================================="
echo "ブラウザで以下のURLを開いてください:"
echo "👉 http://localhost:3002"
echo "=========================================="
echo "終了するには Ctrl + C を押してください。"
echo ""

npm run dev -- --port 3002 --host 0.0.0.0
