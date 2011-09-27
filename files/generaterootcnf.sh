#!/bin/sh
#
# THIS FILE IS MAINTAINED BY PUPPET
#

PW=$(perl -e 'print map{("a".."z","A".."Z",0..9)[int(rand(62))]}(1..16)')
SOCK=$(sed -n 's/^[	 ]*socket[^=]*= *// p' /etc/mysql/my.cnf | head -n 1)
NEWFILE=/etc/mysql/root.cnf.new
MYSQL="mysql --defaults-file=/etc/mysql/debian.cnf"

# Create the new file
cat /dev/null > $NEWFILE
chmod 600 $NEWFILE

# Fill it up with config
cat >$NEWFILE <<EOF
#
# THIS FILE IS MAINTAINED BY PUPPET
#
[client]
host     = localhost
user     = root
password = $PW
socket   = $SOCK 
EOF

$MYSQL mysql <<EOF
UPDATE user SET password=PASSWORD("$PW") WHERE user='root';
FLUSH PRIVILEGES;
EOF

mv /etc/mysql/root.cnf /etc/mysql/root.cnf.old
mv $NEWFILE /etc/mysql/root.cnf
