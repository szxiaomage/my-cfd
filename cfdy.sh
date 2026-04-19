#!/bin/bash

# ==========================================
# 脚本名称: Cloudflare 优选节点管理工具
# 适用环境: Ubuntu/Debian (VPS 专用)
# 开发者: 老路由的网络笔记 (老友版)
# ==========================================

# --- 1. 环境初始化 (小白一键配置) ---
DB_DIR="/etc/cfd"
DB_FILE="$DB_DIR/domains.txt"
TEMPLATE_FILE="/etc/sing-box/url.txt"
RESULT_FILE="$HOME/proxy_list.txt"

# 自动安装依赖
if ! command -v jq &> /dev/null; then
    echo "正在安装必要组件 jq..."
    sudo apt-get update && sudo apt-get install -y jq &> /dev/null
fi

# 创建配置目录
sudo mkdir -p "$DB_DIR"
sudo chmod 777 "$DB_DIR"

# --- 2. 写入默认优选域名 (老友精选 10 个) ---
# 如果文件不存在或为空，则写入默认列表
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

# --- 3. 核心功能函数 ---

# 生成节点逻辑 (带强力纠错)
generate_nodes() {
    if [ -f "$TEMPLATE_FILE" ]; then
        url=$(head -n 1 "$TEMPLATE_FILE")
    else
        echo -e "\n\033[1;33m[提示] 未检测到模板，请粘贴你的 vmess:// 链接：\033[0m"
        read -p "> " url
    fi

    # 清洗数据与补齐 Base64
    raw_body=$(echo "${url#vmess://}" | tr -d '[:space:]')
    len=${#raw_body}
    mod=$((len % 4))
    if [ $mod -eq 2 ]; then raw_body="${raw_body}=="; elif [ $mod -eq 3 ]; then raw_body="${raw_body}="; fi
    
    json=$(echo "$raw_body" | base64 -d 2>/dev/null)
    if [[ ! "$json" == *"{"* ]]; then
        echo -e "\033[0;31m[错误] 链接解析失败！请检查是否复制完整。\033[0m"
        [ -f "$TEMPLATE_FILE" ] && sudo rm "$TEMPLATE_FILE"
        return
    fi

    # 保存正确模板供下次使用
    [ ! -f "$TEMPLATE_FILE" ] && echo "$url" | sudo tee "$TEMPLATE_FILE" > /dev/null

    # 批量生成
    > "$RESULT_FILE"
    echo -e "\n\033[1;32m[OK] 正在为您生成 10 个优选节点...\033[0m"
    while read -r d; do
        [ -z "$d" ] && continue
        new_json=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a' 2>/dev/null)
        [ $? -eq 0 ] && echo "vmess://$(echo -n "$new_json" | base64 -w 0)" >> "$RESULT_FILE"
    done < "$DB_FILE"
    
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    cat "$RESULT_FILE"
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    echo "所有节点已保存在: $RESULT_FILE"
}

# --- 4. 菜单逻辑 ---
while true; do
    echo -e "\n\033[1;36m===== Cloudflare 优选管理工具 =====\033[0m"
    echo -e " 1. 一键生成优选节点"
    echo -e " 2. 查看历史生成记录"
    echo -e " 3. 添加自定义域名"
    echo -e " 4. 删除某个域名"
    echo -e " 5. 查看当前域名库"
    echo -e " 0. 退出脚本"
    echo "===================================="
    read -p "请输入序号: " input
    choice=$(echo "$input" | cut -c1)

    case "$choice" in
        1) generate_nodes ;;
        2) [ -s "$RESULT_FILE" ] && cat "$RESULT_FILE" || echo "暂无记录" ;;
        3) read -p "输入新域名: " d; [ -n "$d" ] && echo "$d" >> "$DB_FILE" && echo "已添加" ;;
        4) read -p "输入删除名: " d; sed -i "/^$d$/d" "$DB_FILE" && echo "已删除" ;;
        5) cat -n "$DB_FILE" ;;
        0) exit 0 ;;
        *) echo "无效输入" ;;
    esac
done
