Set WshShell = CreateObject("WScript.Shell")
' SözEğitim Backend Sunucusunu arka planda siyah pencere olmadan çalıştırır
WshShell.CurrentDirectory = "c:\Users\alii0\Desktop\sozegitim-main"
WshShell.Run "cmd /c .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --app-dir backend_python", 0, False
