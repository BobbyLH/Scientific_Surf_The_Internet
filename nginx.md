# nginx
**Note**：该服务的所有指令都以 `ubuntu 18.04` 环境为准，其他linux版本的包安装指令可以自行搜索(比如CentOs 用的是 `yum install` …)。

**Note**：所有以 `${}` 包裹起来的内容，都需要你自行替换成你自己的相应配置。

## 安装nginx
在你的命令行中输入：
```sh
apt-get install nginx
```

而后再输入：
```sh
which nginx
```

如果返回了nginx命令相应的位置信息，那就证明安装成功了。

## 配置nginx conf 文件

在你的命令行中输入：
```sh
vi /etc/nginx/nginx.conf
```

而后在 `http` 字段的后面插入：
```conf
server {
	listen  443 ssl;
	ssl on;
	ssl_certificate       /etc/v2ray/v2ray.crt;
	ssl_certificate_key   /etc/v2ray/v2ray.key;
	ssl_protocols         TLSv1 TLSv1.1 TLSv1.2;
	ssl_ciphers           HIGH:!aNULL:!MD5;
	server_name           ${your domain};
	location /${your_proxy_path} {
		proxy_redirect off;
		proxy_pass http://127.0.0.1:10000;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_set_header Host $http_host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}
}
```

最后启动你的nginx
```sh
nginx -c /etc/nginx/nginx.conf
```

### 常用nginx命令
  - 重启nginx
    ```sh
    nginx -s reload
    ```

  - 暂停nginx
    ```sh
    nginx -s stop
    ```

**Tips**：不会用 `vi` 文本编译器？已经有很多人写了相关的博客文章了，比如[简书](https://www.jianshu.com/p/bcbe916f97e1)上的，或者更详细介绍了一些常用的Linux指令的[微信公众号](https://mp.weixin.qq.com/s/f2vy2pIpp_PZH-D0g9fDkA)的文章。