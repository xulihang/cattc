B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=5.9
@EndOfDesignText@
'Class module

' The methods between ******************** are REQUIRED for EVERY page you create!!!
' *************************************************************** REQUIRED FROM HERE ********************************************

Sub Class_Globals
	Private ws As WebSocket 'ignore
	' will hold our page information
	Public page As ABMPage
	' page theme
	Private theme As ABMTheme
	' to access the constants
	Private ABM As ABMaterial 'ignore
	
	' Important!	
	' name of the page, must be the same as the class name (case sensitive!)
	Public Name As String = "ABMPageTemplate"  '<--------------------------------------------- IMPORTANT
	
	' will hold the unique browsers window id
	Private ABMPageId As String = ""
	' your own variables	
	Private myToastId As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	' build the (all pages) local structure IMPORTANT!
	BuildPage		
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	'----------------------MODIFICATION-------------------------------	
	Log("Connected")
		
	ws = WebSocket1			
	
	ABMPageId = ABM.GetPageID(page, Name,ws)
	
	Dim session As HttpSession = ABM.GetSession(ws, ABMShared.SessionMaxInactiveIntervalSeconds)
	'----------------------START MODIFICATION 4.00-------------------------------
	If session.IsNew Then
		session.Invalidate
		ABMShared.NavigateToPage(ws, "", "./")
		Return
	End If
	'----------------------END MODIFICATION 4.00-------------------------------
	
	
	'  Set needs auth to true	
	ABMShared.NeedsAuthorization = True
		
	'  if not logged in, send user back to home page
	If ABMShared.NeedsAuthorization Then
		If session.GetAttribute2("IsAuthorized", "") = "" Then  '  check for auth status.....
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


' *************************************** REQUIRED TO HERE ( all above - rarely modified!!! ) ***********************
'
' *********** Also REQUIRED are BuildPage and ConnectPage - but contents may vary ***********************************



