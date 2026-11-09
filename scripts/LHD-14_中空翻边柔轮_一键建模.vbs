Option Explicit
'==============================================================
' 中空翻边型谐波柔轮 一键建模 (对标绿的 LHD-14 结构形式)
' 外翻安装法兰 + 圆弧腹板 + 薄壁齿圈筒体 + 轴承让位止口
'==============================================================
'------------------- 参数区 (单位: 米) -------------------
Const P_M        = 0.0001225  ' 模数 (节圆 ?24.5)
Const P_Z        = 200        ' 齿数
Const P_HA       = 0.90       ' 齿顶高系数
Const P_HF       = 0.90       ' 齿根高系数
Const P_PER      = 24         ' 单齿采样点
Const P_WALL     = 0.00035    ' 齿圈筒壁厚 (最薄)
Const P_FLANGE_D = 0.046      ' 翻边法兰外径
Const P_FLANGE_T = 0.003      ' 法兰厚度 (最厚)
Const P_SEAT_R   = 0.018      ' 轴承止口半径 ?36
Const P_SEAT_T   = 0.002      ' 止口轴向高度
Const P_TOP      = 0.014      ' 总高
Const P_WEB_Z    = 0.0068     ' 腹板与筒体交接高度
Const P_BAND     = 0.0040     ' 齿圈段长度
Const P_BOLT_N   = 12         ' 法兰安装孔数
Const P_BOLT_D   = 0.0035     ' 安装孔径
Const P_BOLT_PCD = 0.040      ' 安装孔分布圆
Const P_FILE     = "D:\桌面\AI实验建模\LHD-14_中空翻边柔轮.SLDPRT"
'---------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_TIP, R_ROOT, H_T, TH_P, TH_H, R_BORE, RF, R_MID
Dim i, k, idx, nOut, ok, tryN
Dim ring(), pts(), w()
Dim cb, sb, s, rr, ang, px, py

'---------------- 附着已打开的 SolidWorks ----------------
For tryN = 1 To 5
    On Error Resume Next
    Set swApp = GetObject(, "SldWorks.Application")
    If Err.Number <> 0 Then Err.Clear
    On Error Goto 0
    If IsObject(swApp) Then Exit For
    WScript.Sleep 1000
Next
If Not IsObject(swApp) Then
    Dim wmi, ps, pr, pid
    pid = 0
    On Error Resume Next
    Set wmi = GetObject("winmgmts:")
    Set ps = wmi.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name='SLDWORKS.exe'")
    For Each pr In ps
        pid = pr.ProcessId
    Next
    If pid > 0 Then Set swApp = GetObject("SolidWorks_PID_" & pid)
    If Err.Number <> 0 Then Err.Clear
    On Error Goto 0
End If
If Not IsObject(swApp) Then
    WScript.Echo "ERROR: 未能附着 SolidWorks 进程"
    WScript.Quit 1
End If

R_P = P_M * P_Z / 2
R_TIP = R_P + P_HA * P_M
R_ROOT = R_P - P_HF * P_M
H_T = R_TIP - R_ROOT
TH_P = 2 * PI / P_Z
TH_H = TH_P / 2
R_BORE = R_ROOT - P_WALL
RF = P_FLANGE_D / 2
R_MID = (R_BORE + R_ROOT) / 2

Dim tpl
tpl = swApp.GetUserPreferenceStringValue(8)
If Len(tpl) = 0 Then tpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2016\templates\gb_part.prtdot"

swApp.CommandInProgress = True
Set swModel = swApp.NewDocument(tpl, 0, 0, 0)
If Not IsObject(swModel) Then
    swApp.CommandInProgress = False
    WScript.Echo "ERROR: 新建零件失败"
    WScript.Quit 1
End If
Set Part = swModel
Set skMgr = Part.SketchManager
Set fm = Part.FeatureManager
On Error Resume Next
Part.ActiveView.EnableGraphicsUpdate = False
On Error Goto 0

