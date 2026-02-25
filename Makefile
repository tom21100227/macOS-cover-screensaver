SAVER_NAME = TomtopiaSaver
PROJECT_DIR = $(CURDIR)
XCODE_PROJECT = $(PROJECT_DIR)/$(SAVER_NAME).xcodeproj
BUILD_DIR = $(PROJECT_DIR)/build
COVERS_SRC = $(PROJECT_DIR)/covers
RESOURCES_DIR = $(PROJECT_DIR)/Resources

# Signing — set these via environment or edit here
SIGNING_IDENTITY ?= Developer ID Application
APPLE_ID ?=
TEAM_ID ?=
APP_PASSWORD ?=

.PHONY: all resources build sign notarize install clean saver-template

all: build

# Step 1: Copy cover images into Xcode Resources
resources:
	rm -rf $(RESOURCES_DIR)/covers
	mkdir -p $(RESOURCES_DIR)/covers
	cp $(COVERS_SRC)/*.jpg $(RESOURCES_DIR)/covers/

# Step 2: Build .saver via xcodebuild
build: resources
	xcodebuild -project $(XCODE_PROJECT) \
		-scheme $(SAVER_NAME) \
		-configuration Release \
		SYMROOT=$(BUILD_DIR) \
		build
	@echo ""
	@echo "Built: $(BUILD_DIR)/Release/$(SAVER_NAME).saver"

# Step 3: Sign with Developer ID
sign:
	codesign --sign "$(SIGNING_IDENTITY)" \
		--timestamp --options runtime --force --deep \
		$(BUILD_DIR)/Release/$(SAVER_NAME).saver
	@echo "Signed successfully"

# Step 4: Notarize
notarize:
	ditto -c -k --keepParent \
		$(BUILD_DIR)/Release/$(SAVER_NAME).saver \
		$(BUILD_DIR)/$(SAVER_NAME).zip
	xcrun notarytool submit $(BUILD_DIR)/$(SAVER_NAME).zip \
		--apple-id "$(APPLE_ID)" \
		--password "$(APP_PASSWORD)" \
		--team-id "$(TEAM_ID)" \
		--wait
	xcrun stapler staple $(BUILD_DIR)/Release/$(SAVER_NAME).saver
	@echo "Notarized and stapled"

# Install locally (for testing)
install: build
	rm -rf ~/Library/Screen\ Savers/$(SAVER_NAME).saver
	ditto $(BUILD_DIR)/Release/$(SAVER_NAME).saver ~/Library/Screen\ Savers/$(SAVER_NAME).saver
	codesign --force --sign - ~/Library/Screen\ Savers/$(SAVER_NAME).saver
	@echo "Installed to ~/Library/Screen Savers/"
	@echo "Open System Settings > Screen Saver to select Tomtopia"

# Build saver template for web app
saver-template: build
	mkdir -p web/static/saver-template
	cp $(BUILD_DIR)/Release/$(SAVER_NAME).saver/Contents/MacOS/$(SAVER_NAME) web/static/saver-template/
	cp $(BUILD_DIR)/Release/$(SAVER_NAME).saver/Contents/Info.plist web/static/saver-template/
	@echo "Saver template copied to web/static/saver-template/"

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SAVER_NAME) clean 2>/dev/null || true
	@echo "Cleaned"
