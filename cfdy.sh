#!/bin/bash

# 颜色定义
INFO='\033[0;32m[INFO]\033[0m'
SUCCESS='\033[1;32m[SUCCESS]\033[0m'
HINT='\033[1;33m[HINT]\033[0m'

echo "------------------------------------------------"
echo "   Cloudflare 优选域名系统 (老路由频道最终版)"
echo "------------------------------------------------"

# 1. 环境清理 (不删数据库)
sudo rm -f /usr/local/bin/cfd /usr/local/bin/cfdt /usr/local/bin/cfds /usr/local/bin/cfdc /usr/local/bin/cfdj /usr/local/bin/cfdy
hash -r

# 2. 依赖安装
if ! command -v jq &> /dev/null; then
    echo -e "${INFO} 正在安装必要依赖 jq..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    elif command -v opkg &> /dev/null; then
        opkg update && opkg install jq
    fi
fi

# 3. 初始化数据库 (增加逻辑：如果文件不存在或为空，才写入默认值)
sudo mkdir -p /etc/cfd
DB_FILE="/etc/cfd/domains.txt"

if [ ! -s "$DB_FILE" ]; then
    echo -e "${INFO} 正在初始化默认域名列表..."
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
else
    echo -e "${INFO} 检测到已有域名列表，保持不变。"
fi
sudo chmod 666 "$DB_FILE"

# 4. 写入子程序 (代码逻辑保持稳定)
# --- 生成程序 (cfd) ---
sudo tee /usr/local/bin/cfd <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
TEMPLATE="/etc/sing-box/url.txt"
RESULT="$HOME/proxy_list.txt"
if [ -f "$TEMPLATE" ]; then url=$(head -n 1 "$TEMPLATE"); else 
echo -e "\033[1;33m未找到模板文件\033[0m"
read -p "请粘贴 vmess:// 链接: " url; fi
body="${url#vmess://}"; json=$(echo "$body" | base64 -d 2>/dev/null)
[ -z "$json" ] && { echo "模板解析失败"; exit 1; }
> "$RESULT"
while read -r d; do [ -z "$d" ] && continue
new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a')
echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT"; done < "$DB"
echo "------------------------------------------------"; cat "$RESULT"
echo "------------------------------------------------"; echo "节点已存入: $RESULT"
EOF

# --- 添加程序 (cfdt) ---
sudo tee /usr/local/bin/cfdt <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
read -p "请输入要添加的域名: " d
if [ -n "$d" ]; then
    echo "$d" >> "$DB"
    sort -u "$DB" -o "$DB"
    echo -e "\033[0;32m已添加: $d\033[0m"
fi
EOF

# --- 删除程序 (cfds) ---
sudo tee /usr/local/bin/cfds <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
read -p "请输入要删除的域名: " d
if [ -n "$d" ]; then
    sed -i "/^$d$/d" "$DB"
    echo -e "\033[0;31m已删除: $d\033[0m"
fi
EOF

# --- 查看库 (cfdc) ---
sudo tee /usr/local/bin/cfdc <<-'EOF' > /dev/null
#!/bin/bash
echo -e "\n\033[1;33m--- 当前域名库 ---\033[0m"; cat -n /etc/cfd/domains.txt
EOF

# --- 查看结果 (cfdj) ---
sudo tee /usr/local/bin/cfdj <<-'EOF' > /dev/null
#!/bin/bash
R="$HOME/proxy_list.txt"
if [ -f "$R" ]; then cat "$R"; else echo "尚未生成过节点"; fi
EOF

# --- 菜单程序 (cfdy) ---
sudo tee /usr/local/bin/cfdy <<-'EOF' > /dev/null
#!/bin/bash
while true; do
    echo -e "\n\033[1;36m===== Cloudflare 优选工具菜单 =====\033[0m"
    echo -e "\033[1;32m 1.\033[0m 生成并显示节点 (cfd)"
    echo -e "\033[1;32m 2.\033[0m 查看已生成的节点 (cfdj)"
    echo -e "\033[1;32m 3.\033[0m 添加优选域名 (cfdt)"
    echo -e "\033[1;32m 4.\033[0m 删除优选域名 (cfds)"
    echo -e "\033[1;32m 5.\033[0m 查看域名列表 (cfdc)"
    echo -e "\033[1;31m 0.\033[0m 退出脚本"
    echo "===================================="
    read -p "请输入序号: " choice
    case $choice in
        1) cfd ;;
        2) cfdj ;;
        3) cfdt ;;
        4) cfds ;;
        5) cfdc ;;
        0) exit 0 ;;
        *) echo "无效输入" ;;
    esac
done
EOF

# 5. 授权并启动
sudo chmod +x /usr/local/bin/cfd /usr/local/bin/cfdt /usr/local/bin/cfds /usr/local/bin/cfdc /usr/local/bin/cfdj /usr/local/bin/cfdy
echo -e "${SUCCESS} 安装成功！"
cfdy