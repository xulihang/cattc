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
	Public Name As String = "SignupWizardPage"
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
	Log("SignupWizardPage Connected")
		
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

End Sub


Sub ConnectPage()


	' ConnectNavigationBar2 is purposely built for public pages... It does not require a login to view
	If ws.Session.HasAttribute("IsAuthorized") And ws.Session.GetAttribute("IsAuthorized")="true" Then
		page.ShowToast("loginedToast","","你已经登录了",2000,False)
		Sleep(2000)
		ABMShared.NavigateToPage(ws,"HomePage","../HomePage")
	Else
		ABMShared.ConnectNavigationBar2(page,  "Signup", "Signup", "Signup",  Not(ws.Session.GetAttribute2("IsAuthorized", "") = ""))
	End If
	
	'page.Cell(1,1).AddComponent(ABMShared.BuildParagraphWithTheme(page, "content",  "Welcome To Our Home Page","contentTheme"))
	Dim wizB As ABMSmartWizard
	wizB.Initialize(page,"wizB","上一步","下一步","完成","")
	wizB.AddStep("stepB1","第一步","邮箱","email",BuildContainer("StepB1Cont"),ABM.SMARTWIZARD_STATE_ACTIVE)
	wizB.AddStep("stepB2","第二步","姓名","Name",BuildContainer("StepB2Cont"),ABM.SMARTWIZARD_STATE_DISABLED)
	wizB.AddStep("stepB3","第三步","密码","",BuildContainer("StepB3Cont"),ABM.SMARTWIZARD_STATE_DISABLED)
	page.Cell(1,1).AddComponent(wizB)

	
	page.Refresh ' IMPORTANT
 
	page.RestoreNavigationBarPosition

	' NEW, because we use ShowLoaderType=ABM.LOADER_TYPE_MANUAL
	page.FinishedLoading 'IMPORTANT
	
End Sub

Sub card1_LinkClicked(Card As String, Action As String)
	Log("Target: "&Card&"  Action: "&Action)
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


Sub BuildContainer(ID As String) As ABMContainer
	Dim cont As ABMContainer
	cont.Initialize(page, ID, "")
	Select Case ID
		Case "StepB1Cont"
			cont.AddRowsM(1, True,0,0,"").AddCells12(1,"")
			cont.BuildGrid ' IMPORTANT!
			'Dim emaillbl As ABMLabel = ABMShared.BuildHeader(page, ID & "emaillbl", "邮箱地址")
			'cont.Cell(1,1).AddComponent(emaillbl)
			Dim emailinp As ABMInput
			emailinp.Initialize(page, ID & "emailinp", ABM.INPUT_TEXT, "邮箱地址:", False, "input")
			'emailinp.PlaceHolderText = "write your email address"
			cont.Cell(1,1).AddComponent(emailinp)
		Case "StepB2Cont"
			cont.AddRowsM(1, True,0,0,"").AddCells12(1,"")
			cont.BuildGrid ' IMPORTANT!
			'Dim namelbl As ABMLabel = ABMShared.BuildHeader(page, ID & "namelbl", "姓名")
			'cont.Cell(1,1).AddComponent(namelbl)
			Dim nameinp As ABMInput
			nameinp.Initialize(page, ID & "nameinp", ABM.INPUT_TEXT, "姓名:", False, "input")
			'nameinp.PlaceHolderText = "write your name"
			cont.Cell(1,1).AddComponent(nameinp)
		Case "StepB3Cont"
			cont.AddRowsM(1, True,0,0,"").AddCells12(1,"")
			cont.BuildGrid ' IMPORTANT!
			'Dim pwdlbl As ABMLabel = ABMShared.BuildHeader(page, ID & "pwdlbl", "密码")
			'cont.Cell(1,1).AddComponent(pwdlbl)
			Dim addressinp As ABMInput
			addressinp.Initialize(page, ID & "passwordinp",ABM.INPUT_PASSWORD,"密码:", False, "input")
			'addressinp.PlaceHolderText = "write your address"
			cont.Cell(1,1).AddComponent(addressinp)
	End Select
	Return cont
End Sub

' clicked on the navigation bar
Sub Page_NavigationbarClicked(Action As String, Value As String)
	' saving the navigation bar position
	page.SaveNavigationBarPosition
	If Action = "ABMSmartWizard" Then Return
	If Action = "LogOff" Then
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
	
	page.Msgbox("login_not", " These pages will not require authorization... ",  "SORRY!"&CRLF&act&" Page Not Available", "Close", False, ABM.MSGBOX_POS_CENTER_CENTER,"")

End Sub


