FROM debian:bookworm

RUN apt update
RUN apt upgrade -y
RUN apt install mariadb-server -y

COPY conf/50-server.cnf	/etc/mysql/mariadb.conf.d/50-server.cnf

# Copy helper scripts into the image and make executable. Do NOT run the
# database setup during image build (mysqld is not running during build).
COPY tools/ /tmp/tools/
RUN chmod +x /tmp/tools/setup.sh

# Run the setup script when the container starts. The script starts the
# server and then runs the SQL setup before exec'ing mysqld_safe so the
# container will keep running.
CMD ["/bin/bash", "/tmp/tools/setup.sh"]