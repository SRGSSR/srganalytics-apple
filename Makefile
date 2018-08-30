#!/usr/bin/xcrun make -f

CARTHAGE_FOLDER=Carthage
CARTHAGE_RESOLUTION_FLAGS=--new-resolver --no-build
CARTHAGE_BUILD_FLAGS=--platform iOS --cache-builds

CARTFILE_PRIVATE=Cartfile.private
CARTFILE_PRIVATE_COMMON=Cartfile.private.common
CARTFILE_PRIVATE_PROPRIETARY=Cartfile.private.proprietary
CARTFILE_PRIVATE_PUBLIC=Cartfile.private.public

CARTFILE_RESOLVED=Cartfile.resolved
CARTFILE_RESOLVED_PROPRIETARY=Cartfile.resolved.proprietary
CARTFILE_RESOLVED_PUBLIC=Cartfile.resolved.public

RESTORE_CARTFILE_PRIVATE_COMMON=@[ -f $(CARTFILE_PRIVATE_COMMON) ] && cp $(CARTFILE_PRIVATE_COMMON) $(CARTFILE_PRIVATE) || touch $(CARTFILE_PRIVATE_COMMON)
RESTORE_CARTFILE_PRIVATE_PROPRIETARY=$(RESTORE_CARTFILE_PRIVATE_COMMON);[ -f $(CARTFILE_PRIVATE_PROPRIETARY) ] && (echo; cat $(CARTFILE_PRIVATE_PROPRIETARY)) >> $(CARTFILE_PRIVATE) || true
RESTORE_CARTFILE_PRIVATE_PUBLIC=$(RESTORE_CARTFILE_PRIVATE_COMMON);[ -f $(CARTFILE_PRIVATE_PUBLIC) ] && (echo; cat $(CARTFILE_PRIVATE_PUBLIC)) >> $(CARTFILE_PRIVATE) || true

CLEAN_CARTFILE_PRIVATE=@rm -f $(CARTFILE_PRIVATE)

RESTORE_CARTFILE_RESOLVED_PROPRIETARY=@[ -f $(CARTFILE_RESOLVED_PROPRIETARY) ] && cp $(CARTFILE_RESOLVED_PROPRIETARY) $(CARTFILE_RESOLVED) || true
RESTORE_CARTFILE_RESOLVED_PUBLIC=@[ -f $(CARTFILE_RESOLVED_PUBLIC) ] && cp $(CARTFILE_RESOLVED_PUBLIC) $(CARTFILE_RESOLVED) || true

SAVE_CARTFILE_RESOLVED_PROPRIETARY=@[ -f $(CARTFILE_RESOLVED) ] && cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_PROPRIETARY) || true
SAVE_CARTFILE_RESOLVED_PUBLIC=@[ -f $(CARTFILE_RESOLVED) ] && cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_PUBLIC) || true

CLEAN_CARTFILE_RESOLVED=@rm -f $(CARTFILE_RESOLVED)

.PHONY: all
all: bootstrap
	@echo "Building the project..."
	@xcodebuild build
	@echo ""

# Resolving dependencies without building the project

.PHONY: dependencies
dependencies: public.dependencies
	@echo "Updating $(CARTFILE_RESOLVED_PROPRIETARY) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PROPRIETARY)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PROPRIETARY)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

.PHONY: public.dependencies
public.dependencies:
	@echo "Updating $(CARTFILE_RESOLVED_PUBLIC) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PUBLIC)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PUBLIC)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

# Dependency compilation with proprietary dependencies

.PHONY: bootstrap
bootstrap:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_PROPRIETARY)..."
	$(RESTORE_CARTFILE_PRIVATE_PROPRIETARY)
	$(RESTORE_CARTFILE_RESOLVED_PROPRIETARY)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PROPRIETARY)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

# Also keep open source build dependencies in sync
.PHONY: update
update: public.dependencies
	@echo "Updating and building $(CARTFILE_RESOLVED_PROPRIETARY) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PROPRIETARY)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PROPRIETARY)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

# Open source dependency compilation

.PHONY: public.bootstrap
public.bootstrap:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_PUBLIC)..."
	$(RESTORE_CARTFILE_PRIVATE_PUBLIC)
	$(RESTORE_CARTFILE_RESOLVED_PUBLIC)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PUBLIC)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

.PHONY: public.update
public.update:
	@echo "Updating and building $(CARTFILE_RESOLVED_PUBLIC) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PUBLIC)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PUBLIC)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

# Framework package to attach to github releases. Only for proprietary builds (open source builds
# can use these binaries as well).

.PHONY: package
package: bootstrap
	@echo "Packaging binaries..."
	@mkdir -p archive
	@carthage build --no-skip-current
	@carthage archive --output archive
	@echo ""

# Cleanup

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@rm -rf $(CARTHAGE_FOLDER)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

.PHONY: help
help:
	@echo "The following targets must be used for proprietary builds:"
	@echo "   all                         Build project dependencies and the project"
	@echo "   dependencies                Update dependencies without building them"
	@echo "   bootstrap                   Build dependencies as declared in $(CARTFILE_RESOLVED_PROPRIETARY)"
	@echo "   update                      Update and build dependencies"
	@echo "   package                     Build and package the framework for attaching to github releases"
	@echo ""
	@echo "The following targets must be used with the public project:"
	@echo "   public.dependencies         Update dependencies without building them"
	@echo "   public.bootstrap            Build dependencies as declared in $(CARTFILE_RESOLVED_PUBLIC)"
	@echo "   public.update               Update and build dependencies"
	@echo ""
	@echo "The following targets are widely available:"
	@echo "   help                        Display this message"
	@echo "   clean                       Clean the project and its dependencies"
