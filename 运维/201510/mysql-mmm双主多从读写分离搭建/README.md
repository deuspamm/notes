#mysql-mmm双主多从读写分离搭建


## 期望目标
  搭建一个mysql双主多从的平台，需要实现双主单点故障自动切换，读写分离，浮动ip

## 整体规划

母机1台：l5630x2 PC3-10600 8gx12

虚拟机5台：centos6.7 mysql5.6 单机16G内存


| 角色 | ip | 主机名 | server_id |
|-------- |--------|--------|--------|
| master  | 192.168.1.11 | hadoop01 | 1 |
| master  | 192.168.1.12 | hadoop02 | 2 |
| slave   | 192.168.1.13 | hadoop03 | 3 |
| slave   | 192.168.1.14 | hadoop04 | 4 |
| monitor | 192.168.1.15 | hadoop05 | 5 |

配置后使用虚拟IP访问集群

| 虚拟ip | role |
|-------- |--------|
| 192.168.1.200 | writer |
| 192.168.1.201 | reader |
| 192.168.1.202 | reader |
| 192.168.1.203 | reader |

## 第一队段：安装并配置mysql

### 安装并配置mysql

5 台机器都安装mysql5.6 配置文件如下,核心的是注释下面开始的部分。另外每台机器的server_id要不一样，
参考规划里面的server_id进行配置

启动mysql之前最好先执行下面这两句，主要是解决目录权限问题

```shell
mkdir /var/log/mysql
sudo chown mysql:mysql /var/log/mysql -R
```

```configure
[client]
port            = 3306
socket          = /var/lib/mysql/mysqld.sock
default-character-set=utf8

[mysqld_safe]
socket          = /var/lib/mysql/mysqld.sock
nice            = 0

[mysqld]
character_set_server=utf8
init_connect='SET NAMES utf8'
user            = mysql
pid-file        = /var/lib/mysql/mysqld.pid
socket          = /var/lib/mysql/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking
lower_case_table_names=1
key_buffer              = 128M
max_allowed_packet      = 32M
thread_stack            = 192K
thread_cache_size       = 8
myisam-recover         = BACKUP
query_cache_limit       = 8M
query_cache_size        = 128M
#log_error = /var/log/mysql/error.log
#log = /var/log/mysql/info.log
expire_logs_days        = 10
max_binlog_size         = 100M

#下面为新添加的内容
default-storage-engine = innodb

replicate-ignore-db = mysql
binlog-ignore-db    = mysql

server-id           = 1
log-bin             = /var/log/mysql/mysql-bin.log
log_bin_index       = /var/log/mysql/mysql-bin.log.index
relay_log           = /var/log/mysql/mysql-bin.relay
relay_log_index     = /var/log/mysql/mysql-bin.relay.index
expire_logs_days    = 10
max_binlog_size     = 100M
log_slave_updates   = 1


[mysqldump]
quick
quote-names
max_allowed_packet      = 16M

[mysql]
default-character-set=utf8

[isamchk]
key_buffer              = 16M
```

### 安装好mysql后设置首次登陆密码，并授权，在所有机器的mysql中执行。

```mysql
SET PASSWORD =PASSWORD('admin');
GRANT ALL PRIVILEGES ON *.* TO root@'192.168.1.%' IDENTIFIED   BY   'admin'   WITH GRANT OPTION;   
FLUSH PRIVILEGES;

```

### 安装好mysql-mmm，在所有机器上执行。
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

yum -y install mysql-mmm*   perl-Time-HiRes*  

### 创建同步账户，备用，在所有机器的mysql中执行。

```mysql
GRANT REPLICATION CLIENT                 ON *.* TO 'mmm_monitor'@'%' IDENTIFIED BY 'monitor';
GRANT SUPER, REPLICATION CLIENT, PROCESS ON *.* TO 'mmm_agent'@'%'   IDENTIFIED BY 'agent';
GRANT REPLICATION SLAVE                  ON *.* TO 'replication'@'%' IDENTIFIED BY 'replication';
FLUSH PRIVILEGES;
```

## 第二阶段：设置主从同步。下面开始进入重点步骤了，先锁住hadoop01主机上的mysql，记录数据库状态，并导出mysql数据库，scp复制到hadoop02-05上

以下代码均在hadoop01上执行：

### 锁住数据库，并展示主数据库的信息

```mysql
FLUSH TABLES WITH READ LOCK;   
SHOW MASTER STATUS;
```
大概会看到类似下面的结果，核心的是日志文件名称和偏移位置：mysql-bin.000001，781

