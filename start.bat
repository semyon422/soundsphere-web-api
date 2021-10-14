@echo off
call setpaths.bat
luajit -e require('lapis.cmd.actions').execute({'server'})
pause