'-------- 1. 旋转基体 (x=r, y=-z) : 齿圈筒体 -> 腹板 -> 法兰 -> 止口 --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "上视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0
skMgr.InsertSketch True
' 顶面
skMgr.CreateLine R_BORE, -P_TOP, 0, R_ROOT, -P_TOP, 0
' 筒体外壁
skMgr.CreateLine R_ROOT, -P_TOP, 0, R_ROOT, -P_WEB_Z, 0
' 腹板外侧圆弧 -> 法兰内上缘 (径向向内、轴向向齿口)
w = Array(R_ROOT, P_WEB_Z, 0.0129, 0.0060, 0.0139, 0.0051, 0.0152, 0.0043, 0.0166, 0.0036, P_SEAT_R, P_FLANGE_T)
ReDim pts(UBound(w) / 2 * 3 + 2)
idx = 0
For i = 0 To UBound(w) Step 2
    pts(idx) = w(i) : pts(idx + 1) = -w(i + 1) : pts(idx + 2) = 0
    idx = idx + 3
Next
skMgr.CreateSpline pts
' 法兰顶面
skMgr.CreateLine P_SEAT_R, -P_FLANGE_T, 0, RF, -P_FLANGE_T, 0
' 法兰外圆
skMgr.CreateLine RF, -P_FLANGE_T, 0, RF, 0, 0
' 法兰背面
skMgr.CreateLine RF, 0, 0, P_SEAT_R, 0, 0
' 轴承止口
skMgr.CreateLine P_SEAT_R, 0, 0, P_SEAT_R, -P_SEAT_T, 0
' 腹板内侧圆弧 -> 筒体内壁
w = Array(P_SEAT_R, P_SEAT_T, 0.0170, 0.0027, 0.0158, 0.0035, 0.0144, 0.0045, 0.0131, 0.0056, 0.0121, 0.0063, R_BORE, P_WEB_Z)
ReDim pts(UBound(w) / 2 * 3 + 2)
idx = 0
For i = 0 To UBound(w) Step 2
    pts(idx) = w(i) : pts(idx + 1) = -w(i + 1) : pts(idx + 2) = 0
    idx = idx + 3
Next
skMgr.CreateSpline pts
' 内孔壁
skMgr.CreateLine R_BORE, -P_WEB_Z, 0, R_BORE, -P_TOP, 0
Dim ax
Set ax = skMgr.CreateCenterLine(0, 0, 0, 0, -P_TOP, 0)
skMgr.InsertSketch True
Part.ClearSelection2 True
ax.Select4 True, Nothing
ok = fm.FeatureRevolve2(True, True, False, False, False, False, 0, 0, 2 * PI, 0, False, False, 0, 0, 0, 0, 0, True, True, True)

'-------- 2. 齿圈 (顶面向下拉伸双圆弧齿廓) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", R_MID, 0, P_TOP, False, 0, Nothing, 0
skMgr.InsertSketch True
nOut = P_PER * P_Z
ReDim ring((nOut + 1) * 3 - 1)
idx = 0
For k = 0 To P_Z - 1
    cb = Cos(k * TH_P) : sb = Sin(k * TH_P)
    For i = 0 To P_PER - 1
        s = 2 * i / P_PER - 1
        rr = R_ROOT + H_T * (1 + Cos(PI * Abs(s))) / 2
        ang = TH_H * s
        px = rr * Cos(ang) : py = rr * Sin(ang)
        ring(idx) = px * cb - py * sb : ring(idx + 1) = px * sb + py * cb : ring(idx + 2) = 0
        idx = idx + 3
    Next
Next
ring(idx) = ring(0) : ring(idx + 1) = ring(1) : ring(idx + 2) = 0
skMgr.CreateSpline ring
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, True, 0, 0, P_BAND, P_BAND, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)

'-------- 3. 内孔复切 --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", R_MID, 0, P_TOP, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, R_BORE
skMgr.InsertSketch True
ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)

'-------- 4. 法兰安装孔 (贯穿) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", R_MID, 0, P_TOP, False, 0, Nothing, 0
skMgr.InsertSketch True
For i = 0 To P_BOLT_N - 1
    ang = i * 2 * PI / P_BOLT_N
    skMgr.CreateCircleByRadius P_BOLT_PCD / 2 * Cos(ang), P_BOLT_PCD / 2 * Sin(ang), 0, P_BOLT_D / 2
Next
skMgr.InsertSketch True
ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)

Part.ClearSelection2 True
Part.EditRebuild3
On Error Resume Next
Part.ViewZoomtofit2
Part.ActiveView.EnableGraphicsUpdate = True
On Error Goto 0
swApp.CommandInProgress = False

'-------- 5. 保存 --------
Dim errs, warns, res
errs = 0 : warns = 0
res = Part.Extension.SaveAs(P_FILE, 0, 1, Nothing, errs, warns)
WScript.Echo "DONE: " & P_FILE & "  err=" & errs
