;---------------------------------------------------------------------------- 
; RocketLauncher Module for ShadPS4 (Full Fade Version) 
;---------------------------------------------------------------------------- 
MEmu := "ShadPS4"
MEmuV := "Pre-release"
MVersion := "2.3"
MSystem := ["Sony Playstation 4"]

;---------------------------------------------------------------------------- 
; FADE IN START (RocketLauncher requires this at top-level) 
;---------------------------------------------------------------------------- 
FadeInStart()  ; must stay: show black overlay at start

;---------------------------------------------------------------------------- 
; START MODULE 
;---------------------------------------------------------------------------- 
StartModule()

;---------------------------------------------------------------------------- 
; GAME PATH 
;---------------------------------------------------------------------------- 
gamePath := romPath . "\" . romName . "\eboot.bin"

If !FileExist(gamePath)
{
    MsgBox, 48, Module Error, Missing eboot.bin:`n%gamePath%
    ExitModule()
}

;---------------------------------------------------------------------------- 
; LAUNCH SHADPS4 FULLSCREEN 
;---------------------------------------------------------------------------- 
Run, "%emuFullPath%" -fullscreen -vulkan "%gamePath%", %emuPath%

;---------------------------------------------------------------------------- 
; WAIT FOR EMULATOR PROCESS & WINDOW 
;---------------------------------------------------------------------------- 
Process, Wait, shadPS4.exe, 15
If ErrorLevel
{
    MsgBox, 48, Module Error, ShadPS4 failed to start.
    ExitModule()
}

; Wait for the emulator window to appear
WinWait, ahk_exe shadPS4.exe,, 15
If !ErrorLevel
{
    WinShow, ahk_exe shadPS4.exe
    WinActivate, ahk_exe shadPS4.exe
    WinMove, ahk_exe shadPS4.exe,, 0, 0
}

Sleep, 1000  ; give graphics time to initialize

;---------------------------------------------------------------------------- 
; FADE OUT BLACK OVERLAY (screen now visible) 
;---------------------------------------------------------------------------- 
FadeInExit()  ; must stay to remove black overlay

;---------------------------------------------------------------------------- 
; KEEP RL ALIVE UNTIL EMULATOR CLOSES 
;---------------------------------------------------------------------------- 
Process, WaitClose, shadPS4.exe

FadeOutExit()  ; must stay
ExitModule()
Return

;---------------------------------------------------------------------------- 
; EXIT KEY HANDLER 
;---------------------------------------------------------------------------- 
CloseProcess:
    FadeOutStart()  ; must stay
    Process, Close, shadPS4.exe
Return
