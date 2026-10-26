**English** | [Русский](README.ru.md) | [简体中文](README.zh-CN.md)

# mess.systems blueprints

Reference architectures of **mess.systems**, one per company capability.

A blueprint is a ready solution for one capability. It answers four questions:

1. **What is it built from.** Components taken from the [tech radar](https://github.com/mess-systems/tech-radar), each with a link to its radar card and ring.
2. **What are the parts called.** Names, labels and tags derived from the [naming standard](https://github.com/mess-systems/naming-standard).
3. **How is it configured.** Configuration examples. They are skeletons that show the shape of a setting, not a copy of a running system.
4. **Why this way.** The rationale for each choice and the options that were rejected.

## Blueprints

| Folder | Capability | Status |
|---|---|---|
| [endpoint/](endpoint/) | Employee device: laptops and desktops, resident agents, standard applications | Draft, evolving |

Planned next: AI gateway, identity, CI.

## How the three repositories fit together

| Repository | Answers |
|---|---|
| [naming-standard](https://github.com/mess-systems/naming-standard) | How things are named |
| [tech-radar](https://github.com/mess-systems/tech-radar) | Which technologies are used and how firmly |
| blueprints (this one) | How the technologies combine into a working capability |

Each radar card lists the blueprints it takes part in, so the link works in both directions.

## Folder layout

```
<capability>/
  README.md        description, components, naming, rationale, open questions
  examples/        configuration skeletons, clearly marked as examples
```

The folder name is the capability, never a product (`endpoint`, not the name of an MDM tool), following the leftmost-is-capability rule of the [naming standard](https://github.com/mess-systems/naming-standard/blob/main/01-naming-conventions.md).

## What a blueprint never contains

Hostnames, IP addresses, real configuration, secret paths, access groups, device inventory or agent versions. Examples use names under the `mess.systems` domain, such as `gateway.ai.corp.svc.mess.systems`.

## Changing a blueprint

A change is a pull request with a short rationale. A new component must first have a radar card.

## License

Text licensed under [Creative Commons Attribution 4.0 International (CC BY 4.0)](LICENSE). Attribution: "mess.systems blueprints (https://github.com/mess-systems/blueprints), CC BY 4.0".
