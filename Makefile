APP     = TelePad
BUNDLE  = $(APP).app
BINARY  = .build/debug/$(APP)
MACOS   = $(BUNDLE)/Contents/MacOS
PLIST   = $(BUNDLE)/Contents/Info.plist

.PHONY: build app run clean

## build  – compile the Swift sources
build:
	swift build

## app    – wrap the binary in a proper .app bundle and ad-hoc sign it
##          A real bundle gives macOS a bundle ID so Accessibility works correctly.
app: build
	@echo "→ Creating $(BUNDLE)…"
	@mkdir -p $(MACOS)
	@cp $(BINARY) $(MACOS)/$(APP)
	@cp Resources/Info.plist $(PLIST)
	@echo "→ Ad-hoc signing…"
	@codesign --force --deep --sign - $(BUNDLE)
	@echo "✓ $(BUNDLE) ready"

## run    – build the .app bundle and launch it (kills any previous instance first)
run: app
	@pkill -x $(APP) 2>/dev/null || true
	@sleep 0.3
	@echo "→ Launching $(BUNDLE)…"
	@open $(BUNDLE)

## clean  – remove build artefacts
clean:
	@rm -rf $(BUNDLE) .build
	@echo "✓ Cleaned"
