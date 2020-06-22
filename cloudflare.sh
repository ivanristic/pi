#!/bin/bash
echo "checking if there is service running..."
CFVSD=$(systemctl is-active cloudflared)
CFVS=/usr/local/bin/cloudflared

if [[ -f $CFVS ]]; then
	echo "$CFVS exists."
else
	echo "creating cloudflared user"
	sudo useradd -s /usr/sbin/nologin -r -M cloudflared

	echo "creatding cloudflared options"

	sudo cat << EOF > /etc/default/cloudflared
	# Commandline args for cloudflared 
	CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query
EOF

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
fi


if [[ $CFVSD == "active" ]]; then
	sudo systemctl stop cloudflared
fi
echo "Curently downloading cloudflared..."
sudo rm cloudflared cloudflared-stable-linux-arm.tgz
wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-arm.tgz
tar -xvzf cloudflared-stable-linux-arm.tgz
sudo cp ./cloudflared /usr/local/bin
sudo chmod +x /usr/local/bin/cloudflared
echo "starting cloudflared"
sudo systemctl start cloudflared
CFVSD=$(systemctl is-active cloudflared)
CFV=$(cloudflared -v)
#if [[ $CFVSD == "activating" ]]; then
if [[ $CFV != "cloudflared version"* ]]; then
	echo "Alternative cloudflared mirror..."
	sudo rm cloudflared cloudflared-stable-linux-arm.tgz
	wget https://hobin.ca/cloudflared/latest?type=tar -O cloudflared-stable-linux-arm.tgz
	tar -xvzf cloudflared-stable-linux-arm.tgz
	sudo systemctl stop cloudflared
	sudo cp ./cloudflared /usr/local/bin
	sudo chmod +x /usr/local/bin/cloudflared
	sudo systemctl start cloudflared
	CFV=$(cloudflared -v)
	echo $CFV
	if [[ $CFV == "cloudflared version"* ]]; then
		echo "changing ownership to files"
		sudo chown cloudflared:cloudflared /etc/default/cloudflared
		sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared
		echo "starting service"
		sudo systemctl enable cloudflared
	else
		echo "problem installing cloudflared"
	fi
fi
