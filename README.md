# Custom Monitoring Scripts
A dump of the scripts used to monitor my environment and write to InfluxDB

This is a dump of all the custom bash and python scripts being used to monitor my network/power/enviroment for my home lab.  I used SNMP wherever possible however some things (such as the memory usage of ESXi) I was unable to poll and had to get creative.  Feel free to take this and tweak them to your needs!

The example-daemon can be used to turn these into startup script and be able to control them via the "service" command.  In the case of CentOS dump it into /etc/init.d, change the variables at the top, then run:

chmod +x /etc/init.d/script-name

chkconfig --add script-name

chkconfig script-name on

service script-name start
