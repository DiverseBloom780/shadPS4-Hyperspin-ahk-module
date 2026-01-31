;----------------------------------------------------------------------------
; RocketLauncher Module for ShadPS4 (Updated for shadPS4QtLauncher v200)
; Author: DiverseBloom780
; Version: 1.5.1
;----------------------------------------------------------------------------

MEmu := "ShadPS4"
MEmuV := "v200-f8ebecb"
MURL := ["https://shadps4.net"]
MAuthor := ["DiverseBloom780"]
MVersion := "1.5.1"
MSystem := ["Sony Playstation 4"]

StartModule()
BezelGUI()
FadeInStart()

;------------------------------------
; CONFIGURATION
;------------------------------------
; Root where the Qt launcher and core live
MEmuRoot := "E:\HyperSpin Attraction - AIO\Arcade\emulators\Sony Playstation 4"

; Prefer the Qt launcher executable name for v200, but allow fallback
MExeCandidates := [ MEmuRoot "\shadPS4QtLauncher.exe", MEmuRoot "\shadPS4.exe" ]

; Read Fullscreen setting from your .ini and normalize
IniRead, FullscreenRaw, % modulePath . "\" . moduleName . ".ini", Settings, Fullscreen, true
Fullscreen := StrLower(Trim(FullscreenRaw))

; Build paths from RocketLauncher variables
romFolder := romPath . "\" . romName
ebootPath := romFolder . "\eboot.bin"

; Validate ROM paths
if !FileExist(romFolder)
    ScriptError("Game folder not found.`nPath: " . romFolder)
if !FileExist(ebootPath)
    ScriptError("Eboot file not found:`n" . ebootPath)

; Find a valid emulator executable (Qt launcher preferred)
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
    ScriptError("No valid emulator executable found in: " . MEmuRoot)

; Resolve the executable name for process/window operations
SplitPath, selectedExe, exeName

; Attempt to locate the spawned core executable (search common user versions folder)
; This will look for shadPS4.exe under MEmuRoot\user\versions recursively and return the first match.
coreExeName := "shadPS4.exe"
corePath := ""
searchRoot := MEmuRoot . "\user\versions"
if FileExist(searchRoot)
{
    Loop, Files, % searchRoot "\*.exe", R
    {
        if (A_LoopFileName = coreExeName)
        {
            corePath := A_LoopFileFullPath
            break
        }
    }
}
; If not found, fall back to expecting the core to be in PATH or spawned next to launcher
if (corePath = "")
{
    ; We'll still use the process name for waits/close operations
    corePath := coreExeName
}

;------------------------------------
; LAUNCH
;------------------------------------
; v200 f8ebecb uses "-g" for game path
LaunchArgs := "-g " . Chr(34) . romFolder . Chr(34)

; Add fullscreen flag if enabled (accepts true/1/yes/on)
if (Fullscreen = "true" || Fullscreen = "1" || Fullscreen = "yes" || Fullscreen = "on")
    LaunchArgs .= " -f"

try
{
    ; Launch using the selected executable
    Run, % Chr(34) . selectedExe . Chr(34) . " " . LaunchArgs, %MEmuRoot%, , pid

    ; Wait for the core process/window to appear.
    ; Prefer waiting for the core executable name (shadPS4.exe). Use a 20s WinWait then fallback to Process, Wait.
    WinWait, ahk_exe %coreExeName%, , 20
    if ErrorLevel
    {
        ; If WinWait timed out, try waiting for the process to start (10s)
        Process, Wait, %coreExeName%, 10
    }

    ; Activate and maximize the core window if present
    WinActivate, ahk_exe %coreExeName%
    WinMaximize, ahk_exe %coreExeName%
}
catch e
{
    ScriptError("Failed to launch emulator.`nError: " . e)
}

FadeInExit()

; Monitor the core emulator process for closure
; Use the process name so it works whether corePath is a full path or just the exe name
Process, WaitClose, %coreExeName%

FadeOutExit()
ExitModule()
Return

;------------------------------------
; EXIT LOGIC (Hotkey Q)
;------------------------------------
$q:: ; The "$" prevents the key from sending itself and causing a loop
CloseProcess:
    FadeOutStart()
    ; Force close the game core and the launcher for a clean return to HyperSpin
    Process, Close, %coreExeName%
    ; Close the launcher executable if it was the Qt launcher
    SplitPath, selectedExe, launcherName
    Process, Close, %launcherName%
Return
