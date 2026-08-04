USER_EMAIL="chat_test_$(date +%s)@example.com"
USER_PASS="test1234"

echo "Signing up..."
REG_RESP=$(curl -s -X POST "http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io/api/auth/signup" -H "Content-Type: application/json" -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\",\"name\":\"Test Chat User\"}")
TOKEN=$(echo $REG_RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

echo "Sending message..."
curl -s -X POST "http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io/api/chat/messages" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"content\":\"test message\"}"

echo -e "\nUploading file..."
echo "test image" > test_image.png
curl -s -X POST "http://g8ize1mukw5u8njwdxr5g1og.163.227.239.97.sslip.io/api/upload" -H "Authorization: Bearer $TOKEN" -F "file=@test_image.png;type=image/png"

