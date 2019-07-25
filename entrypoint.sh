#!/bin/bash

# turn on debug mode > https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

# start supervisor
sudo /usr/bin/supervisord -c /home/frappe/supervisor.conf
