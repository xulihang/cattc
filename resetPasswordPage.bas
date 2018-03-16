B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.01
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private ws As WebSocket 'ignore
	' will hold our page information
	Public page As ABMPage
	' page theme
	Private theme As ABMTheme
	' to access the constants
	Private ABM As ABMaterial 'ignore
	' name of the page, must be the same as the class name (case sensitive!)
	Public Name As String = "resetPasswordPage"
	' name of the app, same as in ABMApplication
'	Public AppName As String = "template"
	
	Private ABMPageId As String = ""
	' your own variables
	Private email As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	' build the local structure IMPORTANT!
	BuildPage
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	'----------------------MODIFICATION-------------------------------
	Log("Home Page Connected")
	ws = WebSocket1
	ABMPageId = ABM.GetPageID(page, Name,ws)
	
	If File.Exists(File.DirApp,"EmailToBeReset")=False Then '避免其它人修改密码
		ABMShared.NavigateToPage(ws, ABMPageId, "../")
		Return
	End If
	
	Dim session As HttpSession = ABM.GetSession(ws, ABMShared.SessionMaxInactiveIntervalSeconds)
	If session.IsNew Then
		session.Invalidate
		ABMShared.NavigateToPage(ws, "", "./")
		Return
	End If
	
	
	' Set needs auth to false.  These are public pages....
	ABMShared.NeedsAuthorization = False
	
	
	' This section is skipped when auth not required...
	If ABMShared.NeedsAuthorization Then
		If session.GetAttribute2("IsAuthorized", "") = "" Then
			Log(" Do I need to login?")
			ABMShared.NavigateToPage(ws, ABMPageId, "../")
			Return
		End If
	End If
	
	
	
	ABM.UpdateFromCache(Me, ABMShared.CachedPages, ABMPageId, ws)
	If page.ComesFromPageCache Then
		' when we have a page that is cached it doesn't matter if it comes or not from a new connection we serve the cached version.
		Log("Comes from cache")
		page.Refresh
		page.FinishedLoading
	Else
		If page.WebsocketReconnected Then
			Log("Websocket reconnected")
			' when we have a client that doesn't have the page in cache and it's websocket reconnected and also it's session is new - basically when the client had internet problems and it's session (and also cache) expired before he reconnected so the user has content in the browser but we don't have any on the server. So we need to reload the page.
			' when a client that doesn't have the page in cache and it's websocket reconnected but it's session is not new - when the client had internet problems and when he reconnected it's session was valid but he had no cache for this page we need to reload the page as the user browser has content, reconnected but we have no content in cache
			ABMShared.NavigateToPage (ws, ABMPageId, "./" & page.PageHTMLName)
		Else
			' when the client did not reconnected it doesn't matter if the session was new or not because this is the websockets first connection so no dynamic content in the browser ... we are going to serve the dynamic content...
			Log("Websocket first connection")
			page.Prepare
			ConnectPage
		End If
	End If
	Log("  -- This Page ID: "&ABMPageId)
End Sub

Private Sub WebSocket_Disconnected
	Log("Disconnected")
End Sub

Sub Page_ParseEvent(Params As Map)
	Dim eventName As String = Params.Get("eventname")
	Dim eventParams() As String = Regex.Split(",",Params.Get("eventparams"))
	If eventName = "beforeunload" Then
		Log("preparing for url refresh")
		ABM.RemoveMeFromCache(ABMShared.CachedPages, ABMPageId)
		Return
	End If
	
	'  Very Helpful to log control clicks and discover what params are required - and such !!!!
	Log(" *** Page Event name: "&eventName&"  "&Params) ' this is used to see what component was clicked and what the parameters are...
	
	
	Dim caller As Object = page.GetEventHandler(Me, eventName)
	If caller = Me Then
		If SubExists(Me, eventName) Then
			Params.Remove("eventname")
			Params.Remove("eventparams")
			' BEGIN NEW DRAGDROP
			If eventName = "page_dropped" Then
				page.ProcessDroppedEvent(Params)
			End If
			' END NEW DRAGDROP
			Select Case Params.Size
				Case 0
					CallSub(Me, eventName)
				Case 1
					CallSub2(Me, eventName, Params.Get(eventParams(0)))
				Case 2
					If Params.get(eventParams(0)) = "abmistable" Then
						Dim PassedTables As List = ABM.ProcessTablesFromTargetName(Params.get(eventParams(1)))
						CallSub2(Me, eventName, PassedTables)
					Else
						CallSub3(Me, eventName, Params.Get(eventParams(0)), Params.Get(eventParams(1)))
					End If
				Case Else
					' cannot be called directly, to many param
					CallSub2(Me, eventName, Params)
			End Select
		End If
	Else
		CallSubDelayed2(caller, "ParseEvent", Params) 'ignore
	End If
