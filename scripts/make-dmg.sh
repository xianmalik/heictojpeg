#!/usr/bin/env bash
# make-dmg.sh — builds a distributable DMG for HeicToJpeg.app
# Usage: bash scripts/make-dmg.sh
# Output: HeicToJpeg.dmg in the repo root

set -euo pipefail

VERSION="${1:-0.1.0-preview}"

APP_NAME="HeicToJpeg.app"
DMG_FINAL="HeicToJpeg-${VERSION}.dmg"
DMG_TMP=".tmp-rw.dmg"
VOL_NAME="HEIC to JPEG"
STAGE_DIR=".dmg-stage"
BG_SRC="Resources/dmg-background.png"
ICON_SRC="Resources/AppIcon.icns"

# ── 1. Sanity check ────────────────────────────────────────────────────────────
if [ ! -d "$APP_NAME" ]; then
  echo "❌  $APP_NAME not found — run 'make app' first."
  exit 1
fi

# ── 2. Stage directory ─────────────────────────────────────────────────────────
echo "→ Staging…"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/.background"
cp -r "$APP_NAME"  "$STAGE_DIR/$APP_NAME"
ln -s /Applications "$STAGE_DIR/Applications"

# Background image
if [ -f "$BG_SRC" ]; then
  cp "$BG_SRC" "$STAGE_DIR/.background/background.png"
else
  echo "⚠️  $BG_SRC not found — DMG will have no background."
fi

# ── 3. Create read-write DMG from staged folder ────────────────────────────────
echo "→ Creating writable DMG…"
rm -f "$DMG_TMP" HeicToJpeg-*.dmg
hdiutil create \
  -srcfolder "$STAGE_DIR" \
  -volname "$VOL_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,b=16" \
  -format UDRW \
  -size 80m \
  "$DMG_TMP"

# ── 4. Mount ───────────────────────────────────────────────────────────────────
echo "→ Mounting…"
MOUNT_POINT="/Volumes/$VOL_NAME"
DEVICE=$(hdiutil attach "$DMG_TMP" -readwrite -nobrowse -mountpoint "$MOUNT_POINT" \
  | grep Apple_HFS | awk '{print $1}')
echo "   Device: $DEVICE  →  $MOUNT_POINT"
sleep 1

# ── 5. Volume icon ─────────────────────────────────────────────────────────────
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$MOUNT_POINT/.VolumeIcon.icns"
  # Set kHasCustomIcon flag on the volume root via xattr
  # FinderInfo is 32 bytes; frFlags are at bytes 8–9 (big-endian).
  # kHasCustomIcon = 0x0400 → byte8=0x04
  xattr -wx com.apple.FinderInfo \
    "0000000000000000040000000000000000000000000000000000000000000000" \
    "$MOUNT_POINT"
fi

# ── 6. Customise Finder window ─────────────────────────────────────────────────
echo "→ Customising Finder window…"
osascript << APPLESCRIPT
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 780, 480}
    tell icon view options of container window
      set arrangement to not arranged
      set icon size to 110
      set shows item info to false
      set shows icon preview to true
      set background picture to POSIX file "$MOUNT_POINT/.background/background.png"
    end tell
    set position of item "$APP_NAME"    of container window to {160, 170}
    set position of item "Applications" of container window to {420, 170}
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT

# Flush .DS_Store to disk
sync
sleep 3

# ── 7. Detach ──────────────────────────────────────────────────────────────────
echo "→ Detaching…"
hdiutil detach "$DEVICE" -quiet || hdiutil detach -force "$DEVICE"

# ── 8. Convert to compressed read-only DMG ─────────────────────────────────────
echo "→ Compressing…"
hdiutil convert "$DMG_TMP" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_FINAL"

# ── 9. Cleanup ─────────────────────────────────────────────────────────────────
rm -f "$DMG_TMP"
rm -rf "$STAGE_DIR"

SIZE=$(du -sh "$DMG_FINAL" | awk '{print $1}')
echo "✅  $DMG_FINAL  ($SIZE)"
