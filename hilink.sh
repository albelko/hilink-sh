#!/bin/sh

COOKIES="$HOME/.hilink/cookies"
curl -X GET -c $COOKIES -b $COOKIES http://192.168.8.1/html/index.html --silent | grep csrf_token | sed "s/.* content=\"\(.*\)\".*/\1/" > "$HOME/.hilink/csrf"
CSRF_TOKEN=$(head -n 1 "$HOME/.hilink/csrf")

dial () {
  curl -X POST -c $COOKIES -b $COOKIES --header "__RequestVerificationToken: $CSRF_TOKEN" --header "Content-type: text/xml" --data "<?xml version='1.0' encoding='UTF-8'?><request><Action>$1</Action></request>" http://192.168.8.1/api/dialup/dial --silent > /dev/null
}

stats () {
  curl -X GET -c $COOKIES -b $COOKIES http://192.168.8.1/api/monitoring/traffic-statistics --silent > "$HOME/.hilink/stats"
  
  DOWNLOADED=$(grep 'CurrentDownload>' "$HOME/.hilink/stats" | awk -F ">" '{print $2}' | awk -F "<" '{print $1}')
  UPLOADED=$(grep 'CurrentUpload>' "$HOME/.hilink/stats" | awk -F ">" '{print $2}' | awk -F "<" '{print $1}')
  TOTAL=$(expr $DOWNLOADED + $UPLOADED)

  DOWNLOADED=$(bc <<< "scale=3;$DOWNLOADED/1024/1024")
  UPLOADED=$(bc <<< "scale=3;$UPLOADED/1024/1024")
  TOTAL=$(bc <<< "scale=3;$TOTAL/1024/1024")

  echo ""
  echo "\033[0;36m⬆︎ UPLD:   " $UPLOADED "Mb"
  echo "\033[0;32m⬇︎ DWLD:   " $DOWNLOADED "Mb"
  echo "\033[0;31m          " $TOTAL "Mb"
  echo ""
}

traffic () {
  curl -X POST -c $COOKIES -b $COOKIES --header "__RequestVerificationToken: $CSRF_TOKEN" --header "Content-type: text/xml" --data "<?xml version="1.0" encoding="UTF-8"?><request><content>*100*1#</content><codeType>CodeType</codeType><timeout></timeout></request>" http://192.168.8.1/api/ussd/send --silent > /dev/null
  sleep 5
  echo ""
  RESPONSE=$(curl -X GET -c $COOKIES -b $COOKIES http://192.168.8.1/api/ussd/get --silent | grep 'content>' | awk -F ">" '{print $2}' | awk -F "<" '{print $1}')
  echo "# $RESPONSE"  
  echo ""
}

case "$1" in
  -c)
    dial 1
  ;;
  -d)
    dial 0
  ;;
  -s)
    stats
  ;;
  -t)
    traffic
  ;;
  -i)
    curl -X GET -c $COOKIES -b $COOKIES http://192.168.8.1/api/device/information
  ;;
  *)
      echo "Unknown command"
      echo ""
  ;;
esac
