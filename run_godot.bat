@echo off
setlocal
set "PROJECT_DIR=C:\Proyecto TFG\escanner-rubik\project"
set "PATH=%PROJECT_DIR%\bin\windows;C:\msys64\ucrt64\bin;%PATH%"
pushd "%PROJECT_DIR%"
"C:\Users\josec\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe" -e --path "%PROJECT_DIR%"
popd