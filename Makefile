.PHONY: help dev down logs clean \
	supabase-start supabase-start-background \
	functions functions-background \
	ngrok-up ngrok-down ngrok-background \
	functions-deploy test_daily_devotional test_slowness fresh \
	archive upload release \
	pull-listings dry-listings push-listings push-listing create-version \
	pull-screenshots dry-screenshots push-screenshots \
	pull-events push-event submit-event submit-version

# Default target
help:
	@echo "🚀 swiftbible – Development Commands"
	@echo ""
	@echo "Quick Start:"
	@echo "  make dev            – Start Supabase, Edge Functions, and ngrok"
	@echo "  make stop           – Stop everything"
	@echo ""
	@echo "Individual Services:"
	@echo "  make supabase-start – Start local Supabase stack"
	@echo "  make functions      – Serve Supabase Edge Functions (requires Supabase running)"
	@echo "  make ngrok-up       – Start ngrok tunnel for webhooks"
	@echo ""
	@echo "Utilities:"
	@echo "  make logs           – Show Supabase status"
	@echo "  make clean          – Stop services and clean temp files"
	@echo ""
	@echo "Deploy:"
	@echo "  make functions-deploy – Deploy all functions to remote project"
	@echo ""
	@echo "App Store:"
	@echo "  make archive          – Archive the app for App Store"
	@echo "  make upload           – Upload the latest archive to App Store Connect"
	@echo "  make release          – Archive + upload in one step"
	@echo ""
	@echo "App Store Listings (metadata across locales):"
	@echo "  make pull-listings              – Download current ASC state to listings.pulled.yaml"
	@echo "  make dry-listings               – Preview what would change without pushing"
	@echo "  make push-listings              – Push all locales from listings.yaml"
	@echo "  make create-version VERSION=X.YY – Create a new editable AppStoreVersion in ASC"
	@echo "  make push-listing LOCALES=ml,hi – Push specific locales"
	@echo ""
	@echo "App Store Screenshots:"
	@echo "  make pull-screenshots                – List current screenshots in ASC"
	@echo "  make dry-screenshots                 – Preview what would be uploaded"
	@echo "  make push-screenshots                – Upload screenshots from appstore/marketing/ultimate (en-US)"
	@echo "  make push-screenshots SOURCE=... LOCALE=es-ES FORCE=1 – override source/locale/force"
	@echo ""
	@echo "App Store In-App Events:"
	@echo "  make pull-events                     – List existing events in ASC"
	@echo "  make push-event EVENT=pentecost      – Create/update event from appstore/events/<slug>/event.yaml"
	@echo "  make submit-event EVENT=pentecost    – Same as push-event then submit for review"
	@echo ""
	@echo "App Store Submission:"
	@echo "  make submit-version                  – Submit current editable version for Apple review"
	@echo ""
	@echo "Tests:"
	@echo "  make test_daily_devotional"
	@echo "  make test_slowness"

functions-deploy:
	supabase functions deploy daily-devotional --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy get-daily-devotional --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy user-self-deletion --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy create-donation-session --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy donation-status --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy donation-history --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy stripe-donation-webhook --project-ref yvanxjoayoiocwzfpkfm

test_daily_devotional:
	curl -X POST 'https://yvanxjoayoiocwzfpkfm.supabase.co/functions/v1/daily-devotional' \
	-H 'Content-Type: application/json' \
	-H 'Authorization: Bearer $(SWIFTBIBLE_KEY)' \
	-H 'SuperSecret: $(SWIFTBIBLE_SUPERSECRET_KEY)' \
	-d '{}';

test_slowness:
	xcodebuild clean build -project ios/swiftbible.xcodeproj/ OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-expression-type-checking" | grep -Ei '^\d+\.\d+ms\t/.+$' | sort -r

supabase-start:
	@echo "🚀 Starting local Supabase..."
	supabase stop --all >/dev/null 2>&1 || true
	supabase start

supabase-start-background:
	@echo "Starting Supabase..."
	supabase start

functions:
	@echo "🔧 Serving Edge Functions..."
	cd supabase && supabase functions serve --env-file .env --no-verify-jwt

functions-background:
	@echo "Starting Edge Functions..."
	@cd supabase && supabase functions serve --env-file .env --no-verify-jwt

ngrok-up:
	@echo "📡 Starting ngrok tunnel..."
	./scripts/ngrok-up.sh

ngrok-background:
	@make ngrok-up

ngrok-down:
	@echo "🛑 Stopping ngrok tunnel..."
	./scripts/ngrok-down.sh

dev:
	@echo "🚀 Starting swiftbible development environment..."
	@echo "  • Supabase"
	@echo "  • Edge Functions"
	@echo "  • ngrok webhook tunnel"
	@echo ""
	@echo "Press Ctrl+C to stop all services."
	@make -j3 supabase-start-background functions-background ngrok-background
	@wait

down:
	@echo "🛑 Stopping swiftbible services..."
	@make ngrok-down >/dev/null 2>&1 || true
	@pkill -f "supabase functions serve" >/dev/null 2>&1 || true
	@echo "✅ Services stopped"

logs:
	@supabase status

clean:
	@echo "🧹 Cleaning up local environment..."
	@make stop
	@echo "✅ Cleanup complete"

