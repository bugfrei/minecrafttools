# Windows API für Pixel auslesen
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public static class ScreenTool
{
    [DllImport("user32.dll")]
    public static extern IntPtr GetDC(IntPtr hwnd);

    [DllImport("gdi32.dll")]
    public static extern uint GetPixel(IntPtr hdc, int nXPos, int nYPos);

    [DllImport("user32.dll")]
    public static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);

    /*
    public static System.Drawing.Color GetColorAt(int x, int y)
    {
        IntPtr hdc = GetDC(IntPtr.Zero);
        uint pixel = GetPixel(hdc, x, y);
        ReleaseDC(IntPtr.Zero, hdc);
        return Color.FromArgb((int)(pixel & 0x000000FF),
                                (int)(pixel & 0x0000FF00) >> 8,
                                (int)(pixel & 0x00FF0000) >> 16);
    }
    */

    public static int[] GetPixelColor(int x, int y)
    {
        IntPtr hdc = GetDC(IntPtr.Zero);
        uint pixel = GetPixel(hdc, x, y);
        ReleaseDC(IntPtr.Zero, hdc);
        int r = (int)(pixel & 0x000000FF);       // Rot-Wert aus dem unteren Byte
        int g = (int)((pixel & 0x0000FF00) >> 8); // Grün-Wert aus dem mittleren Byte
        int b = (int)((pixel & 0x00FF0000) >> 16); // Blau-Wert aus dem oberen Byte
        
        return new int[] { r, g, b };
    }
}
"@ -Language CSharp

# WinAPI für Tastendrucke und Mausklicks
Add-Type @"
using System;
using System.Runtime.InteropServices;


public class Keyboard {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

    public const int KEYEVENTF_KEYDOWN = 0x0000;
    public const int KEYEVENTF_KEYUP = 0x0002;
}
"@

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class MouseHelper {
    [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, IntPtr dwExtraInfo);

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    private const uint MOUSEEVENTF_LEFTDOWN = 0x02;
    private const uint MOUSEEVENTF_LEFTUP = 0x04;

    private const uint MOUSEEVENTF_MIDDLEDOWN = 0x20;
    private const uint MOUSEEVENTF_MIDDLEUP = 0x40;

    private const uint MOUSEEVENTF_RIGHTDOWN = 0x08;
    private const uint MOUSEEVENTF_RIGHTUP = 0x10;

    public static POINT GetMousePosition()
    {
        POINT p;
        GetCursorPos(out p);
        return p;
    }

    public static void LeftDown() {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
    }
    public static void LeftUp() {
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
    }
    public static void RightDown() {
        mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, IntPtr.Zero);
    }
    public static void RightUp() {
        mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, IntPtr.Zero);
    }

    public static void LeftClick() {
        mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, IntPtr.Zero);
        mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, IntPtr.Zero);
    }
    public static void MiddleClick() {
        mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, IntPtr.Zero);
        mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, IntPtr.Zero);
    }
}
"@ -Language CSharp

# Umwandeln eines Zeichens (String) in einen virtuellen Tastencode
function Get-VirtualKey {
    param (
        [ValidateSet(
            'SPACE', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'Esc', 'Shift', 'Strg', 'Alt'

        )]
        [string]$Key
    )

    $keyCodes = @{
        'SPACE' = 0x20
        '0' = 0x30; '1' = 0x31; '2' = 0x32; '3' = 0x33; '4' = 0x34
        '5' = 0x35; '6' = 0x36; '7' = 0x37; '8' = 0x38; '9' = 0x39
        'A' = 0x41; 'B' = 0x42; 'C' = 0x43; 'D' = 0x44; 'E' = 0x45
        'F' = 0x46; 'G' = 0x47; 'H' = 0x48; 'I' = 0x49; 'J' = 0x4A
        'K' = 0x4B; 'L' = 0x4C; 'M' = 0x4D; 'N' = 0x4E; 'O' = 0x4F
        'P' = 0x50; 'Q' = 0x51; 'R' = 0x52; 'S' = 0x53; 'T' = 0x54
        'U' = 0x55; 'V' = 0x56; 'W' = 0x57; 'X' = 0x58; 'Y' = 0x59
        'Z' = 0x5A; 'Esc' = 0x1B; 'Shift' = 0x10; 'Strg' = 0x11; 'Alt' = 0x12
    }

    return $keyCodes[$Key]
}

