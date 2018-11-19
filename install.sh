#!/bin/bash

HADOOP_STREAMING_JAR=/opt/cloudera/parcels/CDH/jars/hadoop-streaming-2.6.0-cdh5.10.1.jar

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

function pipInstall ()
{
pip install ${dirpath}/$1
}

function copyFromLocal ()
{
if hadoop fs -copyFromLocal -f $1
then
echo 'Succeeded to copy '$1' onto Hadoop as '$(whoami)
else
echo 'Failed to copy '$1' onto Hadoop as '$(whoami)
fi
}

dirpath=$(cd `dirname $0`; pwd)
#dirpath="/usr/local/HiCONDiagnosis/install"

echo 'Start to install Oracle client:'

rpmInstall libaio-0.3.109-13.el7.x86_64.rpm
rpmInstall oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
rpmInstall oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm

echo -e 'Oracle client installed.\n'

echo 'Start to pip install virtualenv:'

pipInstall virtualenv-15.1.0-py2.py3-none-any.whl

echo -e 'virtualenv installed.\n'

echo 'Start to update /etc/profile:'

updateFile 'ORACLE_HOME' '/usr/lib/oracle/12.2/client64' /etc/profile
updateFile 'LD_LIBRARY_PATH' '$ORACLE_HOME/lib:/usr/lib:/usr/local/lib' /etc/profile
updateFile 'NLS_LANG' '"SIMPLIFIED CHINESE_CHINA.ZHS16GBK"' /etc/profile
updateFile 'JAVA_HOME' '/home/jdk1.8.0_112' /etc/profile
updateFile 'PATH' '$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/lib:$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$HOME/bin' /etc/profile
insertFile 'export PATH LD_LIBRARY_PATH NLS_LANG' /etc/profile
source /etc/profile

echo -e '/etc/profile updated.\n'

echo -e 'Start to update /etc/ld.so.conf.d'
mkdir -p /etc/ld.so.conf.d
insertFile '/usr/lib/oracle/12.2/client64/lib/' /etc/ld.so.conf.d/oracle.conf
insertFile '/usr/local/HiCONDiagnosis' /etc/ld.so.conf.d/HiCONDiagnosis.conf
insertFile '/usr/local/HICONStrategyAuto' /etc/ld.so.conf.d/HICONStrategyAuto.conf
insertFile 'Flask' /etc/ld.so.conf.d/Flask.conf
ldconfig

echo -e 'Start to add user '$(whoami)' to hadoop'
adduser -g hadoop $(whoami)
hadoop fs -mkdir -p /user/$(whoami)
hadoop fs -chown $(whoami) /user/$(whoami)

#cd to parent directory (/usr/local/HiCONDiagnosis by default) to execute following steps
cd $dirpath/../

echo 'Start to copy emptyInput onto Hadoop:'
touch emptyInput
copyFromLocal emptyInput
if su hdfs -c "hadoop fs -copyFromLocal -f emptyInput"
then echo 'Succeeded to copy emptyInput onto Hadoop as hdfs'
else echo 'Failed to copy emptyInput onto Hadoop as hdfs'
fi

echo 'Start to copy hiconenv.tgz onto Hadoop:'
copyFromLocal hiconenv.tgz
if su hdfs -c "hadoop fs -copyFromLocal -f hiconenv.tgz"
then echo 'Succeeded to copy hiconenv.tgz onto Hadoop as hdfs'
else echo 'Failed to copy hiconenv.tgz onto Hadoop as hdfs'
fi

echo -e '\nStart to chmod:'
chmod +x ../HiCONDiagnosis/*.py
chmod +x ../HiCONDiagnosis/mapper/*.py
chmod +x ../HiCONDiagnosis/reducer/*.py
chmod +x ../HiCONDiagnosis/*.sh
chmod -R +x ../HICONStrategyAuto/*
chmod -R +x ../Flask/*

echo -e '\nUntar hiconenv.tgz:'
tar zxf hiconenv.tgz

#if not existed, create soft link to system-provided hadoop-streaming jar for convenience
if ! ls hadoop-streaming.jar
then
echo -e '\nCreate soft link to streaming jar:'
chmod +x $HADOOP_STREAMING_JAR
ln -s $HADOOP_STREAMING_JAR hadoop-streaming.jar
fi

echo -e '\nInstallation finished.'




