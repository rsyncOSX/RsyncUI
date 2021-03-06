all: release
debug:
	xcodebuild -derivedDataPath $(PWD) -configuration Debug -scheme RsyncSwiftUI
release:
	xcodebuild -derivedDataPath $(PWD) -configuration Release -scheme RsyncSwiftUI
clean:
	rm -Rf Build
	rm -Rf ModuleCache.noindex
	rm -Rf info.plist
	rm -Rf Logs
	rm -rf SourcePackages
