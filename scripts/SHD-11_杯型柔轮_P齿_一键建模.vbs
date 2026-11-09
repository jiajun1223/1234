Option Explicit
'==============================================================
' §Ô???????? ???????? ?????? (?????????????? P??)
' ????? + ??????? + ?????????? (???/???????????)
'==============================================================
'------------------- ?????? (??¦Ë: ??) -------------------
Const P_M        = 0.0001016   ' ??? (??? ?20.32)
Const P_Z        = 200         ' ????
Const P_HA       = 0.90        ' ????????
Const P_HF       = 0.90        ' ????????
Const P_PER      = 24          ' ?????????
Const P_WALL     = 0.00030     ' ????
Const P_FLANGE_D = 0.040       ' ??????
Const P_FLANGE_T = 0.002       ' ??????
Const P_TOP      = 0.012       ' ???
Const P_BAND     = 0.0040      ' ????¦Ã???
Const P_FILLET   = 0.0010      ' ???/???????????
Const P_BOLT_N   = 16
Const P_BOLT_D   = 0.003
Const P_BOLT_PCD = 0.034
Const P_FILE     = "D:\????\AI??ýn?\SHD-11_P?????????.SLDPRT"
'---------------------------------------------------
Const PI = 3.14159265358979

Dim swApp, swModel, Part, skMgr, fm
Dim R_P, R_TIP, R_ROOT, H_T, TH_P, TH_H, R_BORE, RF, R_MID
Dim i, k, idx, nOut, ok, tryN, pass
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
    WScript.Echo "ERROR: ¦Ä????? SolidWorks"
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
R_MID = R_ROOT * 0.5

Dim tpl
tpl = swApp.GetUserPreferenceStringValue(8)
If Len(tpl) = 0 Then tpl = "C:\ProgramData\SolidWorks\SOLIDWORKS 2016\templates\gb_part.prtdot"

swApp.CommandInProgress = True
Set swModel = swApp.NewDocument(tpl, 0, 0, 0)
If Not IsObject(swModel) Then
    swApp.CommandInProgress = False
    WScript.Echo "ERROR: ?????????"
    WScript.Quit 1
End If
Set Part = swModel
Set skMgr = Part.SketchManager
Set fm = Part.FeatureManager
On Error Resume Next
Part.ActiveView.EnableGraphicsUpdate = False
On Error Goto 0

'-------- 1. ?????????? (???? + ??????? + ???) --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "????????", "PLANE", 0, 0, 0, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateLine 0, 0, 0, RF, 0, 0
skMgr.CreateLine RF, 0, 0, RF, -P_FLANGE_T, 0
skMgr.CreateLine RF, -P_FLANGE_T, 0, R_ROOT, -P_FLANGE_T, 0
skMgr.CreateLine R_ROOT, -P_FLANGE_T, 0, R_ROOT, -P_TOP, 0
skMgr.CreateLine R_ROOT, -P_TOP, 0, 0, -P_TOP, 0
skMgr.CreateLine 0, -P_TOP, 0, 0, 0, 0
Dim AX
Set AX = skMgr.CreateCenterLine(0, 0, 0, 0, -P_TOP, 0)
skMgr.InsertSketch True
Part.ClearSelection2 True
AX.Select4 True, Nothing
ok = fm.FeatureRevolve2(True, True, False, False, False, False, 0, 0, 2 * PI, 0, False, False, 0, 0, 0, 0, 0, True, True, True)

'-------- 2. ??? (?????????????) --------
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

'-------- 3. ????? --------
Part.ClearSelection2 True
Part.Extension.SelectByID2 "", "FACE", R_MID, 0, P_TOP, False, 0, Nothing, 0
skMgr.InsertSketch True
skMgr.CreateCircleByRadius 0, 0, 0, R_BORE
skMgr.InsertSketch True
ok = fm.FeatureCut3(True, False, False, 1, 0, 0.01, 0.01, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False)

Part.ClearSelection2 True
Part.EditRebuild3
On Error Resume Next
Part.ActiveView.EnableGraphicsUpdate = True
On Error Goto 0
swApp.CommandInProgress = False

'-------- 4. ????????, ???????????? --------
Dim errs, warns, res
errs = 0 : warns = 0
res = Part.Extension.SaveAs(P_FILE, 0, 1, Nothing, errs, warns)
swApp.CloseDoc Part.GetTitle
WScript.Sleep 800

Dim err2, warn2
err2 = 0 : warn2 = 0
Set Part = swApp.OpenDoc6(P_FILE, 1, 1, "", err2, warn2)
If Not IsObject(Part) Then
    WScript.Echo "ERROR: ??????"
    WScript.Quit 1
End If
Set skMgr = Part.SketchManager
Set fm = Part.FeatureManager
swApp.CommandInProgress = True
On Error Resume Next
Part.ActiveView.EnableGraphicsUpdate = False
On Error Goto 0

For pass = 1 To 3
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

errs = 0 : warns = 0
res = Part.Extension.SaveAs(P_FILE, 0, 1, Nothing, errs, warns)
WScript.Echo "DONE: " & P_FILE & "  err=" & errs
