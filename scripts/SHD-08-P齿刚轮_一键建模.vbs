Option Explicit
'==============================================================
' 谐波减速器 刚轮 (内齿圈) 一键建模
' 无公切线全光滑双圆弧齿廓, 与 200 齿杯型柔轮共轭配对
'==============================================================
'------------------- 参数区 (单位: 米) -------------------
Const P_M        = 0.000105    ' 模数 m (与柔轮一致)
Const P_ZF       = 200         ' 柔轮齿数 (刚轮 = ZF + 2 = 202)
Const P_B        = 0.0035      ' 齿宽 b (与柔轮齿圈匹配)
Const P_HA       = 0.90        ' 齿顶高系数
Const P_HF       = 0.90        ' 齿根高系数
Const P_RHO_A    = 0.0000508   ' 齿顶凸圆弧半径 (≈0.5m)
Const P_RHO_F    = 0.0002642   ' 齿槽凹圆弧半径 (≈2.6m)
Const P_OD       = 0.032       ' 刚轮外径
Const P_FLANGE_T = 0.004       ' 法兰厚度
Const P_BOLT_D   = 0.0032      ' 安装孔直径
Const P_BOLT_N   = 6           ' 安装孔数量
Const P_BOLT_PCD = 0.026       ' 安装孔分布圆
Const P_FILLET   = 0.0008      ' 齿圈/法兰过渡圆角
Const P_PER      = 24          ' 单齿采样点数
Const P_FILE     = "D:\桌面\AI实验建模\SHD-08-P齿刚轮.SLDPRT"
'---------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_A, R_F, H_T, TH_P, H_TOTAL, RING_OD, ZR
Dim i, k, idx, nOut, ok, tryN
Dim ring(), tx(), ty()
Dim cb, sb, s, rr, ang, px, py, baseA

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
    WScript.Echo "ERROR: 未能附着 SolidWorks 进程, 请先打开 SolidWorks"
    WScript.Quit 1
End If

ZR = P_ZF + 2
R_P = P_M * ZR / 2
R_A = R_P - P_HA * P_M        ' 齿顶半径 (内, 凸弧)
R_F = R_P + P_HF * P_M        ' 齿槽底半径 (外, 凹弧)
H_T = R_F - R_A
TH_P = 2 * PI / ZR
H_TOTAL = P_FLANGE_T + P_B
RING_OD = 2 * (R_F + 0.0004)

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

'-------- 1. 单个内齿轮廓 (齿顶凸弧 -> 齿槽凹弧, 全程光滑) --------
ReDim tx(P_PER)
ReDim ty(P_PER)
For i = 0 To P_PER - 1
    s = 2 * i / P_PER - 1
    rr = R_F - H_T * (1 + Cos(PI * Abs(s))) / 2
    ang = s * TH_P / 2
    tx(i) = rr * Cos(ang)
    ty(i) = rr * Sin(ang)
Next

'-------- 2. 圆周阵列: 202 内齿整圈齿廓 --------
nOut = P_PER * ZR
ReDim ring((nOut + 1) * 3 - 1)
idx = 0
For k = 0 To ZR - 1
    baseA = (k + 0.5) * TH_P
    cb = Cos(baseA) : sb = Sin(baseA)
    For i = 0 To P_PER - 1
        px = tx(i) * cb - ty(i) * sb
        py = tx(i) * sb + ty(i) * cb
        ring(idx) = px : ring(idx + 1) = py : ring(idx + 2) = 0
        idx = idx + 3
    Next
Next
ring(idx) = ring(0) : ring(idx + 1) = ring(1) : ring(idx + 2) = 0

'-------- 3. 安装法兰 --------
Part.ClearSelection2 True
Call SelFrontPlane()
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, P_OD / 2
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, P_FLANGE_T, P_FLANGE_T, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)

'-------- 4. 齿圈外圆 --------
Part.ClearSelection2 True
Call SelFrontPlane()
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, RING_OD / 2
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, H_TOTAL, H_TOTAL, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)

'-------- 5. 内齿贯穿切除 --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", 0, 0, H_TOTAL, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateSpline ring
skMgr.InsertSketch True
ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)

'-------- 6. 齿圈与法兰过渡圆角 --------
Part.ClearSelection2 True
If Part.Extension.SelectByID2("", "EDGE", RING_OD / 2, 0, P_FLANGE_T, False, 0, Nothing, 0) Then
    ok = fm.FeatureFillet(0, P_FILLET, 0, 0, Nothing, Nothing, Nothing)
End If

'-------- 7. 安装孔 --------
Part.ClearSelection2 True
If Part.Extension.SelectByID2("", "FACE", P_OD / 2 - 0.002, 0, P_FLANGE_T, False, 0, Nothing, 0) Then
    skMgr.InsertSketch True
    For i = 0 To P_BOLT_N - 1
        ang = i * 2 * PI / P_BOLT_N
        skMgr.CreateCircleByRadius P_BOLT_PCD / 2 * Cos(ang), P_BOLT_PCD / 2 * Sin(ang), 0, P_BOLT_D / 2
    Next
    skMgr.InsertSketch True
    ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)
End If

Part.ClearSelection2 True
Part.EditRebuild3
On Error Resume Next
Part.ViewZoomtofit2
Part.ActiveView.EnableGraphicsUpdate = True
On Error Goto 0
swApp.CommandInProgress = False

'-------- 8. 保存 --------
Dim errs, warns, res
errs = 0 : warns = 0
res = Part.Extension.SaveAs(P_FILE, 0, 1, Nothing, errs, warns)
WScript.Echo "DONE: " & P_FILE & "  err=" & errs

'=========================================================
Sub SelFrontPlane()
    If Not Part.Extension.SelectByID2("前视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0) Then
        Part.Extension.SelectByID2 "Front Plane", "PLANE", 0, 0, 0, False, 0, Nothing, 0
    End If
End Sub
