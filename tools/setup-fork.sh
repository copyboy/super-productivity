#!/bin/sh
# Fork 开发环境一键配置(幂等,可重复运行)
# 存放于 fork-setup 分支,不进 master、不进发往上游的 PR
set -e
cd "$(dirname "$0")/.."

# 1. upstream remote(指向真正的上游仓库)
if git remote get-url upstream >/dev/null 2>&1; then
  echo "· upstream remote 已存在: $(git remote get-url upstream)"
else
  git remote add upstream https://github.com/super-productivity/super-productivity.git
  echo "✔ 已添加 upstream remote"
fi

# 2. sync-upstream 别名(覆盖写入,保持与本脚本一致)
git config alias.sync-upstream '!f() {
  set -e
  if ! git diff-index --quiet HEAD --; then echo "工作区有未提交改动,请先 commit 或 stash 再同步"; exit 1; fi
  cur=$(git branch --show-current)
  git switch master
  git fetch upstream
  git merge --ff-only upstream/master
  git push origin master
  if [ -n "$cur" ] && [ "$cur" != "master" ]; then
    git switch "$cur"
    git rebase master --autostash
    echo "✔ master 已同步,且 $cur 已 rebase 到最新"
  else
    echo "✔ master 已同步到最新上游"
  fi
}; f'
echo "✔ 已配置 git sync-upstream 别名"

# 3. 本地 Node 版本覆盖:.nvmrc 指到 24(上游为 22.x,但 Angular CLI 版本门槛
#    在 22.22.3 以下会静默退出 0 导致空构建;24 已装且满足要求)
#    skip-worktree 让这处本地改动对 git 隐身:不挡 sync-upstream,不混进 PR
printf '24\n' > .nvmrc
git update-index --skip-worktree .nvmrc
echo "✔ .nvmrc 已指向 24 并设置 skip-worktree"

echo
echo "完成。日常在任何分支运行: git sync-upstream"
echo "提示:"
echo "  - 构建可能弄脏 package-lock.json / build/icon.icns(npm11 重写格式、图标再生成),"
echo "    sync 前如报脏工作区,先 git restore 这两个文件再同步"
echo "  - 以后要正式修改 .nvmrc(如上游 Node 版本变化),先:"
echo "      git update-index --no-skip-worktree .nvmrc"