' helper method to set the states
Sub SetWizardStepStates(wiz As ABMSmartWizard, Active As String, wizType As String)
	Dim ActiveInt As Int = Active.SubString(5)
	For i = 1 To ActiveInt - 1
		wiz.SetStepState("step" & wizType & i, ABM.SMARTWIZARD_STATE_DONE)
	Next
	wiz.SetStepState(Active, ABM.SMARTWIZARD_STATE_ACTIVE)
	For i = ActiveInt + 1 To 5
		wiz.SetStepState("step" & wizType & i, ABM.SMARTWIZARD_STATE_DISABLED)
	Next
End Sub
Sub wizB_NavigationToStep(fromReturnName As String, toReturnName As String)
	Dim wizB As ABMSmartWizard = page.Component("wizB")
	If fromReturnName.CompareTo(toReturnName) < 0 Then ' to the right
		Select Case fromReturnName
			Case "stepB1"
				Dim cont As ABMContainer = wizB.GetStep("StepB1")
				Dim emailinp As ABMInput = cont.Component("StepB1ContEmailInp")
				If emailinp.Text.IndexOf("@") = -1 Then
					wizB.SetStepState("stepB1", ABM.SMARTWIZARD_STATE_ERROR)
					wizB.NavigateCancel(toReturnName) ' important
				Else if emailExists(emailinp.Text) Then
					page.ShowToast("existToast","","邮件已被注册",2000,False)
					wizB.SetStepState("stepB1", ABM.SMARTWIZARD_STATE_ERROR)
					wizB.NavigateCancel(toReturnName) ' important
				Else
					SetWizardStepStates(wizB, toReturnName, "B")
					wizB.NavigateGoto(toReturnName) ' important
				End If
			Case "stepB2"
				Dim cont As ABMContainer = wizB.GetStep("StepB2")
				Dim nameinp As ABMInput = cont.Component("StepB2ContNameInp")
				If nameinp.Text = "" Then
					wizB.SetStepState("stepB2", ABM.SMARTWIZARD_STATE_ERROR)
					wizB.NavigateCancel(toReturnName) ' important
				Else
					SetWizardStepStates(wizB, toReturnName, "B")
					wizB.NavigateGoto(toReturnName) ' important
				End If
			Case "stepB3"
				' handled in NavigationFinished
		End Select
	Else If fromReturnName.CompareTo(toReturnName) > 0 Then ' to the left
		SetWizardStepStates(wizB, toReturnName, "B")
		wizB.NavigateGoto(toReturnName) ' important
	Else
		wizB.NavigateGoto(toReturnName) ' important
	End If
	wizB.Refresh ' important
End Sub

Sub wizB_NavigationFinished(ReturnName As String)
	Log(ReturnName)
	Dim wizB As ABMSmartWizard = page.Component("wizB")
	Dim cont As ABMContainer = wizB.GetStep("stepB3")
	Dim passwordinp As ABMInput = cont.Component("StepB3ContPasswordInp")
	If passwordinp.Text = "" Then
		wizB.SetStepState("stepB3", ABM.SMARTWIZARD_STATE_ERROR)
		wizB.NavigateCancel("stepB3") ' important
	Else
		SetWizardStepStates(wizB, "stepB3", "B")
		Dim email,xm,password As String
		' reset the wizard
		cont = wizB.GetStep("stepB1")
		Dim emailinp As ABMInput = cont.Component("StepB1ContEmailInp")
		email=emailinp.Text
		cont = wizB.GetStep("stepB2")
		Dim nameinp As ABMInput = cont.Component("StepB2ContNameInp")
		xm=nameinp.Text
		cont = wizB.GetStep("stepB3")
		Dim passwordinp As ABMInput = cont.Component("StepB3ContPasswordInp")
		password=passwordinp.Text
		Log(email&xm&password)
		Try
			signupDone(email,xm,password)
			page.ShowToast("doneToast","","注册成功",2000,False)
			Sleep(2000)
			ABMShared.NavigateToPage(ws,"HomePage","../HomePage")
		Catch
			page.ShowToast("doneToast","","注册失败",2000,False)
			Log(LastException)
		End Try
	End If
End Sub

Sub signupDone(email As String,xm As String,password As String)
	Dim map1,map2 As Map
	map1.Initialize
	map2.Initialize
	If File.Exists(File.DirApp,"users.json") Then
		Dim jsonp As JSONParser
		jsonp.Initialize(File.ReadString(File.DirApp,"users.json"))
		map1=jsonp.NextObject
	End If
	map2.Put("xm",xm)
	map2.Put("password",password)
	map1.Put(email,map2)
	Dim jsong As JSONGenerator
	jsong.Initialize(map1)
	File.WriteString(File.DirApp,"users.json",jsong.ToString)
End Sub

Sub emailExists(email As String) As Boolean
	If File.Exists(File.DirApp,"users.json") Then
		Dim jsonp As JSONParser
		jsonp.Initialize(File.ReadString(File.DirApp,"users.json"))
		Dim map1 As Map
		map1=jsonp.NextObject
		If map1.ContainsKey(email) Then
			Return True
		Else
			Return False
		End If
	Else
		Return False
	End If
End Sub