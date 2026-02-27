@echo off
echo Installing dependencies...
python -m pip install hypothesis pytest gitpython pydantic

echo.
echo Running portfolio analysis...
python reorganize_portfolio.py --repo-path . --phase analyze

echo.
echo Done! Check .migration folder for results.
pause
