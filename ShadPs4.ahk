;----------------------------------------------------------------------------
; RocketLauncher Module for ShadPS4 (Updated for shadPS4QtLauncher v200)
; Author: DiverseBloom780 (updated)
; Emulator: ShadPS4 / ShadPS4QtLauncher
; Version: 1.5 ; Added "Q" Exit Hotkey and v200 f8ebecb flag support
;----------------------------------------------------------------------------

MEmu := "ShadPS4"
MEmuV := "v200-f8ebecb" [cite: 2]
MURL := ["https://shadps4.net"] [cite: 1, 2]
MAuthor := ["DiverseBloom780"] [cite: 1, 2]
MVersion := "1.5"
MSystem := ["Sony Playstation 4"] [cite: 1, 2]

StartModule()
BezelGUI()
FadeInStart()

;------------------------------------
; CONFIGURATION
;------------------------------------
MEmuRoot := "E:\HyperSpin Attraction - AIO\Arcade\emulators\Sony Playstation 4" [cite: 3, 4]
; Prefer the Qt launcher executable name for v200, but allow fallback [cite: 4]
MExeCandidates := [ MEmuRoot "\shadPS4QtLauncher.exe", MEmuRoot "\shadPS4.exe" ] [cite: 4]

; Read Fullscreen setting from your .ini file [cite: 19, 20]
IniRead, Fullscreen, % modulePath . "\" . moduleName . ".ini", Settings, Fullscreen, true

; Build paths from RocketLauncher variables [cite: 5]
romFolder := romPath . "\" . romName [cite: 5, 6]
ebootPath := romFolder . "\eboot.bin" [cite: 6]

; Validate paths
IfNotExist, %romFolder%
    ScriptError("Game folder not found.`nPath: " . romFolder)
IfNotExist, %ebootPath%
    ScriptError("Eboot file not found:`n" . ebootPath) [cite: 7]

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
    ScriptError("No valid emulator executable found.")

; Determine the filename for process management [cite: 9]
SplitPath, selectedExe, exeName

;------------------------------------
; LAUNCH
;------------------------------------
; v200 f8ebecb uses "-g" for game path [cite: 10, 11]
LaunchArgs := "-g " . Chr(34) . romFolder . Chr(34) [cite: 11, 12]

; Check the Fullscreen boolean read from your .ini [cite: 19, 20]
if (Fullscreen = "true")
    LaunchArgs .= " -f"

try
{
    ; Launch using the selected executable
    Run, % Chr(34) . selectedExe . Chr(34) . " " . LaunchArgs, %MEmuRoot%, , pid [cite: 13]
    
    ; In v200, the launcher spawns shadps4.exe. We wait for that window.
    WinWait, ahk_exe shadps4.exe, , 20 [cite: 13]
    if ErrorLevel
        Process, Wait, shadps4.exe, 10 [cite: 14]
    
    ; Ensure game window is focused and maximized [cite: 15]
    WinActivate, ahk_exe shadps4.exe [cite: 15]
    WinMaximize, ahk_exe shadps4.exe [cite: 15]
}
catch e
{
    ScriptError("Failed to launch emulator.`nError: " . e) [cite: 15]
}

FadeInExit()

; Monitor the core emulator process for closure [cite: 16]
Process, WaitClose, shadps4.exe

FadeOutExit()
ExitModule()
Return

;------------------------------------
; EXIT LOGIC (Hotkey Q)
;------------------------------------
$q:: ; The "$" prevents the key from sending itself and causing a loop
CloseProcess:
    FadeOutStart() [cite: 17]
    ; Force close the game core and the launcher for a clean return to HyperSpin
    Process, Close, shadps4.exe [cite: 18]
    Process, Close, shadPS4QtLauncher.exe
Return
