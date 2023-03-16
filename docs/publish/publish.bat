@echo off
set LOCAL_PATH=.\bin\Debug\net6.0\publish\
echo Selecting profile %1
IF "%1" == "real" (
        set USER=root
        set IP=****
        set PORT=22
        set REMOTE_PATH=/var/www/clients/client0/web24/web/
        set POST_CMD="sudo /bin/systemctl restart app.service"
) ELSE (
        echo Profile '%1' not exist!
        exit
)

echo Checking if ssh client ...
ssh.exe 2> NUL
IF %ERRORLEVEL%==9009 (
    echo Windows Settings > Apps > Optional features, then search for "OpenSSH" in your installed features.
    exit /B
)

echo Checking if scp client ...
scp.exe 2> NUL
IF %ERRORLEVEL%==9009 (
    echo Windows Settings > Apps > Optional features, then search for "OpenSSH" in your installed features.
    exit /B
)

echo Preparing publish...
dotnet publish

echo Removing local config files in %LOCAL_PATH%...
if exist %LOCAL_PATH%"appsettings.Production.json" del %LOCAL_PATH%"appsettings.Production.json"
if exist %LOCAL_PATH%"appsettings.Development.json" del %LOCAL_PATH%"appsettings.Development.json"
if exist %LOCAL_PATH%"appsettings.json" del %LOCAL_PATH%"appsettings.json"
if exist %LOCAL_PATH%"web.config" del %LOCAL_PATH%"web.config"
if exist %LOCAL_PATH%"app_offline.htm" del %LOCAL_PATH%"app_offline.htm"
if exist %LOCAL_PATH%"Logs" rmdir /s /q %LOCAL_PATH%"Logs"

echo Creating zip file...
if exist "new-version.zip" del "new-version.zip"
powershell Compress-Archive -Path %LOCAL_PATH%* -DestinationPath new-version.zip

echo Uploading new version to %IP% %REMOTE_PATH%...
scp -r new-version.zip %USER%@%IP%:%REMOTE_PATH%

echo Unzipping new version on server to %REMOTE_PATH%...
ssh -p %PORT% %USER%@%IP% unzip -o %REMOTE_PATH%new-version.zip -d %REMOTE_PATH%

echo Delete remote zip file %REMOTE_PATH%new-version.zip...
ssh -p %PORT% %USER%@%IP% rm %REMOTE_PATH%new-version.zip

echo Restarting service %SERVICE%...
ssh -p %PORT% %USER%@%IP% %POST_CMD%

echo Delete local zip file...
if exist "new-version.zip" del "new-version.zip"

echo Publish end!