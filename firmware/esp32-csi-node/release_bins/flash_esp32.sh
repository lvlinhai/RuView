#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PORT="${1:-${PORT:-/dev/tty.usbmodem3101}}"
FLASH_SIZE_INPUT="${2:-${FLASH_SIZE:-8MB}}"
BAUD_RATE="${BAUD_RATE:-460800}"
CHIP="${CHIP:-esp32s3}"
FLASH_FREQ="${FLASH_FREQ:-80m}"
FLASH_MODE="${FLASH_MODE:-dio}"

BOOTLOADER_BIN="$SCRIPT_DIR/bootloader.bin"
OTA_BIN="$SCRIPT_DIR/ota_data_initial.bin"

FLASH_SIZE=""
FLASH_LAYOUT=""

case "$FLASH_SIZE_INPUT" in
  8MB)
    FLASH_SIZE="8MB"
    FLASH_LAYOUT="8MB 发布布局"
    PARTITION_BIN="$SCRIPT_DIR/partition-table.bin"
    APP_BIN="$SCRIPT_DIR/esp32-csi-node.bin"
    ;;
  4MB)
    FLASH_SIZE="4MB"
    FLASH_LAYOUT="4MB 发布布局"
    PARTITION_BIN="$SCRIPT_DIR/partition-table-4mb.bin"
    APP_BIN="$SCRIPT_DIR/esp32-csi-node-4mb.bin"
    ;;
  16MB)
    FLASH_SIZE="8MB"
    FLASH_LAYOUT="8MB 发布布局（适配 16MB 板）"
    PARTITION_BIN="$SCRIPT_DIR/partition-table.bin"
    APP_BIN="$SCRIPT_DIR/esp32-csi-node.bin"
    ;;
  *)
    echo "不支持的 FLASH_SIZE: $FLASH_SIZE_INPUT。只能使用 4MB、8MB 或 16MB。" >&2
    exit 1
    ;;
esac

for file in "$BOOTLOADER_BIN" "$PARTITION_BIN" "$OTA_BIN" "$APP_BIN"; do
  if [[ ! -f "$file" ]]; then
    echo "缺少固件文件: $file" >&2
    exit 1
  fi
done

echo "使用串口: $PORT"
echo "目标容量参数: $FLASH_SIZE_INPUT"
echo "烧录布局: $FLASH_LAYOUT"
echo "应用固件: $(basename "$APP_BIN")"

echo "【1/3】正在擦除 Flash..."
python3 -m esptool \
  --chip "$CHIP" \
  --port "$PORT" \
  erase-flash

echo "【2/3】开始烧录固件..."
python3 -m esptool \
  --chip "$CHIP" \
  --port "$PORT" \
  --baud "$BAUD_RATE" \
  --after hard-reset \
  write-flash \
  --flash-mode "$FLASH_MODE" \
  --flash-size "$FLASH_SIZE" \
  --flash-freq "$FLASH_FREQ" \
  0x0 "$BOOTLOADER_BIN" \
  0x8000 "$PARTITION_BIN" \
  0xf000 "$OTA_BIN" \
  0x20000 "$APP_BIN"

echo "【3/3】烧录完成，设备已执行硬复位。"

# wifi 联网指令
# python3 firmware/esp32-csi-node/provision.py \
#     --port /dev/tty.usbmodem3101 \
#     --ssid "802" \   
#     --password "18297807809llh" \
#     --target-ip 192.168.86.4

# 启动指令
# cargo run --manifest-path /Users/llh/StudioProjects/RuView/rust-port/wifi-densepose-rs/Cargo.toml \
#     -p wifi-densepose-sensing-server -- \
#     --source esp32 \
#     --http-port 3000 \
#     --udp-port 5005 \
#     --ui-path /Users/llh/StudioProjects/RuView/ui