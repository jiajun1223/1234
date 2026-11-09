Option Explicit
'==================================================================
' 谐波减速器 杯型柔轮 一键建模 (无公切线全光滑双圆弧 S 齿廓)
'==================================================================
'---------------- 参数区 (单位: 米) ----------------
Const P_M          = 0.0001016
Const P_Z          = 200
Const P_HA         = 0.90
Const P_HF         = 0.90
Const P_SMOOTH     = 12
Const P_FLANGE_D   = 0.040
Const P_FLANGE_T   = 0.002
Const P_CUP_LEN    = 0.012
Const P_WALL       = 0.0003
Const P_BAND       = 0.0035
Const P_BOLT_N     = 16
Const P_BOLT_D     = 0.003
Const P_BOLT_PCD   = 0.034
Const P_FILLET_R   = 0.0010
Const P_OVERLAP    = 0.00015
Const P_FILE       = "D:\桌面\AI实验建模\SHD-08-P齿柔轮.SLDPRT"
'--------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_TIP, R_ROOT, H_TOOTH, THETA_P, THETA_H, R_BORE, R_RING_IN
Dim i, k, idx, nPts, ang, tt, rr, cs, sn, px, py

Set swApp = GetObject(, "SldWorks.Application")
If swApp Is Nothing Then
    WScript.Echo "ERROR: 未找到 SolidWorks"
    WScript.Quit 1
End If

R_P = P_M * P_Z / 2
R_TIP = R_P + P_HA * P_M
R_ROOT = R_P - P_HF * P_M
H_TOOTH = R_TIP - R_ROOT
THETA_P = 2 * PI / P_Z
THETA_H = THETA_P / 2
R_BORE = R_ROOT - P_WALL
R_RING_IN = R_ROOT - P_OVERLAP

Dim tpl
tpl = swApp.GetUserPreferenceStringValue(8)
If Len(tpl) = 0 Then tpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2016\templates\gb_part.prtdot"

swApp.CommandInProgress = True
Set swModel = swApp.NewDocument(tpl, 0, 0, 0)
If swModel Is Nothing Then
    swApp.CommandInProgress = False
    WScript.Echo "ERROR: NewDocument 失败"
    WScript.Quit 1
End If
Set Part = swModel
Set skMgr = Part.SketchManager
Set fm = Part.FeatureManager
On Error Resume Next
Part.ActiveView.EnableGraphicsUpdate = False
On Error Goto 0

'-------- 1. 单齿轮廓 (S 齿廓: 齿顶凸弧 -> 齿侧凹弧 -> 齿槽凹弧) --------
Dim tx(), ty()
ReDim tx(P_SMOOTH * 2)
ReDim ty(P_SMOOTH * 2)
For i = 0 To P_SMOOTH
    tt = i / P_SMOOTH
    rr = R_ROOT + H_TOOTH * (1 + Cos(PI * tt)) / 2
    ang = THETA_H * tt
    tx(i) = rr * Cos(ang)
    ty(i) = rr * Sin(ang)
Next
For i = 1 To P_SMOOTH
    tx(P_SMOOTH + i) = tx(P_SMOOTH - i)
    ty(P_SMOOTH + i) = -ty(P_SMOOTH - i)
Next

Call OpenPlane()
Dim sPts()
ReDim sPts(P_SMOOTH * 2 * 3 + 2)
idx = 0
For i = 0 To P_SMOOTH * 2
    sPts(idx) = tx(i) : sPts(idx + 1) = ty(i) : sPts(idx + 2) = 0
    idx = idx + 3
Next
skMgr.InsertSketch True
skMgr.CreateSpline sPts
skMgr.InsertSketch True

'-------- 2. 圆周阵列 200 齿 --------
nPts = P_SMOOTH * 2 * P_Z
Dim ringPts()
ReDim ringPts(nPts * 3 + 2)
idx = 0
For k = 0 To P_Z - 1
    cs = Cos(k * THETA_P) : sn = Sin(k * THETA_P)
    For i = 0 To P_SMOOTH * 2 - 1
        px = tx(i) * cs - ty(i) * sn
        py = tx(i) * sn + ty(i) * cs
        ringPts(idx) = px : ringPts(idx + 1) = py : ringPts(idx + 2) = 0
        idx = idx + 3
    Next
