#!/bin/bash

# --- 1. 基础配置 ---
DB_DIR="/etc/cfd"
DB_FILE="/etc/cfd/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 安装依赖
if ! command -v jq &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y jq -y
fi

# 初始化目录
sudo mkdir -p "$DB_DIR"
sudo chmod 777 "$DB_DIR"

# 写入默认域名
if [ ! -s "$DB_FILE" ]; then
    cat <<EOF | sudo tee "$DB_FILE" > /dev/null
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
EOF
    sudo chmod 666 "$DB_FILE"
fi

# --- 2. 菜单主逻辑 ---
while true; do
    echo -e "\n\033[1;36m===== CF 优选管理 (老路由版) =====\033[0m"
    echo -e " 1. 一键生成节点"
    echo -e " 5. 查看域名列表"
    echo -e " 0. 退出"
    echo "-------------------------------------"
    read -p "请输入数字: " input
    choice=$(echo "$input" | tr -d '[:space:]' | cut -c1)

    if [ "$choice" == "1" ]; then
        if [ -f "$TEMPLATE_FILE" ]; then url=$(head -n 1 "$TEMPLATE_FILE"); else echo -e "\n请粘贴 vmess://："; read -p "> " url; fi
        body=$(echo "${url#vmess://}" | tr -d '[:space:]')
        len=${#body}; mod=$((len % 4))
        if [ $mod -eq 2 ]; then body="${body}=="; elif [ $mod -eq 3 ]; then body="${body}="; fi
        json=$(echo "$body" | base64 -d 2>/dev/null)
        if [[ ! "$json" == *"{"* ]]; then 
            echo "解析失败"; rm -f "$TEMPLATE_FILE"
        else
            echo "$url" > "$TEMPLATE_FILE"
            > "$RESULT_FILE"
            while read -r d; do [ -z "$d" ] && continue
                new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
                [ $? -eq 0 ] && echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT_FILE"
            done < "$DB_FILE"
            echo "生成成功！"
            cat "$RESULT_FILE"
        fi
    elif [ "$choice" == "5" ]; then
        cat -n "$DB_FILE"
    elif [ "$choice" == "0" ]; then
        exit 0
    fi
done
