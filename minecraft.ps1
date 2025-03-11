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

    private const uint MOUSEEVENTF_LEFTDOWN = 0x02;
    private const uint MOUSEEVENTF_LEFTUP = 0x04;

    private const uint MOUSEEVENTF_MIDDLEDOWN = 0x20;
    private const uint MOUSEEVENTF_MIDDLEUP = 0x40;

    private const uint MOUSEEVENTF_RIGHTDOWN = 0x08;
    private const uint MOUSEEVENTF_RIGHTUP = 0x10;

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

function Down-Key {
    param (
        [byte]$Key
    )
    # Taste drücken
    [Keyboard]::keybd_event($Key, 0, [Keyboard]::KEYEVENTF_KEYDOWN, 0)
}
function Up-Key {
    param (
        [byte]$Key
    )
    # Taste loslassen
    [Keyboard]::keybd_event($Key, 0, [Keyboard]::KEYEVENTF_KEYUP, 0)
}
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

function leftdown {
    [MouseHelper]::LeftDown()
}
function leftup {
    [MouseHelper]::LeftUp()
}
function rightdown {
    [MouseHelper]::RightDown()
}
function rightup {
    [MouseHelper]::RightUp()
}


function click {
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
    try {
        while ($running) {
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
            Write-Host "Click - Rest $ds" -NoNewLine -ForegroundColor Red
            Write-Host " (Strg+C fuer Abbruch)" -ForegroundColor Gray -NoNewLine
            $sleepTime = $time
            if ($maxDiffTime -gt 0) {
                $diffRnd = Get-Random -Minimum 0 -Maximum $maxDiffTime
                $diffRnd = $diffRnd - ($maxDiffTime / 2)
                $sleepTime += $diffRnd
            }
            Write-Host " [Next: $sleepTime ms]" -ForegroundColor Green
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


