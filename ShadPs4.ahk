;----------------------------------------------------------------------------
; RocketLauncher Module for ShadPS4 (Updated for shadPS4QtLauncher v200)
; Author: DiverseBloom780 (updated)
; Emulator: ShadPS4 / ShadPS4QtLauncher
; Version: 1.4 ; Updated for v200 main f8ebecb compatibility
;----------------------------------------------------------------------------

MEmu := "ShadPS4"
MEmuV := "v200-f8ebecb" 
MURL := ["https://shadps4.net"]
MAuthor := ["DiverseBloom780"]
MVersion := "1.4"
MSystem := ["Sony Playstation 4"]

StartModule()
BezelGUI()
FadeInStart()

;------------------------------------
; CONFIGURATION
;------------------------------------
MEmuRoot := "E:\HyperSpin Attraction - AIO\Arcade\emulators\Sony Playstation 4"
MExePath := MEmuRoot "\shadPS4QtLauncher.exe" ; Direct path to the new Qt Launcher [cite: 4]
MGameRoot := "E:\HyperSpin Attraction - AIO\Arcade\collections\Sony Playstation 4\roms"

; Build paths
romFolder := romPath . "\" . romName [cite: 5, 6]
ebootPath := romFolder . "\eboot.bin" [cite: 6]

; Validation
IfNotExist, %MExePath%
{
    MsgBox, 48, Error, Qt Launcher not found.`nPath: %MExePath%
    ExitModule()
    Return
}
IfNotExist, %ebootPath%
{
    MsgBox, 48, Error, Game launch failed. Eboot file not found:`n%ebootPath% [cite: 7]
    ExitModule()
    Return
}

;------------------------------------
; LAUNCH LOGIC
;------------------------------------
; The f8ebecb build uses -g for the game path and -f for fullscreen [cite: 11]
LaunchArgs := "-g " . Chr(34) . romFolder . Chr(34) . " -f" [cite: 12]

try
{
    ; Launch the Qt Launcher with arguments [cite: 13]
    Run, "%MExePath%" %LaunchArgs%, %MEmuRoot%, Max, pid
    
    ; The launcher spawns "shadps4.exe" as the actual game process. 
    ; We wait for the core process instead of the launcher window. 
    WinWait, ahk_exe shadps4.exe, , 20
    if ErrorLevel
    {
        Process, Wait, shadps4.exe, 10
    }
    
    ; Ensure the game window is focused and maximized for the cabinet 
    Sleep, 2000 ; Brief sleep to allow the renderer to initialize
    WinActivate, ahk_exe shadps4.exe
    WinMaximize, ahk_exe shadps4.exe
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
FadeInExit() [cite: 16]

; Monitor the core game process for closure [cite: 16]
Process, WaitClose, shadps4.exe

FadeOutExit()
ExitModule()
Return

;------------------------------------
; EXIT LOGIC
;------------------------------------
CloseProcess:
    FadeOutStart() [cite: 17]
    ; Kill both the core and the launcher to ensure a clean exit 
    Process, Close, shadps4.exe
    Process, Close, shadPS4QtLauncher.exe
Return
