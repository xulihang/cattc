B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=5.9
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
	Public Name As String = "HomePage"
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
    theme.AddLabelTheme("contentTheme")
	theme.Label("contentTheme").Align=ABM.TEXTALIGN_CENTER
End Sub


Sub ConnectPage()


	' ConnectNavigationBar2 is purposely built for public pages... It does not require a login to view
	If ws.Session.HasAttribute("IsAuthorized") And ws.Session.GetAttribute("IsAuthorized")="true" Then
		ABMShared.ConnectNavigationBar(page)
	Else
		ABMShared.ConnectNavigationBar2(page,  "Home", "Home", "Home",  Not(ws.Session.GetAttribute2("IsAuthorized", "") = ""))
	End If
	
	
	
	' add header
	'page.Cell(1,1).AddComponent(ABMShared.BuildParagraphWithTheme(page, "content",  "Welcome To Our Home Page","contentTheme"))
	Dim card1 As ABMCard
	card1.InitializeAsCard(page,"card1","邀请函","第七届全国计算机辅助翻译大赛",ABM.CARD_NOTSPECIFIED,"")
	card1.AddAction("报名")
	page.Cell(1,1).AddComponent(card1)

	
	page.Refresh ' IMPORTANT
 
	page.RestoreNavigationBarPosition

	' NEW, because we use ShowLoaderType=ABM.LOADER_TYPE_MANUAL
	page.FinishedLoading 'IMPORTANT
	
End Sub

Sub card1_LinkClicked(Card As String, Action As String)
	Log("Target: "&Card&"  Action: "&Action)
	ABMShared.NavigateToPage(ws, ABM.GetPageID(page, "SignupWizardPage",ws), "../SignupWizardPage")
End Sub

 Sub card2_LinkClicked(Card As String, Action As String)
	Dim card2 As ABMCard = page.Component("card2")
	
	card2.RotateAnimated(10.0,500, ABM.TWEEN_EASEINSINE, True)

	Log("Target: "&Card&"  Action: "&Action)
	
End Sub

public Sub BuildPage()
	' initialize the theme
	BuildTheme
	page.InitializeWithTheme(Name, "/ws/" & ABMShared.AppName & "/" & Name, False, ABMShared.SessionMaxInactiveIntervalSeconds, theme)
	
	' show the spinning cicles while page is loading....
	page.ShowLoader=True
	page.PageHTMLName = "index.html"
	page.PageTitle = "翻译大赛"  ' You can also set this as a property in "ABMShared.BuildNavigationBar" below...
	
	'  Google SEO stuff...
	page.PageDescription = ""
	page.PageKeywords = ""
	page.PageSiteMapPriority = ""
	page.PageSiteMapFrequency = ABM.SITEMAP_FREQ_YEARLY
		
	' faint green dot (on title bar) when connected - red when not connected with web socket
	page.ShowConnectedIndicator = True
	
	ABMShared.BuildNavigationBarextra(page,  "大赛报名","../images/logo.png", "Home", "Home", "Home")
	
	
	'page.AddRowsM( 5, True, 0, 10, "").AddCellsOSMP( 1, 0, 0, 0, 12, 12, 12, 0,  0, 0, 0, "")
	'page.AddRowsM( 1, True, 0, 10, "").AddCellsOSMP( 2, 0, 0, 0, 6, 6, 6, 0,   0,  10,10, "")
	
	page.AddRowsM(1,True,0,10,"").AddCells12(1,"")

	'IMPORTANT - Build the Grid before you start adding components ( with ConnectPage()!!! )
	page.BuildGrid
	
	ABMLoginHandler.BuildModalSheets(page)
	
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
	
	If Action <> "Home" Then
		NotWorking(Action)  ' shortcut to show - Page Not Available!
	  ' ABMShared.NavigateToPage(ws, ABMPageId, Value)  ' typically, this is not commented out and will direct the flow to the menu option (page) chosen...
	End If   
End Sub

Sub NotWorking(act As String)
	
	page.Msgbox("login_not", " These pages will not require authorization... ",  "SORRY!"&CRLF&act&" Page Not Available", "Close", False, ABM.MSGBOX_POS_CENTER_CENTER,"")

End Sub



