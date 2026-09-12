PROJECT := DepremOldu.xcodeproj
SIMULATOR_NAME ?= iPhone 17 Pro Max
DESTINATION := platform=iOS Simulator,name=$(SIMULATOR_NAME),OS=latest
DERIVED_DATA := .build/DerivedData
UI_RESULT_BUNDLE ?= test-results/DepremOlduUITests.xcresult

.PHONY: project project-check verify verify-iteration version-check package-test build release-build unit-test prepare-ui-test-simulator ui-test ui-test-selected ui-test-report clean

project:
	python3 scripts/generate_xcodeproj.py

project-check: project
	@git diff --exit-code -- $(PROJECT) || (printf '%s\n' "Xcode project is stale; commit the regenerated project." >&2; exit 1)

verify: version-check project-check package-test build release-build unit-test ui-test

verify-iteration: version-check project-check package-test build unit-test

version-check:
	./scripts/validate-versioning.sh

package-test:
	CLANG_MODULE_CACHE_PATH=$(CURDIR)/.build/ModuleCache \
	SWIFTPM_MODULECACHE_OVERRIDE=$(CURDIR)/.build/ModuleCache \
	swift test \
		--package-path Packages/DepremOlduCore \
		--cache-path .build/SwiftPM/Cache \
		--config-path .build/SwiftPM/Config \
		--security-path .build/SwiftPM/Security \
		--scratch-path .build/DepremOlduCore

build:
	xcodebuild build -quiet \
		-project $(PROJECT) \
		-scheme DepremOldu-Development \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO

release-build:
	xcodebuild build -quiet \
		-project $(PROJECT) \
		-scheme DepremOldu-Release \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO

unit-test:
	rm -rf test-results/DepremOlduUnitTests.xcresult
	xcodebuild test -quiet \
		-project $(PROJECT) \
		-scheme DepremOldu-Test \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		-resultBundlePath test-results/DepremOlduUnitTests.xcresult \
		-only-testing:DepremOlduAppTests \
		CODE_SIGNING_ALLOWED=NO

prepare-ui-test-simulator:
	-@xcrun simctl boot '$(SIMULATOR_NAME)' >/dev/null 2>&1
	xcrun simctl bootstatus '$(SIMULATOR_NAME)' -b

ui-test: prepare-ui-test-simulator
	rm -rf '$(UI_RESULT_BUNDLE)'
	rm -rf $(DERIVED_DATA)/Build/Products/Test-iphonesimulator/DepremOlduAppUITests-Runner.app
	rm -rf $(DERIVED_DATA)/Build/Products/Test-iphonesimulator/DepremOlduAppUITests.xctest
	xcodebuild test -quiet \
		-project $(PROJECT) \
		-scheme DepremOldu-Test \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		-resultBundlePath '$(UI_RESULT_BUNDLE)' \
		-only-testing:DepremOlduAppUITests \
		-parallel-testing-enabled NO \
		CODE_SIGNING_ALLOWED=NO

ui-test-selected:
	@if [ -z "$(strip $(UI_TEST_SELECTOR))" ]; then \
		printf '%s\n' "UI_TEST_SELECTOR is required (example: DepremOlduAppUITests/DepremOlduAppUITests/testEarthquakeListShowsContentAndLegend)" >&2; \
		exit 2; \
	fi
	$(MAKE) prepare-ui-test-simulator
	rm -rf test-results/DepremOlduUISelectedTests.xcresult
	rm -rf $(DERIVED_DATA)/Build/Products/Test-iphonesimulator/DepremOlduAppUITests-Runner.app
	rm -rf $(DERIVED_DATA)/Build/Products/Test-iphonesimulator/DepremOlduAppUITests.xctest
	xcodebuild test -quiet \
		-project $(PROJECT) \
		-scheme DepremOldu-Test \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		-resultBundlePath test-results/DepremOlduUISelectedTests.xcresult \
		-only-testing:'$(UI_TEST_SELECTOR)' \
		-parallel-testing-enabled NO \
		CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf .build/DerivedData .build/DepremOlduCore test-results
