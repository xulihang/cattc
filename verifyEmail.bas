﻿B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.01
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Try
		resp.ContentType="text/html"
		resp.CharacterEncoding="UTF-8"

		Dim base64,decoded As String
		base64=req.GetParameter("base64")

		Log(base64)
		Dim su As StringUtils
		Dim data() As Byte
		data=su.DecodeBase64(base64)
		decoded=BytesToString(data,0,data.Length,"UTF8")
		Log(decoded)
		Dim asu As ApacheSU
		Dim list1 As List
		list1=asu.SplitWithSeparator(decoded,"&")
		Log(list1.Get(0))
		Dim email,code As String
		email=list1.Get(0)
		code=list1.Get(1)
		Log(code)
		If File.Exists(File.DirApp,"verifyCodes.map") Then
			Dim map1 As Map
			map1=File.ReadMap(File.DirApp,"verifyCodes.map")
			'Log(map1.Get(email))
			'Log(base64)
			If su.EncodeUrl(base64,"UTF8")=map1.Get(email) Then

				If req.ParameterMap.ContainsKey("type") And req.GetParameter("type")="new" Then
					changeVerified(email)
					resp.Write("邮箱已验证！")
					'wait for (changeVerified(email)) Complete (Success As Boolean)
					'If Success=True Then
					'	resp.Write("邮箱已验证！")
					'	'新注册验证
					'Else
					'	resp.Write("处理失败！")
					'End If

				Else
				    File.WriteString(File.DirApp,"EmailToBeReset",email) '重制密码验证
					resp.SendRedirect("fanyi/resetPasswordPage")
				End If

				'resp.Write("重制成功")
			Else
				resp.Write("代码错误")
			End If
		
		Else
			resp.Write("错误，没有该邮箱记录")
		End If
	Catch
		Log(LastException)
		resp.SendError(500,"参数错误")
	End Try

End Sub

Sub changeVerified(email As String)
    If ABMShared.kvs.IsInitialized=False Then
		ABMShared.kvs.Initialize(File.DirApp,"users.db")
	End If
	Dim map2 As Map
	map2=ABMShared.kvs.Get(email)
	map2.Put("verified","已验证")
	ABMShared.kvs.Put(email,map2)
End Sub