;----------------------------------------------------------------------------
; RocketLauncher Module for ShadPS4 (Qt launcher spawns CLI core - final)
; Version: 1.6.1 (patched to read ui.ini versionSelected, hide CLI, PID close)
; Author: DiverseBloom780 (original), Modified for user by Copilot
;----------------------------------------------------------------------------

MEmu := "ShadPS4"
MEmuV := "v200-f8ebecb"
MURL := ["https://shadps4.net"]
MAuthor := ["DiverseBloom780"]
MVersion := "1.6.1"
MSystem := ["Sony Playstation 4"]

StartModule()
BezelGUI()
FadeInStart()

;------------------------------------
; CONFIGURATION
;------------------------------------
MEmuRoot := "E:\HyperSpin Attraction - AIO\Arcade\emulators\Sony Playstation 4"
MExeCandidates := [ MEmuRoot "\shadPS4QtLauncher.exe", MEmuRoot "\shadPS4.exe" ]

IniRead, FullscreenRaw, % modulePath . "\" . moduleName . ".ini", Settings, Fullscreen, true
Fullscreen := StrLower(Trim(FullscreenRaw))

romFolder := romPath . "\" . romName
ebootPath := romFolder . "\eboot.bin"

if !FileExist(romFolder)
    ScriptError("Game folder not found.`nPath: " . romFolder)

;------------------------------------
; Find launcher and core candidates
;------------------------------------
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

SplitPath, selectedExe, launcherName, , , , launcherDir

coreExeName := "shadPS4.exe"
coreFullPath := ""

