#!/bin/sh

#The time we are going to sleep between readings
sleeptime=30

#Google DNS is a good choice for host and it's anycasted to
#a nearby server.  You may want to modify this though based
#on your location
host="8.8.8.8"

#How many pings are we going to send
number="20"

#How long are we going to wait between pings
#Keep in mind only superusers (root) can use a time 
#value of 200ms or less!!
wait="0.25"

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

	#Lets ping the host!
	results=$(ping -c $number -i $wait -q $host)

	#We need to get ONLY lines 4 and 5 from the results
	#The rest isn't needed for ourpurposes
	counter=0
	while read -r line; do
		((counter++))
		if [ $counter = 4 ]
		then
			line4="$line"
		fi
		if [ $counter = 5 ]
		then
			line5="$line"
		fi
	done <<< "$results"

	echo "$line4"
	echo "$line5"

	#Parse out the 2 lines
	#First we need to get the packet loss
	IFS=',' read -ra arrline4 <<< "$line4" #Split the line based on a ,
	loss=${arrline4[2]} #Get just the 3rd element containing the loss
	IFS='%' read -ra lossnumber <<< "$loss" #Split the thrid element based on a %
	lossnumber=$(echo $lossnumber | xargs) #Remove the leading whitespace

	#Now lets get the min/avg/max/mdev
	IFS=' = ' read -ra arrline5 <<< "$line5" #Split the lines based on a =
	numbers=${arrline5[2]} #Get the right side containing the actual numbers
	IFS='/' read -ra numbersarray <<< "$numbers" #Break out all the numbers based on a /
	#Get the individual values from the array
	min=${numbersarray[0]}
	avg=${numbersarray[1]}
	max=${numbersarray[2]}
	mdev=${numbersarray[3]}

	#Write the data to the database
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ping,host=8.8.8.8,measurement=loss value=$lossnumber"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ping,host=8.8.8.8,measurement=min value=$min"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ping,host=8.8.8.8,measurement=avg value=$avg"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ping,host=8.8.8.8,measurement=max value=$max"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "ping,host=8.8.8.8,measurement=mdev value=$mdev"
	
	#Wait for a bit before checking again
	sleep "$sleeptime"
	
done

