#!/bin/bash
BASE_URL="http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io/api"
USER_EMAIL="testcrud$(date +%s)@example.com"
USER_PASS="password123"

echo "1. Registering user..."
REG_RESP=$(curl -s -X POST "$BASE_URL/auth/signup" -H "Content-Type: application/json" -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\",\"name\":\"Test User\"}")
echo $REG_RESP
TOKEN=$(echo $REG_RESP | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

echo -e "\n2. Get Profile..."
curl -s -X GET "$BASE_URL/profile" -H "Authorization: Bearer $TOKEN" | grep -o '.*'

echo -e "\n\n3. Update Profile..."
curl -s -X POST "$BASE_URL/profile" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"quit_date":"2023-10-01","plan_duration":10}' | grep -o '.*'

echo -e "\n\n4. Create Checkin..."
curl -s -X POST "$BASE_URL/checkins" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data '{"check_in_date": "2026-08-04", "craving_level": 5, "mood": "Happy", "smoked_today": false, "used_tobacco": false}' | grep -o '.*'

echo -e "\n\n5. Get Checkin Today..."
curl -s -X GET "$BASE_URL/checkins/today" -H "Authorization: Bearer $TOKEN" | grep -o '.*'

echo -e "\n\n6. Gamification Stats..."
curl -s -X GET "$BASE_URL/gamification/stats" -H "Authorization: Bearer $TOKEN" | grep -o '.*'

echo -e "\n"
