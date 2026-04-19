#!/bin/bash

# ==========================================
# 脚本名称: Cloudflare 优选节点管理工具 (GitHub 分享版)
# 开发者: 老路由的网络笔记
# 特点：一键安装、自动运行、内置优选域名
# ==========================================

# --- 1. 环境初始化 ---
DB_DIR="/etc/cfd"
DB_FILE="$DB_DIR/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 自动安装依赖 jq
if ! command -v jq &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y jq &> /dev/null
fi

# 创建并配置目录权限
sudo mkdir -p "$DB_DIR"
sudo chmod 777 "$DB_DIR"

# --- 2. 写入 10 个精选优选域名 ---
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

# 将脚本自身安装到系统路径，方便用户后续输入 cfdy 调用
if [ "$0" != "/usr/local/bin/cfdy" ]; then
    sudo cp "$0" /usr/local/bin/cfdy
    sudo chmod +x /usr/local/bin/cfdy
fi

# --- 3. 核心功能函数 ---

generate_nodes() {
    if [ -f "$TEMPLATE_FILE" ]; then
        url=$(head -n 1 "$TEMPLATE_FILE")
    else
        echo -e "\n\033[1;33m[提示] 请粘贴你的 vmess:// 链接 (首次使用需提供)：\033[0m"
        read -p "> " url
    fi

    # 清洗数据与 Base64 补齐
    raw_body=$(echo "${url#vmess://}" | tr -d '[:space:]')
    len=${#raw_body}
    mod=$((len % 4))
    if [ $mod -eq 2 ]; then raw_body="${raw_body}=="; elif [ $mod -eq 3 ]; then raw_body="${raw_body}="; fi
    
    json=$(echo "$raw_body" | base64 -d 2>/dev/null)
    if [[ ! "$json" == *"{"* ]]; then
        echo -e "\033[0;31m[错误] 链接解析失败！\033[0m"
        [ -f "$TEMPLATE_FILE" ] && sudo rm "$TEMPLATE_FILE"
        return
    fi

    # 自动保存模板
    [ ! -f "$TEMPLATE_FILE" ] && echo "$url" | sudo tee "$TEMPLATE_FILE" > /dev/null

    # 批量生成
    > "$RESULT_FILE"
    echo -e "\n\033[1;32m[OK] 正在基于内置域名生成优选节点...\033[0m"
    while read -r d; do
        [ -z "$d" ] && continue
        new_json=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
        [ $? -eq 0 ] && echo "vmess://$(echo -n "$new_json" | base64 -w 0)" >> "$RESULT_FILE"
    done < "$DB_FILE"
    
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    cat "$RESULT_FILE"
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    echo "节点已导出至: $RESULT_FILE"
}

# --- 4. 菜单主循环 ---
main_menu() {
    while true; do
        echo -e "\n\033[1;36m===== Cloudflare 优选工具 (老路由版) =====\033[0m"
        echo -e " 1. 一键生成优选节点"
        echo -e " 2. 查看历史生成记录"
        echo -e " 3. 添加自定义域名"
        echo -e " 4. 删除某个域名"
        echo -e " 5. 查看当前域名库"
        echo -e " 0. 退出脚本"
        echo "=========================================="
        read -p "请输入序号: " input
        choice=$(echo "$input" | cut -c1)

        case "$choice" in
            1) generate_nodes ;;
            2) [ -s "$RESULT_FILE" ] && cat "$RESULT_FILE" || echo "暂无记录" ;;
            3) read -p "输入新域名: " d; [ -n "$d" ] && echo "$d" >> "$DB_FILE" && echo "已添加" ;;
            4) read -p "输入删除名: " d; sed -i "/^$d$/d" "$DB_FILE" && echo "已删除" ;;
            5) cat -n "$DB_FILE" ;;
            0) echo "退出成功，后续输入 cfdy 可再次启动。"; exit 0 ;;
            *) echo "无效输入" ;;
        esac
    done
}

# --- 5. 自动启动入口 ---
# 无论用户是第一次安装运行，还是以后输入 cfdy 运行，都会直接弹出菜单
main_menu
