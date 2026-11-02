Set WshShell = CreateObject("WScript.Shell")
Set FileSystem = CreateObject("Scripting.FileSystemObject")
' SözEğitim Backend Sunucusunu arka planda siyah pencere olmadan çalıştırır
WshShell.CurrentDirectory = FileSystem.GetParentFolderName(WScript.ScriptFullName)
WshShell.Run "cmd /c .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --app-dir backend_python", 0, False
