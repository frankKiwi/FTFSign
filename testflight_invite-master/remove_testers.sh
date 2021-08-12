#!/bin/bash
#!/bin/bash -ilex
 
# Install xctoken
#echo [123456] | sudo -S gem install xctoken

# Example 
# Params1 - ISSUER_ID
# Params2 - KEY_DIR
# Params3 - KEY_ID
# Params4 - APP_ID
# Params5 - BETAGROUP_NAME
# sh remove_testers.sh bce514ea-f50a-4228-9543-b574903f2c6c ./Keys/JingYu/jingyu8/ 5NBN282NV4 1476353235 08

# sh remove_testers.sh 30dc26e4-cbdf-4b91-b2b5-6e4354c00fc4 ./Keys/ 3B56N63924 1575679127 08

# Define ISSUER_ID
export ISSUER_ID=$1

# Define KEY_DIR
export KEY_DIR=$2

# Define KEY_ID
export KEY_ID=$3

# Define App ID
APP_ID=$4

# Define BetaGroup Name
BETAGROUP_NAME=$5

# Expire Time 15 Mins
TOKEN_EXPIRE_TIMESTAMP=$(($(date +%s) + 900))

# Define Token , Generate by xctoken (use ISSUER_ID, KEY_DIR, KEY_ID)
TOKEN="$(xctoken generate)"
echo $TOKEN

echo "APPID=${APP_ID},BETA_GROUP_NAME=${BETAGROUP_NAME},TOKEN=${TOKEN}"

# Current Token TimeStamp
TOKEN_CURRENT=$(date +%s)

next_url="https://api.appstoreconnect.apple.com/v1/betaTesters?filter%5Bapps%5D=${APP_ID}&filter%5BinviteType%5D=PUBLIC_LINK&fields%5BbetaTesters%5D=inviteType"

next_url_length=${#next_url}
while [ $next_url_length -ge 0 ]; do

    TOKEN_CURRENT=$(date +%s)
    # If Token Expired, Just ReGenerate It
    if [ ${TOKEN_CURRENT} -ge ${TOKEN_EXPIRE_TIMESTAMP} ]; then
        TOKEN_EXPIRE_TIMESTAMP=$(($(date +%s) + 900))

        TOKEN="$(xctoken generate)"
        echo 'Generate token'
    fi

    # Get BetaTesters By APP_ID And InviteType
    response=$(
        curl --request GET \
            --url $next_url \
            --header "Authorization:${TOKEN}"
    )

    echo "Get BetaTesters By APP_ID And InviteType, Response = $response"

    #获取测试用户列表
    list=$(echo $response | jq '.data')

    #获取测试用户列表长度
    length=$(echo $response | jq '.data|length')
    
 
    if [ $length == 0 ]; then
        echo 'All  Beta Testers Delete!!!';
        break;
    fi 
    #获取下一页
    #next_url=$(echo $response | jq '.links.next' | sed 's/\"//g')
    #echo "Next Url = $next_url"

    #next_url_length=${#next_url}
    for index in $(seq 0 $(($length - 1))); do
        tester_id=$(echo $list | jq ".[$index].id" | sed 's/\"//g')
        # If Token Expired, Just ReGenerate It
        TOKEN_CURRENT=$(date +%s)
        if [ ${TOKEN_CURRENT} -ge ${TOKEN_EXPIRE_TIMESTAMP} ]; then
            TOKEN_EXPIRE_TIMESTAMP=$(($(date +%s) + 900))
            TOKEN="$(xctoken generate)"

            echo 'Generate token'
        fi

        url="https://api.appstoreconnect.apple.com/v1/betaTesters/${tester_id}"
        echo $url
        response=$(
            curl --request DELETE \
                --url $url \
                --header "Authorization:${TOKEN}"
        )
        echo "Delete BetaTester = ${tester_id}, response = ${response}"
    done
done
