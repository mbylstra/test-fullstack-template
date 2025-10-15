.PHONY: flutter-run-web flutter-run flutter-analyze format run-widgetbook-web adb-wsl rebase-from-latest-template merge-latest-template update-dependencies track-template-repo help

.DEFAULT_GOAL := help

help:
	@echo "Available commands:"
	@echo "  make flutter-run-web   - Run Flutter in web mode on port 8080"
	@echo "  make flutter-run       - Run Flutter"
	@echo "  make flutter-analyze   - Run Flutter analyzer"
	@echo "  make format            - Format Dart code"
	@echo "  make run-widgetbook-web - Run Widgetbook in web mode on port 8081"
	@echo "  make adb-wsl           - Connect to Android device from WSL"
	@echo "  make rebase-from-latest-template - Rebase current branch on latest template changes"
	@echo "  make merge-latest-template - Merge latest template changes into current branch"
	@echo "  make update-dependencies - Update all Dart dependencies"
	@echo "  make track-template-repo - Set up git remote to track template repository"

flutter-run-web:
	flutter run -d web-server --web-port=8080

flutter-run:
	flutter run

flutter-analyze:
	flutter analyze

format:
	dart format .

run-widgetbook-web:
	cd widgetbook && flutter run -d web-server --web-port=8123

adb-wsl:
	@echo 'in windows, run `adb shell ip route` to get your IP address and edit ANDROID_IP_ADDRESS_FOR_WSL_ADB in .envrc in this repo. Then run `adb tcpip 5555` to allow connections from WSL'
	adb connect $$ANDROID_IP_ADDRESS_FOR_WSL_ADB:5555

rebase-from-latest-template:
	./scripts/rebase-from-latest-template.sh

merge-latest-template:
	./scripts/merge-latest-template.sh

update-dependencies:
	dart pub upgrade

track-template-repo:
	./scripts/track-template-repo.sh