#!/bin/bash

# 1. 基础环境准备
sudo rm -f /usr/local/bin/cfd* /usr/local/bin/cfy*
hash -r
[ ! -x "$(command -v jq)" ] && { 
    sudo apt update && sudo apt install -y jq || sudo yum install -y jq || opkg install jq; 
}

# 2. 初始化数据库
sudo mkdir -p /etc/cfd
DB="/etc/cfd/domains.txt"
if [ ! -s "$DB" ]; then
    sudo bash -c "cat > $DB <<EOF
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
sudo chmod 666 "$DB"

# 3. 编写全能主脚本 cfdy
sudo tee /usr/local/bin/cfdy <<-'EOF' > /dev/null
#!/bin/bash
DB="/etc/cfd/domains.txt"
RESULT="$HOME/proxy_list.txt"

# --- 功能函数 ---
func_generate() {
    echo -e "\n\033[1;36m[1] 选择模板来源：\033[0m"
    echo " 1. 粘贴新 vmess 链接 (推荐)"
    echo " 2. 使用本地文件 (/etc/sing-box/url.txt)"
    read -p "选择 [1-2]: " t_choice
    if [ "$t_choice" == "2" ] && [ -f "/etc/sing-box/url.txt" ]; then
        url=$(head -n 1 "/etc/sing-box/url.txt")
    else
        read -p "请粘贴 vmess:// 链接: " url
    fi
    url=$(echo $url | tr -d '\r\n ')
    body="${url#vmess://}"
    json=$(echo "$body" | base64 -d 2>/dev/null)
    if [ -z "$json" ]; then echo "错误：链接无效"; return; fi
    > "$RESULT"
    while read -r d; do
        [ -z "$d" ] && continue
        new=$(echo "$json" | jq -c --arg a "$d" '.add = $a | .ps = .ps + "-优选-" + $a')
        echo "vmess://$(echo -n "$new" | base64 -w 0)" >> "$RESULT"
    done < "$DB"
    echo "------------------------------------------------"
    cat "$RESULT"
    echo "------------------------------------------------"
    echo "已保存至: $RESULT"
}

func_list() {
    echo -e "\n\033[1;33m--- 当前域名库 ---"
    cat -n "$DB"
    echo -e "------------------\033[0m"
}

func_add() {
    read -p "请输入要添加的域名: " d
    [ -n "$d" ] && echo "$d" >> "$DB" && sort -u "$DB" -o "$DB" && echo "已添加: $d"
}

func_del() {
    read -p "请输入要删除的域名: " d
    [ -n "$d" ] && sed -i "/^$d$/d" "$DB" && echo "已删除: $d"
}

# --- 主循环菜单 ---
while true; do
    echo -e "\n\033[1;36m===== 优选工具交互菜单 =====\033[0m"
    echo " 1. 生成并显示节点"
    echo " 2. 查看已生成的节点"
    echo " 3. 添加优选域名"
    echo " 4. 删除优选域名"
    echo " 5. 查看域名列表"
    echo " 0. 退出脚本"
    echo "=============================="
    read -p "请输入序号 [0-5]: " choice
    case $choice in
        1) func_generate ;;
        2) [ -f "$RESULT" ] && cat "$RESULT" || echo "未生成过节点" ;;
        3) func_add ;;
        4) func_del ;;
        5) func_list ;;
        0) exit 0 ;;
        *) echo "无效输入" ;;
    esac
done
EOF

# 4. 授权并启动
sudo chmod +x /usr/local/bin/cfdy
# 为了兼容你习惯的简写，做一个软链接
sudo ln -sf /usr/local/bin/cfdy /usr/local/bin/cfd
echo -e "\033[1;32m安装完成！请输入 cfdy 开启菜单。\033[0m"
cfdy