#!/bin/bash

function insertFile ()
{
if ! grep "\'^$1\'" $2
then
echo 'newly insert '$1' to '$2
echo $1 >> $2
fi
}

function updateFile ()
{
if ! grep "\'^$1\'" $3
then
echo 'newly set '$1'='$2 in file $3
echo $1'='$2 >> $3
fi
}

function rpmInstall ()
{
rpm -ivh ${dirpath}/$1
}

dirpath=$(cd `dirname $0`; pwd)
#dirpath="/usr/local/HiCONDiagnosis/install"

echo 'Start to install Oracle client:'

rpmInstall libaio-0.3.109-13.el7.x86_64.rpm
rpmInstall oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
rpmInstall oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm

echo -e 'Oracle client installed.\n'

echo 'Start to update /etc/profile:'

updateFile 'ORACLE_HOME' '/usr/lib/oracle/12.2/client64' /etc/profile
updateFile 'LD_LIBRARY_PATH' '$ORACLE_HOME/lib:/usr/lib:/usr/local/lib' /etc/profile
updateFile 'NLS_LANG' '"SIMPLIFIED CHINESE_CHINA.ZHS16GBK"' /etc/profile
updateFile 'PATH' '$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/lib:$HOME/bin' /etc/profile
insertFile 'export PATH LD_LIBRARY_PATH NLS_LANG' /etc/profile
source /etc/profile

echo -e '/etc/profile updated.\n'

echo -e '\nInstallation finished.'