fresh:
	@echo "🔄 Resetting Supabase database..."
	supabase db reset --debug # && supabase gen types typescript --local > types/database.ts

# --- App Store ---

ARCHIVE_PATH = build/swiftbible.xcarchive
EXPORT_PATH = build/export
EXPORT_OPTIONS = ios/ExportOptions.plist
SCHEME = swiftbible
PROJECT = ios/swiftbible.xcodeproj

archive:
	@echo "Archiving $(SCHEME)..."
	xcodebuild archive \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "generic/platform=iOS" \
		-archivePath $(ARCHIVE_PATH) \
		SWIFT_COMPILATION_MODE=wholemodule
	@echo "Archive complete: $(ARCHIVE_PATH)"

upload:
	@echo "Exporting and uploading to App Store Connect..."
	@# /usr/bin first → Apple's rsync (Homebrew rsync 3.4+ rejects Xcode's --extended-attributes flag).
	@# Sources appstore/.env so callers don't need to export ASC_KEY_ID / ASC_ISSUER_ID manually.
	@set -a; . appstore/.env; set +a; \
	PATH=/usr/bin:$$PATH xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportOptionsPlist $(EXPORT_OPTIONS) \
		-exportPath $(EXPORT_PATH) \
		-allowProvisioningUpdates \
		-authenticationKeyPath $$HOME/.appstoreconnect/private_keys/AuthKey_$$ASC_KEY_ID.p8 \
		-authenticationKeyID $$ASC_KEY_ID \
		-authenticationKeyIssuerID $$ASC_ISSUER_ID
	@echo "Upload complete!"

release: archive upload

# --- App Store Listings ---
# See skills/app-store-listing/SKILL.md for the full workflow.

pull-listings:
	@uv run --with PyJWT --with cryptography --with requests --with python-dotenv --with PyYAML \
		python3 appstore/push_listing.py --pull

dry-listings:
	@uv run --with PyJWT --with cryptography --with requests --with python-dotenv --with PyYAML \
		python3 appstore/push_listing.py --dry-run $(if $(LOCALES),--locales $(LOCALES),)

push-listings:
	@uv run --with PyJWT --with cryptography --with requests --with python-dotenv --with PyYAML \
		python3 appstore/push_listing.py

push-listing:
	@if [ -z "$(LOCALES)" ]; then echo "Usage: make push-listing LOCALES=ml,hi"; exit 1; fi
	@uv run --with PyJWT --with cryptography --with requests --with python-dotenv --with PyYAML \
		python3 appstore/push_listing.py --locales $(LOCALES)

create-version:
	@if [ -z "$(VERSION)" ]; then echo "Usage: make create-version VERSION=1.40 [DRY=1]"; exit 1; fi
	@uv run --with PyJWT --with cryptography --with requests --with python-dotenv --with PyYAML \
		python3 appstore/push_listing.py --create-version $(VERSION) $(if $(DRY),--dry-run,)

# --- App Store Screenshots ---
# SOURCE defaults to appstore/marketing/ultimate. LOCALE defaults to en-US.
# FORCE=1 to delete-and-replace existing screenshots in ASC.

SCREENSHOT_DEPS = --with PyJWT --with cryptography --with requests --with python-dotenv

pull-screenshots:
	@uv run $(SCREENSHOT_DEPS) python3 appstore/push_screenshots.py --pull \
		$(if $(LOCALE),--locale $(LOCALE),)

dry-screenshots:
	@uv run $(SCREENSHOT_DEPS) python3 appstore/push_screenshots.py --dry-run \
		$(if $(SOURCE),--source $(SOURCE),) \
		$(if $(LOCALE),--locale $(LOCALE),) \
		$(if $(FORCE),--force,)

push-screenshots:
	@uv run $(SCREENSHOT_DEPS) python3 appstore/push_screenshots.py \
		$(if $(SOURCE),--source $(SOURCE),) \
		$(if $(LOCALE),--locale $(LOCALE),) \
		$(if $(FORCE),--force,)

# --- App Store In-App Events ---
# Reads from appstore/events/<slug>/event.yaml. Pass EVENT=<slug>.

EVENT_DEPS = --with PyJWT --with cryptography --with requests --with python-dotenv --with PyYAML

pull-events:
	@uv run $(EVENT_DEPS) python3 appstore/push_event.py --pull

push-event:
	@if [ -z "$(EVENT)" ]; then echo "Usage: make push-event EVENT=pentecost"; exit 1; fi
	@uv run $(EVENT_DEPS) python3 appstore/push_event.py --event $(EVENT) \
		$(if $(DRY),--dry-run,) \
		$(if $(REPLACE_IMAGES),--replace-images,)

submit-event:
	@if [ -z "$(EVENT)" ]; then echo "Usage: make submit-event EVENT=pentecost"; exit 1; fi
	@uv run $(EVENT_DEPS) python3 appstore/push_event.py --event $(EVENT) --submit \
		$(if $(DRY),--dry-run,) \
		$(if $(REPLACE_IMAGES),--replace-images,)

# --- App Store Version Submission ---
# Submits the current editable version for Apple review.

submit-version:
	@uv run --with PyJWT --with cryptography --with requests --with python-dotenv \
		python3 appstore/submit_version.py $(if $(DRY),--dry-run,)
