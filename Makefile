VERSION    := 0.1.0-preview

APP_NAME   := HeicToJpeg.app
APP_DIR    := $(APP_NAME)/Contents/MacOS
RES_DIR    := $(APP_NAME)/Contents/Resources
BINARY_SRC := .build/release/HeicApp
BINARY_DST := $(APP_DIR)/HeicToJpeg
PLIST_SRC  := Resources/Info.plist
PLIST_DST  := $(APP_NAME)/Contents/Info.plist
ICON_SRC   := Resources/AppIcon.icns
ICON_DST   := $(RES_DIR)/AppIcon.icns

.PHONY: app run-app cli dmg clean

app: $(BINARY_DST) $(PLIST_DST) $(ICON_DST)

$(BINARY_DST): $(BINARY_SRC) | $(APP_DIR)
	cp $(BINARY_SRC) $(BINARY_DST)
	cp $(PLIST_SRC) $(PLIST_DST)

$(ICON_DST): $(ICON_SRC) | $(RES_DIR)
	cp $(ICON_SRC) $(ICON_DST)

$(BINARY_SRC):
	swift build -c release

$(APP_DIR):
	mkdir -p $(APP_DIR)

$(RES_DIR):
	mkdir -p $(RES_DIR)

run-app: app
	open $(APP_NAME)

cli:
	swift build -c release --product heictojpeg

dmg: app
	bash scripts/make-dmg.sh $(VERSION)

clean:
	rm -rf .build $(APP_NAME) HeicToJpeg-*.dmg .tmp-rw.dmg .dmg-stage