public Sub BuildPage()
	
	' Each New Page Must have THIS ( BuildPage() )!!!!!!!
	' This is called from: "Public Sub Initialize" near the top of this form..
	
	' initialize the theme  (see method above )
	BuildTheme
	
	
	' initialize this page using our theme
	page.InitializeWithTheme(Name, "/ws/" & ABMShared.AppName & "/" & Name, False, ABMShared.SessionMaxInactiveIntervalSeconds, theme)
	
	' show the spinning cicles while page is loading....
	page.ShowLoader=True
	
	page.PageHTMLName = "index.html"
	
	page.PageTitle = ""  ' You can also set this as a property in "ABMShared.BuildNavigationBar" below...
	
	'  Google SEO stuff...
	page.PageDescription = ""
	page.PageKeywords = ""
	page.PageSiteMapPriority = ""
	page.PageSiteMapFrequency = ABM.SITEMAP_FREQ_YEARLY
		
	' faint green dot (on title bar) when connected - red when not connected with web socket
	page.ShowConnectedIndicator = True   
				
	' BuildNavigationBar - adding a navigation title bar - Note" {B} HELLO WORLD {/B} - in-line bold tags for portion of title
	' "../images/logo.png"  - this is the ABMaterial logo you will see on the left of title bar...
	ABMShared.BuildNavigationBar(page, "Title for template - My {B} HELLO WORLD {/B} Page!", "../images/logo.png",  "",  "",  "")
	
	' debug console that displays on the right...  remove comment to enable....  Then add comment to see whole page again...
	' page.DebugConsoleEnable(True, 250)
					
	' create the page grid  (unless you like staring at blank pages....)
	
	
	' There are several methods (or flavours of) to add rows and cells to a page.
	' We shall concentrate on the most useful ones - used in the following examples...
	
	page.AddRowsM( 5, True, 0, 10, "").AddCellsOSMP( 1, 0, 0, 0, 12, 12, 12, 0,  0, 0, 0, "")

	' add rows to the page - let's break this down:  First - the ROWS part..
	' page.AddRowsM( 5, - add five rows
	' page.AddRowsM( 5, True, - center these rows within the page (adds padding left and right)
	' page.AddRowsM( 5, True, 0, - Top margin of 0  (note - page.AddRows (without the R suffix) has a default margin of 20px)
	' page.AddRowsM( 5, True, 0, 10, - Bottom margin of 10px between each of the 5 rows we added
	' page.AddRowsM( 5, True, 0, 10, "") - Row theme - set to nothing right now, but very, very useful....
	
	' Now the cells part of adding rows... - .AddCellsOSMP( 1,0,0,0,12,12,12, 0, 0, 0, 0,"")
	' AddCellsOS( 1, - add one cell to this row...
	' AddCellsOS( 1, 0, - the offset when shown on small devices (phones)
	' AddCellsOS( 1, 0, 0, - the offset when shown on medium devices (tablets)
	' AddCellsOS( 1, 0, 0, 0, - the offset when shown on large devices (desktop / laptop monitors)
	' AddCellsOS( 1,0,0,0,12,12,12,  - for each device size, what will be the width of each cell - answer - 12 on all
	' AddCellsOS( 1,0,0,0,12,12,12, 0, 0, 0, 0,  - MP (margin/padding for top, bottom left, right)
	' AddCellsOS( 1,0,0,0,12,12,12,"") - lastly - what theme shall be applied to these cells - currently none

	' Here we are adding 5 more rows, but this time each row will have 2 cells - 6 wide on all devices...
	' We are also NOT centering the rows ( False ) - so they will use full page width...
	page.AddRowsM(5, False, 0, 5, "").AddCellsOSMP(2,0,0,0,6,6,6, 10, 10, 0, 0,"")

	' Here we shall add 2 rows with three cells. Each cell will use a differnt theme!
	' Note the first cell is size 6, while the other 2 are size 3.  This must add up to 12....
	page.AddRowsM(2, True, 0, 5, "").AddCellsOSMP(1,0,0,0,6,6,6, 10, 10, 0, 0,"tcell2").AddCellsOSMP(1,0,0,0,3,3,3,  10, 10, 20, 20,"tcell1").AddCellsOSMP(1,0,0,0,3,3,3, 10, 10, 0, 0,"tcell3")

	
	'IMPORTANT - Build the Grid before you start adding components ( with ConnectPage()!!! )
	page.BuildGrid 
	
	'  How does the page add compenents to each cell now???
	' answer: WebSocket_Connected (WebSocket1 As WebSocket) and a call to ConnectPage within the method... 
	
	ABMLoginHandler.BuildModalSheets(page)
	
	
End Sub

