B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=5.9
@EndOfDesignText@

Sub Process_Globals
	Dim ABM As ABMaterial
End Sub

public Sub BuildModalSheets(page As ABMPage)
	' add a modal sheet template to enter contact information
	page.AddModalSheetTemplate(BuildLoginSheet(page))
	
	' add a error box template if the name is not entered
	page.AddModalSheetTemplate(BuildWrongInputModalSheet(page))
End Sub

public Sub HandleLogin(LoginFromPage As String, Page As ABMPage)
	Dim mymodal As ABMModalSheet = Page.ModalSheet("login")
	
	If Page.ws.Session.GetAttribute2("IsAuthorized", "") = "" Then
		'Dim loginpwd As String = ABM.LoadLogin(AppPage, AppName)
        Dim logininp1 As ABMInput = mymodal.Content.Component("logininp1")
        Dim logininp2 As ABMInput = mymodal.Content.Component("logininp2")
		
		
		' 		The Page.ws.Session.SetAttribute("") types (cookies) can be used for many different purposes.
		'       For example, who is logged in, what type of user are they, what do they have access to, etc...
		'       When the user logs out, set all of the attributes to "".....  
		
		
		' if using a MySQL table - use this
		If ABMShared.UsingDB Then   
			
			If logininp2.Text <> "" Then
				' we will use this when a database is present - if users list size > 0, then username and password matched - OK to login..
				Dim SQL As SQL = DBM.GetSQL
				Dim users As List = DBM.SQLSelect(SQL,  "SELECT * FROM Users WHERE UserLogin='" & logininp1.text & "' AND UserPassword='" & logininp2.Text & "'", Null)
				If users.Size > 0 Then	
					' a match was found in the table - log this user in....
					Dim user As Map = users.Get(0)
					Page.ws.Session.SetAttribute("authType", "local")
					Page.ws.Session.SetAttribute("authName", logininp1.Text)
					Page.ws.Session.SetAttribute("IsAuthorized", "true")
					Page.ws.Session.SetAttribute("UserType", "" & user.Get("usertype") ) ' lowercase!				
					Page.ws.Session.SetAttribute("UserID", "" & user.Get("userid") ) ' lowercase!
					Page.ws.Session.SetAttribute("UserRows",  user.Get("userrows") ) ' lowercase!
					DBM.CloseSQL(SQL)
				Else
					'  size of list = 0, no username or password found in table....
					Page.ShowModalSheet("wronginput")  
					Return
						
				End If
				DBM.CloseSQL(SQL)
			End If
			
		' simple login with json as database
		Else   
			If File.Exists(File.DirApp,"users.json") Then
				Dim json As JSONParser
				Dim map1 As Map
				json.Initialize(File.ReadString(File.DirApp,"users.json"))
				map1=json.NextObject
				If map1.ContainsKey(logininp1.Text) Then
					Dim map2 As Map
				    map2=map1.Get(logininp1.Text)
					If logininp2.Text = map2.Get("password") Then
						Page.Msgbox("loginok", " We Shall Continue With Login in 2 seconds....! ",  "Welcome "&logininp1.Text,"Continue", False, ABM.MSGBOX_POS_TOP_CENTER,"")
						Sleep(2000)
						Page.ShowToast("tid1","toastgreen"," Login Successful!",5000,False)
						Page.ws.Session.SetAttribute("authType", "local")
						Page.ws.Session.SetAttribute("authName", logininp1.Text)
						Page.ws.Session.SetAttribute("IsAuthorized", "true")
						Page.ws.Session.SetAttribute("UserType", "admin"  )
						Page.ws.Session.SetAttribute("UserID", "my_name_or_number"  )
				    Else
						Page.Msgbox("loginok", " Can Not Login! ",  "抱歉！"&CRLF&"密码错误", "请重试", False, ABM.MSGBOX_POS_CENTER_CENTER,"")
						'Page.ShowModalSheet("wronginput")   ' this can be used to show wrong credentials for login...
						Return
				    End If
				Else
					Page.Msgbox("loginok", " Can Not Login! ",  "抱歉！"&CRLF&"该邮箱不存在", "请重试", False, ABM.MSGBOX_POS_CENTER_CENTER,"")
					'Page.ShowModalSheet("wronginput")   ' this can be used to show wrong credentials for login...
					Return
				End If
			Else
			    Page.Msgbox("loginok", " Can Not Login! ",  "SORRY!"&CRLF&" Wrong User Name or Password!", "Try Again", False, ABM.MSGBOX_POS_CENTER_CENTER,"")
			    Return
		    End If
		End If	
	
	End If
		
	
	'  user was successful in login.  Now navigate to About Page...
	
	Page.CloseModalSheet("login")
	ABMShared.NavigateToPage(Page.ws, Page.GetPageID,  "../HomePage")

