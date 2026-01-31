;----------------------------------------------------------------------------
; RocketLauncher Module for ShadPS4 (Updated for shadPS4QtLauncher v200)
; Author: DiverseBloom780 (updated)
; Emulator: ShadPS4 / ShadPS4QtLauncher
; Version: 1.3
;----------------------------------------------------------------------------

MEmu := "ShadPS4"
MEmuV := "v200" ; target QtLauncher v200
MURL := ["https://shadps4.net"]
MAuthor := ["DiverseBloom780"]
MVersion := "1.3"
MCRC := ""
iCRC := ""
MID := ""
MSystem := ["Sony Playstation 4"]

StartModule()

BezelGUI()
FadeInStart()

;------------------------------------
; CONFIGURATION - adjust these paths to your setup
;------------------------------------
MEmuRoot := "E:\HyperSpin Attraction - AIO\Arcade\emulators\Sony Playstation 4"
; Prefer the Qt launcher executable name for v200, but allow fallback to legacy exe
MExeCandidates := [ MEmuRoot "\shadPS4QtLauncher.exe", MEmuRoot "\shadPS4.exe" ]
MGameRoot := "E:\HyperSpin Attraction - AIO\Arcade\collections\Sony Playstation 4\roms"

; Build full game path (Assumes romPath and romName are passed by RocketLauncher)
romFolder := romPath . "\" . romName
ebootPath := romFolder . "\eboot.bin"

; Validate game folder and eboot
IfNotExist, %romFolder%
{
    MsgBox, 48, Error, Game folder not found.`n`nPath: %romFolder%
    ExitModule()
    Return
}
IfNotExist, %ebootPath%
{
    MsgBox, 48, Error, Game launch failed. Eboot file not found:`n%ebootPath%
    ExitModule()
    Return
}

; Find a valid emulator executable from candidates
selectedExe := ""
for index, candidate in MExeCandidates
{
    if FileExist(candidate)
    {
        selectedExe := candidate
        break
    }
}

if (selectedExe = "")
{
    MsgBox, 48, Error, Emulator executable not found.`n`nTried:`n% MExeCandidates[1] %`n% MExeCandidates[2] %
    ExitModule()
    Return
}

; Determine process name for waiting/closing (extract filename)
SplitPath, selectedExe, exeName

; Launch emulator with game folder
; Many Qt launchers accept a folder or file as argument; pass the romFolder.
; If your launcher requires a specific flag (for example --game "path"), update LaunchArgs accordingly.
LaunchArgs := "" . Chr(34) . romFolder . Chr(34)

try
{
    Run, % Chr(34) . selectedExe . Chr(34) . " " . LaunchArgs, %MEmuRoot%, , pid
    ; Wait for the process window to appear (gives up after 20 seconds)
    WinWait, ahk_exe %exeName%, , 20
    if ErrorLevel
    {
        ; If no window, still wait for the process to exist
        Process, Wait, %exeName%, 10
    }
    ; Try to maximize the main window if present
    WinActivate, ahk_exe %exeName%
    WinMaximize, ahk_exe %exeName%
}
catch e
{
    MsgBox, 48, Error, Failed to launch emulator.`n`nError: %e%
    ExitModule()
    Return
}

;------------------------------------
; WAIT AND CLEANUP
;------------------------------------
FadeInExit()

; Wait for emulator to close (600 seconds default)
Process, WaitClose, %exeName%, 600

; Final Cleanup and Module Exit
FadeOutExit()
ExitModule()
Return

;------------------------------------
; CloseProcess Label (Used by RocketLauncher for Alt+F4, Exit Key, etc.)
;------------------------------------
CloseProcess:
    FadeOutStart()
    ; Force Close the selected process
    Process, Close, %exeName%
    Return
