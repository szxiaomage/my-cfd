#!/bin/bash

# ==========================================
# 脚本名称: Cloudflare 优选管理工具 (老路由版)
# 开发者: 老路由的网络笔记
# 功能：一键安装、批量生成、内置 10 个精选域名
# ==========================================

# --- 1. 环境初始化 ---
DB_DIR="/etc/cfd"
DB_FILE="/etc/cfd/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 自动安装依赖 jq
if ! command -v jq &> /dev/null; then
    echo "正在为您安装必要组件 jq..."
    sudo apt-get update && sudo apt-get install -y jq -y &> /dev/null
fi

# 创建并配置目录
sudo mkdir -p "$DB_DIR"
sudo chmod 777 "$DB_DIR"

# --- 2. 写入内置 10 个优选域名 ---
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

# --- 3. 核心生成逻辑 ---
generate_nodes() {
    # 检查是否有保存过的模板
    if [ -f "$TEMPLATE_FILE" ]; then
        url=$(head -n 1 "$TEMPLATE_FILE")
    else
        echo -e "\n\033[1;33m[提示] 首次使用，请粘贴你的 vmess:// 链接：\033[0m"
        read -p "> " url
    fi

    # 强力去空格、去回车符
    raw_body=$(echo "${url#vmess://}" | tr -d '[:space:]' | tr -d '\r')
    
    # Base64 自动补全等号
    len=${#raw_body}
    mod=$((len % 4))
    if [ $mod -eq 2 ]; then raw_body="${raw_body}=="; elif [ $mod -eq 3 ]; then raw_body="${raw_body}="; fi
    
    # 解码并验证
    json=$(echo "$raw_body" | base64 -d 2>/dev/null)
    if [[ ! "$json" == *"{"* ]]; then
        echo -e "\033[0;31m[错误] 链接解析失败！请检查复制是否完整。\033[0m"
        [ -f "$TEMPLATE_FILE" ] && rm -f "$TEMPLATE_FILE"
        return
    fi

    # 自动保存正确模板
    [ ! -f "$TEMPLATE_FILE" ] && echo "$url" > "$TEMPLATE_FILE"

    # 开始批量处理
    > "$RESULT_FILE"
    echo -e "\n\033[1;32m正在根据 10 个内置域名生成优选节点...\033[0m"
    while read -r d; do
        [ -z "$d" ] && continue
        # 清洗域名行的回车符
        d_clean=$(echo "$d" | tr -d '\r' | tr -d '[:space:]')
        new_json=$(echo "$json" | jq -c --arg a "$d_clean" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "vmess://$(echo -n "$new_json" | base64 -w 0)" >> "$RESULT_FILE"
        fi
    done < "$DB_FILE"
    
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    cat "$RESULT_FILE"
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    echo -e "已为您生成 $(wc -l < "$RESULT_FILE") 个节点，结果保存在: $RESULT_FILE"
}

# --- 4. 菜单主循环 ---
while true; do
    echo -e "\n\033[1;36m===== Cloudflare 优选管理 (老路由版) =====\033[0m"
    echo -e " 1. 一键批量生成优选节点"
    echo -e " 2. 查看历史生成记录"
    echo -e " 3. 添加自定义域名"
    echo -e " 4. 删除某个域名"
    echo -e " 5. 查看当前优选域名列表"
    echo -e " 0. 退出脚本"
    echo "=========================================="
    read -p "请输入序号 [0-5]: " input
    # 只取第一个有效数字，过滤空格
    choice=$(echo "$input" | tr -d '[:space:]' | cut -c1)

    case "$choice" in
        1) generate_nodes ;;
        2) [ -s "$RESULT_FILE" ] && cat "$RESULT_FILE" || echo "暂无记录" ;;
        3) read -p "输入新域名: " d; [ -n "$d" ] && echo "$d" >> "$DB_FILE" && echo "已添加" ;;
        4) read -p "输入要删除的域名: " d; sed -i "/^$d$/d" "$DB_FILE" && echo "已尝试删除" ;;
        5) cat -n "$DB_FILE" ;;
        0) echo "已退出，后续输入 cfdy 可再次启动。"; exit 0 ;;
        *) [ -n "$choice" ] && echo "输入错误: $choice" ;;
    esac
done
