.PHONY: flutter-run-web flutter-run-chrome flutter-run flutter-analyze format run-widgetbook-web adb-wsl update-dependencies install help

.DEFAULT_GOAL := help

help:
	@echo "Available commands:"
	@echo "  make flutter-run-web   - Run Flutter in web mode on port 8080"
	@echo "  make flutter-run-chrome - Run Flutter in Chrome browser on port 8080"
	@echo "  make flutter-run       - Run Flutter"
	@echo "  make flutter-analyze   - Run Flutter analyzer"
	@echo "  make format            - Format Dart code"
	@echo "  make run-widgetbook-web - Run Widgetbook in web mode on port 8081"
	@echo "  make adb-wsl           - Connect to Android device from WSL"
	@echo "  make install           - Install Flutter dependencies"
	@echo "  make update-dependencies - Update all Dart dependencies"

flutter-run-web:
	flutter run -d web-server --web-port=8080

flutter-run-chrome:
	flutter run -d chrome --web-port=8080

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

install:
	flutter pub get
	cd widgetbook && flutter pub get

update-dependencies:
	dart pub upgrade

