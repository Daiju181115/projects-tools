#!/bin/bash
# SunoBeat Studio スマホ共有スクリプト (QRコード＆公開URL生成)

PORT=3002
LOG_FILE="/tmp/suno-tunnel.log"

echo "======================================================"
echo "📱 SunoBeat Studio をスマホに共有中..."
echo "======================================================"

# 既存のトンネルプロセスがあれば停止
pkill -f "cloudflared tunnel --url http://localhost:$PORT" 2>/dev/null || true
rm -f "$LOG_FILE"

# トンネルをバックグラウンド起動
cloudflared tunnel --url http://localhost:$PORT > "$LOG_FILE" 2>&1 &

echo "一時的なセキュアHTTPS URLを取得しています..."
URL=""
for i in {1..20}; do
  sleep 1
  URL=$(grep -o 'https://[-a-zA-Z0-9.]*\.trycloudflare\.com' "$LOG_FILE" | head -n 1)
  if [ -n "$URL" ]; then
    break
  fi
done

if [ -z "$URL" ]; then
  echo "❌ URLの取得に失敗しました。$LOG_FILE を確認してください。"
  exit 1
fi

echo ""
echo "======================================================"
echo "🎉 スマホ用アクセスURLが発行されました！"
echo "======================================================"
echo ""
echo "👉 $URL"
echo ""
echo "📱 スマホのカメラで以下のQRコードを読み取ってください:"
echo "------------------------------------------------------"
qrencode -t UTF8 "$URL"
echo "------------------------------------------------------"
echo "※ 同じWi-Fiでなくても（外出先やスマホの4G/5G回線でも）開けます。"
echo "※ 共有を終了するには Ctrl + C を押してください。"
echo ""

# トンネルプロセスをフォアグラウンドで待機
wait
