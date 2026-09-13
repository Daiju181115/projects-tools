#!/bin/bash
# GuitarVision 開発サーバー起動スクリプト (Port: 3003)

PROJECT_DIR="/home/fuuchanpapa/projects/guitar-vision"

echo "🎸 =========================================="
echo "   GuitarVision - ギター指板暗記トレーニング"
echo "=========================================="

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ エラー: $PROJECT_DIR が見つかりません。"
  exit 1
fi

cd "$PROJECT_DIR"
echo "🚀 開発サーバーを起動中... (Port: 3003)"
echo "👉 ブラウザで開く: http://localhost:3003"
echo ""

npm run dev
