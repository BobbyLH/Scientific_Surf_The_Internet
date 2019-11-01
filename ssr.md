# SSR
**Note**：该服务的所有指令都以 `ubuntu 18.04` 环境为准，其他linux的安装指令可以自行搜索。

**Note**：所有以 `${}` 包裹起来的内容，都需要你自行替换成你自己的相应配置。

## 安装
第一步，你得先安装一个 `git` 工具：
```sh
apt-get install git
```

接下去，将ssr的git项目clone到本地：
```sh
git clone git@github.com:shadowsocksrr/shadowsocksr.git
```

然后进入这个项目并运行一个shell脚本：
```sh
cd shadowsockssr && bash initcfg.sh
```

而后，你还得安装python3：
```sh
apt-get install python3
```
最后，用python3将ssr服务跑起来：
```sh
python3 server.py
```

## 配置你的SSR
在你的shadowsocksrr文件目录里面，编辑你的user-config.json文件：
```sh
vi user-config.json
```

输入下面的内容：
```json
{
  "server": "0.0.0.0",
  "server_ipv6": "::",
  "server_port": 443,
  "local_address": "127.0.0.1",
  "local_port": 1080,

  "password": "${your password}",
  "method": "aes-256-cfb",
  "protocol": "origin",
  "protocol_param": "",
  "obfs": "tls1.2_ticket_auth",
  "obfs_param": "",
  "speed_limit_per_con": 0,
  "speed_limit_per_user": 0,

  "additional_ports" : {},
  "additional_ports_only" : false,
  "timeout": 120,
  "udp_timeout": 60,
  "dns_ipv6": false,
  "connect_verbose_info": 0,
  "redirect": ["*:443#127.0.0.1:${your port}"],
  "fast_open": false
}
```

## 配置你的shadowsocksr.service文件
创建一个 *shadowsocksr.service* 文件：
```sh
touch ~/.config/systemd/shadowsocksr.service
```

然后编辑它：
```sh
vi ~/.config/systemd/shadowsocksr.service
```

shadowsocksr.service 文件配置如下：
```service
[Unit]
Description=Shadowsocks R Server Service
After=default.target

[Service]
WorkingDirectory=/root/shadowsocksr/shadowsocks
ExecStart=/usr/bin/python3 server.py -c ../user-config.json
Restart=on-abnormal

[Install]
WantedBy=default.target
```

而后运行：
```sh
systemctl daemon-reload
```

检查你的ssr服务运行状态：
```sh
systemctl status shadowsocksr
```