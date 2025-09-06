
# Project Title

A brief description of what this project does and who it's for

# OpenSIPS + RTPEngine + MariaDB Docker Setup

This repository contains a complete Docker Compose setup for running OpenSIPS 3.4 with RTPEngine and MariaDB for SIP proxy/registrar functionality with media relay capabilities.

## Architecture

- **OpenSIPS 3.4**: SIP proxy/registrar server
- **RTPEngine**: Media relay server for RTP/RTCP traffic
- **MariaDB 10.11**: Database backend for OpenSIPS modules

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Basic understanding of SIP and VoIP concepts

## Quick Start

1. **Clone and navigate to the project directory**:
   ```bash
   git clone https://github.com/Vishaltalsaniya-7/Opensips-Rtpengine-mariadb-with-Docker-images.git
   cd opensips-docker
   ```

2. **Create required configuration files** (see Configuration section below)

3. **Build and start the services**:
   ```bash
   docker-compose up -d
   ```

4. **Initialize the database** (see Database Setup section below)

## File Structure

```
├── docker-compose.yml
├── Dockerfile
├── README.md
├── opensips.cfg              # OpenSIPS main configuration
└── opensips-cli.cfg          # OpenSIPS CLI configuration
```

## Configuration Files

### 1. opensips.cfg
Create your OpenSIPS main configuration file. This should include:
- Database connection settings
- SIP routing logic
- RTPEngine integration
- Authentication modules

Example database connection in opensips.cfg:
```
# Database URL
modparam("usrloc", "db_url", "mysql://opensips:opensipsrw@db/opensips")
modparam("auth_db", "db_url", "mysql://opensips:opensipsrw@db/opensips")
modparam("dispatcher", "db_url", "mysql://opensips:opensipsrw@db/opensips")
```

### 2. opensips-cli.cfg
Create the OpenSIPS CLI configuration file with database connection details:

```ini
[default]
log_level = INFO
prompt_name = opensips-cli
prompt_intro = Welcome to OpenSIPS Command Line Interface!
prompt_emptyline_repeat_cmd = False
history_file = ~/.opensips_cli_history
history_file_size = 1000
output_type = pretty-print

[database_admin]
# Database admin connection (for creating databases)
database_admin_url = mysql://root:rootpassword@db

[database_data]
# Database connection for data operations
database_url = mysql://opensips:opensipsrw@db/opensips
database_schema_path = /usr/local/src/opensips/scripts
database_force_drop = False
```

## Database Setup

After starting the containers, you need to initialize the OpenSIPS database:

### Method 1: Using opensips-cli (Recommended)

1. **Access the OpenSIPS container**:
   ```bash
   docker exec -it opensips bash
   ```

2. **Create the database schema**:
   ```bash
   opensips-cli -o database_force_drop=true \
                -o database_admin_url="mysql://root:rootpassword@db" \
                -o database_schema_path="/usr/local/src/opensips/scripts" \
                -x database create
   ```

3. **Configure CLI access**:
   ```bash
   cp /usr/local/etc/opensips/opensips-cli.cfg /root/.opensips-cli.cfg
   # or create a symbolic link
   ln -sf /usr/local/etc/opensips/opensips-cli.cfg /root/.opensips-cli.cfg
   ```

### Method 2: Manual SQL Import

If the opensips-cli method doesn't work, manually import the required tables:

```bash
# Access the OpenSIPS container
docker exec -it opensips bash

# Import required database schemas
mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/auth_db-create.sql
mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/usrloc-create.sql
mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/registrant-create.sql
mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/dispatcher-create.sql
mysql -h db -uroot -prootpassword opensips < /usr/share/opensips/mysql/dialog-create.sql
```

## Service Details

### MariaDB
- **Container**: `opensips-mariadb`
- **Port**: 3307 (mapped from 3306)
- **Database**: `opensips`
- **Credentials**:
  - Root: `root` / `rootpassword`
  - User: `opensips` / `opensipsrw`

### OpenSIPS
- **Container**: `opensips`
- **Ports**: 
  - 5062/UDP and 5062/TCP (SIP)
  - TLS port 5061 commented out
