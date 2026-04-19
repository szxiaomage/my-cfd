#!/bin/bash

# --- 基础配置 ---
DB_DIR="/etc/cfd"
DB_FILE="/etc/cfd/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 安装依赖
if ! command -v jq &> /dev/null; then
    apt-get update && apt-get install -y jq || yum install -y jq
fi

# 初始化目录
mkdir -p "$DB_DIR"
chmod 777 "$DB_DIR"

# 写入默认域名
if [ ! -s "$DB_FILE" ]; then
    cat > "$DB_FILE" <<EOF
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
fi

# --- 核心菜单函数 ---
run_menu() {
    while true; do
        echo -e "\n\033[1;36m===== CF 优选管理 (老路由版) =====\033[0m"
        echo -e " 1. 一键生成节点"
        echo -e " 5. 查看域名列表"
        echo -e " 0. 退出"
        read -p "请输入数字: " input
        # 强行清洗输入
        choice=$(echo "$input" | tr -d '\r' | cut -c1)

        if [ "$choice" == "1" ]; then
            if [ -f "$TEMPLATE_FILE" ]; then url=$(head -n 1 "$TEMPLATE_FILE"); else read -p "输入 vmess://: " url; fi
            body=$(echo "${url#vmess://}" | tr -d '[:space:]' | tr -d '\r')
            # 补齐等号
            len=${#body}; mod=$((len % 4))
            if [ $mod -eq 2 ]; then body="${body}=="; elif [ $mod -eq 3 ]; then body="${body}="; fi
            json=$(echo "$body" | base64 -d 2>/dev/null)
            if [[ ! "$json" == *"{"* ]]; then echo "链接解析失败"; rm -f "$TEMPLATE_FILE"; else
                echo "$url" > "$TEMPLATE_FILE"
                > "$RESULT_FILE"
                while read -r d; do [ -z "$d" ] && continue
                    d=$(echo "$d" | tr -d '\r')
                    new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
                    [ $? -eq 0 ] && echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT_FILE"
                done < "$DB_FILE"
                cat "$RESULT_FILE"
            fi
        elif [ "$choice" == "5" ]; then
            cat -n "$DB_FILE"
        elif [ "$choice" == "0" ]; then
            exit 0
        fi
    done
}

# --- 安装并启动 ---
# 这一步解决 cfdy 命令找不到的问题
cat > /usr/local/bin/cfdy <<EOF
#!/bin/bash
bash <(curl -Ls https://raw.githubusercontent.com/szxiaomage/my-cfd/main/cfdy.sh)
EOF
chmod +x /usr/local/bin/cfdy

# 运行菜单
run_menu
