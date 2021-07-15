#!/bin/bash

ENDPOINT="$1"
USER="$2"
PASSWORD="$3"
DB="$4"
COLLECTION="$5"
DATA="$6"

# install mongoimport cli tool
echo 'Install MongoDB'
apt-get install -y gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
apt-get update -y
apt-get install -y mongodb-org

echo "mongodb-org hold" | dpkg --set-selections
echo "mongodb-org-database hold" | dpkg --set-selections
echo "mongodb-org-server hold" | dpkg --set-selections
echo "mongodb-org-shell hold" | dpkg --set-selections
echo "mongodb-org-mongos hold" | dpkg --set-selections
echo "mongodb-org-tools hold" | dpkg --set-selections

# dump inputs
echo "Enpoint: $ENDPOINT"
echo "User: $USER"
echo "Password: ****"
echo "DB Name: $DB"
echo "Collection Name: $COLLECTION"
echo "Data: $DATA"

# wait until cluster endpoint is listining
apt-get install netcat -y
timeout=600
wait_interval=5
for (( c=0 ; c<$timeout ; c=c+$wait_interval ))	
do
    # check if enpoint is listening
    nc -z -w1 $ENDPOINT 27017
    status=$?
    if [ $status -ne 0 ]; then
        # not listening yet, waiting
        let remaining=$wait_sec-$c
        echo "Endpoint $ENDPOINT is not listening on port 27017 yet, sleeping for $wait_interval. Remaining timeout is $remaining seconds."
        unset status  # reset the $status var
        
        sleep $wait_interval
    else
        # listening, exit loop
        echo "Endpoint is listening on port 27017, exiting wait loop"
        break
    fi
done

# load data to mongodb endpoint
echo "$DATA" | mongoimport -h=$ENDPOINT -u=$USER -p=$PASSWORD -d=$DB -c=$COLLECTION --jsonArray

retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Error importing data"
else
    echo "Imported data successfully"
fi
exit $retVal
