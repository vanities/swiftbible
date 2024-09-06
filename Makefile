.PHONY: functions

functions:
	supabase functions deploy daily-devotional --project-ref yvanxjoayoiocwzfpkfm

test_daily_devotional:
	curl -X POST 'https://yvanxjoayoiocwzfpkfm.supabase.co/functions/v1/daily-devotional' \
	-H 'Content-Type: application/json' \
	-H 'Authorization: Bearer $(SWIFTBIBLE_KEY)' \
	-H 'SuperSecret: $(SWIFTBIBLE_SUPERSECRET_KEY)' \
	-d '{}';
