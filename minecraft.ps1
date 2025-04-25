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

    public static void RightClick() {
        mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, IntPtr.Zero);
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
    public static void MiddleDown() {
        mouse_event(MOUSEEVENTF_MIDDLEDOWN, 0, 0, 0, IntPtr.Zero);
    }
    public static void MiddleUp() {
        mouse_event(MOUSEEVENTF_MIDDLEUP, 0, 0, 0, IntPtr.Zero);
    }

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    public static void MoveTo(int x, int y)
    {
        SetCursorPos(x, y);
    }

    public static void MoveBy(int dx, int dy)
    {
        POINT p;
        GetCursorPos(out p);
        SetCursorPos(p.X + dx, p.Y + dy);
    }

    private const uint MOUSEEVENTF_MOVE = 0x0001;

    public static void MoveRelative(int dx, int dy)
    {
        mouse_event(MOUSEEVENTF_MOVE, (uint)dx, (uint)dy, 0, IntPtr.Zero);
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
            'Esc', 'Enter', 'Shift', 'Strg', 'Alt',
            '-', '=', '!', '"', '$', '&', '/', '(', ')', '?', '*', '#', '<', '>', '|'
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
        'Z' = 0x5A

        'Esc' = 0x1B
        'Enter' = 0x0D
        'Shift' = 0x10
        'Strg' = 0x11  # Control
        'Alt' = 0x12

        '-' = 0xBD  # VK_OEM_MINUS
        '=' = 0xBB  # VK_OEM_PLUS

        '!' = 0x31  # Shift + 1
        '"' = 0xDE  # VK_OEM_7 (Anführungszeichen)
        '$' = 0x34  # Shift + 4
        '&' = 0x37  # Shift + 7
        '/' = 0xBF  # VK_OEM_2
        '(' = 0x39  # Shift + 9
        ')' = 0x30  # Shift + 0
        '?' = 0xBF  # Shift + /
        '*' = 0x6A  # VK_MULTIPLY (NumPad), Shift+8 = Stern
        '#' = 0x33  # Shift + 3
        '<' = 0xBC  # VK_OEM_COMMA + Shift
        '>' = 0xBE  # VK_OEM_PERIOD + Shift
        '|' = 0xDC  # VK_OEM_5 (Backslash/Pipe-Taste, je nach Tastaturbelegung)
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
            'Esc', 'Enter', 'Shift', 'Strg', 'Alt',
            '-', '=', '!', '"', '$', '&', '/', '(', ')', '?', '*', '#', '<', '>', '|'
        )]
        [string]$Key,
        $DelaySeconds = 3
    )

    $keyCode = (Get-VirtualKey $Key)

    if ($keyCode -ne 0) { 
        Press-Key $keyCode $DelaySeconds
    }
}

function Send-Text {
    param (
        [string]$Text
    )

    foreach ($char in $Text.ToCharArray()) {
        if ($char -eq " ") {
            PressKey "SPACE" 0.1
            continue
        }
        PressKey $char 0.1
    }
}

function DelHomes {
    param (
        [int]$From,
        [int]$To,
        [string]$Pattern = "n*"
    )

    Write-Host "Loesche Homes von $($Pattern.Replace("*", $From)) bis $($Pattern.Replace("*", $To)) in 3 Sekunden..."
    Start-Sleep -Seconds 3
    for ($nr = $From; $nr -le $To; $nr++) {
        $h = $Pattern.Replace("*", $nr)
        Send-Command "delhome $h"
        Start-Sleep -Seconds 1
    }
}

