#!/bin/sh
# Fork 开发环境一键配置(幂等,可重复运行)
# 用途:配置 upstream remote 和 git sync-upstream 别名
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

echo
echo "完成。日常在任何分支运行: git sync-upstream"
