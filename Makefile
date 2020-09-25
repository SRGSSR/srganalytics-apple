#!/usr/bin/xcrun make -f

.PHONY: all
all: test-ios test-tvos test-ios-identity test-tvos-identity

.PHONY: test-ios
test-ios:
	@echo "Running iOS unit tests..."
	@xcodebuild test -scheme SRGAnalytics-Package -destination 'platform=iOS Simulator,name=iPhone 11' 2> /dev/null
	@echo "... done.\n"

.PHONY: test-ios-identity
test-ios-identity:
	@echo "Running iOS identity unit tests..."
	@pushd Tests > /dev/null; xcodebuild test -workspace SRGAnalyticsIdentity-tests.xcworkspace -scheme SRGAnalyticsIdentity-tests -destination 'platform=iOS Simulator,name=iPhone 11' 2> /dev/null
	@echo "... done.\n"

.PHONY: test-tvos
test-tvos:
	@echo "Running tvOS unit tests..."
	@xcodebuild test -scheme SRGAnalytics-Package -destination 'platform=tvOS Simulator,name=Apple TV' 2> /dev/null
	@echo "... done.\n"

.PHONY: test-tvos-identity
test-tvos-identity:
	@echo "Running iOS identity unit tests..."
	@pushd Tests > /dev/null; xcodebuild test -workspace SRGAnalyticsIdentity-tests.xcworkspace -scheme SRGAnalyticsIdentity-tests -destination 'platform=tvOS Simulator,name=Apple TV' 2> /dev/null
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   all                 Build and run unit tests for all platforms"
	@echo "   test-ios            Build and run unit tests for iOS"
	@echo "   test-ios-identity   Build and run identity unit tests for iOS"
	@echo "   test-tvos           Build and run unit tests for tvOS"
	@echo "   test-tvos-identity  Build and run identity unit tests for tvOS"
	@echo "   help                Display this help message"