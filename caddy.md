# caddy 服务

**Note**：该服务的所有指令都以 `ubuntu 18.04` 环境为准，其他linux的包安装指令可以自行搜索(比如CentOs 用的是 `yum install` …)。

**Note**：所有以 `${}` 包裹起来的内容，都需要你自行替换成你自己的相应配置。

## 安装caddy
在你的命令行中输入：
```sh
curl https://getcaddy.com | sudo bash -s personal
```

而后再输入：
```sh
which caddy
```

如果返回了caddy命令相应的位置信息，那就证明安装成功了。

## 为 cadddy 建一个保存 _ssl证书_ 的文件夹
```sh
mkdir -p /etc/ssl/caddy

chown -R www-data:root /etc/ssl/caddy

chmod 0770 /etc/ssl/caddy
```

## 写出你自己的第一个 _Hello World_ 服务
```sh
mkdir -p /usr/local/caddy/www/ssr

cd /usr/local/caddy/www/ssr

touch index.html

chown www-data:www-data /usr/local/caddy/www/ssr

vi index.html
```

### 配置index.html
```html
<!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>My First Blog</title>
  </head>
  <body>
    <h1>My First Blog</h1>
    <p>
      Hello World
    </p>
  </body>
</html>
```

## 配置Caddyfile
首先，创建一个 `Caddyfile`：
```sh
mkdir -p /etc/caddy/ && touch Caddyfile
```

而后命令行输入：
```sh
vi /etc/caddy/Caddyfile
```

将下述配置插入你的 *Caddyfile*
```caddyfile
https://${your domain}:${your port} {
 root /usr/local/caddy/www/ssr
 timeouts none
 tls ${your email address}
 gzip
}
```

然后下一份别人写好的 *caddy.server* 到你的机器上，并重启daemon：
```sh
curl -s https://raw.githubusercontent.com/mholt/caddy/master/dist/init/linux-systemd/caddy.service -o /etc/systemd/system/caddy.service

systemctl daemon-reload
```

而后将caddy设置为开机自启动，并查看caddy服务的状态：
```sh
systemctl enable caddy

systemctl status caddy
```

**Tips**：不会用 `vi` 文本编译器？已经有很多人写了相关的博客文章了，比如[简书](https://www.jianshu.com/p/bcbe916f97e1)上的，或者更详细介绍了一些常用的Linux指令的[微信公众号](https://mp.weixin.qq.com/s/f2vy2pIpp_PZH-D0g9fDkA)的文章。