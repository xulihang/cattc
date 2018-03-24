B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.01
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private reviewForm As Form

	Private saveBtn As Button
	Private TabPane1 As TabPane
	Private Button1 As Button
	Private TextArea1 As TextArea
	Private TextField1 As TextField
	Private email As String
	Private score As Map

End Sub

Public Sub show(em As String)
	email=em
	reviewForm.Initialize("reviewForm",600,600)
	reviewForm.RootPane.LoadLayout("reviewtab")
	reviewForm.Title="答者邮箱："&email
	TabPane1.LoadLayout("review","汉译英")
	TabPane1.LoadLayout("review","英译汉")
	TabPane1.LoadLayout("review","技术传播")
	reviewForm.Show
    If score.IsInitialized Then
		score.Clear
	Else
		score.Initialize
    End If
	If File.Exists(File.Combine(File.DirApp,"submitted"),email&".json") Then
		loadcontent
	End If
	If File.Exists(File.Combine(File.DirApp,"submitted"),email&"-score.json") Then
		loadscore
	End If
End Sub



Sub TabPane1_TabChanged (SelectedTab As TabPage)
	
End Sub

Sub saveBtn_MouseClicked (EventData As MouseEvent)
	If File.Exists(File.Combine(File.DirApp,"submitted"),email&"-score.json") Then
		fx.Msgbox(reviewForm,"这是已经打过分的","")
		Return
	End If
	Log(score)
    If score.Size=3 Then
		Dim json As JSONGenerator
		json.Initialize(score)
		File.WriteString(File.Combine(File.DirApp,"submitted"),email&"-score.json",json.ToString)
		fx.Msgbox(reviewForm,"已保存","")
	Else
		fx.Msgbox(reviewForm,"请打完分数","")
    End If
End Sub

'保存单个成绩
Sub Button1_MouseClicked (EventData As MouseEvent)
	Dim btn As Button
	btn=Sender
	Dim pane As Pane
	pane=btn.Parent
	Log(TabPane1.SelectedItem.Text)
	Log(TabPane1.SelectedIndex)

	Dim tf1 As TextField
	tf1=pane.GetNode(2)


	Log(tf1.Text)
	score.Put(TabPane1.SelectedItem.Text,tf1.Text)
	
End Sub

Sub loadscore
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(File.DirApp,"submitted"),email&"-score.json"))
	Dim map1 As Map
	map1=json.NextObject
	For Each tab1 As TabPage In TabPane1.Tabs
		Dim pane As Pane
		pane=tab1.Content
		Dim tf1 As TextField
		tf1=pane.GetNode(2)
		tf1.Text=map1.Get(tab1.Text)
	Next
End Sub

Sub loadcontent
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.Combine(File.DirApp,"submitted"),email&".json"))
	Dim map1 As Map
	map1=json.NextObject
	For Each tab1 As TabPage In TabPane1.Tabs
		Dim pane As Pane
		pane=tab1.Content
		Dim ta1 As TextArea
		ta1=pane.GetNode(0)
		ta1.Text=map1.Get(tab1.Text)
	Next
End Sub