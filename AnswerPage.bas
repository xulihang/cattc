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
	Public Name As String = "AnswerPage"
	' name of the app, same as in ABMApplication
'	Public AppName As String = "template"
	
	Private ABMPageId As String = ""
	' your own variables
	
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
	
	Dim session As HttpSession = ABM.GetSession(ws, ABMShared.SessionMaxInactiveIntervalSeconds)
	If session.IsNew Then
		session.Invalidate
		ABMShared.NavigateToPage(ws, "", "./")
		Return
	End If
	
	
	' Set needs auth to false.  These are public pages....
	ABMShared.NeedsAuthorization = True
	
	
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

	ABMShared.enableMultilanguage(ws,page)
	' ConnectNavigationBar2 is purposely built for public pages... It does not require a login to view
	If ws.Session.HasAttribute("IsAuthorized") And ws.Session.GetAttribute("IsAuthorized")="true" Then
		ABMShared.ConnectNavigationBarLoginedWithTitle(page,"答题情况")
	Else
		Return
	End If

	Dim tabs As ABMTabs
	tabs.Initialize(page, "tabs", "redTabs")
	tabs.AddTab("tab1",page.XTR("0001","汉译英"),BuildTabContainer("tab1","汉译英"),4,4,4,12,12,12,True,True,"","")
	tabs.AddTab("tab2",page.XTR("0002","英译汉"),BuildTabContainer("tab2","英译汉"),4,4,4,12,12,12,True,True,"","")
	tabs.AddTab("tab3",page.XTR("0003","技术传播"),BuildTabContainer("tab3","技术传播"),4,4,4,12,12,12,True,True,"","")
	
	page.Cell(1,1).AddComponent(tabs)
	Dim statusinp As ABMInput
	statusinp.Initialize(page,"inp",ABM.INPUT_TEXT,"状态：",False,"redInput")
	statusinp.Text="未提交"
	statusinp.Enabled=False
	Dim scoreinp As ABMInput
	scoreinp.Initialize(page,"inp",ABM.INPUT_TEXT,"分数：",False,"redInput")
	scoreinp.Text="未出成绩"
	scoreinp.Enabled=False
	Dim submitBtn As ABMButton
	submitBtn.InitializeFlat(page,"submitBtn","","","提交最终作品","redbtn1")
	page.Cell(2,1).AddComponent(statusinp)
	page.Cell(2,2).AddComponent(scoreinp)
	page.Cell(3,1).AddComponent(submitBtn)
	
	loadSaved
	If File.Exists(File.Combine(File.DirApp,"submitted"),ws.Session.GetAttribute("authName")&".json") Then
		statusinp.Text="已提交"
	End If
	If File.Exists(File.Combine(File.DirApp,"submitted"),ws.Session.GetAttribute("authName")&"-score.json") Then
		Dim json As JSONParser
		json.Initialize(File.ReadString(File.Combine(File.DirApp,"submitted"),ws.Session.GetAttribute("authName")&"-score.json"))
		Dim map1 As Map
		map1=json.NextObject
		Dim score As String
		Dim total As Int
		For Each key As String In map1.Keys
			Dim singlescore As Int
			singlescore=map1.Get(key)
			score=score&key&":"&singlescore&" "
			total=total+singlescore
		Next
		score=score&"总分："&total
		scoreinp.Text=score
	End If
	
	ABMShared.ConnectFooter(page)
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
	page.PageTitle = "翻译大赛 CATTCC"  ' You can also set this as a property in "ABMShared.BuildNavigationBar" below...
	
	'  Google SEO stuff...
	page.PageDescription = ""
	page.PageKeywords = ""
	page.PageSiteMapPriority = ""
	page.PageSiteMapFrequency = ABM.SITEMAP_FREQ_YEARLY
		
	' faint green dot (on title bar) when connected - red when not connected with web socket
	page.ShowConnectedIndicator = True
	
	ABMShared.BuildNavigationBarextra(page,  "答题情况","../images/logo.png", "Home", "Home", "Home")
	
	page.AddRows(1,True,"").AddCells12(1,"")
	page.AddRows(1,True,"").AddCellsOS(2,0,0,0,7,7,7,"")
	page.AddRows(1,True,"").AddCellsOS(1,0,0,0,7,7,7,"")
	page.AddRows(1,True,"").AddCells12(1,"")
	page.AddRows(1,True,"").AddCells12(1,"")
	page.BuildGrid ' IMPORTANT!
	
	ABMLoginHandler.BuildModalSheets(page)
	ABMShared.BuildFooter(page)
	
End Sub


'*************************************************************

' handle the login and cancel buttons from the login in form.
Sub loginbtn_Clicked(Target As String)
	ABMLoginHandler.HandleLogin("Home", page)
End Sub

Sub logincancelbtn_Clicked(Target As String)
	ABMLoginHandler.CancelLogin(page)
End Sub

'*************************************************************


Sub saveBtn_Clicked(Target As String)
	Dim tabs As ABMTabs = page.Component("tabs")
	Dim tabid As String
	tabid=Regex.Split("-",Target)(0)
	Dim conc As ABMContainer = tabs.GetTabPage(tabid)
	Dim inp As ABMInput =conc.Component("inp")

	saveWork(tabid,inp.Text)
	
End Sub

