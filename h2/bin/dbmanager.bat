@echo off

if "%OS%" == "Windows_NT" setlocal

if not "%INFA_HOME%"=="" goto okInfaHome
for %%I in (%0) do set CMD_NAME=%%~nI
set CMD_NAME=%CMD_NAME%.bat

rem Get batch file dir from cmd line relative path, or from PATH
rem
for %%I in (%0) do set CMD_FILE_DIR=%%~dpI
if exist "%CMD_FILE_DIR%%CMD_NAME%" goto cdCmdDir
for %%I in (%CMD_NAME%) do set CMD_FILE_DIR=%%~dp$PATH:I

:cdCmdDir
cd "%CMD_FILE_DIR%\..\.."
set INFA_HOME=%cd%

:okInfaHome
set JAVA_HOME=%INFA_HOME%\java
set CLASSPATH=
set CLASSPATH=%CLASSPATH%;%JAVA_HOME%\lib\tools.jar;%INFA_HOME%\H2\bin\h2-1.3.169.jar;

:getCommand
if /I "%1" == "startup" goto doStartup
if /I "%1" == "shutdown" goto doShutdown
if /I "%1" == "updateMRS" goto updateMRSDB
echo Unknown parameter "%1"
goto end

rem DB Server Startup as a foreground process
:doStartup
echo Starting H2 DB server
if /I not "%INFA_HOME%" == "" goto displayInfaHome
echo Using JAVA_HOME:        %JAVA_HOME%
goto startH2
:displayInfaHome
echo Using INFA_HOME:        %INFA_HOME%
:startH2
set INFA_H2_JAVA_OPTS=-Xmx512m %INFA_H2_JAVA_OPTS% -XX:MaxPermSize=128m -XX:+HeapDumpOnOutOfMemoryError
set INFA_JAVA_OPTS=%INFA_JAVA_OPTS% -Dinfa.pcsf.jdbc.driver=org.h2.Driver
start "H2SERVER" "%JAVA_HOME%\bin\javaw" -ea %INFA_H2_JAVA_OPTS% -Duser.dir="%INFA_HOME%\h2\bin" -classpath "%CLASSPATH%" org.h2.tools.Server -pg -pgDaemon -pgAllowOthers -tcp -tcpAllowOthers -tcpPort 9092 -pgPort 5435
"%JAVA_HOME%\bin\java" -classpath "%INFA_HOME%\h2\bin\com.informatica.products.assembly-h2.jar;%INFA_HOME%\h2\bin\h2-1.3.169.jar" com.informatica.h2check.H2ServerTest 9092
set INFA_DB_EX=%ERRORLEVEL%
if "%INFA_DB_EX%" == "1" (
   echo "H2 Database Server did not start properly. Please check if the port allocated to the server is not being used by another process"
)
exit /B %INFA_DB_EX%

rem DB Server Shutdown foreground process
:doShutdown
"%JAVA_HOME%\bin\javaw" -classpath "%CLASSPATH%" org.h2.tools.Server -tcpShutdown tcp://localhost:9092 >> "%INFA_HOME%"/h2/h2-shutdown.out 2>&1
if %ERRORLEVEL%==1 goto notRunning
echo Stopping H2 server
goto end

:updateMRSDB
echo "UPDATE MRS: %2"
"%JAVA_HOME%\bin\java" -classpath "%CLASSPATH%" org.h2.tools.RunScript -url %2 -user %3 -password %4 -script %INFA_HOME%/h2/bin/update.sql
goto end

:notRunning
echo H2 server is not running
goto end

:end
if "%OS%" == "Windows_NT" endlocal