# Taste drücken (nur runter)
function Down-Key {
    param (
        [byte]$Key
    )
    # Taste drücken
    [Keyboard]::keybd_event($Key, 0, [Keyboard]::KEYEVENTF_KEYDOWN, 0)
}

# Taste loslassen (nur hoch)
function Up-Key {
    param (
        [byte]$Key
    )
    # Taste loslassen
    [Keyboard]::keybd_event($Key, 0, [Keyboard]::KEYEVENTF_KEYUP, 0)
}

# Taste drücken und loslassen
function Press-Key {
    param (
        [byte]$Key,
        $DelaySeconds = 3
    )
    # Taste drücken
    [Keyboard]::keybd_event($Key, 0, [Keyboard]::KEYEVENTF_KEYDOWN, 0)
    Start-Sleep -Seconds $DelaySeconds
    # Taste loslassen
    [Keyboard]::keybd_event($Key, 0, [Keyboard]::KEYEVENTF_KEYUP, 0)
}

# Kurzschreibweise für das Drücken einer Taste (mit Validierung)
function PressKey {
    param (
        [ValidateSet(
            'SPACE', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'Esc', 'Shift', 'Strg', 'Alt'
        )]
        [string]$Key,
        $DelaySeconds = 3
    )

    $keyCode = (Get-VirtualKey $Key)

    if ($keyCode -ne 0) { 
        Press-Key $keyCode $DelaySeconds
    }
}
# Kurzschreibweise für das Drücken (nur runter) einer Taste (mit Validierung)
function DownKey {
    param (
        [ValidateSet(
            'SPACE', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'Esc', 'Shift', 'Strg', 'Alt'
        )]
        [string]$Key
    )

    $keyCode = (Get-VirtualKey $Key)

    if ($keyCode -ne 0) { 
        Down-Key $keyCode $DelaySeconds
    }
}

# Kurzschreibweise für das Loslassen (nur hoch) einer Taste (mit Validierung)
function UpKey {
    param (
        [ValidateSet(
            'SPACE', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'Esc', 'Shift', 'Strg', 'Alt'
        )]
        [string]$Key
    )

    $keyCode = (Get-VirtualKey $Key)

    if ($keyCode -ne 0) { 
        Up-Key $keyCode $DelaySeconds
    }
}

# Kurzschreibweise für das Drücken der linken Maustaste(nur runter)
function LeftDown {
    [MouseHelper]::LeftDown()
}
# Kurzschreibweise für das Loslassen der linken Maustaste (nur hoch)
function LeftUp {
    [MouseHelper]::LeftUp()
}
# Kurzschreibweise für das Drücken der rechten Maustaste (nur runter)
function RightDown {
    [MouseHelper]::RightDown()
}
# Kurzschreibweise für das Loslassen der rechten Maustaste (nur hoch)
function RightUp {
    [MouseHelper]::RightUp()
}

# Funktionssammlungen wichtiger Befehle

