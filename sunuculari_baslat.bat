@echo off
chcp 65001 > nul
title SözEğitim Ağ Sunucusu (Backend & Web)
color 0B

echo ======================================================================
echo           SÖZEĞİTİM AĞ SUNUCUSU BAŞLATILIYOR
echo ======================================================================
cd /d "%~dp0"

:: Aktif Yerel IP Adresini Bul
for /f "tokens=4" %%a in ('route print ^| findstr 0.0.0.0.*0.0.0.0 ^| findstr /v "127.0.0.1"') do (
    set LOCAL_IP=%%a
    goto :ip_found
)
:ip_found
if "%LOCAL_IP%"=="" set LOCAL_IP=192.168.1.104

echo.
echo [1/2] Backend Sunucusu (FastAPI) Baslatiliyor...
echo       - Yerel IP:  http://%LOCAL_IP%:8000
echo       - Swagger UI: http://%LOCAL_IP%:8000/docs
echo.
echo [2/2] Web Sunucusu (Flutter Web) Baslatiliyor...
echo       - Tarayici:  http://%LOCAL_IP%:8080
echo.
echo ======================================================================
echo  TELEFONDAN BAGLANTI:
echo  1. Telefonunuzun ayni Wi-Fi agina bagli oldugundan emin olun.
echo  2. Mobil uygulamada giris ekraninda sag ustteki [IP] butonuna basarak
echo     "http://%LOCAL_IP%:8000" adresinin secili oldugundan emin olun.
echo     (Uygulama otomatik olarak da bu IP'yi tarayip baglanacaktir!)
echo ======================================================================
echo.
echo Sunucular calisiyor, bu pencereyi KAPATMAYIN. Simge durumuna kucultebilirsiniz.
echo.

:: Web sunucusunu arka planda baslat (eger calismiyorsa)
powershell -Command "if (-not (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue)) { Start-Process -WindowStyle Hidden .\.venv\Scripts\python.exe -ArgumentList '-m http.server 8080 --directory sozegitim-frontend_temel-2\build\web --bind 0.0.0.0' }"

:: Backend uvicorn sunucusunu on planda baslat (canli loglar gorunsun)
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --app-dir backend_python

pause
