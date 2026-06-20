#!/bin/bash
# 家庭股票日报网站 - GitHub 初始化脚本
# 一次性执行即可

set -e
cd ~/stock-reports-site

echo "========================================="
echo "  家庭股票日报网站 - GitHub 初始化"
echo "========================================="
echo ""

# 1. 初始化本地仓库
echo "[1/5] 初始化本地 git 仓库..."
git add -A
git commit -m "init: 家庭股票日报网站 v1" 2>/dev/null || echo "  (可能已提交)"

# 2. GitHub CLI 登录
echo ""
echo "[2/5] GitHub CLI 登录..."
echo "  浏览器打开: https://github.com/login/device"
echo "  输入验证码: D5EB-4C93"
gh auth login --git-protocol ssh --hostname github.com

# 3. 确认登录
echo ""
echo "[3/5] 确认登录状态..."
gh auth status

# 4. 创建 GitHub 仓库
echo ""
echo "[4/5] 创建 GitHub 仓库..."
gh repo create jiating-gupiao --public --source=. --remote=origin --push

# 5. 启用 GitHub Pages
echo ""
echo "[5/5] 启用 GitHub Pages..."
gh api "repos/34930799-png/jiating-gupiao/pages" \
  -X POST \
  -f "source[branch]=main" \
  -f "source[path]=/"

echo ""
echo "========================================="
echo "  ✅ 初始化完成！"
echo "  网站地址: https://34930799-png.github.io/jiating-gupiao/"
echo "  访问密码: 19520812"
echo "========================================="
