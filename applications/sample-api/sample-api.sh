#!/usr/bin/env bash

echo "********************Initialization started*********************"
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
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update -y
sudo apt install -y python3.8
sudo apt install -y python3-pip
echo python --version
# sudo dnf install -y python3
echo python --version
echo python3 --version
echo python
python3 -m pip install -U numpy --user
python3 -m pip install -U setuptools --user
python3 -m pip install -U Flask --user

echo "*********************************************"
# echo "last try for python installation"
# sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget
# cd /tmp
# wget https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz
# tar -xf Python-3.8.3.tgz
# cd python-3.8.3
# sudo make altinstall
# sudo make install
# echo python --version
# echo python3 --version

echo "****************************************************************"
echo "Installing Nginx"
echo "****************************************************************"
sudo apt update -y
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
echo "Installing Nginx compleated"
echo "****************************************************************"


echo "****************************************************************"
echo '==> Extract api artifact to /var/sample-api'
echo "****************************************************************"
echo $ARTIFACTS_PATH

mkdir $ARTIFACTS_PATH/drop
tar -xvf $ARTIFACTS_PATH/sample-api-*.tar.gz -C $ARTIFACTS_PATH/drop/

echo $ARTIFACTS_PATH
echo "*********************artifacts copied to root**********************************"
mkdir /var/sample-api/

# tar -xvf $ARTIFACTS_PATH/drop/sample-api-* -C /var/sample-api

echo "**********************untar & scp **************"
# tar -xzvf latest.tar.gz
rsync -av $ARTIFACTS_PATH/drop/sample-api-* /var/sample-api/

echo "*********************artifacts copied to root**********************************"

echo 'RELEASE_NUMBER='$RELEASE_NUMBER >> /etc/environment
echo 'API_BUILD_NUMBER='$API_BUILD_NUMBER >> /etc/environment
echo 'API_PORT='$API_PORT >> /etc/environment
source /etc/environment

echo "********************Initialization finished*********************"


echo '******Start our api/script**************************'
echo python3 --version
echo *

# python3 sample-api.py
python3 /var/sample-api/sample-api-0.0.1/src/example/sample-api.py
echo '******End our api ***********************************'
