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
date --set="${2019-11-12 23:32:16 以你此刻的时间为准}"
```

## 安装V2Ray
### 下载脚本
```sh
curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
```

### 执行安装命令
```sh
bash install-release.sh
```

### 启动v2ray服务
```sh
systemctl enable v2ray && systemctl start v2ray
```

### 配置 server 端的 v2ray config
```sh
vi /usr/local/etc/v2ray/config.json
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
    "port": 10001,
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
      "security": "auto",
      "wsSettings": {
        "path": "/${your_proxy_path 转发的路径}"
      }
    }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
```

### 重启服务器的 v2ray

```sh
systemctl restart v2ray
```

### 配置 client 端的 v2ray config
在你客户端运行的v2ray程序中，添加某个json文件，而后输入下面的内容：

```json
{
  "log": {
    "access": "${your_reserve_access_log_path 保存日志的文件夹}/access.log",
    "error": "${your_reserve_error_log_path 保存日志的文件夹}/error.log",
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
          "address": "${your_domain 你的域名}",
          "port": 443,
          "users": [
            {
              "id": "${UUID 你的UUID，即密码}",
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
        "path": "/${your_proxy_path 转发的路径}"
      }
    }
  }
}
```

## TLS
### 暂停nginx释放80端口
```sh
nginx -s stop
```

### 安装acme.sh
```sh
apt install socat && curl  https://get.acme.sh | sh
```

### 生成证书
```sh
~/.acme.sh/acme.sh --issue -d ${your_domain 你的域名} --days 180 --standalone -k ec-256
```

### 将证书和私钥安装到v2ray中
```sh
~/.acme.sh/acme.sh --installcert -d ${your_domain 你的域名} --fullchainpath /usr/local/etc/v2ray/v2ray.crt --keypath /usr/local/etc/v2ray/v2ray.key --ecc
```

### 证书生成后，启动nginx
```sh
nginx
```

### 大约6个月后，手动更新ECC证书
```sh
sudo ~/.acme.sh/acme.sh --renew -d ${your_domain 你的域名} --force --ecc
```

### 证书和私钥的位置
一般来讲，通过上述生成后的证书和私钥，都存放于 `~/.acme.sh/${your_domain}_ecc/` 的目录下：
  - key 的 位置 `~/.acme.sh/${your_domain}_ecc//${your_domain}.key`

  - cer 的 位置 `~/.acme.sh/${your_domain}_ecc//${your_domain}.cer`