- **Memory**: 64MB shared, 32MB package
- **Dependencies**: MariaDB (with health check)

### RTPEngine
- **Container**: `rtpengine`
- **Ports**:
  - 22222/UDP (control)
  - 23000-23100/UDP (RTP media)
- **Public IP**: 172.27.191.2 (update this for your environment)

## Network Configuration

The setup uses a custom bridge network `opensips_net` for inter-container communication.

**Important**: Update the RTPEngine public IP in docker-compose.yml:
```yaml
environment:
  - RTPENGINE_PUBLIC_IP=YOUR_PUBLIC_IP_HERE
```

## Ports and Firewall

Ensure the following ports are accessible:
- **5062** (SIP signaling)
- **22222** (RTPEngine control)
- **23000-23100** (RTP media range)

## Management Commands

### Check service status
```bash
docker ps
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f opensips
docker-compose logs -f rtpengine
docker-compose logs -f db
```

### Access containers
```bash
# OpenSIPS
docker exec -it opensips bash

# Database
docker exec -it opensips-mariadb mysql -uroot -prootpassword

# RTPEngine
docker exec -it rtpengine bash
```

### OpenSIPS CLI operations
```bash
# Inside OpenSIPS container
opensips-cli -x mi ps              # Show processes
opensips-cli -x mi uptime          # Show uptime
opensips-cli -x mi get_statistics  # Show statistics
```

## Troubleshooting

### Common Issues

1. **Database connection failed**:
   - Verify MariaDB is healthy: `docker-compose ps`
   - Check database credentials in configuration files
   - Ensure database is properly initialized

2. **OpenSIPS won't start**:
   - Check configuration syntax: `opensips -C -f /usr/local/etc/opensips/opensips.cfg`
   - Review logs: `docker-compose logs opensips`

3. **RTPEngine issues**:
   - Verify public IP configuration
   - Check port range availability
   - Ensure proper network connectivity

### Database Reset

To completely reset the database:
```bash
docker-compose down -v  # This removes volumes
docker-compose up -d
# Then re-run database initialization
```

## Security Considerations

- Change default passwords in production
- Limit database access to necessary hosts
- Configure proper SIP authentication
- Use TLS for SIP signaling in production
- Implement proper firewall rules

## Customization

- Modify `opensips.cfg` for your specific routing needs
- Adjust RTPEngine port ranges in `.env` file based on expected concurrent calls
- Update database schema as needed for additional modules
- Configure monitoring and logging as required
- Customize environment variables in `.env` file for different deployment scenarios

## Environment Variables Reference

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `MYSQL_ROOT_PASSWORD` | MariaDB root password | `rootpassword` |
| `MYSQL_DATABASE` | OpenSIPS database name | `opensips` |
| `MYSQL_USER` | OpenSIPS database user | `opensips` |
| `MYSQL_PASSWORD` | OpenSIPS database password | `opensipsrw` |
| `DB_HOST` | Database hostname for OpenSIPS | `db` |
| `DB_USER` | Database user for OpenSIPS | `opensips` |
| `DB_PASS` | Database password for OpenSIPS | `opensipsrw` |
| `DB_NAME` | Database name for OpenSIPS | `opensips` |
| `RTPENGINE_LOG_LEVEL` | RTPEngine logging level | `7` |
| `RTPENGINE_PORT_MIN` | RTPEngine minimum port | `23000` |
| `RTPENGINE_PORT_MAX` | RTPEngine maximum port | `23100` |
| `RTPENGINE_PUBLIC_IP` | RTPEngine public IP address | `172.27.191.2` |

## Support

For issues related to:
- **OpenSIPS**: Check [OpenSIPS documentation](https://opensips.org/Documentation)
- **RTPEngine**: See [RTPEngine GitHub](https://github.com/sipwise/rtpengine)
- **Docker**: Refer to [Docker documentation](https://docs.docker.com/)

## License

This setup is provided as-is for educational and development purposes. Please ensure compliance with relevant software licenses.

## Developed and maintained by Vishal Talsaniya
