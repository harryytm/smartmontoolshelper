@echo off
title smartmontools helper

:main_menu
set varTask=
cls
echo.
echo Please select tasks to perform
echo ==============================
echo.
echo 1. Send command to selected disks(/dev/pdN)
echo 2. Scan all external disks
echo.
echo v. Display smertmontools version
echo e. Exit
echo.
set /p varTask=Enter the number of the task: 
echo.
if "%varTask%" == "1" goto send_selected_menu
if "%varTask%" == "2" goto scan_usb
if "%varTask%" == "v" goto disp_version
if "%varTask%" == "e" goto end
echo Error: Invalid input
timeout /t 3
goto main_menu

:send_selected_menu
if "%startdev%" == "" goto set_ranges
if "%enddev%" == "" goto set_ranges
set varTask=
cls
echo.
echo Send command to selected disks
echo ==============================
echo.
echo Current selected disks: /dev/pd%startdev% to /dev/pd%enddev%
echo.
echo 1. Change selected disks
echo 2. Display disks information
echo 3. Display disks S.M.A.R.T. attributes
echo 4. Display disks temperature
echo 5. Set standby time and APM
echo 6. Start extended self-test
echo r. Return to main menu
echo.
set /p varTask=Enter the number of the task: 
echo.
if "%varTask%" == "1" goto set_ranges
if "%varTask%" == "2" goto disp_disks_info
if "%varTask%" == "3" goto disp_disks_attribute
if "%varTask%" == "4" goto disp_disks_temp
if "%varTask%" == "5" goto set_disks_standby_apm
if "%varTask%" == "6" goto send_selftestlong_pd
if "%varTask%" == "r" goto main_menu
echo Error: Invalid input
timeout /t 3
goto send_selected_menu

:set_ranges
echo Please enter the range of disks to select.
echo.
set /p startdev=From device: /dev/pd
set /p enddev=To device: /dev/pd
echo.
goto send_selected_menu

:scan_usb
cls
echo Scanning external disks . . .
echo.
smartctl --scan-open -d usb -n standby
call :exec_completed
goto main_menu

:send_selected_msg
cls
echo Sending command to disks /dev/pd%startdev% to /dev/pd%enddev% . . .
echo.
goto :EOF

:disp_disks_info
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to /dev/pd%%a...
     echo.
     smartctl /dev/pd%%a -i
     echo.
)
call :exec_completed
goto send_selected_menu

:disp_disks_attribute
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to /dev/pd%%a...
     echo.
     smartctl /dev/pd%%a -Aif brief
     echo.
)
call :exec_completed
goto send_selected_menu

:disp_disks_temp
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to /dev/pd%%a...
     echo.
     smartctl /dev/pd%%a -l scttemp
     echo.
)
goto send_selected_menu

:disp_version
cls
smartctl -V
call :exec_completed
goto main_menu

:set_disks_standby_apm
rem Default setting in case settings is empty
if "%standby%" == "" set standby=120
if "%standbynow%" == "" set standbynow=0
if "%apm%" == "" set apm=191

echo Current settings:
echo.
echo Device(s) /dev/pd%startdev% to /dev/pd%enddev%
echo Standby value: %standby%
echo APM value: %apm%
echo Standby after sent command: %standbynow%
echo.
set /p current=Use current? 1=yes empty=no: 
if "%current%" == "1" goto default_standby_apm

echo Please config the setting, leave empty to use current settings.
echo.
echo 120=10mins 241=30mins
set /p standby=Standby (%standby%): 
set /p apm=APM (%apm%): 
set /p standbynow=Standby after sent command? 1=yes empty=no: 

:default_standby_apm
cls
echo Will send command to device(s) /dev/pd%startdev% to /dev/pd%enddev%
echo.
echo Standby value: %standby%
echo APM value: %apm%
echo Standby after sent command: %standbynow%
timeout /t 3
echo.
echo %date% %time%
call :send_selected_msg
if "%standbynow%" == "1" set standbynowsw= -s standby,now
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to /dev/pd%%a ...
     echo.
     smartctl /dev/pd%%a -d sat -i -s apm,%apm% -s standby,%standby%%standbynowsw%
)
echo.
echo %date% %time%
call :exec_completed
goto send_selected_menu

:exec_completed
rem Section to diplay command completed message and return to main menu
echo.
echo Command completed.
pause
goto :eof

:end