# Autoclicker
function Click {
    param( 
        [Switch] $Simulate,
        [Switch] $NoDifferentTime,
        [Switch] $Middle,
        [Switch] $Long,
        [String] $Command
    )
    if ($Command -Contains "M") {
        $Middle = $true
    }
    if ($Command -Contains "L") {
        $Long = $true
    }

    $DifferentTime = (!($noDifferentTime))
    if ($DifferentTime) {
        Write-Host "Zeit je click wird +/- um 1/4 abweichen"
    }
    $defTime = 750
    $defDuration = 3
    if ($Middle) {
        $defTime = 30
    }	
    if ($Long) {
        $defTime = 2000
        $defDuration = 10
    }
    Write-Host "Zeit in Millisekunden zwischen den Klicks (" -NoNewline
    Write-Host $defTime -ForegroundColor Gray -NoNewline
    Write-Host "): " -NoNewline
    $time = Read-Host
    if ($time -eq "") {
        $time = $defTime
    }
    [int] $time = $time
    Write-Host "Dauert in Minuten (" -NoNewline
    Write-Host $defDuration -ForegroundColor Gray -NoNewline
    Write-Host "): " -NoNewline
    $dauer = Read-Host
    Write-Host "Autoclicker startet in 5 Sekunden..."
    Start-Sleep -Seconds 5
    if ($dauer -eq "") {
        $dauer = $defDuration
    }
    $sec = ([int]$dauer) * 60

    $running = $true

    $Start = [datetime]::Now

    $End = $Start.AddSeconds($sec)
    # Beenden durch Drücken von STRG+C

    $maxDiffTime = 0
    if ($DifferentTime) {
        $maxDiffTime = $time / 2
    }
    $nextMove = ($End - [DateTime]::Now).TotalSeconds - 60
    $clickCount = 0
    $lastInfo = 0
    try {
        while ($running) {
            $clickCount++
            if (!$Simulate) {
                if ($Middle) {
                    [MouseHelper]::MiddleClick()
                }
                else {
                    [MouseHelper]::LeftClick()
                }
            }
            $d = $End - [DateTime]::Now
            if ($Long) {
                if ($d.TotalSeconds -le $nextMove) {
                    $nextMove = ($End - [DateTime]::Now).TotalSeconds - 60
                    pressKey "S"
                    Start-Sleep -Seconds 1
                    pressKey "W"
                }
            }

            $ds = $d.ToString("mm\:ss")
            $sleepTime = $time
            if ($maxDiffTime -gt 0) {
                $diffRnd = Get-Random -Minimum 0 -Maximum $maxDiffTime
                $diffRnd = $diffRnd - ($maxDiffTime / 2)
                $sleepTime += $diffRnd
            }
            if (([int]$d.TotalSeconds) -ne $lastInfo) {
                Write-Host "Click $clickCount - Rest $ds" -NoNewLine -ForegroundColor Red
                Write-Host " (Strg+C fuer Abbruch)" -ForegroundColor Gray -NoNewLine
                $lastInfo = [int]$d.TotalSeconds
                Write-Host " [Next: $sleepTime ms]" -ForegroundColor Green
            }
            Start-Sleep -Milliseconds $sleepTime
            if ([datetime]::Now -ge $End) {
                $running = $false
            }
        }
    }
    catch {
        Write-Host "Autoclicker gestoppt."
    }
}

# Vote-Seiten öffnen
function op {
    Set-Clipboard "Zocarnium"
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://minecraft-server.eu/vote/index/200CE?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://servers-minecraft.net/server-opsucht-net.39576?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://topg.org/de/minecraft-server/server-663465?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://minecraft.buzz/vote/10595?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://www.minecraft-serverlist.net/vote/58319?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://minecraft-mp.com/server/331753/vote/?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://www.mc-liste.de/server/66/vote?ref=opsucht.net#serverPage"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://minecraftpocket-servers.com/server/78709/vote/?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://serverliste.net/vote/4992?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://best-minecraft-servers.co/server-opsucht-net-citybuild.23283/vote?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://topminecraftservers.org/vote/37528?ref=opsucht.net"'
    Start "C:\Program Files\Google\Chrome\Application\chrome.exe" '--start-fullscreen "https://minecraft-servers.biz/server/opsucht-net-citybuild-wirtschafts-server/?ref=opsucht.net"'
}

function Jump {
    param (
        [int] $Minuten = 10
    )
    $sec = $Minuten * 60
    $End = [datetime]::Now.AddSeconds($sec)
    $running = $true
    Write-Host "ESSEN AUSWAEHLEN!!!!" -ForegroundColor Red
    while ($true) {
        $j = Read-Host "Essen ausgewählt? (j/N)"
        if ($j -eq "j") {
            break
        }
    }
    Write-Host "Springen begint in 5 Sekunden"
    Start-Sleep -Seconds 5
    DownKey "Space"
    RightDown
    try {
        while ($running) {
            $d = $End - [DateTime]::Now
            $ds = $d.ToString("mm\:ss")
            Write-Host "Jump - Rest $ds" -ForegroundColor Red
            Write-Host " (Strg+C fuer Abbruch)" -ForegroundColor Gray -NoNewLine
            Start-Sleep -Seconds 1
            if ([datetime]::Now -ge $End) {
                $running = $false
            }
        }
    }
    catch {
        Write-Host "Jump gestoppt."
    }

    UpKey "Space"
    RightUp
}


