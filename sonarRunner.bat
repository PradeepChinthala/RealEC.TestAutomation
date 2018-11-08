@echo off
cls

if not "%MSBUILD_RUNNER_HOME%" == "" goto SonarRunner

goto SonarRunnerHomeError

:SonarRunner
if %MSBUILD_RUNNER_HOME:~-1%==\ set SONAR_RUNNER_HOME=%MSBUILD_RUNNER_HOME:~0,-1%

echo.
echo * MSBUILD_RUNNER_HOME:
echo %MSBUILD_RUNNER_HOME%

set PROJECT_HOME=%~dp0
if %PROJECT_HOME:~-1%==\ set PROJECT_HOME=%PROJECT_HOME:~0,-1%

echo.
echo * PROJECT_HOME:
echo %PROJECT_HOME%

:Run
%MSBUILD_RUNNER_HOME%\MSBuild.SonarQube.Runner.exe begin /n:"RealEC.TestAutomation" /k:"RealEC.TestAutomation" /v:"1.0.0.%1"
"C:\Program Files\MSBuild\14.0\Bin\MSBuild.exe" /t:Rebuild "%PROJECT_HOME%\RealEC.TestAutomation.sln"
%MSBUILD_RUNNER_HOME%\MSBuild.SonarQube.Runner.exe end

goto END

:SonarRunnerHomeError
echo.
echo * MSBUILD_RUNNER_HOME not found

:END
echo.