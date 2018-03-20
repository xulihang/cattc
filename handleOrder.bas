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
	If req.Method <> "POST" Then
		resp.SendError(500, "method not supported.")
		Return
	End If
	'we need to call req.InputStream before calling GetParameter.
	'Otherwise the stream will be read internally (as the parameter might be in the post body).
	Dim In As InputStream = req.InputStream
	Dim filename As String
	filename=DateTime.Now&".json"
	Dim out As OutputStream = File.OpenOutput(File.DirApp,filename, False)
	File.Copy2(In, out)
	out.Close
	getIfSucceed(filename)
	resp.Write("File received successfully.")
End Sub

Sub getIfSucceed(filename As String)
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.DirApp,filename))

	Dim map1,map2,map3,map4 As Map
	Dim list1 As List
	map1=json.NextObject
	list1=map1.Get("events")
	map2=list1.Get(0)
	map3=map2.Get("data")
	If map3.Get("completed")=True Then
	    map4=map3.Get("customer")
	    Log(map4.Get("email"))
		File.Copy(File.DirApp,filename,File.Combine(File.DirApp,"reciept"),map4.Get("email")&".json")
		File.Delete(File.DirApp,filename)
		changePaid(map4.Get("email"))
	End If
End Sub

Sub changePaid(email As String)
	If ABMShared.kvs.IsInitialized=False Then
		ABMShared.kvs.Initialize(File.DirApp,"users.db")
	End If
	Dim map2 As Map
	map2=ABMShared.kvs.Get(email)
	map2.Put("paid","已付款")
	ABMShared.kvs.Put(email,map2)
End Sub