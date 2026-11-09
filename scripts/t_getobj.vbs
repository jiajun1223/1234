Option Explicit
Dim svc, procs, p, swApp, pid
Set svc = GetObject("winmgmts:")
Set procs = svc.ExecQuery("SELECT ProcessId FROM Win32_Process WHERE Name = 'SLDWORKS.exe'")
pid = 0
For Each p In procs
  pid = p.ProcessId
Next
WScript.Echo "PID=" & pid
On Error Resume Next
Set swApp = GetObject("SolidWorks_PID_" & pid)
If Err.Number <> 0 Then
  WScript.Echo "moniker FAIL: " & Err.Description
  Err.Clear
Else
  WScript.Echo "moniker OK rev=" & swApp.RevisionNumber()
End If
On Error Goto 0