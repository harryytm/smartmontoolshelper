@echo off
title smartmontools helper
rem Check if the script is running with administrator rights
attrib %windir%\system32 -h | findstr /I "denied" >nul
if not errorlevel 1 goto admin_needed
cls
echo.
echo smartmontoolshelper
echo Copyright (C) 2017 Harry Yeung Tim Ming
echo.
echo This program is free software; you can redistribute it and/or
echo modify it under the terms of the GNU General Public License
echo as published by the Free Software Foundation; either version 2
echo of the License, or (at your option) any later version.
echo.
echo This program is distributed in the hope that it will be useful,
echo but WITHOUT ANY WARRANTY; without even the implied warranty of
echo MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
echo GNU General Public License for more details.
echo.
echo You should have received a copy of the GNU General Public License
echo along with this program; if not, write to the Free Software
echo Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
echo.
timeout /t 1

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
echo 0. Exit
echo.
set /p varTask=Enter the number of the task: 
echo.
if "%varTask%" == "1" goto send_selected_menu
if "%varTask%" == "2" goto scan_usb
if "%varTask%" == "v" goto disp_version
if "%varTask%" == "0" goto end
echo Error: Invalid input
timeout /t 1
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
echo Current selected disks: Disk %startdev% to Disk %enddev%
echo.
echo 1. Change selected disks
echo 2. Display disks information
echo 3. Display disks S.M.A.R.T. attributes
echo 4. Display disks temperature
echo 5. Set standby time and APM
echo 6. Start extended self-test
echo 7. Display self-test log
echo 0. Return to main menu
echo.
set /p varTask=Enter the number of the task: 
echo.
if "%varTask%" == "1" goto set_ranges
if "%varTask%" == "2" goto disp_disks_info
if "%varTask%" == "3" goto disp_disks_attribute
if "%varTask%" == "4" goto disp_disks_temp
if "%varTask%" == "5" goto set_disks_standby_apm
if "%varTask%" == "6" goto send_selftestlong
if "%varTask%" == "7" goto disp_disks_selftest
if "%varTask%" == "0" goto main_menu
echo Error: Invalid input
timeout /t 3
goto send_selected_menu

rem Messages section

:send_selected_msg
cls
echo Sending command to disks from Disk %startdev% to Disk %enddev% ...
echo.
goto :EOF

:exec_completed
rem Section to diplay command completed message and return to main menu
echo.
echo Command completed.
pause
goto :EOF

:admin_needed
cls
echo Error: Administrator rights needed,
echo Please run this script with administrator rights!
echo.
pause
goto END

:set_ranges
echo Please enter the range of disks to select,
echo leave empty to use current settings.
echo.
set /p startdev=From Disk: 
set /p enddev=To Disk: 
echo.
goto send_selected_menu

:scan_usb
cls
echo Scanning external disks ...
echo.
smartctl --scan-open -d usb -n standby
call :exec_completed
goto main_menu

:disp_disks_info
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
		 echo Device:           Disk %%a
     smartctl /dev/pd%%a -i | findstr /c:"Device Model:" /c:"Serial Number:"
     echo.
)
call :exec_completed
goto send_selected_menu

:disp_disks_attribute
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to /dev/pd%%a ...
     echo.
     smartctl /dev/pd%%a -Aif brief
     echo.
)
call :exec_completed
goto send_selected_menu

:disp_disks_selftest
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to /dev/pd%%a ...
     echo.
     smartctl /dev/pd%%a -l selftest -i
     echo.
)
call :exec_completed
goto send_selected_menu

:disp_disks_temp
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
     echo Sending command to Disk %%a...
     echo.
     smartctl /dev/pd%%a -l scttemp
     echo.
)
call :exec_completed
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
if "%current%" == "1" goto current_standby_apm
echo Please config the setting, leave empty to use current settings.
echo.
echo 120=10mins 241=30mins
set /p standby=Standby (%standby%): 
set /p apm=APM (%apm%): 
set /p standbynow=Standby after sent command? 1=yes empty=no: 
:current_standby_apm
cls
echo Will send command to device(s) /dev/pd%startdev% to /dev/pd%enddev%
echo.
echo Standby value: %standby%
echo APM value: %apm%
echo Standby after sent command: %standbynow%
timeout /t 2
echo.
echo %date% %time%
call :send_selected_msg
if "%standbynow%" == "1" set standbynowsw= -s standby,now
for /L %%a in (%startdev%,1,%enddev%) do (
	echo Sending command to /dev/pd%%a ...
	smartctl /dev/pd%%a -d sat -i -s apm,%apm% -s standby,%standby%%standbynowsw% | findstr /c:"Device Model:" /c:"Serial Number:" /c:"APM set to level" /c:"Standby timer set to"
	echo.
)
echo.
echo %date% %time%
call :exec_completed
goto send_selected_menu

:send_selftestlong
call :send_selected_msg
for /L %%a in (%startdev%,1,%enddev%) do (
	echo Sending command to Disk %%a...
	smartctl /dev/pd%%a -n standby -t long
	echo.
)
call :exec_completed
goto send_selected_menu

:END
