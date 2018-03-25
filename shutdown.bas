B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.01
@EndOfDesignText@
'Handler class
Sub Class_Globals

End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)

	Log(req.GetSession.GetAttribute2("authName", ""))
	If req.GetSession.GetAttribute2("authName", "")=File.ReadString(File.DirApp,"admin.conf") Then
		ABMShared.kvs.Close
		ExitApplication
		resp.Write("shuting down...")
	Else
		resp.Write("not logined")
	End If
End Sub