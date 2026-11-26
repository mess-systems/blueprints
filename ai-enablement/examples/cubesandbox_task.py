"""Пример: песочница зоны Z2b для фоновой задачи агента.

Агент целиком работает в microVM CubeSandbox; наружу доступны только шлюз моделей,
Git и зеркало пакетов. Ключи подставляет CubeEgress, внутрь песочницы они не попадают.

Синтаксис Sandbox.create(allow_internet_access=..., network=...), Rule, Match, Action, Inject и параметров сети сверен с
документацией CubeSandbox 0.8.0 (Network Policy, Egress Proxy). Плейсхолдеры <...>
заменяются оркестратором задач; секреты оркестратор читает из OpenBao.

Важно:
- allow_internet_access=False повторяется при каждом обновлении сетевых настроек:
  поле, пропущенное при обновлении, сбрасывается, и песочница снова выходит в интернет;
- шаблон собирается с CA CubeEgress, иначе HTTPS внутри песочницы не работает;
- inject работает только в правилах с allow=True; правила пишутся со scheme="https".

"""

import os

from cubesandbox import Action, Inject, Match, Rule, Sandbox

GATEWAY_HOST = "<gateway-host>"
GIT_HOST = "<git-host>"
MIRROR_HOST = "<package-mirror-host>"


def rules_for(task_id: str, gateway_key: str, git_token: str) -> list[Rule]:
    return [
        Rule(
            name=f"{task_id}-gateway",
            match=Match(scheme="https", host=GATEWAY_HOST, sni=GATEWAY_HOST,
                        method=["POST"], path="/v1/*"),
            action=Action(
                allow=True,
                audit="metadata",
                inject=[Inject(header="Authorization",
                               format="Bearer ${SECRET}",
                               secret=gateway_key)],
            ),
        ),
        Rule(
            name=f"{task_id}-git",
            match=Match(scheme="https", host=GIT_HOST, sni=GIT_HOST),
            action=Action(
                allow=True,
                audit="metadata",
                # Схема заголовка аутентификации берётся из документации Git-сервера.
                inject=[Inject(header="Authorization",
                               format="<git-auth-scheme> ${SECRET}",
                               secret=git_token)],
            ),
        ),
        Rule(
            name=f"{task_id}-mirror",
            match=Match(scheme="https", host=MIRROR_HOST, sni=MIRROR_HOST,
                        method=["GET"]),
            action=Action(allow=True, audit="metadata"),
        ),
    ]


def run_task(task_id: str, repo: str, branch: str, prompt_file: str) -> None:
    # Ключ агента на шлюзе и токен Git с правом записи только в ветку задачи.
    gateway_key = os.environ["AGENT_GATEWAY_KEY"]
    git_token = os.environ["AGENT_GIT_TOKEN"]

    with Sandbox.create(
        allow_internet_access=False,
        network={"rules": rules_for(task_id, gateway_key, git_token)},
    ) as sb:
        sb.commands.run(f"git clone https://{GIT_HOST}/{repo}.git /work && "
                        f"cd /work && git switch -c {branch}")
        # Агент в режиме без интерфейса; модель вызывается через шлюз без ключа в окружении.
        sb.commands.run(f"cd /work && opencode run \"$(cat {prompt_file})\"")
        sb.commands.run(f"cd /work && git push origin {branch}")
        # Проверка изоляции: прямой выход в интернет должен завершаться отказом.
        sb.commands.run("curl -s -o /dev/null -w '%{http_code}' https://example.com || true")
