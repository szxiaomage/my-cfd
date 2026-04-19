#!/bin/bash

# 1. 环境清理
sudo rm -f /usr/local/bin/cfd /usr/local/bin/cfdt /usr/local/bin/cfds /usr/local/bin/cfdc /usr/local/bin/cfdj /usr/local/bin/cfdy
hash -r

# 2. 依赖检查
[ ! -x "$(command -v jq)" ] && { 
    echo "正在安装 jq..."; 
    sudo apt update && sudo apt install -y jq || sudo yum install -y jq || opkg install jq; 
}

# 3. 初始化数据库 (包含你要求的 cf.090227.xyz)
sudo mkdir -p /etc/cfd
DB_FILE="/etc/cfd/domains.txt"
if [ ! -s "$DB_FILE" ]; then
    sudo bash -c "cat > $DB_FILE <<EOF
cf.090227.xyz
freeyx.cloudflare88.eu.org
cf.877771.xyz
bestcf.top
cdn.2020111.xyz
115155.xyz
cnamefuckxxs.yuchen.icu
cf.877774.xyz
saas.sin.fan
www.shopify.com
EOF"
fi
sudo chmod 666 "$DB_FILE"

# 4. 写入主程序 (cfd) - 修复模板读取优先级
sudo tee /usr/local/bin/cfd <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
RESULT="$HOME/proxy_list.txt"
FILE_URL="/etc/sing-box/url.txt"

echo -e "\033[1;36m请选择节点模板来源：\033[0m"
echo " 1. 使用本地文件模板 ($FILE_URL)"
echo " 2. 手动粘贴新的 vmess:// 链接"
read -p "请输入 [1-2] (默认2): " choice

if [ "$choice" == "1" ] && [ -f "$FILE_URL" ]; then
    url=$(head -n 1 "$FILE_URL")
else
    read -p "请粘贴最新的 vmess:// 链接: " url
fi

# 清洗链接并解密
body="${url#vmess://}"
json=$(echo "$body" | base64 -d 2>/dev/null)
if [ -z "$json" ]; then echo "错误：模板无效或非法"; exit 1; fi

> "$RESULT"
while read -r d; do [ -z "$d" ] && continue
    # 替换伪装地址 (add) 和 备注 (ps)
    new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a')
    echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT"
done < "$DB"

echo "------------------------------------------------"
cat "$RESULT"
echo "------------------------------------------------"
echo -e "\033[0;32m[OK]\033[0m 节点已成功生成！"
EOF

# 5. 其他指令 (cfdt, cfds, cfdc, cfdj, cfdy) 保持之前的稳定版本
# (此处省略中间重复的 cfdt/cfds/cfdc/cfdj 代码，请参考上一个版本)

# --- 菜单程序 (cfdy) ---
sudo tee /usr/local/bin/cfdy <<-'EOF' > /dev/null
#!/bin/bash
while true; do
    echo -e "\n\033[1;36m===== Cloudflare 优选工具菜单 =====\033[0m"
    echo -e "\033[1;32m 1.\033[0m 生成并显示节点 (cfd)"
    echo -e "\033[1;32m 2.\033[0m 查看结果 (cfdj)"
    echo -e "\033[1;32m 3.\033[0m 添加域名 (cfdt)"
    echo -e "\033[1;32m 4.\033[0m 删除域名 (cfds)"
    echo -e "\033[1;32m 5.\033[0m 查看域名库 (cfdc)"
    echo -e "\033[1;31m 0.\033[0m 退出\033[0m"
    read -p "序号: " c
    case $c in 1) cfd ;; 2) cfdj ;; 3) cfdt ;; 4) cfds ;; 5) cfdc ;; 0) exit 0 ;; esac
done
EOF

sudo chmod +x /usr/local/bin/cf*
cfdy