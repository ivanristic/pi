#!/bin/bash
#Ubuntu
#wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb
#sudo apt-get install ./cloudflared-stable-linux-amd64.debc

#Raspbian
echo "Curently downloading cloudflared..."
wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-arm.tgz
tar -xvzf cloudflared-stable-linux-arm.tgz
sudo cp ./cloudflared /usr/local/bin
sudo chmod +x /usr/local/bin/cloudflared
CFV=$(cloudflared -v)
#echo $CFV
if [[ $CFV == "Segmentation fault"* ]]; then
	echo "Alternative cloudflared mirror..."
	wget https://hobin.ca/cloudflared/latest?type=tar -O cloudflared-stable-linux-arm.tgz
	tar -xvzf cloudflared-stable-linux-arm.tgz
	sudo cp ./cloudflared /usr/local/bin
	sudo chmod +x /usr/local/bin/cloudflared
	CFV=$(cloudflared -v)
elif [[ $CFV == "cloudflared version"* ]]; then
#Segmentation fault
#https://bin.equinox.io/a/4SUTAEmvqzB/cloudflared-2018.7.2-linux-arm.tar.gz
#https://hobin.ca/cloudflared/latest?type=tar
	echo "found " $CFV
	
	echo "creating cloudflared user"
	sudo useradd -s /usr/sbin/nologin -r -M cloudflared
	
	echo "creatding cloudflared options"
	#touch cloudflared
	#echo "# Commandline args for cloudflared
	#> CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query" > cloudflared
	#sudo mv cloudflared /etc/default/cloudflared
	sudo cat << EOF > /etc/default/cloudflared
	# Commandline args for cloudflared 
	CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query
EOF
	
	echo "changing ownership to files"
	sudo chown cloudflared:cloudflared /etc/default/cloudflared
	sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared
	
	echo "creating cloudflared service"
	touch cloudflared.service
	sudo cat << EOF > /etc/systemd/system/cloudflared.service
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns \$CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
	chmod 0644 /etc/systemd/system/cloudflared.service
	
	echo "starting service"
	sudo systemctl enable cloudflared
	sudo systemctl start cloudflared
	sudo systemctl status cloudflared
else
	clear
	echo "Unable to install cloudflared!!!!!!!!!"
fi
