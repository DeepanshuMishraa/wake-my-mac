.PHONY: build app dmg run clean

build:
	swift build

app:
	./Scripts/build-app.sh

dmg: app
	./Scripts/create-dmg.sh

run: build
	./.build/debug/WatchMyMac

clean:
	rm -rf .build build
