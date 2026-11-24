# Примеры к типовой архитектуре patch-management

Все файлы в этой папке — заготовки. Они показывают форму настройки, а не копию работающей системы. Имена вымышлены и лежат в домене `mess.systems`. Секреты, ключи и пароли сюда не кладутся.

| Файл | Зачем |
|---|---|
| `renovate.example.json` | Конфигурация Renovate в репозитории, пресет [config:recommended](https://docs.renovatebot.com/presets-config/). Платформа и токен задаются в конфигурации запуска, не в этом файле. |
| `ci-scan.example.yml` | Шаг CI: Trivy, CycloneDX, загрузка в Dependency-Track по [официальному POST](https://docs.dependencytrack.org/usage/cicd/), подпись Cosign. |
| `cosign-verify.example.sh` | Проверка подписи перед продвижением образа. |
| `argocd-application.example.yaml` | Приложение Argo CD, образ по digest, без автоматической синхронизации в форме, похожей на `prd`. |
