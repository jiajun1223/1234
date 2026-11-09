Option Explicit
'==============================================================
' 高端精密谐波减速器 杯型柔轮 一键建模 (无公切线全光滑 S 齿廓)
' 对标 HD S齿 / 绿的 P齿 双圆弧齿形   GB/T14118 8号 节圆 20.32
'==============================================================
'------------------- 参数区 (单位: 米) -------------------
Const P_M        = 0.000105    ' 模数 m (8号英制系列)
Const P_Z        = 200         ' 齿数
Const P_HA       = 0.90        ' 齿顶高系数
Const P_HF       = 0.90        ' 齿根高系数
Const P_PER      = 24          ' 单齿采样点数
Const P_FLANGE_D = 0.040       ' 输出法兰外径
Const P_FLANGE_T = 0.002       ' 法兰厚度
Const P_CUP_LEN  = 0.012       ' 柔轮总长
Const P_WALL     = 0.0003      ' 筒壁厚
Const P_BAND     = 0.0035      ' 齿圈段长度
Const P_BOLT_N   = 16          ' 法兰螺栓孔数
Const P_BOLT_D   = 0.003       ' 螺栓孔径
Const P_BOLT_PCD = 0.034       ' 螺栓孔分布圆
Const P_FILLET   = 0.0008      ' 筒壁/法兰过渡圆角
Const P_FILE     = "D:\桌面\AI实验建模\SHD-08-P齿柔轮.SLDPRT"
'---------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_TIP, R_ROOT, H_T, TH_P, TH_H, R_BORE
Dim i, k, idx, nOut, ok, tryN
Dim ring(), sPts(), tx(), ty()
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
    WScript.Echo "ERROR: 未能附着 SolidWorks 进程, 请先打开 SolidWorks"
    WScript.Quit 1
End If

R_P = P_M * P_Z / 2
R_TIP = R_P + P_HA * P_M
R_ROOT = R_P - P_HF * P_M
H_T = R_TIP - R_ROOT
TH_P = 2 * PI / P_Z
TH_H = TH_P / 2
R_BORE = R_ROOT - P_WALL

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

'-------- 1. 单个齿轮廓 (齿顶凸弧 -> 齿侧凹弧 -> 齿槽凹弧, 全程光滑) --------
ReDim tx(P_PER)
ReDim ty(P_PER)
For i = 0 To P_PER - 1
    s = 2 * i / P_PER - 1
    rr = R_ROOT + H_T * (1 + Cos(PI * Abs(s))) / 2
    ang = TH_H * s
    tx(i) = rr * Cos(ang)
    ty(i) = rr * Sin(ang)
Next
tx(P_PER) = tx(0)
ty(P_PER) = ty(0)
ReDim sPts((P_PER + 1) * 3 - 1)
idx = 0
For i = 0 To P_PER
    sPts(idx) = tx(i) : sPts(idx + 1) = ty(i) : sPts(idx + 2) = 0
    idx = idx + 3
Next
Part.ClearSelection2 True
Call SelFrontPlane()
skMgr.InsertSketch True
skMgr.CreateSpline sPts
skMgr.InsertSketch True

'-------- 2. 圆周阵列: 200 齿整圈齿廓 --------
nOut = P_PER * P_Z
ReDim ring((nOut + 1) * 3 - 1)
idx = 0
For k = 0 To P_Z - 1
    cb = Cos(k * TH_P) : sb = Sin(k * TH_P)
    For i = 0 To P_PER - 1
        px = tx(i) * cb - ty(i) * sb
        py = tx(i) * sb + ty(i) * cb
        ring(idx) = px : ring(idx + 1) = py : ring(idx + 2) = 0
        idx = idx + 3
    Next
Next
ring(idx) = ring(0) : ring(idx + 1) = ring(1) : ring(idx + 2) = 0

'-------- 3. 输出法兰 ?40 x 2 --------
Part.ClearSelection2 True
Call SelFrontPlane()
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, P_FLANGE_D / 2
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, P_FLANGE_T, P_FLANGE_T, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)

'-------- 4. 薄壁筒体 --------
Part.ClearSelection2 True
Call SelFrontPlane()
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, R_ROOT
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, P_CUP_LEN, P_CUP_LEN, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)

'-------- 5. 齿圈段 (顶面向下拉伸整圈齿廓) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", 0, 0, P_CUP_LEN, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateSpline ring
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, True, 0, 0, P_BAND, P_BAND, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)

'-------- 6. 内孔 (旋转切除) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "上视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateLine 0, 0, 0, R_BORE, 0, 0
skMgr.CreateLine R_BORE, 0, 0, R_BORE, -P_CUP_LEN, 0
skMgr.CreateLine R_BORE, -P_CUP_LEN, 0, 0, -P_CUP_LEN, 0
skMgr.CreateLine 0, -P_CUP_LEN, 0, 0, 0, 0
Dim cl
Set cl = skMgr.CreateCenterLine(0, 0, 0, 0, -P_CUP_LEN, 0)
skMgr.InsertSketch True
Part.ClearSelection2 True
cl.Select4 True, Nothing
ok = fm.FeatureRevolve2(True, True, False, True, False, False, 0, 0, 2 * PI, 0, False, False, 0, 0, 0, 0, 0, True, True, True)

'-------- 7. 筒壁与法兰过渡圆角 --------
Part.ClearSelection2 True
If Part.Extension.SelectByID2("", "EDGE", R_ROOT, 0, P_FLANGE_T, False, 0, Nothing, 0) Then
    ok = fm.FeatureFillet(0, P_FILLET, 0, 0, Nothing, Nothing, Nothing)
End If

'-------- 8. 法兰螺栓孔 --------
Part.ClearSelection2 True
If Part.Extension.SelectByID2("", "FACE", P_FLANGE_D / 2 - 0.003, 0, P_FLANGE_T, False, 0, Nothing, 0) Then
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

'-------- 9. 保存 --------
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
