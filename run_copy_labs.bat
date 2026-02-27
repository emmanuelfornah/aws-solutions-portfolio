@echo off
echo ========================================
echo COPY LABS TO PILLAR DIRECTORIES
echo ========================================
echo.
echo This will COPY (not move) labs to avoid OneDrive issues
echo.
pause

python copy_labs_to_pillars.py

echo.
pause
