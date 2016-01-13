#!/bin/sh

#This script get the current bandwidth usage for both the main
#Internet interface as well as the kids/guest interface and
#writes them to the InfluxDB instance running on this machine.

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

#We need to get a baseline for the traffic before starting the loop
#otherwise we have nothing to base out calculations on.

#Get in and out octets
oldin=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifInOctets.4 -Ov`
oldout=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifOutOctets.4 -Ov`
kidsoldin=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifInOctets.3 -Ov`
kidsoldout=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifOutOctets.3 -Ov`

#Strip out the value from the string
oldin=$(echo $oldin | cut -c 12-)
oldout=$(echo $oldout | cut -c 12-)
kidsoldin=$(echo $kidsoldin | cut -c 12-)
kidsoldout=$(echo $kidsoldout | cut -c 12-)

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
	#We need to wait between readings to have somthing to compare to
	sleep "$sleeptime"

	#Get in and out octets
	in=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifInOctets.4 -Ov`
	out=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifOutOctets.4 -Ov`
	kidsin=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifInOctets.3 -Ov`
	kidsout=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifOutOctets.3 -Ov`
	
	#Strip out the value from the string
	in=$(echo $in | cut -c 12-)
	out=$(echo $out | cut -c 12-)
	kidsin=$(echo $kidsin | cut -c 12-)
	kidsout=$(echo $kidsout | cut -c 12-)
	
	#Get the difference between the old and current
	diffin=$((in - oldin))
	diffout=$((out - oldout))
	kidsdiffin=$((kidsin - kidsoldin))
	kidsdiffout=$((kidsout - kidsoldout))
	
	#Calculate the bytes-per-second
	inbps=$((diffin / sleeptime))
	outbps=$((diffout / sleeptime))
	kidsinbps=$((kidsdiffin / sleeptime))
	kidsoutbps=$((kidsdiffout / sleeptime))
	
	#Seems we need some basic data validation - can't have values less than 0!
	if [[ $inbps -lt 0 || $outbps -lt 0 || $kidsinbps -lt 0 || $kidsoutbps -lt 0 ]] 
	then
		#There is an issue with one or more readings, get fresh ones
		#then wait for the next loop to calculate again.
		echo "We have a problem...moving to plan B"
		
		#Get in and out octets
		oldin=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifInOctets.4 -Ov`
		oldout=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifOutOctets.4 -Ov`
		kidsoldin=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifInOctets.3 -Ov`
		kidsoldout=`snmpget -v 2c -c public 192.168.9.1 IF-MIB::ifOutOctets.3 -Ov`

		#Strip out the value from the string
		oldin=$(echo $oldin | cut -c 12-)
		oldout=$(echo $oldout | cut -c 12-)
		kidsoldin=$(echo $kidsoldin | cut -c 12-)
		kidsoldout=$(echo $kidsoldout | cut -c 12-)
	else
		#Output the current traffic
		echo "Main current inbound traffic: $inbps bps"
		echo "Main current outbound traffic: $outbps bps"
		echo "Kids/Guest current inbound traffic: $kidsinbps bps"
		echo "Kids/Guest current outbound traffic: $kidsoutbps bps"
		
		#Write the data to the database
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=sophosutm,interface=eth2,direction=inbound value=$inbps"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=sophosutm,interface=eth2,direction=outbound value=$outbps"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=sophosutm,interface=eth1,direction=inbound value=$kidsinbps"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=sophosutm,interface=eth1,direction=outbound value=$kidsoutbps"
		
		#Move the current variables to the old ones
		oldin=$in
		oldout=$out
		kidsoldin=$kidsin
		kidsoldout=$kidsout
	fi
	
done
