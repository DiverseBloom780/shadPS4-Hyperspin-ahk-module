;----------------------------------------------------------------------------
; RocketLauncher Module for ShadPS4 (Updated for shadPS4QtLauncher v200)
; Author: DiverseBloom780 (updated)
; Emulator: ShadPS4 / ShadPS4QtLauncher
; Version: 1.4 ; Added v200 f8ebecb flag support and .ini integration
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
MExeCandidates := [ MEmuRoot "\shadPS4QtLauncher.exe", MEmuRoot "\shadPS4.exe" ] ; [cite: 4]
MGameRoot := "E:\HyperSpin Attraction - AIO\Arcade\collections\Sony Playstation 4\roms"

; Read Fullscreen setting from your .ini file
IniRead, Fullscreen, % modulePath . "\" . moduleName . ".ini", Settings, Fullscreen, true ;

romFolder := romPath . "\" . romName ; [cite: 5, 6]
ebootPath := romFolder . "\eboot.bin" ; [cite: 6]

; Validate game folder and eboot
IfNotExist, %romFolder%
    ScriptError("Game folder not found.`nPath: " . romFolder)
IfNotExist, %ebootPath%
    ScriptError("Eboot file not found:`n" . ebootPath) ; [cite: 7]

; Find a valid emulator executable [cite: 8]
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
    ScriptError("No valid emulator executable found in " . MEmuRoot) ; [cite: 8]

SplitPath, selectedExe, exeName ; [cite: 9]

;------------------------------------
; LAUNCH
;------------------------------------
; v200 main f8ebecb uses -g for the game path 
LaunchArgs := "-g " . Chr(34) . romFolder . Chr(34)
if (Fullscreen = "true")
    LaunchArgs .= " -f" ; Adds fullscreen flag if enabled in .ini

try
{
    Run, % Chr(34) . selectedExe . Chr(34) . " " . LaunchArgs, %MEmuRoot%, , pid ; [cite: 13]
    
    ; Wait for the specific game process (shadps4.exe)
    WinWait, ahk_exe shadps4.exe, , 20 ; [cite: 13]
    if ErrorLevel
        Process, Wait, shadps4.exe, 10 ; [cite: 14]
    
    Sleep, 1000 ; Allow renderer to stabilize
    WinActivate, ahk_exe shadps4.exe ; [cite: 15]
    WinMaximize, ahk_exe shadps4.exe ; [cite: 15]
}
catch e
{
    ScriptError("Failed to launch emulator.`nError: " . e) ; [cite: 15]
}

FadeInExit()
Process, WaitClose, shadps4.exe ; [cite: 16]
FadeOutExit()
ExitModule()
Return

;------------------------------------
; EXIT LOGIC [cite: 17]
;------------------------------------
CloseProcess:
    FadeOutStart()
    Process, Close, shadps4.exe ; 
    Process, Close, shadPS4QtLauncher.exe ; Ensures launcher also closes
Return
