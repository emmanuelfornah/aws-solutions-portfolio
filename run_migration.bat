@echo off
echo ========================================
echo LAB MIGRATION TO PILLAR DIRECTORIES
echo ========================================
echo.
echo WARNING: This will move your lab directories using git mv.
echo Make sure you have committed any pending changes first!
echo.
echo Press Ctrl+C to cancel, or
pause

echo.
echo Running migration...
python migrate_labs.py

echo.
echo Done! Check git status to see the changes.
pause
