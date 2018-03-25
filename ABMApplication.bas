﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=5.9
@EndOfDesignText@
'Main application
Sub Class_Globals
	' change to match you app
	Private InitialPage As String = "HomePage/"  '<-------- First page to load
	
	' NOTE: Once you've set the above parameters, run the App once.  That way, the complete folder structure for your app will be created
	' /appname/
	' /appname/images/
	' /appname/uploads/
	'
	' You can then put the images you need in the pages into the /appname/images/ folder and start using them.
	
	' other variables needed
	Private AppPage As ABMPage
	Private theme As ABMTheme
	Private ws As WebSocket 'ignore
	Private ABM As ABMaterial 'ignore
	Private Pages As List
	Private PageNeedsUpload As List
	
	Private ABMPageId As String = ""
End Sub

Public Sub Initialize
	Pages.Initialize
	PageNeedsUpload.Initialize
	ABM.AppVersion = ABMShared.AppVersion
	ABM.AppPublishedStartURL = ABMShared.AppPublishedStartURL
	ABMShared.AppName = "fanyi"   '<-------------------------------------------------------- IMPORTANT
	
	' turn this mis-guided feature OFF - doesn't play well with others....  will be removed in future updates...
	ABM.EnablePassiveEventListeners=False
	
	' add your icons
	' ABM.AddAppleTouchIcon("", "")
	' ABM.AddMSTileIcon("", "")
	ABM.AddFavorityIcon("favicon.ico", "")
	
	#If RELEASE	
	'ABM.ActivateUseCDN("DONATORKEY", "https://cdn.jsdelivr.net/gh/RealAlwaysbusy/ABMaterial@v3.81-rc1/")
	'ABM.PreloadAllJavascriptAndCSSFiles=True	' NEW
	ABM.ActivateGZip("DONATORKEY", 1000) ' NEW
	
	Dim folders As List ' NEW
	folders.Initialize
	folders.Add(File.DirApp & "/www/" & ABMShared.AppName & "/images")
	ABM.ActivatePNGOptimize("DONATORKEY", folders, False , 9, False, True )
	#End If
	
	' build the local structure IMPORTANT!
	BuildPage
	ABMShared.NeedsAuthorization = False
	

End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	Log("Connected")
	ws = WebSocket1
	
	ABMPageId = ABM.GetPageID(AppPage, ABMShared.AppName,ws)
	'----------------------START MODIFICATION 4.00-------------------------------
	If AppPage.WebsocketReconnected Then
		ABMShared.NavigateToPage(ws, "", "./")
		Return
	End If
	
	Dim session As HttpSession = ABM.GetSession(ws, ABMShared.SessionMaxInactiveIntervalSeconds) 'ignore
	If session.IsNew Then
		session.Invalidate
		ABMShared.NavigateToPage(ws, "", "./")
		Return
	End If
	'----------------------END MODIFICATION 4.00-------------------------------
		
	' Prepare the page IMPORTANT!
	AppPage.Prepare
	' Run ConnectPage here in ABMApplication
	ConnectPage
	' navigate to the first page
'	
	If ABMShared.NeedsAuthorization Then
		If session.GetAttribute2("IsAuthorized", "") = "" Then
'			AppPage.ShowModalSheet("login")
            Log(" Needs Login with handler")
			ABMLoginHandler.ShowLogin(AppPage)
			Return
		End If
	End If
	ABMShared.NavigateToPage(ws, "","./" & InitialPage)
	
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
	Dim caller As Object = AppPage.GetEventHandler(Me, eventName)
	If caller = Me Then
		If SubExists(Me, eventName) Then
			Params.Remove("eventname")
			Params.Remove("eventparams")
			' BEGIN NEW DRAGDROP
			If eventName = "page_dropped" Then
				AppPage.ProcessDroppedEvent(Params)
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

public Sub AddPage(Page As ABMPage)
	Pages.Add(Page.Name)
	PageNeedsUpload.Add(ABM.WritePageToDisk(Page, File.DirApp & "/www/" & ABMShared.AppName & "/" & Page.Name & "/", Page.PageHTMLName, ABMShared.NeedsAuthorization))
End Sub

