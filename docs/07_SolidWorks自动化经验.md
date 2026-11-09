# SolidWorks 自动化经验（踩坑与可靠手法）

## 环境
- SW2016 SP5：D:\SW2016\SOLIDWORKS Corp\SOLIDWORKS\SLDWORKS.exe
- 机器上有损坏的 SW2021 残留（C:\），不要走那条。

## 附着 SW（COM）
- `GetObject(, "SldWorks.Application")` 和 `GetObject("SolidWorks_PID_<pid>")` 在本机都失败（MK_E_UNAVAILABLE）。
- **可靠方式**：枚举 ROT（Running Object Table），匹配 moniker 前缀 `SolidWorks_PID_`。
  C#: GetRunningObjectTable → EnumRunning → 逐个 GetDisplayName，匹配前缀后 GetObject。
- VBS 里的 `GetObject` 附着守卫在本环境会失败退出，属环境问题；模型通过等价 C#/ROT 路径构建验证。

## 可靠建模手法（本会话验证过）
1. 圆/直线挤出（FeatureExtrusion2 / FeatureCut3）：最稳。
2. 从顶面贯穿切除（T1=1 通孔）：稳。
3. **从轴线起完整封闭轮廓的旋转切除**（FeatureRevolve2, IsCut=true）：稳（CSF 杯腔、锥孔都这么做的）。
4. 齿圈样条挤出 + 之后内孔复切（齿圈挤出会把齿圈段内腔填满，需再切一次，半径 R+0.0002 避免共面失败）。
5. **两段法**：主体特征 save→close→reopen→再补螺栓孔等（同会话连续做螺栓孔常失败）。

## 不靠谱（会失败）
- 薄壁 <0.25 的"细条"切除/旋转：会丢面或被静默拒绝。
- FeatureFillet / FeatureChamfer 在薄壁处基本失败。
- 旋转凸台带多段样条/多处圆角：常失败；改成"旋转实心 + 后续切除"更稳。
- 从底面盲切（Flip=true）方向会反：一律从顶面贯穿。
- SW 的 ConeParams 第 7 字段不是工作半角，角度要以边界圆实测为准。

## 其他坑
- C# Add-Type：C#5 限制（无 ?.、无 out var、未用变量=错误、Nothing 无效用 null、反斜杠路径被 JS 模板改坏→路径当参数传）。
- VBS：UTF-8 BOM 会让 cscript 报错，须写 ANSI(GBK)（[IO.File]::WriteAllText($p,$t,[Text.Encoding]::Default)）。
- 反射调用：FeatureExtrusion2(23参)/FeatureCut3(26参)/FeatureRevolve2(20参,第4参=IsCut)/AddMate5(15参,最后 out int)。
- 面选择点：内孔环面的点在 (R_bore+R_root)/2，不能落在孔内。
