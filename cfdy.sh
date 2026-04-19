#!/bin/bash

# --- 环境初始化 ---
DB_DIR="/etc/cfd"
DB_FILE="/etc/cfd/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 安装依赖
if ! command -v jq &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y jq -y
fi

# 创建目录
sudo mkdir -p "$DB_DIR" && sudo chmod 777 "$DB_DIR"

# 默认优选域名
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

# --- 菜单循环 ---
while true; do
    echo -e "\n\033[1;36m===== Cloudflare 优选管理 (老路由版) =====\033[0m"
    echo -e " 1. 一键生成优选节点"
    echo -e " 5. 查看当前域名库"
    echo -e " 0. 退出脚本"
    echo "----------------------------------------"
    read -p "请输入序号: " input
    choice=$(echo "$input" | tr -d '[:space:]' | cut -c1)

    case "$choice" in
        1)
            if [ -f "$TEMPLATE_FILE" ]; then
                url=$(head -n 1 "$TEMPLATE_FILE")
            else
                echo -e "\n请粘贴 vmess:// 链接："
                read -p "> " url
            fi
            
            # 清洗
            raw_body=$(echo "${url#vmess://}" | tr -d '[:space:]' | tr -d '\r')
            len=${#raw_body}; mod=$((len % 4))
            if [ $mod -eq 2 ]; then raw_body="${raw_body}=="; elif [ $mod -eq 3 ]; then raw_body="${raw_body}="; fi
            
            json=$(echo "$raw_body" | base64 -d 2>/dev/null)
            if [[ ! "$json" == *"{"* ]]; then
                echo -e "\033[0;31m解析失败，请检查链接！\033[0m"
                [ -f "$TEMPLATE_FILE" ] && rm -f "$TEMPLATE_FILE"
            else
                echo "$url" > "$TEMPLATE_FILE"
                > "$RESULT_FILE"
                while read -r d; do
                    [ -z "$d" ] && continue
                    d=$(echo "$d" | tr -d '\r') # 二次清洗域名里的回车
                    new_json=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
                    [ $? -eq 0 ] && echo "vmess://$(echo -n "$new_json" | base64 -w 0)" >> "$RESULT_FILE"
                done < "$DB_FILE"
                echo -e "\033[1;32m生成成功！结果已保存至: $RESULT_FILE\033[0m"
                cat "$RESULT_FILE"
            fi ;;
        5) cat -n "$DB_FILE" ;;
        0) echo "脚本已退出。"; exit 0 ;;
        *) [ -n "$choice" ] && echo "无效输入。" ;;
    esac
done
