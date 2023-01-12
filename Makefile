all: framework

PROJECT=BatchPianoDispatcher.xcodeproj
SIMULATOR='platform=iOS Simulator,name=iPhone 14'
DERIVED_DATA=$(CURDIR)/DerivedData

clean:
	rm -rf $(DERIVED_DATA)
	set -o pipefail && xcodebuild clean -project $(PROJECT) -scheme BatchPianoDispatcher | xcpretty

framework: clean
	set -o pipefail && xcodebuild build -project $(PROJECT) -scheme BatchPianoDispatcher -destination generic/platform=iOS | xcpretty

test: clean
	set -o pipefail && xcodebuild test -project $(PROJECT) -scheme BatchPianoDispatcher -destination $(SIMULATOR) | xcpretty

format:
	bash Scripts/format.sh

format-check:
	bash Scripts/format-check.sh

.PHONY: test
