#!/bin/bash

# 颜色定义
INFO='\033[0;32m[INFO]\033[0m'
SUCCESS='\033[1;32m[SUCCESS]\033[0m'
HINT='\033[1;33m[HINT]\033[0m'

echo "------------------------------------------------"
echo "   Cloudflare 优选域名系统 (老路由频道专供)"
echo "------------------------------------------------"

# 1. 环境清理
sudo rm -f /usr/local/bin/cfd /usr/local/bin/cfdt /usr/local/bin/cfds /usr/local/bin/cfdc /usr/local/bin/cfdj /usr/local/bin/cfdy
hash -r

# 2. 依赖安装 (jq 是必须的)
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

# 3. 初始化数据库 (强制写入默认域名)
sudo mkdir -p /etc/cfd
sudo bash -c 'cat > /etc/cfd/domains.txt <<EOF
freeyx.cloudflare88.eu.org
cf.877771.xyz
bestcf.top
cdn.2020111.xyz
115155.xyz
cnamefuckxxs.yuchen.icu
cf.877774.xyz
saas.sin.fan
www.shopify.com
EOF'
sudo chmod 666 /etc/cfd/domains.txt

# 4. 写入子程序
# --- 生成程序 (cfd) ---
sudo tee /usr/local/bin/cfd <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
TEMPLATE="/etc/sing-box/url.txt"
RESULT="$HOME/proxy_list.txt"
if [ -f "$TEMPLATE" ]; then url=$(head -n 1 "$TEMPLATE"); else 
echo -e "\033[1;33m未找到 /etc/sing-box/url.txt 模板文件\033[0m"
read -p "请粘贴 vmess:// 链接作为原始模板: " url; fi
body="${url#vmess://}"; json=$(echo "$body" | base64 -d 2>/dev/null)
[ -z "$json" ] && { echo "模板解析失败，请检查链接是否正确"; exit 1; }
> "$RESULT"
while read -r d; do [ -z "$d" ] && continue
new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a')
echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT"; done < "$DB"
echo "------------------------------------------------"; cat "$RESULT"
echo "------------------------------------------------"; echo "节点已存入家目录的: proxy_list.txt"
EOF

# --- 添加程序 (cfdt) ---
sudo tee /usr/local/bin/cfdt <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
read -p "请输入要【添加】的优选域名: " d
if [ -n "$d" ]; then
    echo "$d" >> "$DB"
    sort -u "$DB" -o "$DB"
    echo -e "\033[0;32m已成功添加: $d\033[0m"
else
    echo "未输入域名，操作取消"
fi
EOF

# --- 删除程序 (cfds) ---
sudo tee /usr/local/bin/cfds <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
read -p "请输入要【删除】的优选域名: " d
if [ -n "$d" ]; then
    sed -i "/^$d$/d" "$DB"
    echo -e "\033[0;31m已成功删除: $d\033[0m"
else
    echo "未输入域名，操作取消"
fi
EOF

# --- 查看域名库 (cfdc) ---
sudo tee /usr/local/bin/cfdc <<-'EOF' > /dev/null
#!/bin/bash
echo -e "\n\033[1;33m--- 当前域名库共有 $(wc -l < /etc/cfd/domains.txt) 个域名 ---\033[0m"
cat -n /etc/cfd/domains.txt
EOF

# --- 查看结果 (cfdj) ---
sudo tee /usr/local/bin/cfdj <<-'EOF' > /dev/null
#!/bin/bash
R="$HOME/proxy_list.txt"
if [ -f "$R" ]; then 
echo -e "\n\033[1;36m===== 上次生成的优选节点列表 =====\033[0m"
echo "------------------------------------------------"
cat "$R"
echo "------------------------------------------------"
else echo -e "\033[0;31m尚未生成过节点，请先执行选项 1\033[0m"; fi
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
    read -p "请输入序号 [0-5]: " choice
    case $choice in
        1) cfd ;;
        2) cfdj ;;
        3) cfdt ;;
        4) cfds ;;
        5) cfdc ;;
        0) echo "脚本已退出。以后可通过输入 cfdy 再次调出菜单。"; exit 0 ;;
        *) echo -e "\033[0;31m无效输入，请重新选择\033[0m" ;;
    esac
done
EOF

# 5. 统一授权
sudo chmod +x /usr/local/bin/cfd /usr/local/bin/cfdt /usr/local/bin/cfds /usr/local/bin/cfdc /usr/local/bin/cfdj /usr/local/bin/cfdy

# 6. 安装完成直接弹出菜单
echo -e "${SUCCESS} 安装成功！"
cfdy