#!/bin/sh

#This script get the current bandwidth usage for core network 
#links in the LAN
#Port 1 = Trunk to Upstairs Zyxel
#Port 2 = 2TB NAS
#Port 9 = VM1 VM Trunk
#Port 14 = QNAP NAS iSCSI

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

#We need to get a baseline for the traffic before starting the loop
#otherwise we have nothing to base out calculations on.

#Get in and out octets
oldin1=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.1 -Ov`
oldin2=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.2 -Ov`
oldin9=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.9 -Ov`
oldin14=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.14 -Ov`
oldout1=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.1 -Ov`
oldout2=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.2 -Ov`
oldout9=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.9 -Ov`
oldout14=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.14 -Ov`

#Strip out the value from the string
oldin1=$(echo $oldin1 | cut -c 12-)
oldin2=$(echo $oldin2 | cut -c 12-)
oldin9=$(echo $oldin9 | cut -c 12-)
oldin14=$(echo $oldin14 | cut -c 12-)
oldout1=$(echo $oldout1 | cut -c 12-)
oldout2=$(echo $oldout2 | cut -c 12-)
oldout9=$(echo $oldout9 | cut -c 12-)
oldout14=$(echo $oldout14 | cut -c 12-)

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
	#We need to wait between readings to have somthing to compare to
	sleep "$sleeptime"

	#Get in and out octets
	in1=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.1 -Ov`
	in2=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.2 -Ov`
	in9=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.9 -Ov`
	in14=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.14 -Ov`
	out1=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.1 -Ov`
	out2=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.2 -Ov`
	out9=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.9 -Ov`
	out14=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.14 -Ov`
	
	#Strip out the value from the string
	in1=$(echo $in1 | cut -c 12-)
	in2=$(echo $in2 | cut -c 12-)
	in9=$(echo $in9 | cut -c 12-)
	in14=$(echo $in14 | cut -c 12-)
	out1=$(echo $out1 | cut -c 12-)
	out2=$(echo $out2 | cut -c 12-)
	out9=$(echo $out9 | cut -c 12-)
	out14=$(echo $out14 | cut -c 12-)
	
	#Get the difference between the old and current
	diffin1=$((in1 - oldin1))
	diffin2=$((in2 - oldin2))
	diffin9=$((in9 - oldin9))
	diffin14=$((in14 - oldin14))
	diffout1=$((out1 - oldout1))
	diffout2=$((out2 - oldout2))
	diffout9=$((out9 - oldout9))
	diffout14=$((out14 - oldout14))
	
	#Calculate the bytes-per-second
	inbps1=$((diffin1 / sleeptime))
	inbps2=$((diffin2 / sleeptime))
	inbps9=$((diffin9 / sleeptime))
	inbps14=$((diffin14 / sleeptime))
	outbps1=$((diffout1 / sleeptime))
	outbps2=$((diffout2 / sleeptime))
	outbps9=$((diffout9 / sleeptime))
	outbps14=$((diffout14 / sleeptime))
	
	#Seems we need some basic data validation - can't have values less than 0!
	if [[ $inbps1 -lt 0 || $outbps1 -lt 0 || $inbps2 -lt 0 || $outbps2 -lt 0 || $inbps9 -lt 0 || $outbps9 -lt 0 || $inbps14 -lt 0 || $outbps14 -lt 0 ]] 
	then
		#There is an issue with one or more readings, get fresh ones
		#then wait for the next loop to calculate again.
		echo "We have a problem...moving to plan B"
		
		#Get in and out octets
		oldin1=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.1 -Ov`
		oldin2=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.2 -Ov`
		oldin9=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.9 -Ov`
		oldin14=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifInOctets.14 -Ov`
		oldout1=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.1 -Ov`
		oldout2=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.2 -Ov`
		oldout9=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.9 -Ov`
		oldout14=`snmpget -v 2c -c public 192.168.9.15 IF-MIB::ifOutOctets.14 -Ov`

		#Strip out the value from the string
		oldin1=$(echo $oldin1 | cut -c 12-)
		oldin2=$(echo $oldin2 | cut -c 12-)
		oldin9=$(echo $oldin9 | cut -c 12-)
		oldin14=$(echo $oldin14 | cut -c 12-)
		oldout1=$(echo $oldout1 | cut -c 12-)
		oldout2=$(echo $oldout2 | cut -c 12-)
		oldout9=$(echo $oldout9 | cut -c 12-)
		oldout14=$(echo $oldout14 | cut -c 12-)
	else
		#Output the current traffic
		echo "Port 1 Inbound Traffic: $inbps1 Bps"
		echo "Port 1 Outbound Traffic: $outbps1 Bps"
		echo "Port 2 Inbound Traffic: $inbps2 Bps"
		echo "Port 2 Outbound Traffic: $outbps2 Bps"
		echo "Port 9 Inbound Traffic: $inbps9 Bps"
		echo "Port 9 Outbound Traffic: $outbps9 Bps"
		echo "Port 14 Inbound Traffic: $inbps14 Bps"
		echo "Port 14 Outbound Traffic: $outbps14 Bps"
		
		#Write the data to the database
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig1,direction=inbound value=$inbps1"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig1,direction=outbound value=$outbps1"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig2,direction=inbound value=$inbps2"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig2,direction=outbound value=$outbps2"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig9,direction=inbound value=$inbps9"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig9,direction=outbound value=$outbps9"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig14,direction=inbound value=$inbps14"
		curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=zyxel1,interface=gig14,direction=outbound value=$outbps14"
		
		#Move the current variables to the old ones
		oldin1=$in1
		oldin2=$in2
		oldin9=$in9
		oldin14=$in14
		oldout1=$out1
		oldout2=$out2
		oldout9=$out9
		oldout14=$out14
	fi
	
done
