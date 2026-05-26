APP_NAME   := HeicToJpeg.app
APP_DIR    := $(APP_NAME)/Contents/MacOS
BINARY_SRC := .build/release/HeicApp
BINARY_DST := $(APP_DIR)/HeicToJpeg
PLIST_SRC  := Resources/Info.plist
PLIST_DST  := $(APP_NAME)/Contents/Info.plist

.PHONY: app run-app cli clean

app: $(BINARY_DST) $(PLIST_DST)

$(BINARY_DST): $(BINARY_SRC) | $(APP_DIR)
	cp $(BINARY_SRC) $(BINARY_DST)
	cp $(PLIST_SRC) $(PLIST_DST)

$(BINARY_SRC):
	swift build -c release

$(APP_DIR):
	mkdir -p $(APP_DIR)

run-app: app
	open $(APP_NAME)

cli:
	swift build -c release --product heictojpeg

clean:
	rm -rf .build $(APP_NAME)
