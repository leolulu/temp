@echo off

setlocal enabledelayedexpansion

REM ������Ч�����б��ļ�
echo ��ʼ���������ļ�...
del %FIRST_TWO_WORKDAYS_JSON_PATH%
del %ALL_DAYS_INFO_JSON_PATH%
powershell -ExecutionPolicy Bypass -File .\fetch_dates.ps1


REM ���ǻ�ѡ�ɲ��֡�
set maxRetries=5
set retries=0
set success=false

:retrySikulix
echo �رմ��ǻ۽���...
taskkill /F /IM dzh2.exe /T

echo �������ǻ�...
start /D C:\daily_stock\dzh365_2 DZHTool.exe
ping 127.0.0.1 -n 30 > nul
cd /d C:\daily_stock\sikuli

REM Start the java command in a new window with a unique title
echo ����SikulixJob�Ӵ���...
start "SikulixJob" cmd /c "echo 1 > java_sikuli_errorlevel.txt & java -jar sikulix.jar -r allinone_stock_after_4pm.sikuli > sikuli.log & echo %errorlevel% > java_sikuli_errorlevel.txt"

REM Start a delayed task in the background that will kill the java command after 30 minutes
echo ����TimeoutJob�Ӵ���...
start "TimeoutJob" cmd /c "ping 127.0.0.1 -n 1800 > nul && taskkill /F /FI "WindowTitle eq SikulixJob" /T"

:checkSikulix
REM Check if the SikulixJob is still running every minute
tasklist /FI "WindowTitle eq SikulixJob" | findstr /i "cmd.exe" > nul
if errorlevel 1 (
    REM The job has finished
    echo ��⵽SikulixJob�����ѹر�...
    
    REM Read the errorlevel from the temporary file
    set /p sikulixErrorlevel=<java_sikuli_errorlevel.txt
	
	for /f "tokens=* delims= " %%a in ("!sikulixErrorlevel!") do set "sikulixErrorlevel=%%a"
	for /f "tokens=* delims= " %%a in ("!sikulixErrorlevel:~0,-1!") do set "sikulixErrorlevel=%%a"
	
	echo ͨ������ļ����ļ���sikulixErrorlevel��ֵΪ��
	echo !sikulixErrorlevel!
    if !sikulixErrorlevel! equ 0 (
	    echo sikuli���������������sucessΪtrue...
        set success=true
    )
) else (
    echo SikulixJob���������У��ȴ���ʮ��...
    ping 127.0.0.1 -n 60 > nul
    goto :checkSikulix
)

REM Kill the timeout job (if it's still running)
echo �ر��Ѿ�û���õ�TimeoutJob...
taskkill /F /FI "WindowTitle eq TimeoutJob" /T

echo ��Ϊ���ǻ۽׶��ѽ���������sucess״̬Ϊ��
echo %success%
if %success% == true (
    echo ���ǻ����н��check1ͨ��...
) else (
    set /a retries+=1
	echo ���ǻ۽׶�����״̬��������׼����ʼ���ԣ���ǰ���Դ���Ϊ��
	echo !retries!
    if !retries! lss %maxRetries% (
        goto :retrySikulix
    )
)
if %success% == true (
    echo ���ǻ����н��check2ͨ��...
) else (
    echo ���ǻ۽׶�����ʧ�ܣ��Ѵﵽ������Դ���...
    goto :skip_code
)
echo ���ǻ۽׶����гɹ�...


REM OCRʶ�𲿷�
for /f "tokens=1 delims=:" %%a in ("%time%") do set currentHour=%%a
set /a currentHour=1%currentHour%-100
if %currentHour% geq 13 (
    if %currentHour% lss 16 (
        echo 13�㵽16��֮�䣬����ִ�д���
        goto :skip_code
    )
)
ping 127.0.0.1 -n 10 > nul
start python "C:\daily_stock\screenshot_ocr.py" >> sikuli.log


REM ��������
:skip_code