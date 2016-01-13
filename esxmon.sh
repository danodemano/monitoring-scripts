#!/bin/sh

#This script gets the current memory and CPU usage for the
#main ESXi server.  It's hacky at best but it works.

#The time we are going to sleep between readings
sleeptime=30

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

	#Let's start with the "easy" one, get the CPU usage
	cpu1=`snmpget -v 2c -c public 192.168.9.26 HOST-RESOURCES-MIB::hrProcessorLoad.1 -Ov`
	cpu2=`snmpget -v 2c -c public 192.168.9.26 HOST-RESOURCES-MIB::hrProcessorLoad.2 -Ov`
	cpu3=`snmpget -v 2c -c public 192.168.9.26 HOST-RESOURCES-MIB::hrProcessorLoad.3 -Ov`
	cpu4=`snmpget -v 2c -c public 192.168.9.26 HOST-RESOURCES-MIB::hrProcessorLoad.4 -Ov`

	#Strip out the value from the SNMP query
	cpu1=$(echo $cpu1 | cut -c 10-)
	cpu2=$(echo $cpu2 | cut -c 10-)
	cpu3=$(echo $cpu3 | cut -c 10-)
	cpu4=$(echo $cpu4 | cut -c 10-)

	#Now lets get the hardware info from the remote host
	hwinfo=$(ssh -t root@192.168.9.26 "esxcfg-info --hardware")

	#Lets try to find the lines we are looking for
	while read -r line; do
		#Check if we have the line we are looking for
		if [[ $line == *"Kernel Memory"* ]]
		then
		  kmemline=$line
		fi
		if [[ $line == *"-Free."* ]]
		then
		  freememline=$line
		fi
		#echo "... $line ..."
	done <<< "$hwinfo"

	#Remove the long string of .s
	kmemline=$(echo $kmemline | tr -s '[.]')
	freememline=$(echo $freememline | tr -s '[.]')

	#Lets parse out the memory values from the strings
	#First split on the only remaining . in the strings
	IFS='.' read -ra kmemarr <<< "$kmemline"
	kmem=${kmemarr[1]}
	IFS='.' read -ra freememarr <<< "$freememline"
	freemem=${freememarr[1]}
	#Now break it apart on the space
	IFS=' ' read -ra kmemarr <<< "$kmem"
	kmem=${kmemarr[0]}
	IFS=' ' read -ra freememarr <<< "$freemem"
	freemem=${freememarr[0]}

	#Now we can finally calculate used percentage
	used=$((kmem - freemem))
	used=$((used * 100))
	pcent=$((used / kmem))
	
	echo "CPU1: $cpu1%"
	echo "CPU2: $cpu2%"
	echo "CPU3: $cpu3%"
	echo "CPU4: $cpu4%"
	echo "Memory Used: $pcent%"
	
	#Write the data to the database
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "esxi_stats,host=esxi1,type=cpu_usage,cpu_number=1 value=$cpu1"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "esxi_stats,host=esxi1,type=cpu_usage,cpu_number=2 value=$cpu2"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "esxi_stats,host=esxi1,type=cpu_usage,cpu_number=3 value=$cpu3"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "esxi_stats,host=esxi1,type=cpu_usage,cpu_number=4 value=$cpu4"
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "esxi_stats,host=esxi1,type=memory_usage value=$pcent"

	#Wait for a bit before checking again
	sleep "$sleeptime"
	
done
