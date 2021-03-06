#!/bin/bash

# --- VARS ---
DefaultServerAddress="vpn.mycompany.com"
EasyRSADir="/etc/openvpn/easy-rsa"
KeysBaseDir="$EasyRSADir/keys"

ClientConfTemplate="$EasyRSADir/templates/client.conf"
ServerCAFile="/etc/openvpn/ca.crt"

# if ServerAddress is not defined as sys Environment variable
if [ -z $ServerAddress ]
then
  # find public IP address
  PUBIP="$( curl -L -k http://ifconfig.co )"
  if [ ! -z "$PUBIP" ]
  then
    ServerAddress="$PUBIP"
  else
    # PUBIP not exists - use DefaultServerAddress
    ServerAddress="$DefaultServerAddress"
  fi
fi


# --- SCRIPT ---

if [ "$1" ]
then
        keyname="$1"
else
        echo "Usage: $0 <keyname>"
        echo "Example: $0 DonJohn"
        exit 1
fi

# check keyname
if [ -e "$KeysBaseDir/$keyname.crt" ]
then
        echo "key file already exists: $keyname.crt"
        echo "Please give another name!"
        echo "Example: $keyname-`date +%Y`"
        exit 1
fi

# import keyvars
source $EasyRSADir/vars

# genkey
$EasyRSADir/pkitool "$keyname"

# genconf
ClientConf=$KeysBaseDir/$keyname-conf.ovpn
cp -f $ClientConfTemplate $ClientConf

#  serveraddress
sed -i 's@--ServerAddress--@'"$ServerAddress"'@g' $ClientConf

#  insert ca
sed -i '/<ca>/r '"$ServerCAFile"'' $ClientConf
#  insert cert
ls -hal $KeysBaseDir/$keyname.crt
sed -i '/<cert>/r '"$KeysBaseDir/$keyname.crt"'' $ClientConf
#  insert key
sed -i '/<key>/r '"$KeysBaseDir/$keyname.key"'' $ClientConf

GenDate=$( date +"%Y%m%d %T" )
echo -e "\n\n# Generated: $GenDate" >> $KeysBaseDir/$keyname-conf.ovpn


# MSG
echo ""
echo ""
echo "Client config file: $KeysBaseDir/$keyname-conf.ovpn"

