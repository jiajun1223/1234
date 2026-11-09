# 谐波减速器柔轮 / 刚轮 建模知识库与成果汇总

本仓库是「SHD/CSF 谐波减速器柔轮、刚轮」SolidWorks 参数化建模项目的**完整知识沉淀**，
包含：设计标准、壁厚与斜度结论、精度公差、对标数据、尺寸系列、建模自动化经验、最终模型清单，
以及整个会话中逐步确认和修正的关键决策。

**用途**：换一台电脑后，只要读本仓库（先读 README，再看 docs/00_项目总览），
就能恢复到与当前会话一致的设计认知与进度，无需重新试错。

## 目录结构

| 路径 | 内容 |
|---|---|
| `README.md` | 本说明 |
| `docs/` | 全部知识文档（设计标准 / 结论 / 数据 / 经验 / 决策日志） |
| `models/` | 最终 SolidWorks 零件（.SLDPRT）与 DXF 图纸 |
| `scripts/` | 一键建模 VBS 宏脚本（GBK 编码） |
| `reference/` | 原始数据（DWG 解析、齿形点云 CSV、手册参数） |
| `images/` | 关键截图 |
| `AGENTS.md` | 精简版约定，供 AI 会话自动加载 |

## 建议阅读顺序（恢复进度）

1. `docs/00_项目总览与进度.md` —— 我在做什么、做到哪一步
2. `docs/09_对话关键决策日志.md` —— 哪些结论是"用户纠正过的"，务必遵守
3. `docs/01_齿形设计标准.md` —— 齿形硬性规则
4. `docs/02_壁厚与斜度设计.md` + `docs/03_底盘优化最终结论.md` —— 壁厚与底盘
5. `docs/07_SolidWorks自动化经验.md` —— 怎么稳定驱动 SW 建模
6. `docs/08_模型文件清单.md` —— 每个模型是什么、关键尺寸

## 环境

- SolidWorks 2016 SP5，路径 `D:\SW2016\SOLIDWORKS Corp\SOLIDWORKS\SLDWORKS.exe`
- Windows，Python 3.12（捆绑于 `~/.dsh/dsh-runtimes/...`）
- 已装 DSH 插件：dshmarket / modlens / dsh-computer-use-win / dsh-univer-office / dsh-cad /
  cadcraft / dwg-reader / dsh-sw-cad / dsh-mech-workbench / dsh-fs-encoding

## 生成时间

2026-11-09（汇总整理）
