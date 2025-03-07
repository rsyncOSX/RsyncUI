APP = RsyncUI
BUNDLE_ID = no.blogspot.$(APP)
VERSION = 2.3.7

BUILD_PATH = $(PWD)/build
APP_PATH = "$(BUILD_PATH)/$(APP).app"
ZIP_PATH = "$(BUILD_PATH)/$(APP).$(VERSION).zip"

build: clean archive notarize sign prepare-dmg open

# --- MAIN WORLFLOW FUNCTIONS --- #

archive: clean
	osascript -e 'display notification "Exporting application archive..." with title "Build the Stats"'
	echo "Exporting application archive..."

	xcodebuild \
  		-scheme $(APP) \
  		-destination 'platform=OS X,arch=x86_64' \
  		-configuration Release archive \
  		-archivePath $(BUILD_PATH)/$(APP).xcarchive

	echo "Application built, starting the export archive..."

	xcodebuild -exportArchive \
  		-exportOptionsPlist "exportOptions.plist" \
  		-archivePath $(BUILD_PATH)/$(APP).xcarchive \
  		-exportPath $(BUILD_PATH)

	ditto -c -k --keepParent $(APP_PATH) $(ZIP_PATH)

	echo "Project archived successfully"

notarize:
	osascript -e 'display notification "Submitting app for notarization..." with title "Build the Stats"'
	echo "Submitting app for notarization..."

	xcrun notarytool submit --keychain-profile "RsyncUI" --wait $(ZIP_PATH)

	echo "Stats successfully notarized"

sign:
	osascript -e 'display notification "Stampling the Stats..." with title "Build the Stats"'
	echo "Going to staple an application..."

	xcrun stapler staple $(APP_PATH)
	spctl -a -t exec -vvv $(APP_PATH)

	osascript -e 'display notification "Stats successfully stapled" with title "Build the Stats"'
	echo "Stats successfully stapled"

prepare-dmg:

	../create-dmg/create-dmg \
	    --volname "RsyncUI ver $(VERSION)" \
	    --background "./images/background.png" \
	    --window-pos 200 120 \
	    --window-size 500 320 \
	    --icon-size 80 \
	    --icon "RsyncUI.app" 125 175 \
	    --hide-extension "RsyncUI.app" \
	    --app-drop-link 375 175 \
	    --no-internet-enable \
	    --codesign 93M47F4H9T\
	    "$(APP).$(VERSION).dmg" \
	    $(APP_PATH)

# --- HELPERS --- #

clean:
	rm -rf $(BUILD_PATH)
	if [ -a $(PWD)/$(APP).$(VERSION).dmg ]; then rm $(PWD)/$(APP).$(VERSION).dmg; fi;

check:
	xcrun notarytool log f62c4146-0758-4942-baac-9575190858b8 --keychain-profile "RsyncUI"

history:
	xcrun notarytool history --keychain-profile "RsyncUI"

open:
	osascript -e 'display notification "Stats signed and ready for distribution" with title "Build the Stats"'
	echo "Opening working folder..."
	open $(PWD)
