.PHONY: help dev down logs clean \
	supabase-start supabase-start-background \
	functions functions-background \
	ngrok-up ngrok-down ngrok-background \
	functions-deploy test_daily_devotional test_slowness fresh

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
	@echo "Tests:"
	@echo "  make test_daily_devotional"
	@echo "  make test_slowness"

functions-deploy:
	supabase functions deploy daily-devotional --project-ref yvanxjoayoiocwzfpkfm
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
	xcodebuild clean build -project swiftbible.xcodeproj/ OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-expression-type-checking" | grep -Ei '^\d+\.\d+ms\t/.+$' | sort -r

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
