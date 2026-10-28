; Vespera's Windows installer: NSIS, per-user (no admin). Built by launcher.yml's Package step
; (makensis -DXVERSION=x.y.z packaging/windows/installer.nsi from the repository root; the
; binary it wraps is launcher/dist/vespera-launcher.exe, put there by that step, already
; crt-static so it needs nothing else). The zip stays for self-update; this is the
; double-clickable install: shortcuts, an uninstaller, Add/Remove Programs. Everything lands
; in %LOCALAPPDATA%\Vespera.

Unicode true
!include "MUI2.nsh"
!include "FileFunc.nsh"

!define APP "Vespera"
!define EXE "vespera-launcher.exe"
!define UNINST "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"
!ifndef XVERSION
  !define XVERSION "0.0.0"
!endif

Name "${APP} ${XVERSION}"
OutFile "launcher\out\vespera-launcher-windows-x64-setup.exe"
InstallDir "$LOCALAPPDATA\${APP}"
InstallDirRegKey HKCU "Software\${APP}" ""
RequestExecutionLevel user
SetCompressor /SOLID lzma

!define MUI_ICON "packaging\icons\vespera.ico"
!define MUI_UNICON "packaging\icons\vespera.ico"
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
; English first: it is the default when the system's language is neither.
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Russian"

Section "Install"
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File "launcher\dist\${EXE}"
  WriteUninstaller "$INSTDIR\uninstall.exe"

  CreateShortcut "$SMPROGRAMS\${APP}.lnk" "$INSTDIR\${EXE}"
  CreateShortcut "$DESKTOP\${APP}.lnk" "$INSTDIR\${EXE}"

  ; Add/Remove Programs (HKCU: per-user, like the install). EstimatedSize is KiB, as a DWORD.
  WriteRegStr HKCU "Software\${APP}" "" "$INSTDIR"
  WriteRegStr HKCU "${UNINST}" "DisplayName" "${APP}"
  WriteRegStr HKCU "${UNINST}" "DisplayVersion" "${XVERSION}"
  WriteRegStr HKCU "${UNINST}" "Publisher" "${APP}"
  WriteRegStr HKCU "${UNINST}" "DisplayIcon" "$INSTDIR\${EXE}"
  WriteRegStr HKCU "${UNINST}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKCU "${UNINST}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegDWORD HKCU "${UNINST}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/M=${EXE}" $0 $1 $2
  IntOp $0 $0 / 1024
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINST}" "EstimatedSize" "$0"
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$INSTDIR\${EXE}"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\${APP}.lnk"
  Delete "$DESKTOP\${APP}.lnk"
  DeleteRegKey HKCU "${UNINST}"
  DeleteRegKey HKCU "Software\${APP}"
SectionEnd