Next
ringPts(idx) = ringPts(0) : ringPts(idx + 1) = ringPts(1) : ringPts(idx + 2) = 0

Call OpenPlane()
skMgr.InsertSketch True
skMgr.CreateSpline ringPts
skMgr.CreateCircleByRadius 0, 0, 0, R_RING_IN
skMgr.InsertSketch True
Dim ok
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, P_BAND, P_BAND, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 1, P_CUP_LEN - P_BAND, False)
If ok Is Nothing Then WScript.Echo "WARN: 齿圈拉伸失败"

'-------- 3. 筒体 --------
Call OpenPlane()
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, R_ROOT
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, P_CUP_LEN - P_FLANGE_T, P_CUP_LEN - P_FLANGE_T, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 1, P_FLANGE_T, False)
If ok Is Nothing Then WScript.Echo "WARN: 筒体拉伸失败"

'-------- 4. 法兰 --------
Call OpenPlane()
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, P_FLANGE_D / 2
skMgr.InsertSketch True
ok = fm.FeatureExtrusion2(True, False, False, 0, 0, P_FLANGE_T, P_FLANGE_T, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
If ok Is Nothing Then WScript.Echo "WARN: 法兰拉伸失败"

'-------- 5. 内孔 (旋转切除) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "上视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateLine 0, -P_FLANGE_T, 0, R_BORE, -P_FLANGE_T, 0
skMgr.CreateLine R_BORE, -P_FLANGE_T, 0, R_BORE, -P_CUP_LEN, 0
skMgr.CreateLine R_BORE, -P_CUP_LEN, 0, 0, -P_CUP_LEN, 0
skMgr.CreateLine 0, -P_CUP_LEN, 0, 0, -P_FLANGE_T, 0
Dim cl
Set cl = skMgr.CreateCenterLine(0, 0, 0, 0, -P_CUP_LEN, 0)
skMgr.InsertSketch True
Part.ClearSelection2 True
cl.Select4 True, Nothing
ok = fm.FeatureRevolve2(True, True, False, True, False, False, 0, 0, 2 * PI, 0, False, False, 0, 0, 0, 0, 0, True, True, True)
If ok Is Nothing Then WScript.Echo "WARN: 内孔失败"

'-------- 6. 筒壁/法兰过渡圆角 --------
Part.ClearSelection2 True
If Part.Extension.SelectByID2("", "EDGE", R_ROOT, 0, P_FLANGE_T, False, 0, Nothing, 0) Then
    ok = fm.FeatureFillet(0, P_FILLET_R, 0, 0, Nothing, Nothing, Nothing)
    If ok Is Nothing Then WScript.Echo "WARN: 圆角失败"
End If

'-------- 7. 法兰螺栓孔 --------
Part.ClearSelection2 True
If Part.Extension.SelectByID2("", "FACE", P_FLANGE_D / 2 - 0.003, 0, P_FLANGE_T, False, 0, Nothing, 0) Then
    skMgr.InsertSketch True
    For i = 0 To P_BOLT_N - 1
        ang = i * 2 * PI / P_BOLT_N
        skMgr.CreateCircleByRadius P_BOLT_PCD / 2 * Cos(ang), P_BOLT_PCD / 2 * Sin(ang), 0, P_BOLT_D / 2
    Next
    skMgr.InsertSketch True
    ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)
    If ok Is Nothing Then WScript.Echo "WARN: 螺栓孔失败"
End If

Part.ClearSelection2 True
Part.EditRebuild3
On Error Resume Next
Part.ViewZoomtofit2
On Error Goto 0
swApp.CommandInProgress = False

'-------- 8. 保存 --------
Dim errs, warns, res
errs = 0 : warns = 0
res = Part.Extension.SaveAs(P_FILE, 0, 1, Nothing, errs, warns)
WScript.Echo "DONE: " & P_FILE & "  err=" & errs & "  warn=" & warns & "  res=" & CStr(res)

'==========================================================
Sub OpenPlane()
    Part.ClearSelection2 True
    If Not Part.Extension.SelectByID2("前视基准面", "PLANE", 0, 0, 0, False, 0, Nothing, 0) Then
        If Not Part.Extension.SelectByID2("Front Plane", "PLANE", 0, 0, 0, False, 0, Nothing, 0) Then
            WScript.Echo "ERROR: 选不到前视基准面"
        End If
    End If
    skMgr.InsertSketch True
End Sub
