Option Explicit
'==============================================================
' 礼帽(外翻法兰)柔轮 — 轴向渐变壁厚 一键建模
' 法兰厚(刚性) -> 平缓腹板 -> 筒壁由厚渐薄 -> 齿圈最薄
'==============================================================
'------------------- 参数区 (单位: 米) -------------------
Const P_M        = 0.0001225
Const P_Z        = 200
Const P_HA       = 0.90
Const P_HF       = 0.90
Const P_PER      = 24
Const P_WALL_TOP = 0.00035     ' 齿圈段壁厚(最薄)
Const P_WALL_BOT = 0.00100     ' 筒体根部壁厚(较厚)
Const P_FLANGE_D = 0.046
Const P_FLANGE_T = 0.003
Const P_TOP      = 0.014
Const P_WEB_Z    = 0.0052      ' 腹板结束高度
Const P_WEB_R    = 0.0140      ' 腹板起点半径
Const P_BAND     = 0.0040
Const P_BOLT_N   = 12
Const P_BOLT_D   = 0.0035
Const P_BOLT_PCD = 0.040
Const P_FILE     = "D:\桌面\AI实验建模\LCS-14_礼帽柔轮_渐变壁厚.SLDPRT"
'---------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_TIP, R_ROOT, H_T, TH_P, TH_H, R_TOP_IN, R_BOT_IN, RF, R_MID
Dim i, k, idx, nOut, ok, tryN, retry
Dim ring(), sp()
Dim cb, sb, s, rr, ang, px, py

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
    WScript.Echo "ERROR: 未能附着 SolidWorks"
    WScript.Quit 1
End If

R_P = P_M * P_Z / 2
R_TIP = R_P + P_HA * P_M
R_ROOT = R_P - P_HF * P_M
H_T = R_TIP - R_ROOT
TH_P = 2 * PI / P_Z
TH_H = TH_P / 2
R_TOP_IN = R_ROOT - P_WALL_TOP
R_BOT_IN = R_ROOT - P_WALL_BOT
RF = P_FLANGE_D / 2
R_MID = (R_TOP_IN + R_ROOT) / 2

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

'-------- 1. 渐变壁厚旋转基体 (x=r, y=-z) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "上视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateLine R_BOT_IN, 0, 0, RF, 0, 0
skMgr.CreateLine RF, 0, 0, RF, -P_FLANGE_T, 0
skMgr.CreateLine RF, -P_FLANGE_T, 0, P_WEB_R, -P_FLANGE_T, 0
sp = Array(P_WEB_R, -P_FLANGE_T, 0, 0.0132, -0.0037, 0, 0.0126, -0.0045, 0, R_ROOT, -P_WEB_Z, 0)
skMgr.CreateSpline sp
skMgr.CreateLine R_ROOT, -P_WEB_Z, 0, R_ROOT, -P_TOP, 0
skMgr.CreateLine R_ROOT, -P_TOP, 0, R_TOP_IN, -P_TOP, 0
sp = Array(R_TOP_IN, -P_TOP, 0, 0.01160, -0.0120, 0, 0.01142, -0.0098, 0, 0.01128, -0.0078, 0, R_BOT_IN, -P_WEB_Z, 0)
skMgr.CreateSpline sp
skMgr.CreateLine R_BOT_IN, -P_WEB_Z, 0, R_BOT_IN, 0, 0
Dim AX
Set AX = skMgr.CreateCenterLine(0, 0, 0, 0, -P_TOP, 0)
skMgr.InsertSketch True
Part.ClearSelection2 True
AX.Select4 True, Nothing
ok = fm.FeatureRevolve2(True, True, False, False, False, False, 0, 0, 2 * PI, 0, False, False, 0, 0, 0, 0, 0, True, True, True)

'-------- 2. 齿圈 --------
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
skMgr.CreateCircleByRadius 0, 0, 0, R_TOP_IN + 0.0002
skMgr.InsertSketch True
ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)
Part.EditRebuild3

'-------- 4. 法兰螺栓通孔 (带重试) --------
For retry = 1 To 3
    Part.ClearSelection2 True
    If Part.Extension.SelectByID2("", "FACE", R_MID, 0, P_TOP, False, 0, Nothing, 0) Then
        skMgr.InsertSketch True
        For i = 0 To P_BOLT_N - 1
            ang = i * 2 * PI / P_BOLT_N
            skMgr.CreateCircleByRadius P_BOLT_PCD / 2 * Cos(ang), P_BOLT_PCD / 2 * Sin(ang), 0, P_BOLT_D / 2
        Next
        skMgr.InsertSketch True
        ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)
        If Not IsNull(ok) Then Exit For
        Part.EditRebuild3
    End If
Next

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
