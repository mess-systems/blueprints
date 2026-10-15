[English](README.md) | [Русский](README.ru.md) | **简体中文**

# 参考架构：endpoint

员工设备：人们日常工作使用的笔记本和台式机。本参考架构规定设备上运行哪些常驻代理、哪些应用是标准应用、设备如何命名和打标签，以及原因。

**状态：** 草稿，持续演进。创建于 2026-10-15。译文仅供参考；规范文本为[英文版](README.md)。

**能力代码。** [命名标准](https://github.com/mess-systems/naming-standard/blob/main/i18n/zh-CN/01-naming-conventions.md)（v2.3）中域 `device` 下的 `endpoint`。它指员工设备上运行的一切，从不出现在 DNS 名称中。[技术雷达](https://github.com/mess-systems/tech-radar)以 `device` 作为同一范围的类别。浏览器交付的虚拟桌面是同一域中的服务器侧能力 `vdi`。

## 1. 范围

| 包含 | 不包含 |
|---|---|
| 公司笔记本和台式机 | 手机和平板（以后单独的参考架构） |
| 常驻代理和标准应用 | 服务器侧组件（Fleet 服务器、Wazuh 管理器、NetBird 管理端）：它们属于各自的能力 |
| 设备命名和标签 | 个人设备（BYOD 别名规则除外） |

## 2. 配置档、形态与平台

| 配置档 | 适用对象 | 基线 |
|---|---|---|
| `std` | 所有员工 | 默认基线 |
| `eng` | 工程师 | 构建工具、AI 编码代理、沙箱、容器 |
| `paw` | 管理员，仅用于管理工作 | 专用、加固的特权访问工作站。无邮件、聊天和 AI 客户端 |

| 形态 | 含义 |
|---|---|
| `lt` | 笔记本 |
| `dt` | 台式机或固定工作站 |

| 平台 | 配置档 |
|---|---|
| Windows 11 Pro | `std`、`eng`、`paw` |
| macOS（当前或上一版本） | `std`、`eng`、`paw` |
| Ubuntu 26.04 LTS | `std`、`eng`、`paw` |
| CachyOS | 仅 `eng` |

## 3. 命名与标签

设备名称：`<profile>-<form>-<asset-id>`，例如 `eng-lt-k7m2qa`。

- `asset-id` 为 6 个字符，字母表为 `a-z 2-9`，去掉 `o`、`l`、`i`，以字母开头。由资产系统分配，永不改变。不使用序列号。
- 名称符合 Windows 计算机名 15 个字符的限制。
- 正则：`^(std|eng|paw)-(lt|dt)-[a-hjkmnp-z][a-hjkmnp-z2-9]{5}$`。
- 个人设备保留自己的主机名；管理工具可为其设别名 `byod-<form>-<asset-id>`，仅用于台账。
- 名称不授予任何权限。访问取决于组和设备状态，而不是名称。
- 终端在服务 DNS 区中没有记录。

Fleet 和 Wazuh 中的标签带有 `capability=endpoint`，并遵循[标签与标记](https://github.com/mess-systems/naming-standard/blob/main/i18n/zh-CN/05-labels-and-tags.md)：`plane`、`owner`（组）、`endpoint-profile`、`device-form`、`data-class`。用户名、序列号和主机名绝不进入标签。

命名规则已纳入命名标准（自 v2.2 起）：[06 终端约定](https://github.com/mess-systems/naming-standard/blob/main/i18n/zh-CN/06-endpoint-conventions.md)。

## 4. 常驻代理

常驻代理是设备开机期间一直运行的后台服务。操作系统内置功能（磁盘加密、防火墙、更新）属于设置，不是代理。Ansible 不是代理：它通过 SSH 或定时的 `ansible-pull` 运行。

| 代理 | 用途 | 雷达 | `std` | `eng` | `paw` |
|---|---|---|---|---|---|
| Fleet（fleetd 与 osquery） | 资产清单、策略、设备查询 | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/fleet.md) | 是 | 是 | 是 |
| Wazuh 代理 | 安全日志与检测 | [Adopt](https://github.com/mess-systems/tech-radar/blob/main/technologies/wazuh.md) | 是 | 是 | 是 |
| NetBird 客户端 | 通过 SSO 以网状网络访问内部服务 | [Adopt](https://github.com/mess-systems/tech-radar/blob/main/technologies/netbird.md) | 是 | 是 | 是 |
| RustDesk 服务 | 远程支持 | [Adopt](https://github.com/mess-systems/tech-radar/blob/main/technologies/rustdesk.md) | 是 | 是 | 否：特权访问工作站不允许入站远程控制 |
| agentdesktop | AI 客户端的清单与托管设置、沙箱策略、将模型流量路由到 AI 网关 | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/agentdesktop.md) | 是 | 是 | 否：`paw` 上没有 AI 客户端 |
| 容器运行时（Podman） | 开发容器和 CLI 代理沙箱 | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/podman.md) | 否 | 是 | 否 |
| SPIRE 代理 | 为完全托管且通过证明的设备提供 SPIFFE 设备身份 | [Trial](https://github.com/mess-systems/tech-radar/blob/main/technologies/spire.md) | 否 | 否 | 是（提议） |

所有人都在使用 AI，因此凡是装有 AI 客户端的配置档都需要管控 AI 客户端。`paw` 按设计没有 AI 客户端。

### 4.1 每台设备的代理数量

| 配置档 | 代理 | 数量 | 精简后 |
|---|---|---|---|
| `std` | Fleet、Wazuh、NetBird、RustDesk、agentdesktop | 5 | 4 |
| `eng` | `std` 的五个代理加容器运行时 | 6 | 4 |
| `paw` | Fleet、Wazuh、NetBird、SPIRE | 4 | 4 |

同一配置档在所有平台上的数量相同。如果在 `std` 或 `eng` 上也启用 SPIRE 代理，数量加 1。

### 4.2 精简

| 重叠 | 精简方式 | 效果 |
|---|---|---|
| Fleet 和 Wazuh 都收集清单并检查设置 | Wazuh 通过其 osquery 模块读取 osquery 结果，关闭自身的清单收集和配置评估。Fleet 负责清单和策略，Wazuh 负责日志和检测 | 减少重复数据；代理数量不变 |
| RustDesk 和 NetBird 都能访问设备 | 支持客户端按用户请求启动，而不是作为服务常驻 | `std` 和 `eng` 各减 1 |
| 容器运行时作为常驻守护进程 | Podman 无守护进程：rootless、按需启动，因此不是常驻代理 | `eng` 减 1 |
| agentdesktop 和 Fleet 都做软件清单 | AI 客户端清单取自 Fleet；agentdesktop 只保留托管设置和沙箱策略 | 减少重复数据；代理保留 |

### 4.3 平台说明

| 平台 | 说明 |
|---|---|
| Windows 11 Pro | 所有代理均有官方版本。BitLocker、Defender 和防火墙为内置。 |
| macOS | Apple MDM 配置描述文件由 Fleet 服务器下发；除 fleetd 外无需其他代理。FileVault 为内置。 |
| Ubuntu 26.04 LTS | 所有代理均有 Debian 或 Ubuntu 软件包。LUKS2 配合 TPM2。 |
| CachyOS | Fleet、Wazuh 和 NetBird 在该平台上可用。 |

## 5. 标准应用

由用户启动，不在后台常驻。雷达只涵盖标准中点名的产品，因此大多数用户应用按设计不在雷达中。

| 类别 | 产品 | 配置档 | 雷达 |
|---|---|---|---|
| 浏览器 | 带策略的 Firefox | 全部 | 不在雷达中 |
| 办公 | LibreOffice | `std`、`eng` | 不在雷达中 |
| 邮件 | Thunderbird | `std`、`eng` | 不在雷达中 |
| 密码 | Bitwarden 客户端；离线 KeePassXC | 全部 | 服务器 [Vaultwarden](https://github.com/mess-systems/tech-radar/blob/main/technologies/vaultwarden.md) 处于 Assess |
| 聊天 | Element | `std`、`eng` | [Matrix](https://github.com/mess-systems/tech-radar/blob/main/technologies/matrix.md)（Adopt）作为协议 |
| 压缩 | 7-Zip | `std`、`eng` | 不在雷达中 |
| 媒体 | VLC | `std`、`eng` | 不在雷达中 |
| PDF | PDF Arranger、Okular、Xournal++、OCRmyPDF（Linux） | `std`、`eng` | 不在雷达中 |
| 用户配置 | chezmoi | `eng` | 不在雷达中 |
| AI CLI 代理 | 默认 OpenCode；goose、Codex CLI、Gemini CLI | `eng` | 暂无卡片 |
| 面向所有人的 AI 聊天 | 通过 AI 网关的 LibreChat 网页客户端 | `std`、`eng` | [LibreChat](https://github.com/mess-systems/tech-radar/blob/main/technologies/librechat.md)（Trial）、[agentgateway](https://github.com/mess-systems/tech-radar/blob/main/technologies/agentgateway.md)（Adopt） |
| 用于高风险工作的远程桌面（能力 `vdi`） | 浏览器中的 Kasm Workspaces | `std`、`eng` | [Kasm Workspaces](https://github.com/mess-systems/tech-radar/blob/main/technologies/kasm-workspaces.md)（Adopt） |
| Linux 上的 Windows 应用 | WinBoat | Linux 上的 `eng` | [WinBoat](https://github.com/mess-systems/tech-radar/blob/main/technologies/winboat.md)（Adopt） |

`paw` 上只有浏览器、密码管理器和管理工具。无邮件、聊天和 AI 客户端。

配置通过 [Ansible](https://github.com/mess-systems/tech-radar/blob/main/technologies/ansible.md)（Adopt）和 Fleet 策略下发。

## 6. 理由

- **代理要少。** 每个常驻代理都消耗电量、增加攻击面和支持成本。基线让每项任务只有一个代理，并消除重叠（第 4.2 节）。
- **开源且自托管。** 所有代理都向公司自己运行的服务器报告，路径中没有第三方中继。
- **按设备状态而非网络授予访问。** NetBird 在 SSO 之后提供网状网络访问；设备名称不授予任何权限。
- **AI 只走一个网关。** agentdesktop 让 AI 客户端以短期凭据连接公司 AI 网关；提供商密钥留在网关，从不下发到设备。
- **`paw` 保持最小。** 无入站远程控制、无邮件、聊天或 AI：特权工作站只用于管理工作。

## 7. 配置示例

[examples/](examples/) 中的文件**仅为示例**：使用占位值的骨架，展示设置的形态，不是任何运行系统的配置。

| 文件 | 展示内容 |
|---|---|
| [fleet-labels.example.yml](examples/fleet-labels.example.yml) | 根据设备名称按配置档分组设备的 Fleet 标签 |
| [wazuh-agent-osquery.example.xml](examples/wazuh-agent-osquery.example.xml) | Wazuh 代理读取 osquery 结果，而不运行自身的清单收集 |
| [agentdesktop.example.yaml](examples/agentdesktop.example.yaml) | AI 客户端路由到 AI 网关 |
| [podman-containers.example.conf](examples/podman-containers.example.conf) | `eng` 的 rootless Podman 默认设置 |

## 8. 未决问题

1. AI CLI 代理（OpenCode 等）在雷达中没有卡片。一张分组卡片还是每个一张。
2. 密码管理器：Bitwarden 客户端配合 Vaultwarden（Assess），还是其他选择。
3. Fleet 免费版：远程锁定和擦除、按标签分配配置描述文件以及强制加密是付费功能；免费版需用脚本替代。
4. 设备上的 SPIRE 代理：SPIRE 在工作负载上处于 Trial；用于设备尚未决定。
