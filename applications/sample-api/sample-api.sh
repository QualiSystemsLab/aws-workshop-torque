#!/usr/bin/env bash

# Stop Script on Error
set -e

# For Debugging (print env. variables into a file)  
printenv > /var/log/colony-vars-"$(basename "$BASH_SOURCE" .sh)".txt

# Update packages and Upgrade system
echo "****************************************************************"
echo "Updating System"
echo "****************************************************************"
apt-get update -y


echo "****************************************************************"
echo "Installing python"
echo "****************************************************************"
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.8
sudo apt install python3-pip

echo "****************************************************************"
echo "Installing Nginx"
echo "****************************************************************"
sudo apt update
sudo apt install -y nginx
sudo service nginx start

cd /etc/nginx/sites-available
cat << EOF > default
server {
    listen        3001;
    server_name   *.com;
    location / {
        proxy_pass         http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
}
EOF

echo 'sites available modified'

sudo nginx -s reload

echo 'reload successful'


echo "****************************************************************"
echo '==> Extract api artifact to /var/www/secrets-manager-api'
echo "****************************************************************"

mkdir $ARTIFACTS_PATH/drop
tar -xvf $ARTIFACTS_PATH/sample-api.tar.gz -C $ARTIFACTS_PATH/drop/
mkdir /var/www/sample-api/
tar -xvf $ARTIFACTS_PATH/drop/drop/sample-*.tar.gz -C /var/www/sample-api

echo 'RELEASE_NUMBER='$RELEASE_NUMBER >> /etc/environment
echo 'API_BUILD_NUMBER='$API_BUILD_NUMBER >> /etc/environment
echo 'API_PORT='$API_PORT >> /etc/environment
source /etc/environment