![ls 当前主数据库状态](https://github.com/lenxeon/notes/blob/master/运维/201510/mysql-mmm双主多从读写分离搭建/当前主数据库状态.png)

### 备份数据库
先不要结束这个shell,再开一个新shell ssh到hadoop01，准备备份mysql

> mysqldump -uroot -p --all-databases > db.sql

### 解除数据库的锁
> UNLOCK TABLES;

### scp刚才的备份到其它四台机器

> scp /etc/my.cnf hadoop02:/etc

> scp /etc/my.cnf hadoop03:/etc

> scp /etc/my.cnf hadoop04:/etc

> scp /etc/my.cnf hadoop05:/etc

### 在hadoop02-05上导入数据库，并开启slave进程
> mysql -uroot -p < db.sql

```mysql
flush privileges;  

CHANGE MASTER TO master_host='192.168.1.11', master_port=3306, master_user='replication',master_password='replication', master_log_file='mysql-bin.000001', master_log_pos=781;  

start slave;  
show slave status\G
```

![ls 从数据库状态](https://github.com/lenxeon/notes/blob/master/运维/201510/mysql-mmm双主多从读写分离搭建/从数据库状态.png)

### 经过上面这一段操作，hadoop02-05可以从hadoop01同步数据了，接下来设置双master,让hadoop01以hadoop02为主库
在hadoop02上

#### 锁住数据库，并展示主数据库的信息

```mysql
FLUSH TABLES WITH READ LOCK;   
SHOW MASTER STATUS;
```
核心的是日志文件名称和偏移位置：mysql-bin.000001，1180，和上面的相似就不给图了。

#### 不用备份数据库了，直接在hadoop01上执行
```mysql
flush privileges;  

CHANGE MASTER TO master_host='192.168.1.12', master_port=3306, master_user='replication',master_password='replication', master_log_file='mysql-bin.000001', master_log_pos=1180;  

start slave;
show slave status\G
```

## 第三阶段，开启mmm-agent和mmm-monitor服务

###在hadoop01上配置 /etc/mysql-mmm/mmm_common.cnf,并scp复制到hadoop02-05

```configure
active_master_role      writer

<host default>
    cluster_interface       eth0

    pid_path                /var/run/mysql-mmm/mmm_agentd.pid
    bin_path                /usr/libexec/mysql-mmm/

    replication_user        replication
    replication_password    replication

    agent_user              mmm_agent
    agent_password          agent
</host>

<host hadoop01>
    ip      192.168.1.11
    mode    master
    peer    hadoop02
</host>

<host hadoop02>
    ip      192.168.1.12
    mode    master
    peer    hadoop01
</host>

<host hadoop03>
    ip      192.168.1.13
    mode    slave
</host>

<host hadoop04>
    ip      192.168.1.14
    mode    slave
</host>

<role writer>
    hosts   hadoop01, hadoop02
    ips     192.168.1.200
    mode    exclusive
</role>

<role reader>
    hosts   hadoop02, hadoop03, hadoop04
    ips     192.168.1.201, 192.168.1.202, 192.168.1.203
    mode    balanced
</role>

```

###在hadoop01-05上配置 /etc/mysql-mmm/mmm_agent.cnf
把this db1修改为对应的hadoop0x
并启动 agent 服务

```shell
# cd /etc/init.d/
# chkconfig mysql-mmm-agent on
# service mysql-mmm-agent start
```

###在hadoop05上配置 /etc/mysql-mmm/mmm_mon.cnf

```configure
include mmm_common.conf

<monitor>
    ip                  192.168.84.174
    pid_path            /var/run/mysql-mmm/mmm_mond.pid
    bin_path            /usr/libexec/mysql-mmm
    status_path         /var/lib/mysql-mmm/mmm_mond.status
    ping_ips            192.168.1.11, 192.168.1.12, 192.168.1.13, 192.168.1.14
    auto_set_online     60

    # The kill_host_bin does not exist by default, though the monitor will
    # throw a warning about it missing.  See the section 5.10 "Kill Host
    # Functionality" in the PDF documentation.
    #
    # kill_host_bin     /usr/libexec/mysql-mmm/monitor/kill_host
    #
</monitor>

<host default>
    monitor_user        mmm_monitor
    monitor_password    monitor
</host>

debug 0 #是否开启日志 0不开启 1开启

```
并启动 monitor 服务

```shell
# cd /etc/init.d/
# chkconfig mysql-mmm-monitor on
# service mysql-mmm-monitor start
```

稍等一会儿可以用mmm_control show 查看状态

![ls 查看监控状态](https://github.com/lenxeon/notes/blob/master/运维/201510/mysql-mmm双主多从读写分离搭建/查看监控状态.png)

测试故障转移，关闭hadoop01上的mysql服务
![ls 查看监控状态-关闭hadoop01](https://github.com/lenxeon/notes/blob/master/运维/201510/mysql-mmm双主多从读写分离搭建/查看监控状态-关闭hadoop01.png)

测试故障转移，重启hadoop01上的mysql服务并关闭hadoop02上的mysql服务
![ls 查看监控状态-重启hadoop01并关闭hadoop02](https://github.com/lenxeon/notes/blob/master/运维/201510/mysql-mmm双主多从读写分离搭建/查看监控状态-重启hadoop01并关闭hadoop02.png)
