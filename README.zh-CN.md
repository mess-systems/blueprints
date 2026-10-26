[English](README.md) | [Русский](README.ru.md) | **简体中文**

# mess.systems 参考架构

**mess.systems** 的参考架构（blueprints），每项公司能力一份。

参考架构是针对一项能力的现成方案，回答四个问题：

1. **由什么组成。** 组件取自[技术雷达](https://github.com/mess-systems/tech-radar)，每个组件链接到其雷达卡片和环。
2. **各部分如何命名。** 名称、标签依据[命名标准](https://github.com/mess-systems/naming-standard)。
3. **如何配置。** 配置示例。它们只是展示设置形态的骨架，不是运行系统的副本。
4. **为什么这样。** 每个选择的理由以及被否决的方案。

## 参考架构列表

| 目录 | 能力 | 状态 |
|---|---|---|
| [endpoint/](endpoint/) | 员工设备：笔记本和台式机、常驻代理、标准应用 | 草稿，持续演进 |

计划中：AI 网关、身份、CI。

## 三个仓库的关系

| 仓库 | 回答 |
|---|---|
| [naming-standard](https://github.com/mess-systems/naming-standard) | 如何命名 |
| [tech-radar](https://github.com/mess-systems/tech-radar) | 使用哪些技术以及采用程度 |
| blueprints（本仓库） | 技术如何组合成可用的能力 |

每张雷达卡片都列出其参与的参考架构，因此链接是双向的。

## 目录结构

```
<capability>/
  README.md        描述、组成、命名、理由、未决问题
  examples/        配置骨架，明确标注为示例
```

目录名是能力而不是产品（`endpoint`，而不是某个 MDM 工具的名称）。

## 参考架构中绝不包含

主机名、IP 地址、真实配置、密钥路径、访问组、设备清单或代理版本。示例使用 `mess.systems` 域下的名称，例如 `gateway.ai.corp.svc.mess.systems`。

## 修改

修改以 pull request 提交并附简短理由。新组件须先有雷达卡片。

## 许可

文本采用 [CC BY 4.0](LICENSE) 许可。署名："mess.systems blueprints (https://github.com/mess-systems/blueprints), CC BY 4.0"。
