#!/bin/bash

# set fixed locale
export LC_ALL=C
export LANG=C

#### EDIT SECTION 1 HERE ####
# Set your spacewalk server
SPACEWALK=127.0.0.1


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR;
. ya-errata-import.cfg 

##Lets get a listing of all the channels! 

ALLCHANNELS=`spacewalk-api --server=127.0.0.1 --user $SPACEWALK_USER --password $SPACEWALK_PASS channel.listAllChannels "%session%" | grep label`

#Set the field separator to new line
IFS=$'\n'

#Try to iterate over each line
I=0
for item in $ALLCHANNELS
do
        CHANNELNAME=`echo $item | awk -F \' '{print $4}'` 

 	REPOURL=`spacewalk-api --server=127.0.0.1 --user $SPACEWALK_USER --password $SPACEWALK_PASS channel.software.getDetails "%session%" "$CHANNELNAME" | grep gpg_key_url | awk -F \' '{print $4}'`
	
	KEYS[$I]=$REPOURL;
	spacewalk-repo-sync -q --channel=$CHANNELNAME
	CHANNELNAME="";
	I=$((I+1))
done


echo "" > /tmp/spacewalkgpgkeys
#Write out the keys first
for key in ${KEYS[*]}
do
	echo $key >> /tmp/spacewalkgpgkeys
done

rm -rf /var/www/html/pub/keys/*

for url in ${KEYS[*]}
do
echo "Downloading: $url"
wget -N -q $url -P /var/www/html/pub/keys/

done

ls -1 /var/www/html/pub/keys | xargs -n1 -I '{}' echo http://cias-linux-management.rit.edu/pub/keys/{} > /var/www/html/pub/gpg_urls.txt

#write out the uniq url's to the spacewalk web directory
#cat /tmp/spacewalkgpgkeys | uniq > /var/www/html/pub/gpg_urls.txt


exit 1;