# Hilfe
function op? {
    [CmdletBinding()]
    [Alias("oph", "ophelp", "mc?", "mch", "mchelp")]
    param (
        # Validierung der Befehle
        [ValidateSet(
            'Jump', 'Click', 'op', 'op?', 'PressKey', 'DownKey', 'UpKey', 'LeftDown', 'LeftUp', 'RightDown', 'RightUp'
        )]
        [string] $Command
    )

    switch ($Command) {
        'Jump' {
            Write-Host "Jump [Minuten]"
            Write-Host "  Minuten: Dauer in Minuten (Standard: 10)"
            Write-Host ""
            Write-Host "Springen und essen (Essen muss ausgewählt sein!)"
        }
        'Click' {
            Write-Host "Click [-Simulate] [-NoDifferentTime] [-Middle] [-Long] [Command]"
            Write-Host "  -Simulate: Simuliert das Klicken (ohne Mausaktion)"
            Write-Host "  -NoDifferentTime: Keine unterschiedlichen Zeiten zwischen den Klicks"
            Write-Host "  -Middle: Klick mit der mittleren Maustaste"
            Write-Host "  -Long: Klick mit der linken Maustaste und drückt S und W jede Minute"
            Write-Host "  Command: Klickbefehl (M = Middle, L = Long)"
            Write-Host ""
            Write-Host "Autoclicker"

        }
        'op' {
            Write-Host "op"
            Write-Host "  Öffnet die Vote-Seiten in Chrome"
        }
        'op?' {
            Write-Host "op?"
            Write-Host "  Zeigt die Hilfe für die Vote-Seiten"
        }
        'PressKey' {
            Write-Host "PressKey [Key] [DelaySeconds]"
            Write-Host "  Key: Tastencode (SPACE, 0-9, A-Z, Esc, Shift, Strg, Alt)"
            Write-Host "  DelaySeconds: Verzögerung in Sekunden (Standard: 3)"
            Write-Host ""
            Write-Host "Taste drücken und loslassen"
        }
        'DownKey' {
            Write-Host "DownKey [Key]"
            Write-Host "  Key: Tastencode (SPACE, 0-9, A-Z, Esc, Shift, Strg, Alt)"
            Write-Host ""
            Write-Host "Taste drücken (nur runter)"
        }
        'UpKey' {
            Write-Host "UpKey [Key]"
            Write-Host "  Key: Tastencode (SPACE, 0-9, A-Z, Esc, Shift, Strg, Alt)"
            Write-Host ""
            Write-Host "Taste loslassen (nur hoch)"
        }
        'LeftDown' {
            Write-Host "LeftDown"
            Write-Host "  Drückt die linke Maustaste (nur runter)"
        }
        'LeftUp' {
            Write-Host "LeftUp"
            Write-Host "  Lässt die linke Maustaste los (nur hoch)"
        }
        'RightDown' {
            Write-Host "RightDown"
            Write-Host "  Drückt die rechte Maustaste (nur runter)"
        }
        'RightUp' {
            Write-Host "RightUp"
            Write-Host "  Lässt die rechte Maustaste los (nur hoch)"
        }
        default {
            Write-Host "Auflistung aller Befehle:"
            Write-Host "  Click: Autoclicker"
            Write-Host "  op: Öffnet die Vote-Seiten in Chrome"
            Write-Host "  op?: Zeigt die Hilfe für die Vote-Seiten"
            Write-Host "  PressKey: Taste drücken und loslassen"
            Write-Host "  DownKey: Taste drücken (nur runter)"
            Write-Host "  UpKey: Taste loslassen (nur hoch)"
            Write-Host "  LeftDown: Drückt die linke Maustaste (nur runter)"
            Write-Host "  LeftUp: Lässt die linke Maustaste los (nur hoch)"
            Write-Host "  RightDown: Drückt die rechte Maustaste (nur runter)"

        }
    }

}

