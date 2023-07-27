@echo off

setlocal enabledelayedexpansion

REM 生成有效日期列表文件
echo 开始生成日期文件...
del %FIRST_TWO_WORKDAYS_JSON_PATH%
del %ALL_DAYS_INFO_JSON_PATH%
powershell -ExecutionPolicy Bypass -File .\fetch_dates.ps1


REM 大智慧选股部分↓
set maxRetries=5
set retries=0
set success=false

:retrySikulix
echo 关闭大智慧进程...
taskkill /F /IM dzh2.exe /T

echo 启动大智慧...
start /D C:\daily_stock\dzh365_2 DZHTool.exe
ping 127.0.0.1 -n 30 > nul
cd /d C:\daily_stock\sikuli

REM Start the java command in a new window with a unique title
echo 启动SikulixJob子窗口...
start "SikulixJob" cmd /c "echo 1 > java_sikuli_errorlevel.txt & set java_sikuli_errorlevel_path=%CD%\java_sikuli_errorlevel.txt & java -jar sikulix.jar -r allinone_stock_after_4pm.sikuli > sikuli.log"

REM Start a delayed task in the background that will kill the java command after 30 minutes
echo 启动TimeoutJob子窗口...
start "TimeoutJob" cmd /c "ping 127.0.0.1 -n 1800 > nul && taskkill /F /FI "WindowTitle eq SikulixJob" /T"

:checkSikulix
REM Check if the SikulixJob is still running every minute
tasklist /FI "WindowTitle eq SikulixJob" | findstr /i "cmd.exe" > nul
if errorlevel 1 (
    REM The job has finished
    echo 检测到SikulixJob窗口已关闭...
    
    REM Read the errorlevel from the temporary file
    set /p sikulixErrorlevel=<java_sikuli_errorlevel.txt
	
	for /f "tokens=* delims= " %%a in ("!sikulixErrorlevel!") do set "sikulixErrorlevel=%%a"
	for /f "tokens=* delims= " %%a in ("!sikulixErrorlevel:~0,-1!") do set "sikulixErrorlevel=%%a"
	
	echo 通过检测文件，文件中sikulixErrorlevel的值为：
	echo !sikulixErrorlevel!
    if !sikulixErrorlevel! equ 0 (
	    echo sikuli检测结果正常，设置sucess为true...
        set success=true
    )
) else (
    echo SikulixJob正在运行中，等待六十秒...
    ping 127.0.0.1 -n 60 > nul
    goto :checkSikulix
)

REM Kill the timeout job (if it's still running)
echo 关闭已经没有用的TimeoutJob...
taskkill /F /FI "WindowTitle eq TimeoutJob" /T

echo 认为大智慧阶段已结束，最终sucess状态为：
echo %success%
if %success% == true (
    echo 大智慧运行结果check1通过...
) else (
    set /a retries+=1
	echo 大智慧阶段运行状态不正常，准备开始重试，当前重试次数为：
	echo !retries!
    if !retries! lss %maxRetries% (
        goto :retrySikulix
    )
)
if %success% == true (
    echo 大智慧运行结果check2通过...
) else (
    echo 大智慧阶段运行失败，已达到最大重试次数...
    goto :skip_code
)
echo 大智慧阶段运行成功...


REM OCR识别部分
for /f "tokens=1 delims=:" %%a in ("%time%") do set currentHour=%%a
set /a currentHour=1%currentHour%-100
if %currentHour% geq 13 (
    if %currentHour% lss 16 (
        echo 13点到16点之间，跳过执行代码
        goto :skip_code
    )
)
ping 127.0.0.1 -n 10 > nul
start python "C:\daily_stock\screenshot_ocr.py" >> sikuli.log


REM 结束部分
:skip_code