function Send-Command {
    param (
        [string]$Command
    )

    PressKey "-" 0.1
    Start-Sleep -Milliseconds 100

    Send-Text $Command
    PressKey "ENTER" 0.1
}
# Kurzschreibweise für das Drücken (nur runter) einer Taste (mit Validierung)
function DownKey {
    param (
        [ValidateSet(
            'SPACE', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'Esc', 'Enter', 'Shift', 'Strg', 'Alt',
            '-', '=', '!', '"', '$', '&', '/', '(', ')', '?', '*', '#', '<', '>', '|'
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
            'Esc', 'Enter', 'Shift', 'Strg', 'Alt',
            '-', '=', '!', '"', '$', '&', '/', '(', ')', '?', '*', '#', '<', '>', '|'
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
# Kurzschreibweise für das Drücken der rechten Maustaste (nur runter)
function MiddleDown {
    [MouseHelper]::MiddleDown()
}
# Kurzschreibweise für das Loslassen der rechten Maustaste (nur hoch)
function MiddleUp {
    [MouseHelper]::MiddleUp()
}

# Funktionssammlungen wichtiger Befehle

# Autoclicker
function Click {
    param( 
        [Switch] $Simulate,
        [Switch] $NoDifferentTime,
        [Switch] $Middle,
        [Switch] $Right,
        [Switch] $Long,
        [String] $Command,
        [Switch] $Jump
    )
    if ($Command -Contains "M") {
        $Middle = $true
    }
    if ($Command -Contains "R") {
        $Right = $true
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
    if ($Jump) {
        DownKey "Space"
    }
    try {
        while ($running) {
            $clickCount++
            if (!$Simulate) {
                if ($Middle) {
                    [MouseHelper]::MiddleClick()
                }
                else {
                    if ($Right) {
                        [MouseHelper]::RightClick()
                    }
                    else {
                        [MouseHelper]::LeftClick()
                    }
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

    if ($Jump) {
        UpKey "Space"
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
    Write-Host "Auszeit (Enter=Keine; -=Shutdown Abbruch) :"
    Read-Host $aus
    if ($aus -eq "-") {
        aus -Abbruch
    }
    elseif ($aus -ne "") {
        Aus $aus
    }
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
        [string] $Modus = ""
    )
    Write-Host "Maus positionieren - Position wird in 5 Sekunden ausgelesen"
    Start-Sleep -Seconds 5
    $p = [MouseHelper]::GetMousePosition()
    $x = $p.X
    $y = $p.Y
    if ($Modus -eq "") {
        Write-Host "Mausposition: X: $x, Y: $y"
    }
    else {
        Write-Host "Mausposition: X: $x, Y: $y"
        Write-Host "$Modus=$x,$y" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "In " -NoNewLine
        Write-Host "~/.minecraftrc " -ForegroundColor Yellow -NoNewLine
        Write-Host "eintragen" 
        Set-Clipboard "$Modus=$x,$y"
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
            if ($_ -match "^$ValueName=(.*)") {
                Write-Host $Matches[1]
            }
        }
        else {
            if ($_ -match "^$ValueName=(\d+),(\d+)") {
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
    [CmdletBinding()]
    [Alias("halt")]
    param(
        # Validierung für Modis: Haltbarkeit 1, Haltbarkeit 2
        [ArgumentCompleter({
                [OutputType([System.Management.Automation.CompletionResult])]
                param(
                    [string] $CommandName,
                    [string] $ParameterName,
                    [string] $WordToComplete,
                    [System.Management.Automation.Language.CommandAst] $CommandAst,
                    [System.Collections.IDictionary] $FakeBoundParameters
                )
                $rc = Get-Content "~/.minecraftrc"
                $CompletionResults = @()
                $rc | ForEach-Object {
                    if ($_.Contains("=")) {
                        $ValueName = $_.Split("=")[0].Trim()
                        $CompletionResults += $ValueName
                    }
                }
                $CompletionResults += "O"
                $CompletionResults += "F"
                $CompletionResults += "R"
                $CompletionResults += "V"
                $CompletionResults += "C"
                $CompletionResults += "X"
                $CompletionResults += "1"
                $CompletionResults += "2"
                $CompletionResults += "3"
                $CompletionResults += "4"
                $CompletionResults += "Alle"
                $CompletionResults += "*"
                $CompletionResults += "A"
                $CompletionResults += "Main"
                $CompletionResults += "M"
            
                return $CompletionResults
            })]
        $Modus = "Alle"
    )   
    if ($Modus -is [string]) {
        $Modus = @($Modus)
    }
    $fullModus = @()
    $all = ""
    $Alle = $false
    foreach ($m in $Modus) {
        Switch ($m) {
            "O" { $m = "Offhand" }
            "F" { $m = "Schwert" }
            "R" { $m = "Spitzhacke" }
            "V" { $m = "Schaufel" }
            "C" { $m = "Axt" }
            "X" { $m = "Hacke" }
            "1" { $m = "Slot1" }
            "2" { $m = "Slot2" }
            "3" { $m = "Slot3" }
            "4" { $m = "Slot4" }
            "*" { $m = "Alle" }
            "A" { $m = "Alle" }
            "M" { $m = "Main" }
        }
        if ($m -eq "Alle") {
            $Alle = $true
        }
        if ($m -eq "Main") {
            $fullModus += "Spitzhacke"
            $fullModus += "Schaufel"
            $fullModus += "Axt"
            $fullModus += "Hacke"
            $all += "Spitzhacke, Schaufel, Axt, Hacke, "
        }
        else {
            $fullModus += $m
            $all += "$m, "
        }
    }
    $all = $all.Substring(0, $all.Length - 2)

    Write-Host "Modus : $all" -ForegroundColor Yellow
    $mods = @()
    if ($Alle) {
        $rc = Get-Content "~/.minecraftrc"
        $name = ""
        $rc | ForEach-Object {
            if ($_.Contains("=")) {
                $name = $_.Split("=")[0].Trim()
                $mods += $name
            }
        }
    }       
    else {
        foreach ($m in $fullModus) {
            $mods += $m
        }
    }
    if ($mods.Count -eq 0) {
        Write-Host "Keine Modis gefunden"
        return
    }
    $modPos = @()
    foreach ($mod in $mods) {
        $pos = ReadRC $mod "XY"
        if ($pos -eq $Null) {
            Write-Host "Position fuer die angegebene Haltbarkeit nicht in ~/.minecraftrc gefunden!"
            return;
        }
        
        Add-Member -InputObject $pos -MemberType NoteProperty -Name "Name" -Value $mod
        $modPos += $pos
    }
    if ($modPos.Count -eq 0) {
        Write-Host "Position fuer die angegebene Haltbarkeit nicht in ~/.minecraftrc gefunden!"
        return;
    }
    Write-Host "Haltbarkeitspruefung beginnt in 5 Sekunden"
    Start-Sleep -Seconds 5

    Write-Host "Abbruch mit Ctrl-C"
    $ac = 0
    $esc = 0
    $controlBeep = 0
    while ($true) {
        $signal = ""
        Clear-Host
        foreach ($pos in $modPos) {
            $x = $pos.X
            $y = $pos.Y

            $c = [ScreenTool]::GetPixelColor($x, $y)
            $r = $c[0]
            $g = $c[1]
            $b = $c[2]

            Write-Host "Pos: $($pos.Name) R: $r, G: $g, B: $b -> " -NoNewLine
            if ($r -ge 254 -and ($g -ge 160 -and $g -lt 255)) {
                Write-Host "GELB!" -ForegroundColor DarkYellow
                $ac++
                if ($ac -gt 3) {
                    if ($signal -lt 1) {
                        $signal = 1
                    }
                    $ac = 0
                }
                $controlBeep = 0
            }
            elseif ($r -ge 254 -and ($g -ge 100 -and $g -lt 160)) {
                Write-Host "ORANGE!" -ForegroundColor Red
                if ($signal -lt 2) {
                    $signal = 2
                }
                $controlBeep = 0
            }
            elseif ($r -ge 254 -and ($g -ge 50 -and $g -lt 100)) {
                Write-Host "RED!" -ForegroundColor Red
                if ($signal -lt 3) {
                    $signal = 3
                }
                $controlBeep = 0
            }
            elseif ($r -eq 0 -and $g -eq 0) {
                Write-Host "SCHWARZ!" -ForegroundColor Black -BackgroundColor Red
                if ($signal -lt 4) {
                    $signal = 4
                }
                if ($esc -eq 3) {
                    PressKey Esc
                }

                $c = [ScreenTool]::GetPixelColor($x - 1, $y)
                $r = $c[0]
                $g = $c[1]
                $b = $c[2]
                if ($r -eq 0 -and $g -eq 0) {
                    if ($signal -lt 5) {
                        $signal = 5
                    }
                }

                $esc++
                $controlBeep = 0
            }
            else {
                Write-Host "OK" -ForegroundColor Green
            }
        }
        switch ($signal) {
            1 {
                [Console]::Beep(1000, 200)
            }
            2 {
                [Console]::Beep(1000, 400)
            }
            3 {
                [Console]::Beep(1000, 800)
            }
            4 {
                [System.Console]::Beep(1000, 1000)
            }
            5 {
                for ($a = 0; $a -lt 10; $a++) {
                    [System.Console]::Beep(500, 500); [System.Console]::Beep(2000, 500)	
                }
            }
        }
        if ($controlBeep -ge 60) {
            for ($i = 0; $i -lt 3; $i++) { [Console]::Beep(3000, 50); Start-Sleep -Milliseconds 100 }
            $controlBeep = 0
        }
        $controlBeep++
        Start-Sleep -Seconds 1
    }
}

function aus {
    param(
        $Zeit = "",
        [Switch] $Abbruch
    )
    if ($Abbruch) {
        $Zeit = ""
    }


    if ($Zeit -ne "") {
        $dest = [datetime]::parse($zeit)
        $jetzt = [datetime]::now
        $diff = $dest - $jetzt
        [long] $dsec = $diff.totalseconds
        if ($dsec -lt 0) {
            $dsec += (24 * 60 * 60)
        }
        shutdown /a *>$null
        Write-Host "Computer aus in $dsec Sekunden"
        shutdown /s /f /t $dsec
    }
    else {
        Write-Host "Herunterfahren abgebrochen"
        shutdown /a *>$null
    }
}

# Angelsystem

$SCREEN_LEFT = 2160
$SCREEN_TOP = 0
$SCREEN_RIGHT = 3439
$SCREEN_BOTTOM = 764

$SCREEN_CENTER_X = ($SCREEN_LEFT + $SCREEN_RIGHT) / 2
$SCREEN_CENTER_Y = ($SCREEN_TOP + $SCREEN_BOTTOM) / 2

function Angeln {
    Write-Host "Auszeit (Enter=Keine; -=Shutdown Abbruch) : " -NoNewLine
    $aus = Read-Host 
    if ($aus -eq "-") {
        aus -Abbruch
    }
    elseif ($aus -ne "") {
        Aus $aus
    }
    
    Write-Host "Angeln beginnt in 5 Sekunden"
    Start-Sleep -Seconds 5
    Write-Host "Angeln beginnt"
    $lastMove = [DateTime]::Now
    while ($true) {
        Write-Host "Auswerfen" -ForegroundColor Red
        [MouseHelper]::RightClick()
        Start-Sleep -Seconds 2
        CheckBiss
        Write-Host "Einholen" -ForegroundColor Green
        [MouseHelper]::RightClick()
        Start-Sleep -Seconds 1
        $lastMoveDiff = [DateTime]::Now - $lastMove
        if ($lastMoveDiff.TotalSeconds -gt 60) {
            DownKey "S"
            Start-Sleep -Seconds 1
            UpKey "S"
            DownKey "W"
            Start-Sleep -Milliseconds 1100
            UpKey "W"
            $lastMove = [DateTime]::Now
        }
    }
}

function CheckBiss {
    param (
    )
    $x = 28
    $y = 709

    $count = 0
    while ($true) {
        Start-Sleep -Milliseconds 100
        $count++
        $color = [ScreenTool]::GetPixelColor($x, $y)
        if ($color[0] -gt 50) {
            Write-Host "Angebissen"
            break
        }
        if ($count -gt 400) {
            Write-Host "Kein Biss"
            break
        }
    }

}
function ScannCenter {
    param ()
    $radius = 3
    $found = $false
    $count = 0
    while (!$found) {
        $pos = FindRedInCenterNear -radius $radius -preRadius ($radius - 2)
        if ($pos -ne $null) {
            return $pos
            break
        }
        else {
            $radius += 2
            $count++
            if ($count -gt 40) {
                Write-Host "Kein Rot gefunden"
                return $null
                break
            }
        }
    }
}
function FindRedInCenterNear {
    param (
        $x = -1,
        $y = -1,
        [int] $radius = 50,
        [int] $preRadius = 0

    )
    if ($x -eq -1) {
        $x = $SCREEN_CENTER_X
    }
    if ($y -eq -1) {
        $y = $SCREEN_CENTER_Y
    }

    Write-Host "X $x  Y $y"
    
    $found = $false
    for ($i = - $radius; $i -le $radius; $i += 2) {
        if ($preRadius -gt 0 -and ($i -ge - $preRadius -and $i -le $preRadius)) {
            continue
        }
        for ($j = - $radius; $j -le $radius; $j += 2) {
            if ($preRadius -gt 0 -and ($j -ge - $preRadius -and $j -le $preRadius)) {
                continue
            }
            $color = [ScreenTool]::GetPixelColor($x + $i, $y + $j)
            if ($color[0] -gt 100 -and $color[1] -lt 50 -and $color[2] -lt 50) {
                Write-Host "Red found at: X: $($x + $i), Y: $($y + $j)"
                $found = $true
                $returnObject = [PSCustomObject]@{
                    X = $x + $i
                    Y = $y + $j
                }
                break
            }
        }
        if ($found) {
            break
        }
    }
    if ($found) {
        return $returnObject
    }
    else {
        return $null
    }
}

function GoBackward {
    param()

    DownKey "S"
    DownKey "D"
    Start-Sleep -Milliseconds 300
    UpKey "D"
    UpKey "S"
}
function GoForward {
    param()

    DownKey "W"
    DownKey "D"
    Start-Sleep -Milliseconds 300
    UpKey "D"
    UpKey "W"
}
function GoLeft {
    param()

    DownKey "A"
    DownKey "W"
    Start-Sleep -Milliseconds 200
    UpKey "W"
    UpKey "A"
}
function GoRight {
    param()

    DownKey "D"
    DownKey "W"
    Start-Sleep -Milliseconds 100
    UpKey "W"
    UpKey "D"
}

function Kakao() {
    param (
        [int] $Anzahl = 100
    )
    for ($i = 1; $i -lt $Anzahl; $i++) {
        # 106 °
        GoRight
        PressKey "2" -DelaySeconds 0
        Start-Sleep -Milliseconds 50
        [MouseHelper]::RightClick()
        Start-Sleep -Milliseconds 50
        PressKey "1" -DelaySeconds 0
        Start-Sleep -Milliseconds 40
        [MouseHelper]::RightDown()
        Start-Sleep -Milliseconds 260
        [MouseHelper]::RightUp()
        Start-Sleep -Milliseconds 40
        PressKey "C" -DelaySeconds 0
        GoLeft
        Start-Sleep -Milliseconds 40
        [MouseHelper]::LeftClick()
        Start-Sleep -Milliseconds 40
    }
}
function Bambus1 {
    # ### ### ###
    # ### ### ###   VOLL BLÖCKE
    # ### ### ###
    # ###     ###
    # ###  B  ###   BLÖCKE l&r, BAMBUS m
    # ###     ###   
    # ### ___ ###   FALLTÜRE hochgeklappt
    # ###     ###   FREI (hier stehen)
    # ###     ###
    # ### ### ###
    # ### ### ###   VOLL BLÖCKE
    # ### ### ###
    #
    # 
    param (
        [int] $Anzahl = 100
    )
    for ($i = 1; $i -lt $Anzahl; $i++) {
        GoBackward
        PressKey "1" -DelaySeconds 0
        Start-Sleep -Milliseconds 50
        [MouseHelper]::RightDown()
        Start-Sleep -Milliseconds 260
        [MouseHelper]::RightUp()
        Start-Sleep -Milliseconds 40
        GoForward
        PressKey "F" -DelaySeconds 0
        Start-Sleep -Milliseconds 40
        [MouseHelper]::LeftClick()
        Start-Sleep -Milliseconds 40
    }
}

function Mine {
    param(
        [switch] $WithMove
    )
    Write-Host "Mining beginnt in ..."
    Write-Host "3, " -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "2, " -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "1" -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "Mining beginnt"
    $cnt = 30
    $stp = 12
    LeftDown
    if ($WithMove) {
        for ($i = 0; $i -lt ($cnt / 2); $i++) {
            [MouseHelper]::MoveRelative(-$stp, 0);
            Start-Sleep -Milliseconds 5
        }
        while ($true) {
            for ($i = 0; $i -lt $cnt; $i++) {
                [MouseHelper]::MoveRelative($stp, 0);
                Start-Sleep -Milliseconds 5
            }
            for ($i = 0; $i -lt $cnt; $i++) {
                [MouseHelper]::MoveRelative(-$stp, 0);
                Start-Sleep -Milliseconds 5
            }
        }
    }
    else {
        LeftDown -DelaySeconds 0
        while ($true) {

            Start-Sleep -Milliseconds 300
            $p = [MouseHelper]::GetMousePosition()
            $x = $p.X
            $y = $p.Y
            if ($x -lt 200) {
                [System.Console]::Beep(1000, 1000)
                LeftDown -DelaySeconds 0
            }

        }
    }

}

function Plant {
    param(

    )
    Write-Host "Saehen beginnt in ..." -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "3, " -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "2, " -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "1" -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "Saehen beginnt"
    RightDown
    # Alle Felder
    $richtung = $true;
    $anzFelder = 10
    for ($f = 0; $f -lt $anzFelder; $f++) {
        Write-Host "Feld $($f+1): " -NoNewline
        # ein Feld je 7 Reihen
        for ($r = 0; $r -lt 7; $r++) {
            Write-Host "$($r+1) " -NoNewline
            if ($richtung) {
                PlantBack
                PlantRight
            }
            else {
                PlantForward
                PlantRight        
            }
            $richtung = !$richtung
        }
        if ($f -lt 9) {
            PlantRight 1000
            Start-Sleep -Milliseconds 200
            PlantLeft 1500
        }
        Write-Host
    }
    # Feld 10 hat 8 Reihe    
    PlantBack

    RightUp

}

function PlantBack {
    param ( $time = 2050 )
    DownKey "S"
    PlantMiddle $time
    UpKey "S"
}
function PlantForward {
    param ( $time = 2050 )
    DownKey "W"
    PlantMiddle $time
    UpKey "W"
}
function PlantRight {
    param ( $time = 220 )
    DownKey "D"
    PlantMiddle $time
    UpKey "D"
}
function PlantLeft {
    param ( $time = 210 )
    DownKey "A"
    PlantMiddle $time
    UpKey "A"
}

function PlantMiddle {
    param (
        $time = 2200
    )
    $start = [DateTime]::Now
    while ($true) {
        $diff = ([Datetime]::Now - $start).TotalMilliseconds
        if ($diff -gt $time) {
            break;
        }
        [MouseHelper]::MiddleClick()
        Start-Sleep -Milliseconds 20
    }
}

function test {
    Start-Sleep -Seconds 3
    RightDown
    PlantBack
    PlantRight
    PlantForward
    RightUp
}