public Sub ConnectPage()			
	' connecting the navigation bar - now that we have built one above...	
	' examine the code in ABMShared to see how this works...
	
	ABMShared.ConnectNavigationBar(page)
	
	
	' Let add some components to the page - labels (with text), buttons and other controls...
	' page.Cell(1,1).AddComponent(ABMShared.BuildLabel - here we add a label component to Row 1 / Cell 1, using a single statement
	' and a method found in ABMShared Code Module.  
	' page.Cell(1,1).AddComponent(ABMShared.BuildLabel(page, "basic1",  - each component MUST have a Unique ID ("basic1" in this case)
	' Notice that the text is right-justified...  How???  Using a theme - "lbltheme1"
	' I will let you discover what the other parameters are for this method...	
	page.Cell(1,1).AddComponent(ABMShared.BuildLabel(page, "basic1",   "See the faint green dot above in title bar?  This means your websocket is connected! {BR} All of this page's code is explained in the source file! {BR}{NBSP}",  ABM.SIZE_H4, "lbltheme1", 0, "25px"))

	' Here we add another component in Row 2, Cell 1 - It is essentially a label with block quote 
	page.Cell(2,1).AddComponent(ABMShared.BuildParagraphBQWithZDepth(page, "basic13",   "Hi There!  I am in Row 2 of this page!  My Text color is Blue and I have a Block Quote because of the 'theme' applied. I can also wrap to the next line and show as much text that nobody will ever read if I happened to prefix this as:{BR} {BR}'Important Instructions - {B}{I}MUST READ!'{/B}{/I}  {BR}{BR} I Have 'Flow Text' Applied. What does that mean? Resize this browser window and watch THIS text size shrink and grow accordingly!" ))

	' Lets do something different in Row 3...
	' This is a switch component (ID switch1) - (On - Off). It is set to ON (True).
	' This switch has a theme called "switch"
	Dim switch1 As ABMSwitch
	switch1.Initialize(page, "switch1","Switch Me OFF", "Switch 1 Off to see toast message!", True, "switch")
	' Add this switch component to Row 3...
	page.Cell(3,1).AddComponent(switch1)   


	'  The following components are ALSO added to Row 3 - hey why not???
	' cram another switch into cell on on row 3.  No theme for this - just a title has been added...
	Dim switch2 As ABMSwitch
	switch2.Initialize(page, "switch2","Switch 2 ON", "Switch Me ON", False, "")
	switch2.Enabled=True
	' Add a title to this switch component
	switch2.Title = " Switch 2 has THIS Title"
	page.Cell(3,1).AddComponent(switch2)
	
	' Just to crowd things some more - lets add a simple label the traditional way.... Along with a trick

	' Sometimes when we add components to the same row/cell - we need a little space between them. 
	' Here we add a dummy item to do just that... with non breakable spaces - {NBSP}
	' We have sized the space using - ABM.SIZE_H6
	' comment out the next three lines and you will see the effect - with no space between
	Dim space1 As ABMLabel
	space1.Initialize(page,"space1","{NBSP}{NBSP}{NBSP}{NBSP} ", ABM.SIZE_H6, False,"")
	page.Cell(3,1).AddComponent(space1)
	
	' Now we can add this label just below the space dummy...
	Dim space1 As ABMLabel
	' Notice this ID is "space2" even thou the object name is the same...
	space1.Initialize(page,"space2","{NBSP} I am a simple label... Are we learning anything yet? ",ABM.SIZE_SPAN,False,"")
	page.Cell(3,1).AddComponent(space1)

	' Ok, what about the other 1 row (5) we have with a 1 cell layout?  We aren't going to use it (right now). 
	' No big deal - nothing bad happens other than a little empty space...

	' Since we didn't use Row 5 - we now start at row 6 which has two cells
	' Rows with 2 cells.  Let's add some fun stuff.
	' For the first row (6) - use a theme.  This theme creates a border around the row.
	' comment this out to remove the border...
	page.Row(6).UseTheme("row1theme")
	
	
	' describe what the buttons do with some label controls...
	page.Cell(6,1).AddComponent(ABMShared.BuildLabel(page, "btns1",   "Buttons in these cells are left justified by default. {BR} The background color is the default - blue (no theme). {BR} {B} Click Button B1 to raise event called: btnpids1_clicked {/B}",  ABM.SIZE_H4, "", 0, "20px"))
	page.Cell(6,2).UseTheme("cnter") ' center the stuff in this row/cell (6,2)
	page.Cell(6,2).AddComponent(ABMShared.BuildLabel(page, "btns2",   "Buttons in these cells are centered by using a theme - 'cnter'. {BR} Hover over these buttons to see effects... {BR} Click the round (floating) button to see a menu.",  ABM.SIZE_H4, "", 0, "20px"))

	' REMEMBER! - even thou we use the same object name to create these buttons - the ID must be unique!

	' This is a flat button - simple as they get.  
	' with no theme - the default behaviour is applied...
	Dim btnpids As ABMButton
	btnpids.InitializeFlat( page ,  "btnpids1", "mdi-action-settings", ABM.ICONALIGN_LEFT,"B1 - A Flat Button","")
	page.Cell(7,1).AddComponent(btnpids)

	' This button is centered in cell 2 by using a theme (see -	MyTheme.AddCellTheme("cnter") in ABMShared module
	Dim btnpids As ABMButton
	btnpids.InitializeRaised( page ,  "btnpids2", "mdi-action-delete", ABM.ICONALIGN_LEFT,"B2 - A Raised Button","amber")
	page.Cell(7,2).UseTheme("cnter")
	page.Cell(7,2).AddComponent(btnpids)

	' Full cell width anyone????  Dish it up.
	Dim btnpids As ABMButton
	btnpids.InitializeFlat( page ,  "btnpids3", "mdi-action-settings", ABM.ICONALIGN_LEFT,"B3 - Full Cell Width (Down Arrow means a menu is present) --> ","")
	btnpids.UseFullCellWidth = True
	btnpids.AddMenuItem("mnu9","A menu on a button eh...")
	btnpids.AddMenuItem("mnu8","Now that'sweet...")
	
	page.Cell(8,1).AddComponent(btnpids)

	' This floating button was set to a large size, centered and has a menu. 
	Dim btnpids As ABMButton
	btnpids.InitializeFloating( page ,  "btnpids4", "mdi-editor-format-list-numbered","amber1")
	btnpids.Size = ABM.BUTTONSIZE_LARGE
	page.Cell(8,2).UseTheme("cnter")
	btnpids.AddMenuItem("mnu1","Menu Item 1")
	btnpids.AddMenuItem("mnu2","Menu Item 2")
	btnpids.AddMenuItem("mnu3","Menu Item 3")
	btnpids.DropdownShowBelow = True
	page.Cell(8,2).AddComponent(btnpids)
	
	' brag a little - it's worth it...
	page.Row(9).UseTheme("row1theme")  ' border this row....(9)
	page.Cell(9,1).AddComponent(ABMShared.BuildLabel(page, "text1",   "Up until this point, you have not heard, read or have had implied the notion of JavaScript, HTML, JQuery, CSS or other such foul language... {BR} And you won't from this point on either! {BR}{BR}  That is the Beauty of {B}{I} ABMaterial! {/B}{/I} {BR}{BR} Click the image to see (img.IsMaterialBoxed = True) effect ---> ",  ABM.SIZE_H4, "lbltheme3", 0, "20px"))
		
	' add an image to say what we really mean....
	' note where the image is derived from.  Go find it in the folder and replace it with your own image (if you wish)...	
	Dim img As ABMImage
	img.Initialize(page , "img1" ,"../images/alot.jpg", 1.0)
	page.Cell(9,2).UseTheme("cnter")
	page.Cell(9,2).AddComponent(img)
	img.IsMaterialBoxed = True
    ' uncomment these to see the effects on the image...
	'	img.SetFixedSize( 120,75)
	'	img.IsCircular = True



	page.Cell(10,1).AddComponent(ABMShared.BuildLabel(page, "pdftext1",   "The PDF Viewer Component",  ABM.SIZE_H4, "lbltheme1", 0, "20px"))
		
	' Now here is a cool component - the PDF viewer...
	' note the options of this control - without you having to code a damn thing...	
	' also note where the pdf file exists... - "../images/1.pdf"
	Dim pdf As ABMPDFViewer
	pdf.Initialize(page, "pdf", 600, "../images/1.pdf","")
	pdf.PreparePrintingText = "Preparing to print..."
	pdf.ReadDirection = ABM.PDF_READDIRECTION_LTR
	pdf.AllowDownload = True
	pdf.AllowOpen = False
	pdf.AllowPrint = True
	pdf.AllowSideBar = True
	pdf.AllowViewBookmark = False
	page.Cell(10,1).AddComponent(pdf)
	
	
	' Now It's Your Turn ...  Comment out this line below and add your own control...
	' go to the demo site and choose some other control from the Controls menu section.
	' add it in page.Cell(10,2) - just like below...
	page.Cell(10,2).AddComponent(ABMShared.BuildLabel(page, "text2",   "{BR}{BR}{BR}{BR}{BR}{BR}{BR} Ok, now it's your turn....  {BR} Click link below...{BR}and add your own control here... {BR}{BR} {AL}http://prd.one-two.com:51042/demo/CompCardPage/abmaterial-card.html{AT}{C:#00B183}ABMaterial Demo Site{/C}{/AL} {BR}  {BR}{BR} Simply copy and paste code (in most cases), as I did with the PDF viewer!",  ABM.SIZE_H4, "lbltheme2", 0, "20px"))
	

	' At this point, you should pretty much understand how to add various components to rows and cells.
	page.Cell(11,1).AddComponent(ABMShared.BuildLabel(page, "text4",   "Size 6 Cell - using cell theme (tcell2) ",  ABM.SIZE_H4, "", 0, "25px"))
	page.Cell(11,2).AddComponent(ABMShared.BuildLabel(page, "text5",   "Size 3 Cell - with border",  ABM.SIZE_H4, "lbltheme3", 0, "20px"))
	page.Cell(11,3).AddComponent(ABMShared.BuildLabel(page, "text6",   "Size 3 Cell - Font 25px",  ABM.SIZE_H6, "", 0, "25px"))
	page.Cell(12,2).AddComponent(ABMShared.BuildLabel(page, "text7",   "Hi - Row 12 / Cell 2 here...  My height is automatically adjusted to fit this text.",  ABM.SIZE_H4, "", 0, "25px"))
		
	' To make ANY of the above show - we need to refresh the page!
	page.Refresh		
	
	
	' restoring the navigation bar position
	page.RestoreNavigationBarPosition


	' We aslo must tell the browser we finished loading... and stop the spinning circles....
	page.FinishedLoading

	
	' ************************************************
	' We are done - page will Show and Good to Go!!!!!
	' ************************************************
	
	
