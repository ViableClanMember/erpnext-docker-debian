FROM debian:9.6-slim

# install package
RUN apt-get -y update \
  && apt-get -y install \
  # prerequisite
  build-essential \
  python-setuptools \
  wget \
  cron \
  sudo \
  locales \
  git \
  # production
  supervisor \
  nginx \
  # used for envsubst, making nginx cnf from template
  gettext-base \
  # fixed for wkhtmltopdf SSL problems
  # https://github.com/pipech/erpnext-docker-debian/issues/31
  libssl1.0-dev \
  # clean up
  && apt-get autoremove --purge \
  && apt-get clean

# [work around] for  "cmd": "chsh frappe -s $(which bash)", "stderr": "Password: chsh: PAM: Authentication failure"
# caused by > bench/playbooks/create_user.yml > shell: "chsh {{ frappe_user }} -s $(which bash)"
RUN sed -i 's/auth       required   pam_shells.so/auth       sufficient   pam_shells.so/' /etc/pam.d/chsh

# set locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen
ENV LC_ALL=en_US.UTF-8 \
  LC_CTYPE=en_US.UTF-8 \
  LANG=en_US.UTF-8

# manually install mariadb
RUN apt-get update \
  # add repo from mariadb mirrors
  # https://downloads.mariadb.org/mariadb/repositories
  && apt-get install -y software-properties-common dirmngr \
  && apt-key adv --no-tty --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 \
  && add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/debian stretch main' \
  # make frontend noninteractive to skip root password change
  && export DEBIAN_FRONTEND=noninteractive \
  # install mariadb
  && apt-get update \
  && apt-get install -y \
  # package form bench playbook
  # https://github.com/frappe/bench/blob/d1810e1dc1849daabace392c55b39057c09e98b9/playbooks/roles/mariadb/tasks/debian.yml#L23
  mariadb-client \
  mariadb-common \
  libmariadbclient18 \
  python-mysqldb \
  python3-mysqldb

# add users without sudo password
ENV systemUser=frappe
RUN adduser --disabled-password --gecos "" $systemUser \
  && usermod -aG sudo $systemUser \
  && echo "%sudo  ALL=(ALL)  NOPASSWD: ALL" > /etc/sudoers.d/sudoers

RUN mkdir -p /var/lib/nginx/body
RUN mkdir -p /var/lib/nginx/fastcgi
RUN mkdir -p /var/lib/nginx/proxy
RUN mkdir -p /var/lib/nginx/uwsgi

# set user and workdir
USER $systemUser
WORKDIR /home/$systemUser

# install prerequisite for bench with easy install script
ENV easyinstallRepo='https://raw.githubusercontent.com/frappe/bench/master/playbooks/install.py' \
  benchPath=bench-repo \
  benchBranch=master \
  benchFolderName=bench \
  benchRepo='https://github.com/frappe/bench' \
  frappeRepo='https://github.com/frappe/frappe' \
  erpnextRepo='https://github.com/frappe/erpnext'

# for python 2 use = python
# for python 3 use = python3 or python3.6 for centos
ARG pythonVersion=python3
ARG appBranch=version-12

RUN git clone $benchRepo /tmp/.bench --depth 1 --branch $benchBranch \
  # start easy install
  && wget $easyinstallRepo \
  # remove mariadb from bench playbook
  && sed -i '/mariadb/d' /tmp/.bench/playbooks/site.yml \
  && python install.py \
  --without-bench-setup \
  # install bench
  && rm -rf bench \
  && echo "=========================================== 1 ===========================================" \
  && git clone --branch $benchBranch --depth 1 --origin upstream $benchRepo $benchPath  \
  && echo "=========================================== 2 ===========================================" \
  && sudo pip install -e $benchPath \
  # init bench folder
  && echo "=========================================== 3 ===========================================" \
  && bench init $benchFolderName --frappe-path $frappeRepo --frappe-branch $appBranch --python $pythonVersion \
  # cd to bench folder
  && cd $benchFolderName \
  # install erpnext
  && echo "=========================================== 4 ===========================================" \
  && bench get-app erpnext $erpnextRepo --branch $appBranch \
  # [work around] fix for Setup failed >> Could not start up: Error in setup
  && echo "=========================================== 5 ===========================================" \
  && bench update --patch \
  && echo "=========================================== delete unnecessary frappe apps ===========================================" \
  && rm -rf \
  apps/frappe_io \
  apps/foundation \
  && sed -i '/foundation\|frappe_io/d' sites/apps.txt \
  # delete temp file
  && sudo rm -rf /tmp/* \
  # clean up installation
  && sudo apt-get autoremove --purge -y \
  && sudo apt-get clean

# [work around] change back config for work around for  "cmd": "chsh frappe -s $(which bash)", "stderr": "Password: chsh: PAM: Authentication failure"
RUN sudo sed -i 's/auth       sufficient   pam_shells.so/auth       required   pam_shells.so/' /etc/pam.d/chsh

# set user and workdir
USER $systemUser
WORKDIR /home/$systemUser/$benchFolderName

# run start mysql service and start bench when container start
COPY entrypoint.sh /home/$systemUser/
RUN sudo chmod +x /home/$systemUser/entrypoint.sh

COPY redis_cache.conf /home/$systemUser/$benchFolderName/conf/
COPY redis_queue.conf /home/$systemUser/$benchFolderName/conf/
COPY redis_socketio.conf /home/$systemUser/$benchFolderName/conf/
COPY common_site_config.json /home/$systemUser/$benchFolderName/sites/
COPY supervisor.conf /home/$systemUser/
COPY nginx.conf /home/$systemUser/

# image entrypoint script
CMD ["/home/frappe/entrypoint.sh"]

# expose port
EXPOSE 8000
