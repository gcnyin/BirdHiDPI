.PHONY: build test icon app release clean

build:
	swift build

test:
	./scripts/validate-localizations.sh
	swift test

icon:
	./scripts/build-icon.sh

app:
	./scripts/build-app.sh

release:
	./scripts/package-release.sh

clean:
	swift package clean
	rm -rf dist
