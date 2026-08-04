#!/bin/bash
BASE_URL="http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io/api"
USER_EMAIL="testcrud$(date +%s)@example.com"
USER_PASS="password123"

echo "1. Registering user..."
REG_RESP=$(curl -s -X POST "$BASE_URL/auth/register" -H "Content-Type: application/json" -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\",\"name\":\"Test User\"}")
echo $REG_RESP
USER_ID=$(echo $REG_RESP | grep -o '"user":{"id":[^,]*' | cut -d: -f3)
TOKEN=$(echo $REG_RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Registration failed. Trying login..."
  LOGIN_RESP=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}")
  echo $LOGIN_RESP
  TOKEN=$(echo $LOGIN_RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)
fi

echo -e "\n2. Get Profile..."
curl -s -X GET "$BASE_URL/profile" -H "Authorization: Bearer $TOKEN" | grep -o '.*'

echo -e "\n\n3. Update Profile..."
curl -s -X PUT "$BASE_URL/profile" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"quit_date":"2023-10-01","cigarettes_per_day":10,"price_per_pack":5,"currency":"USD"}' | grep -o '.*'

echo -e "\n\n4. Create Checkin..."
curl -s -X POST "$BASE_URL/checkins" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"status":"clean","cravings_count":2,"mood":"good","notes":"Feeling strong"}' | grep -o '.*'

echo -e "\n\n5. Get Checkins..."
curl -s -X GET "$BASE_URL/checkins" -H "Authorization: Bearer $TOKEN" | grep -o '.*'

echo -e "\n\n6. Gamification Leaderboard..."
curl -s -X GET "$BASE_URL/gamification/leaderboard" | grep -o '.*'

echo -e "\n"
