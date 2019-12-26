# v2ray 服务
**Note**：该服务的所有指令都以 `ubuntu 18.04` 环境为准，其他linux版本的包安装指令可以自行搜索(比如CentOs 用的是 `yum install` …)。

**Note**：所有以 `${}` 包裹起来的内容，都需要你自行替换成你自己的相应配置。

## 服务器时间校准
使用 *V2Ray* 一定要保证服务器和客户端的时间误差在90秒以内，第一步先查看服务器上的时间(注意时区)：
```sh
date -R
```

如果服务器时间不准，可以：
```sh
date --set="${2019-11-12 23:32:16}"
```

## 安装V2Ray
### 下载脚本
```sh
wget https://install.direct/go.sh
```

### 执行安装命令
```sh
bash go.sh
```

### 启动v2ray服务
```sh
systemctl start v2ray
```

### 配置 server 端的 v2ray config
```sh
vi /etc/v2ray/config.json
```

输入下面的内容：
```json
{
  "log" : {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 10000,
    "listen":"127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "${UUID}",
          "level": 1,
          "alterId": 64
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "wsSettings": {
      "path": "/${your_proxy_path}"
      }
    }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
```

### 配置 client 端的 v2ray config
在你客户端运行的v2ray程序中，添加某个json文件，而后输入下面的内容：

```json
{
  "log": {
    "access": "${your_reserve_access_log_path}/access.log",
    "error": "${your_reserve_error_log_path}/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 1180,
    "listen": "127.0.0.1",
    "protocol": "socks",
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"]
    },
    "settings": {
      "auth": "noauth",
      "udp": false
    }
  },
  "outbound": {
    "protocol": "vmess",
    "settings": {
      "vnext": [
        {
          "address": "${your_domain}",
          "port": 443,
          "users": [
            {
              "id": "${UUID}",
              "alterId": 64
            }
          ]
        }
      ]
    },
    "streamSettings": {
      "network": "ws",
      "security": "tls",
      "wsSettings": {
        "path": "/${your_proxy_path}"
      }
    }
  }
}
```

## TLS
### 安装acme.sh
```sh
curl  https://get.acme.sh | sh
```

### 手动更新ECC证书
```sh
sudo ~/.acme.sh/acme.sh --renew -d ${yourdomain} --force --ecc
```