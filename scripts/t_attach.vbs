Option Explicit
Dim swApp, p1, p2, t0
On Error Resume Next
Set swApp = GetObject(, "SldWorks.Application")
If Err.Number <> 0 Then
  WScript.Echo "GetObject 失败(" & Err.Description & "), 尝试连接已运行实例..."
  Err.Clear
  Set swApp = CreateObject("SldWorks.Application")
End If
On Error Goto 0
If swApp Is Nothing Then
  WScript.Echo "无法连接 SolidWorks"
  WScript.Quit 1
End If
WScript.Echo "连接成功 rev=" & swApp.RevisionNumber()
Set p1 = GetObject("winmgmts:").ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name = 'SLDWORKS.exe'")
For Each p2 In p1: t0 = t0 & p2.ProcessId & " ": Next
WScript.Echo "当前 SLDWORKS 进程: " & t0