End Sub

' clicked on the navigation bar
Sub Page_NavigationbarClicked(Action As String, Value As String)	
	' saving the navigation bar position
	page.SaveNavigationBarPosition
	If Action = "LogOff" Then
		ABMShared.LogOff(page)
		Return
	End If

	ABMShared.NavigateToPage(ws, ABMPageId, Value)
End Sub

Sub Page_MsgboxResult(returnName As String, result As String)
	' here is where we react to msgbox button clicks...
	' this example only used msgbox.  There is also page.msgbox2 - for one or more responses...
	
	Select Case returnName
		Case "BTNS1"
		Log(" What is the msgbox result (button click)?: "&result)
		Select Case result
			Case "abmok"
				myToastId = myToastId + 1
				page.ShowToast("toast" & myToastId, "toastgreen", " Modal Message Box Was CLosed!", 5000, False)
			' add more cases accordingly...
				
		End Select
	End Select

End Sub

Sub Page_InputboxResult(returnName As String, result As String)
	
	' used with Input boxes - a later section perhaps...
	
End Sub

Sub Page_DebugConsole(message As String)
	Log("---> " & message)	
End Sub


Sub BuildSimpleItem(id As String, icon As String, Title As String) As ABMLabel ' not used here.....
	Dim lbl As ABMLabel
	If icon <> "" Then
		lbl.Initialize(page, id, Title, ABM.SIZE_H6, True,  "header") ' there isn't a "header" theme so nothing is applied!
	Else
		lbl.Initialize(page, id, Title, ABM.SIZE_H6, True, "")
	End If
	lbl.VerticalAlign = True
	lbl.IconName = icon
	Return lbl
End Sub


' this is the event that is fired when switch 1 is clicked - hence the switch1_Clicked name...
Sub switch1_Clicked(Target As String)
	Dim checked As String
	Dim switch1 As ABMSwitch = page.Component("switch1")
	If switch1.State Then
		checked= "On"
	Else
		checked= "Off"
	End If
	myToastId = myToastId + 1
	page.ShowToast("toast" & myToastId, "toastgreen", "Here is the toast message - Switch 1 is " & checked, 5000, False)
End Sub


' this is the event that is fired when associated button is clicked... 
Sub btnpids1_clicked(Target As String)
	' see - Page_MsgboxResult(returnName As String, result As String) for how to react to these message boxes...
	Log(Target&" was clicked")
	page.Msgbox("BTNS1","This modal message is center and bottom aligned...{BR}Many options exist to place box where you like...","You Clicked button B1 and got this MESSAGE with Big Bold Text.","Dismiss Me",False,ABM.MSGBOX_POS_BOTTOM_CENTER,"")
	
End Sub
