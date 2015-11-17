#映射指定IP到本地


## 期望目标
  我们知道，如果想使用某个域名访问时指向本地，可以通过修改hosts文件来实现，但hosts是一个域名
对应一个ip，不可以两边都是域名。但有时我们希望把一个ip转向本地，比如debug的时候，如果能简单一点
就不用去项目中修改配置文件，因实你实在不敢保证每次提交的时候都能保证记得把配置文件改回去。或许你
还有一个方案，测试和正式的配置文件分开，保存2份。事实上我情愿修改环境，也不情愿去修改代码，
因为环境设置错了在本地，代码修改错了问题可能就比较大了。

## 尝试

111.13.101.208 是百度的ip,我们希望输入这个ip时转向到本地
```shell
⚙ lenxeon@localhost  /Volumes  ping baidu.com
PING baidu.com (111.13.101.208): 56 data bytes
64 bytes from 111.13.101.208: icmp_seq=0 ttl=44 time=7.984 ms
64 bytes from 111.13.101.208: icmp_seq=1 ttl=44 time=5.267 ms
64 bytes from 111.13.101.208: icmp_seq=2 ttl=44 time=5.305 ms
64 bytes from 111.13.101.208: icmp_seq=3 ttl=44 time=6.777 ms
^C
--- baidu.com ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 5.267/6.333/7.984/1.131 ms
```

先看看当前的网络配置
```shell
⚙ lenxeon@localhost  /Volumes  ifconfig
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
 options=3<RXCSUM,TXCSUM>
 inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
 inet 127.0.0.1 netmask 0xff000000
 inet6 ::1 prefixlen 128
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
 ether 7c:d1:c3:f3:d9:8f
 inet6 fe80::7ed1:c3ff:fef3:d98f%en0 prefixlen 64 scopeid 0x4
 inet 10.0.1.128 netmask 0xffff0000 broadcast 10.0.255.255
 media: autoselect
 status: active
p2p0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 2304
 ether 0e:d1:c3:f3:d9:8f
 media: autoselect
 status: inactive
 ```

添加转身映射，可以看到多了111.13.101.208这个配置
 ```shell
 ⚙ lenxeon@localhost  /Volumes  sudo ifconfig en0 alias 111.13.101.208
 ⚙ lenxeon@localhost  /Volumes 
 ⚙ lenxeon@localhost  /Volumes  ifconfig
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=3<RXCSUM,TXCSUM>
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
	inet 127.0.0.1 netmask 0xff000000
	inet6 ::1 prefixlen 128
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 7c:d1:c3:f3:d9:8f
	inet6 fe80::7ed1:c3ff:fef3:d98f%en0 prefixlen 64 scopeid 0x4
	inet 10.0.1.128 netmask 0xffff0000 broadcast 10.0.255.255
	inet 111.13.101.208 netmask 0xff000000 broadcast 111.255.255.255  #看到了么，关键在这里
	media: autoselect
	status: active
p2p0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 2304
	ether 0e:d1:c3:f3:d9:8f
	media: autoselect
	status: inactive
  ```

效果

![ls 百度ip到本地](https://github.com/lenxeon/notes/blob/master/运维/201510/映射指定IP到本地/百度ip到本地.png)

删除映射，命令前多一个-号即可
 ```shell
 ⚙ lenxeon@localhost  /Volumes  sudo ifconfig en0 -alias 111.13.101.208
 ⚙ lenxeon@localhost  /Volumes 
 ⚙ lenxeon@localhost  /Volumes  ifconfig
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=3<RXCSUM,TXCSUM>
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
	inet 127.0.0.1 netmask 0xff000000
	inet6 ::1 prefixlen 128
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 7c:d1:c3:f3:d9:8f
	inet6 fe80::7ed1:c3ff:fef3:d98f%en0 prefixlen 64 scopeid 0x4
	inet 10.0.1.128 netmask 0xffff0000 broadcast 10.0.255.255
	media: autoselect
	status: active
p2p0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 2304
	ether 0e:d1:c3:f3:d9:8f
	media: autoselect
	status: inactive
  ```