; --- Prefer Qt ui.ini versionSelected if present ---
qtIni := launcherDir . "\ui.ini"
if FileExist(qtIni)
{
    IniRead, versionSelectedRaw, %qtIni%, version_manager, versionSelected, 
    if (versionSelectedRaw != "")
    {
        ; Normalize slashes and remove quotes/spaces
        StringReplace, versionSelectedRaw, versionSelectedRaw, /, \, All
        versionSelected := Trim(StrReplace(versionSelectedRaw, """", ""))
        ; If relative, make absolute relative to launcherDir
        if !(SubStr(versionSelected,2,1) = ":")
            versionSelected := launcherDir . "\" . versionSelected
        ; Collapse duplicate backslashes
        StringReplace, versionSelected, versionSelected, "\\", "\", All
        if FileExist(versionSelected)
        {
            coreFullPath := versionSelected
            ; Log usage
            Log("Using versionSelected from ui.ini as coreFullPath: " . coreFullPath)
        }
        else
        {
            Log("versionSelected found in ui.ini but file not present: " . versionSelected)
        }
    }
    else
    {
        Log("ui.ini present but versionSelected empty.")
    }
}
else
{
    Log("ui.ini not found at: " . qtIni)
}

; If ui.ini didn't yield a valid core, fall back to Pre-release path or recursive search
if (coreFullPath = "")
{
    preReleasePath := MEmuRoot . "\user\versions\Pre-release\" . coreExeName
    if FileExist(preReleasePath)
    {
        coreFullPath := preReleasePath
        Log("Found core at Pre-release path: " . coreFullPath)
    }
    else
    {
        searchRoot := MEmuRoot . "\user\versions"
        if FileExist(searchRoot)
        {
            Loop, Files, % searchRoot "\*.exe", R
            {
                if (A_LoopFileName = coreExeName)
                {
                    coreFullPath := A_LoopFileFullPath
                    Log("Found core by recursive search: " . coreFullPath)
                    break
                }
            }
        }
    }
}

if (coreFullPath = "")
{
    coreFullPath := coreExeName
    Log("Falling back to core exe name: " . coreFullPath)
}

;------------------------------------
; Debug/log helper
;------------------------------------
Log(msg) {
    global modulePath
    debugFile := modulePath . "\shadps4_debug.log"
    FormatTime, ts, , yyyy-MM-dd HH:mm:ss
    FileAppend, % ts " | " msg "`n", %debugFile%
}

;------------------------------------
; WMI helpers
;------------------------------------
GetPidByPath(path)
{
    if (path = "")
        return 0
    StringLower, pathLower, path
    pid := 0
    try {
        wmi := ComObjGet("winmgmts:")
        for proc in wmi.ExecQuery("Select ProcessId, ExecutablePath from Win32_Process")
        {
            if (proc.ExecutablePath)
            {
                StringLower, p, proc.ExecutablePath
                if (p = pathLower)
                {
                    pid := proc.ProcessId
                    break
                }
            }
        }
    } catch {}
    return pid
}

GetPidByCommandLine(tokens)
{
    if (!IsObject(tokens))
        return 0
    pid := 0
    try {
        wmi := ComObjGet("winmgmts:")
        for proc in wmi.ExecQuery("Select ProcessId, CommandLine from Win32_Process")
        {
            if (proc.CommandLine)
            {
                StringLower, cmd, proc.CommandLine
                for index, t in tokens
                {
                    StringLower, tokenLower, t
                    if (tokenLower = "")
                        continue
                    if (InStr(cmd, tokenLower))
                    {
                        pid := proc.ProcessId
                        return pid
                    }
                }
            }
        }
    } catch {}
    return pid
}

GetChildPids(parentPID)
{
    arr := []
    try {
        wmi := ComObjGet("winmgmts:")
        q := "Select ProcessId, ParentProcessId, ExecutablePath, CommandLine from Win32_Process where ParentProcessId=" . parentPID
        for proc in wmi.ExecQuery(q)
        {
            obj := {}
            obj.Pid := proc.ProcessId
            obj.Path := proc.ExecutablePath
            obj.Cmd := proc.CommandLine
            arr.Push(obj)
        }
    } catch {}
    return arr
}

;------------------------------------
; Window/console helpers
;------------------------------------
HideConsoleWindowsByPid(pid)
{
    if (!pid)
        return
    WinGet, idList, List
    Loop, %idList%
    {
        this_id := idList%A_Index%
        WinGet, thisPID, PID, ahk_id %this_id%
        if (thisPID = pid)
        {
            WinGetClass, cls, ahk_id %this_id%
            ; Hide console windows (ConsoleWindowClass) and any other top-level windows owned by the PID
            if (cls = "ConsoleWindowClass" || cls = "ConsoleWindow")
                WinHide, ahk_id %this_id%
            else
                WinHide, ahk_id %this_id%
        }
    }
}

;------------------------------------
; LAUNCH
;------------------------------------
; Prefer passing eboot.bin if present; otherwise pass rom folder
if FileExist(ebootPath)
    LaunchTarget := ebootPath
else
    LaunchTarget := romFolder

LaunchArgs := "-g " . Chr(34) . LaunchTarget . Chr(34)
if (Fullscreen = "true" || Fullscreen = "1" || Fullscreen = "yes" || Fullscreen = "on")
    LaunchArgs .= " -f"

; Timeouts and polling (tweakable)
launcherWaitTimeout := 8
coreWaitTimeout := 120
corePollInterval := 400

try
{
    Log("=== Launch start ===")
    Log("Selected launcher: " . selectedExe)
    Log("Launcher name: " . launcherName)
    Log("Preferred core path: " . coreFullPath)
    Log("Launch target: " . LaunchTarget)
    Log("Launch args: " . LaunchArgs)

    ; Start the Qt launcher (or fallback)
    Run, % Chr(34) . selectedExe . Chr(34) . " " . LaunchArgs, %MEmuRoot%, , launcherPID
    if (ErrorLevel)
        ScriptError("Run failed for: " . selectedExe)
    Log("Launcher started, PID: " . launcherPID)

    ; Wait briefly for launcher process to appear
    start := A_TickCount
    while ((A_TickCount - start) < (launcherWaitTimeout * 1000))
    {
        Process, Exist, %launcherName%
        if (ErrorLevel)
        {
            Log("Launcher process detected by name, PID: " . ErrorLevel)
            break
        }
        Sleep, 200
    }

    ; Poll for core process:
    ; 1) children of launcherPID
    ; 2) by full path
    ; 3) by command line tokens (include full eboot path)
    ; 4) fallback to exe name
    Log("Polling for core process (timeout " . coreWaitTimeout . "s)...")
    startCore := A_TickCount
    corePID := 0
    tokens := []
    tokens.Push(LaunchTarget)
    tokens.Push(romName)
    tokens.Push("eboot.bin")
    while ((A_TickCount - startCore) < (coreWaitTimeout * 1000))
    {
        ; 1) children of launcher
        if (launcherPID)
        {
            children := GetChildPids(launcherPID)
            for index, c in children
            {
                if (c.Path)
                {
                    StringLower, pth, c.Path
                    if (InStr(pth, "shadps4.exe") || (coreFullPath != coreExeName && pth = StrLower(coreFullPath)))
                    {
                        corePID := c.Pid
                        Log("Core found as child of launcher by path/name, PID: " . corePID)
                        break
                    }
                }
                if (c.Cmd)
                {
                    StringLower, cmd, c.Cmd
                    for idx, t in tokens
                    {
                        StringLower, tokenLower, t
                        if (tokenLower = "")
                            continue
                        if (InStr(cmd, tokenLower))
                        {
                            corePID := c.Pid
                            Log("Core found as child of launcher by command line token, PID: " . corePID)
                            break
                        }
                    }
                    if (corePID)
                        break
                }
            }
            if (corePID)
                break
        }

        ; 2) by full path
        if (coreFullPath != coreExeName)
        {
            corePID := GetPidByPath(coreFullPath)
            if (corePID)
            {
                Log("Core found by full path, PID: " . corePID)
                break
            }
        }

        ; 3) by command line tokens
        corePID := GetPidByCommandLine(tokens)
        if (corePID)
        {
            Log("Core found by command line token, PID: " . corePID)
            break
        }

        ; 4) fallback: by exe name
        Process, Exist, %coreExeName%
        if (ErrorLevel)
        {
            corePID := ErrorLevel
            Log("Core found by exe name, PID: " . corePID)
            break
        }

        Sleep, corePollInterval
    }

    if (corePID = 0)
    {
        Log("Core not detected within timeout. Final WinWait attempt for ahk_exe " . coreExeName)
        WinWait, ahk_exe %coreExeName%, , 5
        if (!ErrorLevel)
        {
            Log("Core window appeared via WinWait.")
            Process, Exist, %coreExeName%
            if (ErrorLevel)
                corePID := ErrorLevel
        }
        else
        {
            ScriptError("Core process/window not detected within timeout. Check core path and launcher behavior.")
        }
    }

    DetectedCorePID := corePID
    Log("DetectedCorePID: " . DetectedCorePID)

    ; Hide console windows for launcher and core if present
    if (launcherPID)
    {
        Log("Attempting to hide console windows for launcher PID: " . launcherPID)
        HideConsoleWindowsByPid(launcherPID)
    }
    if (DetectedCorePID)
    {
        Log("Attempting to hide console windows for core PID: " . DetectedCorePID)
        HideConsoleWindowsByPid(DetectedCorePID)
    }

    ; Activate/maximize only if a GUI window exists
    if (WinExist("ahk_exe " . coreExeName))
    {
        WinActivate, ahk_exe %coreExeName%
        WinMaximize, ahk_exe %coreExeName%
    }
}
catch e
{
    ScriptError("Failed to launch emulator.`nError: " . e)
}

FadeInExit()

;------------------------------------
; Monitor core process for closure
;------------------------------------
Log("Monitoring core process for closure. PID: " . DetectedCorePID)
if (DetectedCorePID)
{
    Loop
    {
        Process, Exist, %DetectedCorePID%
        if (!ErrorLevel)
            break
        Sleep, 500
    }
}
else
{
    Process, WaitClose, %coreExeName%
}
Log("Core process closed, exiting module.")

FadeOutExit()
ExitModule()
Return

;------------------------------------
; EXIT LOGIC (Hotkey Q)
;------------------------------------
$q::
CloseProcess:
    FadeOutStart()
    try {
        if (DetectedCorePID)
        {
            Log("Closing core by PID: " . DetectedCorePID)
            Process, Close, %DetectedCorePID%
            Sleep, 300
        }
    } catch {}
    Process, Close, %coreExeName%
    Process, Close, %launcherName%
Return
