#!/bin/bash

echo "Starting docker runtime.."

# turn on debug mode > https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

ls -al

if [ ! -d "/bench/bench" ]; then
    echo "No bench detecting, initializing now..."
    cd /bench
    sudo chmod 777 .
    bench init bench
    bench get-app erpnext https://github.com/frappe/erpnext --branch version-12
    bench update --patch
fi;

ls -al

# start supervisor
sudo /usr/bin/supervisord -c /home/frappe/supervisor.conf
