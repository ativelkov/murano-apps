#!/bin/bash

function include(){
    curr_dir=$(cd $(dirname "$0") && pwd)
    inc_file_path=$curr_dir/$1
    if [ -f "$inc_file_path" ]; then
        . $inc_file_path
    else
        echo -e "$inc_file_path not found!"
        exit 1
    fi
}
include "common.sh"

get_os
[[ $? -ne 0 ]] && exit 1
if [[ "$DistroBasedOn" != "redhat" ]]; then
    DEBUGLVL=4
    log "ERROR: We are sorry, only \"redhat\" based distribution of Linux supported for this service type, exiting!"
    exit 1
fi

bash installer.sh -p sys -i "java-1.7.0-openjdk-devel"

cd /usr/share/tomcat6/webapps
git clone $1 app

/bin/cp app/WEB-INF/lib/*.* /usr/share/tomcat6/lib/

service tomcat6 restart

cd app/WEB-INF/classes
for f in $(find . -name "*.java"); do
    javac -cp /usr/share/tomcat6/lib/tomcat-servlet-2.5-api.jar "$f"
done
