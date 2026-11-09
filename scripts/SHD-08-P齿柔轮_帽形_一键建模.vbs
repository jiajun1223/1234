Option Explicit
'==============================================================
' 帽形(礼帽型)谐波柔轮 一键建模   m=0.105  Z=200
' 轴向厚度渐变: 厚法兰 -> 光滑腹板 -> 薄壁筒 -> 齿圈
'==============================================================
'------------------- 参数区 (单位: 米) -------------------
Const P_M        = 0.000105   ' 模数
Const P_Z        = 200        ' 齿数
Const P_HA       = 0.90       ' 齿顶高系数
Const P_HF       = 0.90       ' 齿根高系数
Const P_PER      = 24         ' 单齿采样点
Const P_FLANGE_D = 0.040      ' 法兰外径
Const P_FLANGE_T = 0.002      ' 法兰厚度
Const P_TOP      = 0.012      ' 总高
Const P_WALL     = 0.0003     ' 筒壁厚 (齿圈段基体)
Const P_BAND     = 0.0035     ' 齿圈段长度
Const P_WEB_TOP  = 0.0070     ' 腹板过渡终点高度
Const P_BOLT_N   = 16
Const P_BOLT_D   = 0.003
Const P_BOLT_PCD = 0.034
Const P_FILE     = "D:\桌面\AI实验建模\SHD-08-P齿柔轮_帽形_m0.105.SLDPRT"
'---------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_TIP, R_ROOT, H_T, TH_P, TH_H, R_BORE, R_MID
Dim i, k, idx, nOut, ok, tryN
Dim ring(), sp(), web()
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

'-------- 1. 帽形旋转轮廓 (x=r, y=-z) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "上视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0
skMgr.InsertSketch True
' 底部: 内孔 -> 外径
skMgr.CreateLine R_BORE, 0, 0, P_FLANGE_D / 2, 0, 0
' 法兰外圆柱
skMgr.CreateLine P_FLANGE_D / 2, 0, 0, P_FLANGE_D / 2, -P_FLANGE_T, 0
' 腹板光滑样条 (厚 -> 薄)
web = Array(0.0200, 0.0020, 0.0185, 0.0020, 0.0170, 0.0021, 0.0155, 0.0024, _
            0.0140, 0.0030, 0.0128, 0.0039, 0.0119, 0.0050, 0.0112, 0.0060, _
            0.0107, 0.0068, R_ROOT, P_WEB_TOP)
ReDim sp(UBound(web) / 2 * 3 + 2)
idx = 0
For i = 0 To UBound(web) Step 2
    sp(idx) = web(i) : sp(idx + 1) = -web(i + 1) : sp(idx + 2) = 0
    idx = idx + 3
Next
skMgr.CreateSpline sp
' 薄壁筒
skMgr.CreateLine R_ROOT, -P_WEB_TOP, 0, R_ROOT, -P_TOP, 0
' 顶面 + 内孔
skMgr.CreateLine R_ROOT, -P_TOP, 0, R_BORE, -P_TOP, 0
skMgr.CreateLine R_BORE, -P_TOP, 0, R_BORE, 0, 0
Dim ax
Set ax = skMgr.CreateCenterLine(0, 0, 0, 0, -P_TOP, 0)
skMgr.InsertSketch True
Part.ClearSelection2 True
ax.Select4 True, Nothing
ok = fm.FeatureRevolve2(True, True, False, False, False, False, 0, 0, 2 * PI, 0, False, False, 0, 0, 0, 0, 0, True, True, True)

'-------- 2. 齿圈 (顶面向下拉伸齿廓) --------
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

'-------- 3. 内孔复切 (齿圈段) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", R_MID, 0, P_TOP, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, R_BORE
skMgr.InsertSketch True
ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)

'-------- 4. 法兰螺栓孔 (顶面贯穿) --------
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
