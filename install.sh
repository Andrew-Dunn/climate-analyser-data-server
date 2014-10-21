#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

EC2RC=$(eval echo "~${SUDO_USER}/ec2rc.sh")
if [ ! -f $EC2RC ]; then
    echo "ec2rc.sh not found in user's home directory."
    exit 2
fi
source $EC2RC

RUNASUSER="sudo -u $SUDO_USER"

yum -y install java-1.7.0-openjdk java-1.7.0-openjdk-devel

$RUNASUSER bash <<EOF
cp dependencies/apache-tomcat-7.0.56.tar.gz apache-tomcat-7.0.56.tar.gz
tar -xzf apache-tomcat-7.0.56.tar.gz
mv apache-tomcat-7.0.56 tomcat
rm apache-tomcat-7.0.56.tar.gz

cp dependencies/thredds.war tomcat/webapps/thredds.war
EOF

yum -y install git make gcc gcc-c++ pkgconfig libstdc++-devel curl curlpp curlpp-devel curl-devel libxml2 libxml2* libxml2-devel openssl-devel mailcap
yum -y remove fuse fuse* fuse-devel

$RUNASUSER bash <<EOF
cp dependencies/fuse-2.9.3.tar.gz fuse-2.9.3.tar.gz
tar -xzf fuse-2.9.3.tar.gz*
rm -f fuse-2.9.3.tar.gz*
mv fuse-2.9.3 fuse
EOF

cd fuse

$RUNASUSER bash <<EOF
./configure --prefix=/usr
make
EOF

make install
ldconfig
modprobe fuse
cd ..
rm -rf fuse

$RUNASUSER bash <<EOF
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
EOF

cd s3fs-fuse

$RUNASUSER bash <<EOF
export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig/
./autogen.sh
./configure --prefix=/usr
make
EOF

make install
cd ..
rm -rf s3fs-fuse

mkdir -p $PWD/datafiles
chown $SUDO_UID:$SUDO_GID $PWD/datafiles

echo "user_allow_other" > /etc/fuse.conf

$RUNASUSER bash <<EOF
cat > scripts/mount_nectar.sh <<EOI
#!/bin/bash
/usr/bin/s3fs data $PWD/datafiles -o url="$S3_URL" -o use_path_request_style -o allow_other -o uid=$SUDO_UID -o gid=$SUDO_GID
EOI

cat > scripts/unmount_nectar.sh <<EOI
#!/bin/bash
fusermount -u $PWD/datafiles
EOI

chmod +x scripts/mount_nectar.sh
chmod +x scripts/unmount_nectar.sh

./scripts/mount_nectar.sh
echo "Data storage has been mounted to '$PWD/datafiles'"

echo "Sleeping for 5 seconds."
sleep 5s
./scripts/start_tomcat.sh
echo "Sleeping for 20 seconds."
sleep 20s

./scripts/configure_thredds.sh
sleep 2s
./scripts/stop_tomcat.sh
sleep 2s
./scripts/start_tomcat.sh
EOF
