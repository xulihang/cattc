B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=6.01
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private dialogForm As Form
	Private Button1 As Button
	Private ListView1 As ListView
	Private email As String
End Sub

Public Sub show(key As String)
	dialogForm.Initialize("dialog",600,600)
	dialogForm.RootPane.LoadLayout("dialog")
	dialogForm.Show
    email=key
	loadMap(Main.kvs.Get(key))
End Sub


Sub Button1_MouseClicked (EventData As MouseEvent)
	Dim map1 As Map
	map1.Initialize
	For Each item As Pane In ListView1.Items
		Dim lbl As Label
		Dim tf As TextField
		lbl=item.GetNode(1)
		tf=item.GetNode(0)
		map1.Put(lbl.Text,tf.Text)
	Next
	Main.kvs.Put(email,map1)
End Sub

Sub loadMap(map1 As Map)
	For Each key As String In map1.Keys
		Dim pane1 As Pane
		pane1.Initialize("innerpane")
		pane1.LoadLayout("innerPane")
		Dim lbl As Label
		Dim tf As TextField
		lbl=pane1.GetNode(1)
		lbl.Text=key
		tf=pane1.GetNode(0)
		tf.Text=map1.Get(key)
		ListView1.Items.Add(pane1)
	Next
End Sub