End Sub

public Sub BuildTheme()
	
	' start with the base theme defined in ABMShared Code Module
	' Private theme As ABMTheme   -  in class_globals above...

	theme.Initialize("pagetheme")

	theme.AddABMTheme(ABMShared.MyTheme)

End Sub


Sub ConnectPage()

	
	' ConnectNavigationBar2 is purposely built for public pages... It does not require a login to view
	
	'ABMShared.ConnectNavigationBar(page)
	
    Dim emailinp As ABMInput
	emailinp.Initialize(page,"emailinp",ABM.INPUT_EMAIL,"邮箱：",False,"")
	email=File.ReadString(File.DirApp,"EmailToBeReset")
	emailinp.Text=email
	emailinp.Enabled=False
	File.Delete(File.DirApp,"EmailToBeReset") '避免其它人再修改
	Dim pwd1 As ABMInput
	pwd1.Initialize(page,"pwd1inp",ABM.INPUT_PASSWORD,"请输入新密码：",False,"")
	Dim pwd2 As ABMInput
	pwd2.Initialize(page,"pwd2inp",ABM.INPUT_PASSWORD,"请再输入新密码：",False,"")
	Dim btn1 As ABMButton
	btn1.InitializeFlat(page, "btn1", "", "", "提交", "transparent")
	page.Cell(1,1).AddComponent(emailinp)
	page.Cell(2,1).AddComponent(pwd1)
	page.Cell(3,1).AddComponent(pwd2)
	page.Cell(4,1).AddComponent(btn1)
	page.Refresh ' IMPORTANT
 
	page.RestoreNavigationBarPosition

	' NEW, because we use ShowLoaderType=ABM.LOADER_TYPE_MANUAL
	page.FinishedLoading 'IMPORTANT
	
End Sub

public Sub BuildPage()
	' initialize the theme
	BuildTheme
	page.InitializeWithTheme(Name, "/ws/" & ABMShared.AppName & "/" & Name, False, ABMShared.SessionMaxInactiveIntervalSeconds, theme)
	
	' show the spinning cicles while page is loading....
	page.ShowLoader=True
	page.PageHTMLName = "index.html"
	page.PageTitle = "重制密码"  ' You can also set this as a property in "ABMShared.BuildNavigationBar" below...
	
	'  Google SEO stuff...
	page.PageDescription = ""
	page.PageKeywords = ""
	page.PageSiteMapPriority = ""
	page.PageSiteMapFrequency = ABM.SITEMAP_FREQ_YEARLY
		
	' faint green dot (on title bar) when connected - red when not connected with web socket
	page.ShowConnectedIndicator = True
	
	ABMShared.BuildNavigationBarextra(page,  "重制密码","../images/logo.png", "Home", "Home", "Home")
	
	page.AddRows(4,True,"").AddCells12(1,"")
	page.BuildGrid ' IMPORTANT!
End Sub

' clicked on the navigation bar
Sub Page_NavigationbarClicked(Action As String, Value As String)
	' saving the navigation bar position
	page.SaveNavigationBarPosition
End Sub

Sub btn1_Clicked(Target As String)
	'Dim emailinp As ABMInput= page.Component("emailinp") 就不从页面获取了
	Dim pwd1inp As ABMInput= page.Component("pwd1inp")
	Dim pwd2inp As ABMInput= page.Component("pwd2inp")
	Log(pwd1inp.Text)
    If pwd1inp.Text=pwd2inp.Text Then
		changePwd(email,pwd1inp.Text)
		page.Msgbox("","密码修改成功","通知","好的",False,ABM.MSGBOX_POS_CENTER_CENTER,"redmsgbox")
	    Sleep(1000)
		ABMShared.NavigateToPage(ws,ABMPageId,"../HomePage")
	Else
		page.Msgbox("","密码不一致","错误","好的",False,ABM.MSGBOX_POS_CENTER_CENTER,"redmsgbox")
    End If

End Sub

Sub changePwd(emailaccount As String,pwd As String)
	Dim jsonp As JSONParser
	Dim jsong As JSONGenerator
	If File.Exists(File.DirApp,"users.json") Then
		jsonp.Initialize(File.ReadString(File.DirApp,"users.json"))
		Dim map1,map2 As Map
		map1=jsonp.NextObject
		map2=map1.Get(emailaccount)
		map2.Put("password",pwd)
		jsong.Initialize(map1)
		File.WriteString(File.DirApp,"users.json",jsong.ToString)
	End If
End Sub