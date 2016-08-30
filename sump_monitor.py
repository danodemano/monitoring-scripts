#Import the required modules
import RPi.GPIO as GPIO
import time
import requests
import math

#Setup the GPIO
GPIO.setmode(GPIO.BCM)

#Define the TRIG and ECO pins - these are labeled on the sensor
TRIG = 23
ECHO = 24

#Number of readings we are going to take to avoid issues
numreadings = 7

#Alert that we are starting the measurement
print "Distance Measurement In Progress"

#Loop based on the above number
distancearray=[]
count = 0
while (count < numreadings):
        #Setup the two pins for reading
        GPIO.setup(TRIG,GPIO.OUT)
        GPIO.setup(ECHO,GPIO.IN)

        GPIO.output(TRIG, False)
        print "Waiting For Sensor To Settle"
        time.sleep(2)

        GPIO.output(TRIG, True)
        time.sleep(0.00001)
        GPIO.output(TRIG, False)

        while GPIO.input(ECHO)==0:
          pulse_start = time.time()

        while GPIO.input(ECHO)==1:
          pulse_end = time.time()

        pulse_duration = pulse_end - pulse_start

        distance = pulse_duration * 17150

        distance = round(distance, 2)

        print "Distance:",distance,"cm"

        distancearray.append(distance)

        count = count + 1

#Get the half of the reading number and round up
mid = numreadings / 2
mid = int(math.ceil(mid))

#Sort the array
distancearray.sort()

#Just for debugging
print distancearray
print distancearray[mid]

#Put the middle value back into the distance variable
distance = distancearray[mid]

#Write the data to the influxdn instance
data = 'environment,host=rpi1,location=basement,type=sumppump value=' + str(distance)
print data
output = requests.post('http://192.168.9.42:8086/write?db=home', data=data)
print output

#Release connections to the GPIO pins
GPIO.cleanup()
