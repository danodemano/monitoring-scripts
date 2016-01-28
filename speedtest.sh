#!/bin/sh

#NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
#NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
#NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
#This script requires speedtest-cli to function!!!!!!!!!!!!!!!!!!!!!!!

#The time we are going to sleep between readings
sleeptime=60

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

	#Store the speedtest results into a variable
	results=$(speedtest-cli --simple)
	
	#echo "$results"
	
	#Lets try to find the lines we are looking for
	while read -r line; do
		#Check if we have the line we are looking for
		if [[ $line == *"Ping"* ]]
		then
		  ping=$line
		fi
		if [[ $line == *"Download"* ]]
		then
		  download=$line
		fi
		if [[ $line == *"Upload"* ]]
		then
		  upload=$line
		fi
	done <<< "$results"
	
	echo "$ping"
	echo "$download"
	echo "$upload"
	
	#Break apart the results based on a space
	IFS=' ' read -ra arrping <<< "$ping"
	ping=${arrping[1]}
	IFS=' ' read -ra arrdownload <<< "$download"
	download=${arrdownload[1]}
	IFS=' ' read -ra arrupload <<< "$upload"
	upload=${arrupload[1]}
	
	#Convet to mbps
	download=`echo - | awk "{print $download * 1048576}"`
	upload=`echo - | awk "{print $upload * 1048576}"`
	#download=$((download * 1048576))
	#upload=$((upload * 1048576))
	
	echo "$ping"
	echo "$download"
	echo "$upload"
	
	#Write to the database
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "speedtest,metric=ping value=$ping"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "speedtest,metric=download value=$download"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "speedtest,metric=upload value=$upload"

	#Wait for a bit before checking again
	sleep "$sleeptime"
	
done
