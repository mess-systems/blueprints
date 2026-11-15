#!/usr/bin/env bash
# ПРИМЕР. Не конфигурация работающей системы. Все значения в <...> условные.
# Один вход после чистой установки Ubuntu 26.04 LTS: Ansible -> ansible-pull -> chezmoi -> репозитории.
set -euo pipefail

PROFILE="${PROFILE:?задайте std, eng или paw}"
CONFIG_REPO="https://git.sdlc.eng.svc.mess.systems/corp/device-workstation.git"   # пример имени
DOTFILES_REPO="https://git.sdlc.eng.svc.mess.systems/<user>/dotfiles.git"          # пример имени
START=$(date +%s)
step() { echo "[$(( $(date +%s) - START ))s] $*"; }   # время шагов идёт в журнал учения

step "1. Ansible"
sudo apt-get update -y
sudo apt-get install -y ansible git

step "2. Роль workstation (первый прогон, дальше по таймеру)"
sudo ansible-pull --url "$CONFIG_REPO" --checkout main \
  --extra-vars "endpoint_profile=${PROFILE}" site.yml

step "3. Настройки пользователя"
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply "$DOTFILES_REPO"

step "4. Репозитории по списку"
mkdir -p "$HOME/src"
while read -r url dir; do
  [[ -z "$url" || "$url" == \#* ]] && continue
  [[ -d "$HOME/src/$dir" ]] || git clone "$url" "$HOME/src/$dir"
done < "$HOME/.config/workstation/repos.txt"

step "5. Вход: SSO и OpenBao (короткий токен через OIDC)"
echo "Выполните: bao login -method=oidc"

step "Готово. Проверка «можно работать» — по чек-листу учения."