function MausPos {
    param(
        # Validierung für Modis: Haltbarkeit 1, Haltbarkeit 2
        [ValidateSet(
            'Ohne', 'Haltbarkeit1', 'Haltbarkeit2'
        )]
        [string] $Modus
    )
    Write-Host "Maus positionieren - Position wird in 5 Sekunden ausgelesen"
    Start-Sleep -Seconds 5
    $p = [MouseHelper]::GetMousePosition()
    $x = $p.X
    $y = $p.Y
    switch ($Modus) {
        'Ohne' {
            Write-Host "Mausposition: X: $x, Y: $y"
        }
        'Haltbarkeit1' {
            Write-Host "Mausposition: X: $x, Y: $y"
            Write-Host "Haltbarkeit1=$x,$y" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "In " -NoNewLine
            Write-Host "~/.minecraftrc " -ForegroundColor Yellow -NoNewLine
            Write-Host "eintragen" 
            Set-Clipboard "Haltbarkeit1=$x,$y"
        }
        'Haltbarkeit2' {
            Write-Host "Mausposition: X: $x, Y: $y"
            Write-Host "Haltbarkeit2=$x,$y" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "In " -NoNewLine
            Write-Host "~/.minecraftrc " -ForegroundColor Yellow -NoNewLine
            Write-Host "eintragen" 
            Set-Clipboard "Haltbarkeit2=$x,$y"
        }
    }
    $c = [ScreenTool]::GetPixelColor($x, $y)
    Write-Host "Farbe: R: $($c[0]), G: $($c[1]), B: $($c[2])"
}

function  ReadRC {
    param(
        $ValueName,
        # Validate Typ: Raw,XY
        [ValidateSet(
            'Raw', 'XY'
        )]
        $Typ
    )
    if (!(Test-Path "~/.minecraftrc")) {
        Write-Host "Datei ~/.minecraftrc existiert nicht"
        return
    }
    $rc = Get-Content "~/.minecraftrc"
    $rc | ForEach-Object {
        if ($Typ -eq "Raw") {
            if ($_ -match "$ValueName=(.*)") {
                Write-Host $Matches[1]
            }
        }
        else {
            if ($_ -match "$ValueName=(\d+),(\d+)") {
                $x = $Matches[1]
                $y = $Matches[2]
                $pos = [PSCustomObject]@{
                    X = $x
                    Y = $y
                }
                return $pos
            }
        }
    }
}

function Haltbarkeit {
    param(
        # Validierung für Modis: Haltbarkeit 1, Haltbarkeit 2
        [ValidateSet(
            'Haltbarkeit1', 'Haltbarkeit2', 'Anderer'
        )]
        [string] $Modus,
        [string] $Anderer
    )   

    if ($Modus -eq "Anderer") {
        $mod = $Anderer
    }
    else {
        $mod = $Modus
    }
    Write-Host "Haltbarkeitspruefung beginnt in 5 Sekunden"
    Start-Sleep -Seconds 5

    $pos = ReadRC $mod "XY"
    $x = $pos.X
    $y = $pos.Y
    Write-Host "Haltbarkeit: $mod"
    Write-Host "Mausposition: X: $x, Y: $y"
    $color = [ScreenTool]::GetPixelColor($x, $y)
    Write-Host "Farbe: R: $($color[0]), G: $($color[1]), B: $($color[2])"

    Write-Host "Abbruch mit Ctrl-C"
    $ac = 0
    $esc = 0
    while ($true) {
        $c = [ScreenTool]::GetPixelColor($x, $y)
        $r = $c[0]
        $g = $c[1]
        $b = $c[2]
        if ($r -gt 250 -and $g -lt 110 -and $g -gt 50) {
            Write-Host "ORANGE!" -ForegroundColor DarkYellow
            $ac++
            if ($ac -gt 10) {
                [Console]::Beep(1000, 100)
                $ac = 0
            }
        }
        if ($r -gt 250 -and $g -lt 50 -and $g -gt 10) {
            Write-Host "RED!" -ForegroundColor Red
            [Console]::Beep(1000, 400)
        }
        if ($r -eq 0 -and $g -eq 0) {
            Write-Host "SCHWARZ!"
            [System.Console]::Beep(1000, 1000)
            if ($esc -eq 2) {
                PressKey Esc
            }
            $esc++
        }
        Start-Sleep -Seconds 1
        Write-Host "Farbe: R: $r, G: $g, B: $b"
    }
}