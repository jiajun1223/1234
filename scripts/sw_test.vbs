On Error Resume Next
Dim sw, t0
WScript.Echo "start " & Now
Set sw = CreateObject("SldWorks.Application")
If Err.Number <> 0 Then
  WScript.Echo "CreateObject failed: 0x" & Hex(Err.Number) & " " & Err.Description
  WScript.Quit 1
End If
WScript.Echo "created rev=" & sw.RevisionNumber
sw.Visible = True
WScript.Echo "visible ok, docs=" & sw.GetDocumentCount()
WScript.Echo "done " & Now
