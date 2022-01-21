#!/bin/bash

yum -y update 
yum -y install httpd
MYIP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h2>Web Server with IP: $MYIP</h2><br><font color="red">Build by Terraform" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd