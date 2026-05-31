#!/usr/bin/env bash
# make-dmg.sh — builds a distributable DMG for HeicToJpeg.app
# Usage: bash scripts/make-dmg.sh
# Output: HeicToJpeg.dmg in the repo root

set -euo pipefail

APP_NAME="HeicToJpeg.app"
DMG_FINAL="HeicToJpeg.dmg"
DMG_TMP=".tmp-rw.dmg"
VOL_NAME="HEIC to JPEG"
STAGE_DIR=".dmg-stage"

# ── 1. Sanity check ────────────────────────────────────────────────────────────
if [ ! -d "$APP_NAME" ]; then
  echo "❌  $APP_NAME not found — run 'make app' first."
  exit 1
fi

# ── 2. Stage directory ─────────────────────────────────────────────────────────
echo "→ Staging…"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -r "$APP_NAME" "$STAGE_DIR/$APP_NAME"
ln -s /Applications "$STAGE_DIR/Applications"

# ── 3. Create read-write DMG from staged folder ────────────────────────────────
echo "→ Creating writable DMG…"
rm -f "$DMG_TMP" "$DMG_FINAL"
hdiutil create \
  -srcfolder "$STAGE_DIR" \
  -volname "$VOL_NAME" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,b=16" \
  -format UDRW \
  -size 60m \
  "$DMG_TMP"

# ── 4. Mount ───────────────────────────────────────────────────────────────────
echo "→ Mounting…"
MOUNT_POINT="/Volumes/$VOL_NAME"
DEVICE=$(hdiutil attach "$DMG_TMP" -readwrite -nobrowse -mountpoint "$MOUNT_POINT" \
  | grep Apple_HFS | awk '{print $1}')
echo "   Device: $DEVICE  →  $MOUNT_POINT"
sleep 1

# ── 5. Customise window with Finder / osascript ────────────────────────────────
echo "→ Customising Finder window…"
osascript <<APPLESCRIPT
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
    end tell
    set position of item "$APP_NAME"   of container window to {160, 180}
    set position of item "Applications" of container window to {420, 180}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

# Give Finder time to flush .DS_Store
sync
sleep 3

# ── 6. Detach ──────────────────────────────────────────────────────────────────
echo "→ Detaching…"
hdiutil detach "$DEVICE" -quiet || hdiutil detach -force "$DEVICE"

# ── 7. Convert to compressed read-only DMG ─────────────────────────────────────
echo "→ Compressing…"
hdiutil convert "$DMG_TMP" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_FINAL"

# ── 8. Cleanup ─────────────────────────────────────────────────────────────────
rm -f "$DMG_TMP"
rm -rf "$STAGE_DIR"

SIZE=$(du -sh "$DMG_FINAL" | awk '{print $1}')
echo "✅  $DMG_FINAL  ($SIZE)"