'----------------------START MODIFICATION 4.00-------------------------------
public Sub StartServer(srvr As Server, srvrName As String, srvrPort As Int)
	ABM.WriteAppLauchPageToDisk(AppPage, File.DirApp & "/www/" & ABMShared.AppName, "index.html", ABMShared.NeedsAuthorization)

	' start the server
	srvr.Initialize(srvrName)

	' uncomment this if you want to directly access the app in the url without having to add the app name
	' e.g. 192.168.1.105:51042 or 192.168.1.105 if you are using port 80
	'srvr.AddFilter( "/", "ABMRootFilter", False )
	
	' NEW V3 Cache Control
	srvr.AddFilter("/*", "ABMCacheControl", False)
	' NEW 4.00 custom error pages (optional) Needs the ABMErrorHandler class
	srvr.SetCustomErrorPages(CreateMap("org.eclipse.jetty.server.error_page.global": "/" & ABMShared.AppName & "/error")) ' OPTIONAL
	srvr.AddHandler("/" & ABMShared.AppName & "/error", "ABMErrorHandler", False) ' OPTIONAL
	
	srvr.AddWebSocket("/ws/" & ABMShared.AppName, "ABMApplication")
	For i =0 To Pages.Size - 1
		srvr.AddWebSocket("/ws/" & ABMShared.AppName & "/" & Pages.Get(i) , Pages.Get(i))
		If PageNeedsUpload.Get(i) Then
			srvr.AddHandler("/" & ABMShared.AppName & "/" & Pages.Get(i) & "/abmuploadhandler", "ABMUploadHandler", False)
		End If
	Next
	srvr.AddBackgroundWorker("ABMCacheScavenger")
	srvr.Port = srvrPort
		
	#If RELEASE		
	srvr.SetStaticFilesOptions(CreateMap("gzip":True,"dirAllowed":False))
	#Else		
		srvr.SetStaticFilesOptions(CreateMap("gzip":False,"dirAllowed":False))
	#End If
	
	srvr.Start
	
	Dim joServer As JavaObject = srvr
	joServer.GetFieldJO("server").RunMethod("stop", Null)
	joServer.GetFieldJO("context").RunMethodJO("getSessionHandler", Null).RunMethodJO("getSessionCookieConfig", Null).RunMethod("setMaxAge", Array(31536000)) ' 1 year
	
	' NEW FEATURE! Each App has its own Session Cookie
	joServer.GetFieldJO("context").RunMethodJO("getSessionHandler", Null).RunMethodJO("getSessionCookieConfig", Null).RunMethod("setName", Array(ABMShared.AppName.ToUpperCase))
	joServer.GetFieldJO("server").RunMethod("start", Null)
	
	Dim secs As Long = ABMShared.CacheScavengePeriodSeconds ' must be defined as a long, else you get a 'java.lang.RuntimeException: Method: setIntervalSec not matched.' error
	joServer.GetFieldJO("context").RunMethodJO("getSessionHandler", Null).RunMethodJO("getSessionIdManager", Null).RunMethodJO("getSessionHouseKeeper", Null).RunMethod("setIntervalSec", Array As Object(secs))
			
	Dim jo As JavaObject = srvr
	Dim connectors() As Object = jo.GetFieldJO("server").RunMethod("getConnectors", Null)
	Dim timeout As Long = ABMShared.SessionMaxInactiveIntervalSeconds*1000
	For Each c As JavaObject In connectors
		c.RunMethod("setIdleTimeout", Array(timeout))
	Next

	ABMShared.CachedPages = srvr.CreateThreadSafeMap
End Sub

