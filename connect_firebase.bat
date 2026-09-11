@echo off
title Firebase CLI Setup - NABHA RuralCare
echo ============================================================
echo         NABHA RuralCare - Firebase CLI Setup
echo ============================================================
echo.

:: Ensure both Firebase CLI and FlutterFire CLI are in PATH
set "PATH=%PATH%;C:\Users\siddh\AppData\Local\Microsoft\WinGet\Packages\Google.FirebaseCLI_Microsoft.Winget.Source_8wekyb3d8bbwe;C:\Users\siddh\AppData\Local\Pub\Cache\bin"

cd /d "c:\NABHA\flutter_app"

echo [1/2] Authenticating Firebase CLI...
echo (A browser window will open to log in with your Google account)
echo.
firebase login

echo.
echo [2/2] Running FlutterFire Configure...
echo (Select your Firebase project when prompted)
echo.
flutterfire configure

echo.
echo ============================================================
echo Firebase CLI configuration finished!
echo ============================================================
pause
