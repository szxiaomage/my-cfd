一个强大且易于使用的 Bash 脚本，用于批量生成基于 Cloudflare IP 的vmess节点链接。脚本会自动替换服务器地址，并可智能生成优选节点。
功能特性
一键完成安装：只需一条命令即可安装，自动将脚本配置为系统命令cfdy。
自动从/etc/sing-box/url.txt读取节点作为模板。
如果模板文件为空或无效，会提示用户手动粘贴一个链接模板。
生成模式：
内置Cloudflare 优选域名10个，可自己增加或者删除优选域名。
安装成功后，您可以随时在终端的任何位置输入以下命令来启动脚本：cfdy



此脚本参考byJoey大神生成，感谢大神的辛苦付出。

此脚本原创作者:byJoey GitHub：https://github.com/byJoey/cfy




一键安装与运行
请复制并执行以下命令。它会自动下载脚本，并触发脚本的自安装程序。首次运行完成即安装。

```bash
bash <(curl -l -s https://raw.githubusercontent.com/szxiaomage/my-cfd/main/cfdy.sh)
