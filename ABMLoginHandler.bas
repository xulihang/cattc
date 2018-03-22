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

public Sub HandleLogin(LoginFromPageID As String, Page As ABMPage)
	Dim mymodal As ABMModalSheet = Page.ModalSheet("login")
	If ABMShared.wrongRecord.IsInitialized=False Then
		ABMShared.wrongRecord.Initialize
	End If
	
	If Page.ws.Session.GetAttribute2("IsAuthorized", "") = "" Then
		'Dim loginpwd As String = ABM.LoadLogin(AppPage, AppName)
        Dim logininp1 As ABMInput = mymodal.Content.Component("logininp1")
        Dim logininp2 As ABMInput = mymodal.Content.Component("logininp2")
		If File.Exists(File.DirApp&"/logs",logininp1.Text&".log") Then
			Dim logstring As String
			logstring=File.ReadString(File.DirApp&"/logs",logininp1.Text&".log")
			Dim triedTimes As Long
			Dim difference  As Int
			If logstring.Contains("lastTry:") Then '之前的错误尝试，没有被清除
				triedTimes=logstring.Replace("lastTry:","")
				difference=DateTime.Now-triedTimes
				If difference>120000 Then
					If ABMShared.wrongRecord.ContainsKey(logininp1.Text) Then
						ABMShared.wrongRecord.Remove(logininp1.Text) '已经是两分钟前的错误尝试了，就给清空了
					End If
					File.Delete(File.DirApp&"/logs",logininp1.Text&".log")
				End If
			Else
				triedTimes=logstring
				difference=DateTime.Now-triedTimes
				If difference<60000 Then
					Page.ShowToast("loginok", "", Page.XTR("0001","密码错误次数过多，请")&(60-difference/1000)&Page.XTR("0002","秒以后再试"), 2000, False)
					Return
				Else
					File.Delete(File.DirApp&"/logs",logininp1.Text&".log")
					ABMShared.wrongRecord.Remove(logininp1.Text)
				End If
			End If
		End If
		
		
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
			If File.Exists(File.DirApp,"users.db") Then
				If ABMShared.kvs.IsInitialized=False Then
					ABMShared.kvs.Initialize(File.DirApp, "users.db")
				End If
				If ABMShared.kvs.ContainsKey(logininp1.Text)=True Then
					Dim map2 As Map
					map2=ABMShared.kvs.Get((logininp1.Text))
					Log(map2)
					If logininp2.Text = map2.Get("password") Then
						Page.Msgbox("loginok", Page.XTR("0003","登录成功，两秒后跳转页面"),  Page.XTR("0004","欢迎")&logininp1.Text,Page.XTR("0005","继续"), False, ABM.MSGBOX_POS_TOP_CENTER,"redmsgbox")
						Sleep(2000)
						'Page.ShowToast("tid1","toastgreen"," Login Successful!",5000,False)
						Page.ws.Session.SetAttribute("authType", "local")
						Page.ws.Session.SetAttribute("authName", logininp1.Text)
						Page.ws.Session.SetAttribute("IsAuthorized", "true")
						Page.ws.Session.SetAttribute("UserType", "admin"  )
						Page.ws.Session.SetAttribute("UserID", "my_name_or_number"  )
				    Else
						
						If ABMShared.wrongRecord.ContainsKey(logininp1.Text) Then
							Dim wrongTimes As Int
							wrongTimes=ABMShared.wrongRecord.Get(logininp1.Text)
							wrongTimes=wrongTimes+1
							Log(wrongTimes)
							ABMShared.wrongRecord.Put(logininp1.Text,wrongTimes)
							If wrongTimes<5 Then
								File.WriteString(File.DirApp&"/logs",logininp1.Text&".log","lastTry:"&DateTime.Now)
								Page.ShowToast("loginok", "", Page.XTR("0006","抱歉！")&CRLF&Page.XTR("0007","密码错误"), 2000, False)
							Else
								Page.ShowToast("loginok", "", Page.XTR("0008","密码错误次数过多，请1分钟以后再试"), 2000, False)
								File.WriteString(File.DirApp&"/logs",logininp1.Text&".log",DateTime.Now)
							End If
						Else
							ABMShared.wrongRecord.Put(logininp1.Text,1)
							File.WriteString(File.DirApp&"/logs",logininp1.Text&".log","lastTry:"&DateTime.Now)
							Page.ShowToast("loginok", "", Page.XTR("0006","抱歉！")&CRLF&Page.XTR("0007","密码错误"), 2000, False)
						End If
						'Page.ShowModalSheet("wronginput")   ' this can be used to show wrong credentials for login...
						Return
				    End If
				Else
					Page.ShowToast("loginwrong", "", Page.XTR("0006","抱歉！")&CRLF& Page.XTR("0017","该邮箱不存在"), 2000, False)
					'Page.Msgbox("loginok", " Can Not Login! ",  "抱歉！"&CRLF&"该邮箱不存在", "请重试", False, ABM.MSGBOX_POS_CENTER_CENTER,"")
					'Page.ShowModalSheet("wronginput")   ' this can be used to show wrong credentials for login...
					Return
				End If
			Else
				Page.ShowToast("loginwrong", "",  Page.XTR("0006","抱歉！")&CRLF& Page.XTR("0009","用户名或密码错误"), 2000, False)
			    Return
		    End If
		End If	
	
	End If
		
	
	'  user was successful in login.  Now navigate to About Page...
	
	Page.CloseModalSheet("login")
	
	ABMShared.NavigateToPage(Page.ws,Page.GetPageID,  "../")

