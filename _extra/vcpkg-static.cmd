@ECHO OFF

SETLOCAL

SET "VCPKG_EXE=%~dp0\vcpkg.exe"
IF NOT EXIST "%VCPKG_EXE%" (
  SET "VCPKG_EXE=vcpkg"
)

SET "VCPKG_DEFAULT_TRIPLET=x64-windows-static"

"%VCPKG_EXE%" %*
