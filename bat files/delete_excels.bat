@echo off
set "TARGET_DIR=H:\Juan\3. Projects\GH Sawken\Python\UpdateGoldsGlobal\excels"

:: Deletes all files in the directory (non-recursive)
del /Q "%TARGET_DIR%\*.*"

echo All files in %TARGET_DIR% have been deleted.
pause
