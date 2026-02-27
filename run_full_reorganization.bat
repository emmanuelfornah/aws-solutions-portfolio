@echo off
echo ========================================
echo AWS WELL-ARCHITECTED PORTFOLIO REORGANIZATION
echo ========================================
echo.
echo This will create pillar directories and generate documentation.
echo Your lab files will NOT be moved automatically (requires manual review).
echo.
pause

echo Installing dependencies...
python -m pip install hypothesis pytest gitpython pydantic

echo.
echo Running full reorganization...
python execute_full_reorganization.py

echo.
echo Done! Check the pillar directories and .migration folder.
pause
