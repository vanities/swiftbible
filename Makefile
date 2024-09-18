.PHONY: functions test_daily_devotional test_slowness

functions:
	supabase functions deploy daily-devotional --project-ref yvanxjoayoiocwzfpkfm
	supabase functions deploy user-self-deletion --project-ref yvanxjoayoiocwzfpkfm

test_daily_devotional:
	curl -X POST 'https://yvanxjoayoiocwzfpkfm.supabase.co/functions/v1/daily-devotional' \
	-H 'Content-Type: application/json' \
	-H 'Authorization: Bearer $(SWIFTBIBLE_KEY)' \
	-H 'SuperSecret: $(SWIFTBIBLE_SUPERSECRET_KEY)' \
	-d '{}';

test_slowness:
	xcodebuild clean build -project swiftbible.xcodeproj/ OTHER_SWIFT_FLAGS="-Xfrontend -debug-time-expression-type-checking" | grep -Ei '^\d+\.\d+ms\t/.+$' | sort -r
