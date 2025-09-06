# Use official OpenSIPS 3.4 image as base
FROM opensips/opensips:3.4

ENV DEBIAN_FRONTEND=noninteractive

# Install extra tools + MySQL/MariaDB dev headers for mysqlclient
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    nano \
    net-tools \
    sngrep \
    mariadb-client \
    default-libmysqlclient-dev \
    build-essential \
    iproute2 \
    iputils-ping \
    telnet \
    git \
    python3 python3-pip python3-dev \
    python3-setuptools python3-wheel \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install opensips-auth-modules opensips-mysql-module 

#if mysql table is not created then run below command
#RUN opensips-cli >> opensips-cli -o database_force_drop=true \
          #   -o database_admin_url="mysql://root:rootpassword@db" \
           #  -o database_schema_path="/usr/local/src/opensips/scripts" \
            # -x database create

        
# mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/auth_db-create.sql
# mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/usrloc-create.sql
# mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/registrant-create.sql
# mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/dispatcher-create.sql
# mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/dialog-create.sql


 
# Install OpenSIPS CLI properly
RUN pip3 install --upgrade pip setuptools wheel && \
git clone https://github.com/OpenSIPS/opensips-cli.git /usr/local/src/opensips-cli && \
cd /usr/local/src/opensips-cli && \
pip3 install . && \
cd /   
# Install opensips-cli from GitHub

# Create directory for configs
RUN mkdir -p /usr/local/etc/opensips

# Set working directory
WORKDIR /usr/local/etc/opensips

# Copy configs
COPY opensips.cfg /usr/local/etc/opensips/opensips.cfg
COPY opensips-cli.cfg /usr/local/etc/opensips-cli.cfg

# Default command to start OpenSIPS
CMD ["opensips", "-F", "-f", "/usr/local/etc/opensips/opensips.cfg"]
