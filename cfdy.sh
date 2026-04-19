#!/bin/bash

# --- 基础配置 ---
DB_DIR="/etc/cfd"
DB_FILE="/etc/cfd/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 自动安装依赖
if ! command -v jq &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y jq -y
fi

# 初始化目录
sudo mkdir -p "$DB_DIR"
sudo chmod 777 "$DB_DIR"

# 写入默认域名 (10个)
if [ ! -s "$DB_FILE" ]; then
    cat <<EOT | sudo tee "$DB_FILE" > /dev/null
cf.090227.xyz
cf.877771.xyz
freeyx.cloudflare88.eu.org
bestcf.top
cdn.2020111.xyz
115155.xyz
cnamefuckxxs.yuchen.icu
cf.877774.xyz
saas.sin.fan
www.shopify.com
EOT
    sudo chmod 666 "$DB_FILE"
fi

# --- 核心菜单函数 ---
run_menu() {
    while true; do
        echo -e "\n\033[1;36m===== CF 优选管理 (老路由终极版) =====\033[0m"
        echo -e " 1. 一键生成节点"
        echo -e " 5. 查看域名列表"
        echo -e " 0. 退出"
        echo "-------------------------------------"
        read -p "请输入数字: " input
        choice=$(echo "$input" | tr -d '[:space:]' | cut -c1)

        if [ "$choice" == "1" ]; then
            if [ -f "$TEMPLATE_FILE" ]; then 
                url=$(head -n 1 "$TEMPLATE_FILE")
            else 
                echo -e "\n未检测到模板，请粘贴 vmess:// 链接："
                read -p "> " url
            fi
            
            body=$(echo "${url#vmess://}" | tr -d '[:space:]')
            len=${#body}; mod=$((len % 4))
            if [ $mod -eq 2 ]; then body="${body}=="; elif [ $mod -eq 3 ]; then body="${body}="; fi
            
            json=$(echo "$body" | base64 -d 2>/dev/null)
            if [[ ! "$json" == *"{"* ]]; then 
                echo -e "\033[0;31m解析失败，请检查链接！\033[0m"
                rm -f "$TEMPLATE_FILE"
            else
                echo "$url" > "$TEMPLATE_FILE"
                > "$RESULT_FILE"
                echo "正在生成..."
                while read -r d; do
                    [ -z "$d" ] && continue
                    new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
                    [ $? -eq 0 ] && echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT_FILE"
                done < "$DB_FILE"
                echo -e "\033[1;32m生成成功！\033[0m"
                cat "$RESULT_FILE"
            fi
        elif [ "$choice" == "5" ]; then
            cat -n "$DB_FILE"
        elif [ "$choice" == "0" ]; then
            exit 0
        fi
    done
}

# 安装到系统
sudo cp ~/final_cfdy.sh /usr/local/bin/cfdy 2>/dev/null
sudo chmod +x /usr/local/bin/cfdy 2>/dev/null

run_menu
