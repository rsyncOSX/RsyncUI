all: release
debug:
	xcodebuild -derivedDataPath $(PWD) -configuration Debug -scheme RsyncUI
release:
	xcodebuild -derivedDataPath $(PWD) -configuration Release -scheme RsyncUI
clean:
	rm -Rf Build
	rm -Rf ModuleCache.noindex
	rm -Rf info.plist
	rm -Rf Logs
	rm -rf SourcePackages
	rm -rf SDKStatCaches.noindex
