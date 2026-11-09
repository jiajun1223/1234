Option Explicit
Dim s, pid, o
pid = 432
Test "SldWorks.Application", 1
Test "!SolidWorks_PID_" & pid, 2
Test "clsid:0a5bc87b-fdbf-4a0b-bc8a-de1271220e81", 3
Test "SolidWorks_PID_" & pid, 4

Sub Test(name, mode)
  Dim obj, errDesc
  On Error Resume Next
  Err.Clear
  If mode = 1 Then
    Set obj = GetObject(, name)
  Else
    Set obj = GetObject(name)
  End If
  errDesc = Err.Description
  If Err.Number <> 0 Or obj Is Nothing Then
    WScript.Echo mode & " [" & name & "] FAIL " & errDesc
  Else
    WScript.Echo mode & " [" & name & "] OK rev=" & obj.RevisionNumber()
  End If
  On Error Goto 0
End Sub