Sub submitBtn_Clicked(Target As String)
	If submitWork=True Then
		page.ShowToast("","","已提交",2000,False)
	End If
End Sub

Sub saveWork(tabid As String,text As String)
	If File.Exists(File.Combine(File.DirApp,"submitted"),ws.Session.GetAttribute("authName")&".json") Then
		page.ShowToast("","","您已经正式提交过了",2000,False)
		Return
	End If
	File.WriteString(File.Combine(File.DirApp,"saved"),ws.Session.GetAttribute("authName")&"-"&tabid&".txt",text)
	page.ShowToast("","","已保存",2000,False)
End Sub

Sub submitWork As Boolean
	If File.Exists(File.Combine(File.DirApp,"submitted"),ws.Session.GetAttribute("authName")&".json") Then
		page.ShowToast("","","您已经提交过了",2000,False)
		Return False
	End If
    Dim json As JSONGenerator
	Dim map1 As Map
	map1.Initialize
	Dim i As Int=1
	For Each item As String In Array As String("汉译英","英译汉","技术传播") 
		If File.Exists(File.Combine(File.DirApp,"saved"),ws.Session.GetAttribute("authName")&"-"&"tab"&i&".txt") Then
			map1.Put(item,File.ReadString(File.Combine(File.DirApp,"saved"),ws.Session.GetAttribute("authName")&"-"&"tab"&i&".txt"))
			i=i+1
		Else
			page.ShowToast("","","请先保存所有作品",2000,False)
			Return False
		End If

	Next
	json.Initialize(map1)
	File.WriteString(File.Combine(File.DirApp,"submitted"),ws.Session.GetAttribute("authName")&".json",json.ToString)
    Return True
End Sub

Sub loadSaved
	For i=1 To 3
		If File.Exists(File.Combine(File.DirApp,"saved"),ws.Session.GetAttribute("authName")&"-"&"tab"&i&".txt") Then
			Dim tabs As ABMTabs = page.Component("tabs")
			Dim conc As ABMContainer = tabs.GetTabPage("tab"&i)
			Dim inp As ABMInput =conc.Component("inp")
			inp.Text=File.ReadString(File.Combine(File.DirApp,"saved"),ws.Session.GetAttribute("authName")&"-"&"tab"&i&".txt")
		End If
	Next
End Sub

' clicked on the navigation bar
Sub Page_NavigationbarClicked(Action As String, Value As String)
	' saving the navigation bar position
	page.SaveNavigationBarPosition
	If Action = "LogOff" Then
		'ws.Session.Invalidate
		ABMShared.LogOff(page)
		Return
	End If
	
	If Action = "Login" Then
		ABMLoginHandler.ShowLogin(page)
		Return
	End If
	If Action = "Home" Then
		ABMShared.NavigateToPage(ws, ABMPageId, Value)
		Return
	End If
	If Action <> "Home" Then
		NotWorking(Action)  ' shortcut to show - Page Not Available!
		' ABMShared.NavigateToPage(ws, ABMPageId, Value)  ' typically, this is not commented out and will direct the flow to the menu option (page) chosen...
	End If
End Sub

Sub NotWorking(act As String)
	
	page.Msgbox("login_not", " These pages will not require authorization... ",  "SORRY!"&CRLF&act&" Page Not Available", "Close", False, ABM.MSGBOX_POS_CENTER_CENTER,"redmsgbox")

End Sub

Sub BuildTabContainer(id As String, Text As String) As ABMContainer
	Dim tabc As ABMContainer
	Dim lbl As ABMLabel
	lbl.Initialize(page, id , Text, ABM.SIZE_PARAGRAPH, True, "")

	Dim inp As ABMInput
	inp.Initialize(page,"inp",ABM.INPUT_TEXT,"在此答题",True,"redInput")
	inp.Align=ABM.INPUT_TEXTALIGN_LEFT
	Dim saveBtn As ABMButton
	saveBtn.InitializeFlat(page,"saveBtn","","","保存","redbtn1")

	Select id
		Case "tab1"
			tabc.Initialize(page, id, "tabpagewhite")
			tabc.AddRows(2,True,"").AddCells12(1,"")
			tabc.AddRows(1,True,"").AddCellsOS(1,0,0,0,6,6,6,"")
			tabc.BuildGrid ' IMPORTANT!
			tabc.Cell(1,1).AddComponent(lbl)
			tabc.Cell(2,1).AddComponent(inp)
		Case "tab2"
			tabc.Initialize(page, id, "tabpagewhite")
			tabc.AddRows(2,True,"").AddCells12(1,"")
			tabc.AddRows(1,True,"").AddCellsOS(1,0,0,0,6,6,6,"")
			tabc.BuildGrid ' IMPORTANT!
			tabc.Cell(1,1).AddComponent(lbl)
			tabc.Cell(2,1).AddComponent(inp)
		Case "tab3"
			tabc.Initialize(page, id, "tabpagewhite")
			tabc.AddRows(2,True,"").AddCells12(1,"")
			tabc.AddRows(1,True,"").AddCellsOS(1,0,0,0,6,6,6,"")
			tabc.BuildGrid ' IMPORTANT!

			tabc.Cell(1,1).AddComponent(lbl)
			tabc.Cell(2,1).AddComponent(inp)

	End Select


	tabc.Cell(3,1).AddComponent(saveBtn)
	Return tabc
End Sub