End Sub


public Sub ShowLogin(page As ABMPage)
	
	page.ShowModalSheet("login")
	Dim mymodal As ABMModalSheet = page.ModalSheet("login")
	Dim logininp1 As ABMInput = mymodal.Content.Component("logininp1")
	logininp1.SetFocus

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
	myModal.Initialize(AppPage, "login", False,  False,"redModal")
	'myModal.Content.UseTheme("modalcontent")
	'myModal.Footer.UseTheme("modalfooter")
	myModal.IsDismissible = False
	
	' create the grid for the content
	myModal.Content.AddRowsM(4,True,  -10, 0,"").AddCells12MP(1, 0,0,0,0,"")	
	myModal.Content.BuildGrid 'IMPORTANT once you loaded the complete grid AND before you start adding components
	
	' add paragraph	
	myModal.Content.Cell(1,1).AddComponent(ABMShared.BuildParagraphBQWithoutZDepth( AppPage,"par1","请输入邮箱号和密码：") )

	' create the input fields for the content
	Dim inp1 As ABMInput
	inp1.Initialize(AppPage, "logininp1", ABM.INPUT_TEXT, "邮箱",  False, "redInput")
	myModal.Content.Cell(3,1).AddComponent(inp1)
	
	Dim inp2 As ABMInput
	inp2.Initialize(AppPage, "logininp2", ABM.INPUT_PASSWORD, "密码", False, "redInput")
	myModal.Content.Cell(3,1).AddComponent(inp2)
	
	myModal.Footer.AddRowsM( 2,True,0,0, "").AddCells12(1,"")
	myModal.Footer.BuildGrid 'IMPORTANT once you loaded the complete grid AND before you start adding components
	
	' create the button for the footer
	Dim msbtn1 As ABMButton
	msbtn1.InitializeFlat(AppPage, "loginbtn", "", "", "登录", "transparentbtn")
	myModal.Footer.Cell(1,1).AddComponent(msbtn1)	

	Dim msbtn2 As ABMButton
	msbtn2.InitializeFlat(AppPage, "logincancelbtn", "", "", "取消", "transparentbtn")
	myModal.Footer.Cell(1,1).AddComponent(msbtn2)	
	
	Dim msbtn3 As ABMButton
	msbtn3.InitializeFlat(AppPage, "forgetpassbtn", "", "", "忘记密码", "transparentbtn")
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
	lbl1.Initialize(page, "contlbl1", page.XTR("0015","邮箱号或密码错"),ABM.SIZE_PARAGRAPH, False, "")
	myModalError.Content.Cell(1,1).AddComponent(lbl1)
	
	Return myModalError
End Sub