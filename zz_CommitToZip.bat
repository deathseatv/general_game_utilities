@echo off
setlocal
cd /d "%~dp0"

git archive --format=zip -o "project.zip" HEAD || exit /b 1

echo.
echo Archived commit:
git log -1 --pretty=fuller
pause