public Sub StartServerHTTP2(srvr As Server, srvrName As String, srvrPort As Int, SSLsvrPort As Int,  SSLKeyStoreFileName As String, SSLKeyStorePassword As String, SSLKeyManagerPassword As String)
	ABM.WriteAppLauchPageToDisk(AppPage, File.DirApp & "/www/" & ABMShared.AppName, "index.html", ABMShared.NeedsAuthorization)

	Dim ssl As SslConfiguration
	ssl.Initialize
	ssl.SetKeyStorePath(File.DirApp, SSLKeyStoreFileName) 'path to keystore file
	ssl.KeyStorePassword = SSLKeyStorePassword
	ssl.KeyManagerPassword = SSLKeyManagerPassword
	srvr.SetSslConfiguration(ssl, SSLsvrPort)

	' start the server
	srvr.Initialize(srvrName)
	
	' uncomment this if you want to directly access the app in the url without having to add the app name
	' e.g. 192.168.1.105:51042 or 192.168.1.105 if you are using port 80
	'srvr.AddFilter( "/", "ABMRootFilter", False )
	
	' NEW V3 Cache Control
	srvr.AddFilter("/*", "ABMCacheControl", False)
	' NEW 4.00  custom error pages (optional) Needs the ABMErrorHandler class
	srvr.SetCustomErrorPages(CreateMap("org.eclipse.jetty.server.error_page.global": "/" & ABMShared.AppName & "/error")) ' OPTIONAL
	srvr.AddHandler("/" & ABMShared.AppName & "/error", "ABMErrorHandler", False) ' OPTIONAL
	
	srvr.AddWebSocket("/ws/" & ABMShared.AppName, "ABMApplication")
	For i =0 To Pages.Size - 1
		srvr.AddWebSocket("/ws/" & ABMShared.AppName & "/" & Pages.Get(i) , Pages.Get(i))
		If PageNeedsUpload.Get(i) Then
			srvr.AddHandler("/" & ABMShared.AppName & "/" & Pages.Get(i) & "/abmuploadhandler", "ABMUploadHandler", False)
		End If
	Next
	srvr.AddBackgroundWorker("ABMCacheScavenger")
	srvr.Port = srvrPort
	srvr.Http2Enabled = True
	
	#If RELEASE		
	srvr.SetStaticFilesOptions(CreateMap("gzip":True,"dirAllowed":False))
	#Else		
		srvr.SetStaticFilesOptions(CreateMap("gzip":False,"dirAllowed":False))
	#End If
		
	srvr.Start
	
	Dim joServer As JavaObject = srvr
	joServer.GetFieldJO("server").RunMethod("stop", Null)
	joServer.GetFieldJO("context").RunMethodJO("getSessionHandler", Null).RunMethodJO("getSessionCookieConfig", Null).RunMethod("setMaxAge", Array(31536000)) ' 1 year
	
	' NEW FEATURE! Each App has its own Session Cookie
	joServer.GetFieldJO("context").RunMethodJO("getSessionHandler", Null).RunMethodJO("getSessionCookieConfig", Null).RunMethod("setName", Array(ABMShared.AppName.ToUpperCase))
	joServer.GetFieldJO("server").RunMethod("start", Null)
	
	Dim secs As Long = ABMShared.CacheScavengePeriodSeconds ' must be defined as a long, else you get a 'java.lang.RuntimeException: Method: setIntervalSec not matched.' error
	joServer.GetFieldJO("context").RunMethodJO("getSessionHandler", Null).RunMethodJO("getSessionIdManager", Null).RunMethodJO("getSessionHouseKeeper", Null).RunMethod("setIntervalSec", Array As Object(secs))
	
	Dim jo As JavaObject = srvr
	Dim connectors() As Object = jo.GetFieldJO("server").RunMethod("getConnectors", Null)
	Dim timeout As Long = ABMShared.SessionMaxInactiveIntervalSeconds*1000
	For Each c As JavaObject In connectors
		c.RunMethod("setIdleTimeout", Array(timeout))
	Next

	ABMShared.CachedPages = srvr.CreateThreadSafeMap
End Sub
'----------------------END MODIFICATION 4.00-------------------------------

public Sub BuildTheme()
	' start with the base theme defined in ABMShared
	theme.Initialize("pagetheme")
	theme.AddABMTheme(ABMShared.MyTheme)
	
	' add additional themes specific for this page
	
End Sub

public Sub BuildPage()
	' initialize the theme
	BuildTheme
	
	' initialize this page using our theme
	AppPage.InitializeWithTheme(ABMShared.AppName, "/ws/" & ABMShared.AppName, False, ABMShared.SessionMaxInactiveIntervalSeconds , theme)
	AppPage.ShowLoader=True
	AppPage.PageTitle = "Loading..."
	AppPage.PageDescription = "Template for ABMaterial, a Material UI Framework for B4J"
	AppPage.PageHTMLName = "index.html"
	AppPage.PageKeywords = ""
	AppPage.PageSiteMapPriority = "0.00"
	AppPage.PageSiteMapFrequency = ABM.SITEMAP_FREQ_YEARLY
	AppPage.ShowConnectedIndicator = True
		
	' adding a navigation bar
	
			
	' create the page grid
	AppPage.AddRows(1,True, "").AddCells12(1,"")
	AppPage.BuildGrid 'IMPORTANT once you loaded the complete grid AND before you start adding components
	
	' add a modal sheet template to enter contact information
'	AppPage.AddModalSheetTemplate(BuildLoginSheet)
	
	' add a error box template if the name is not entered
'	AppPage.AddModalSheetTemplate(BuildWrongInputModalSheet)

	ABMLoginHandler.BuildModalSheets(AppPage)
	
	
End Sub

public Sub ConnectPage()
	' you dynamic stuff
	ABMShared.enableMultilanguage(ws,AppPage)
	AppPage.Refresh ' IMPORTANT
	
	' Tell the browser we finished loading
	AppPage.FinishedLoading 'IMPORTANT
	
	AppPage.RestoreNavigationBarPosition
End Sub


Sub loginbtn_Clicked(Target As String)
	ABMLoginHandler.HandleLogin("Works", AppPage)
End Sub

Sub logincancelbtn_Clicked(Target As String)
	ABMLoginHandler.CancelLogin(AppPage)
End Sub


' clicked on the navigation bar
Sub Page_NavigationbarClicked(Action As String, Value As String)
	AppPage.SaveNavigationBarPosition
End Sub
