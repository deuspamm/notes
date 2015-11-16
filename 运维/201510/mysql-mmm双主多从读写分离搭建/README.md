#mysql-mmm双主多从读写分离搭建


## 期望目标
  搭建一个mysql双主多从的平台，需要实现双主单点故障自动切换，读写分离，浮动ip

## 整体规划

母机1台：l5630x2 8g PC3-10600x12

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

## 开始配置
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





##使用示例及测试

配置

![ls 效果图](https://github.com/lenxeon/notes/blob/master/后端/201511/jackson同一实体在不同的场景下指定输出不同的字段/配置.png)

配置前

![ls 效果图](https://github.com/lenxeon/notes/blob/master/后端/201511/jackson同一实体在不同的场景下指定输出不同的字段/测试结果-配置前.png)

配置后

![ls 效果图](https://github.com/lenxeon/notes/blob/master/后端/201511/jackson同一实体在不同的场景下指定输出不同的字段/测试结果-配置后.png)
