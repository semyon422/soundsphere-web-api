@echo off
nginx -s stop
taskkill /IM nginx.exe /f