End Sub


public Sub ShowLogin(page As ABMPage)
	page.ShowModalSheet("login")
End Sub

public Sub CancelLogin(page As ABMPage)
	
	page.CloseModalSheet("login")
	ABMShared.NavigateToPage(page.ws, page.GetPageID,  "./")
	
End Sub

public Sub closeSheet(page As ABMPage)
	page.CloseModalSheet("login")
End Sub



Sub BuildLoginSheet(AppPage As ABMPage) As ABMModalSheet
	Dim myModal As ABMModalSheet
	myModal.Initialize(AppPage, "login", False,  False,"")
	myModal.Content.UseTheme("modalcontent")
	myModal.Footer.UseTheme("modalfooter")
	myModal.IsDismissible = False
	
	' create the grid for the content
	myModal.Content.AddRowsM(4,True,  -10, 0,"").AddCells12MP(1, 0,0,0,0,"")	
	myModal.Content.BuildGrid 'IMPORTANT once you loaded the complete grid AND before you start adding components
	
	' add paragraph	
	myModal.Content.Cell(1,1).AddComponent(ABMShared.BuildParagraphBQWithZDepth( AppPage,"par1","请输入邮箱号和密码：") )

	' create the input fields for the content
	Dim inp1 As ABMInput
	inp1.Initialize(AppPage, "logininp1", ABM.INPUT_TEXT, "邮箱",  False, "lightblue")	
	myModal.Content.Cell(3,1).AddComponent(inp1)
	
	Dim inp2 As ABMInput
	inp2.Initialize(AppPage, "logininp2", ABM.INPUT_PASSWORD, "密码", False, "lightblue")
	myModal.Content.Cell(3,1).AddComponent(inp2)
	
	myModal.Footer.AddRowsM( 2,True,0,0, "").AddCells12(1,"")
	myModal.Footer.BuildGrid 'IMPORTANT once you loaded the complete grid AND before you start adding components
	
	' create the button for the footer
	Dim msbtn1 As ABMButton
	msbtn1.InitializeFlat(AppPage, "loginbtn", "", "", "登录", "transparent")
	myModal.Footer.Cell(1,1).AddComponent(msbtn1)	

	Dim msbtn2 As ABMButton
	msbtn2.InitializeFlat(AppPage, "logincancelbtn", "", "", "取消", "transparent")
	myModal.Footer.Cell(1,1).AddComponent(msbtn2)	
	
	Dim msbtn3 As ABMButton
	msbtn3.InitializeFlat(AppPage, "forgetpassbtn", "", "", "忘记密码", "transparent")
	myModal.Footer.Cell(1,1).AddComponent(msbtn3)

	Return myModal
End Sub


Sub BuildWrongInputModalSheet(page As ABMPage) As ABMModalSheet
	Dim myModalError As ABMModalSheet
	myModalError.Initialize(page, "wronginput", False, False, "modal")
	myModalError.IsDismissible = True
	
	' create the grid for the content
	myModalError.Content.AddRows(1,True, "").AddCells12(1,"")	
	myModalError.Content.BuildGrid 'IMPORTANT once you loaded the complete grid AND before you start adding components
	
	Dim lbl1 As ABMLabel
	lbl1.Initialize(page, "contlbl1", "邮箱号或密码错",ABM.SIZE_PARAGRAPH, False, "")
	myModalError.Content.Cell(1,1).AddComponent(lbl1)
	
	Return myModalError
End Sub