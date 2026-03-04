# Find-History.ps1
# Interactive full-screen search through PowerShell history
# Uses alternate screen buffer for a clean full-screen display
#
# Usage:
#   - Ctrl+H : search and inject the command directly onto the prompt
#   - pah    : search and copy the command to clipboard

function Invoke-HistorySearch {
    param([int]$MaxCommands = 1000)

    # Import PSReadLine if needed
    if (-not (Get-Module PSReadLine)) {
        Import-Module PSReadLine -ErrorAction SilentlyContinue
    }

    # Get history file path
    try {
        $historyPath = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistorySavePath()
    } catch {
        $historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    }

    if (-not (Test-Path $historyPath)) {
        return $null
    }

    $allHistory = Get-Content $historyPath -Tail $MaxCommands -Encoding UTF8 | Where-Object { $_.Trim() }
    [Array]::Reverse($allHistory)

    if ($allHistory.Count -eq 0) {
        return $null
    }

    $esc = [char]0x1b

    # Switch to alternate screen buffer
    [Console]::Write("$esc[?1049h")
    # Hide cursor
    [Console]::Write("$esc[?25l")

    $searchTerm = ""
    $selectedIndex = 0
    $filtered = $allHistory
    $selected = $null

    try {
        do {
            $width = [Console]::WindowWidth
            $height = [Console]::WindowHeight

            # Filter
            if ($searchTerm -eq "") {
                $filtered = $allHistory
            } else {
                try {
                    $filtered = @($allHistory | Where-Object { $_ -match $searchTerm })
                } catch {
                    $filtered = @($allHistory | Where-Object { $_ -like "*$searchTerm*" })
                }
            }

            if ($selectedIndex -ge $filtered.Count) {
                $selectedIndex = [Math]::Max(0, $filtered.Count - 1)
            }

            # Build screen content in a buffer
            $buf = [System.Text.StringBuilder]::new()

            # Move cursor to top-left
            $null = $buf.Append("$esc[H")

            # Line 1: Title
            $title = " POWERSHELL HISTORY SEARCH "
            $pad = [Math]::Max(0, $width - $title.Length)
            $leftPad = [Math]::Floor($pad / 2)
            $rightPad = $pad - $leftPad
            $null = $buf.Append("$esc[46;30m$(' ' * $leftPad)$title$(' ' * $rightPad)$esc[0m`n")

            # Line 2: empty
            $null = $buf.Append("$esc[K`n")

            # Line 3: Search bar
            $searchDisplay = "  Search: ${searchTerm}_"
            if ($searchDisplay.Length -lt $width) {
                $searchDisplay = $searchDisplay + (' ' * ($width - $searchDisplay.Length))
            }
            $null = $buf.Append("$esc[33m$searchDisplay$esc[0m`n")

            # Line 4: Results info
            $infoLine = "  $($filtered.Count) / $($allHistory.Count) commands"
            if ($infoLine.Length -lt $width) { $infoLine = $infoLine + (' ' * ($width - $infoLine.Length)) }
            $null = $buf.Append("$esc[90m$infoLine$esc[0m`n")

            # Line 5: Separator
            $sepLen = [Math]::Min($width - 4, 60)
            $sep = "  " + ('-' * $sepLen)
            if ($sep.Length -lt $width) { $sep = $sep + (' ' * ($width - $sep.Length)) }
            $null = $buf.Append("$esc[90m$sep$esc[0m`n")

            # Results area
            $headerLines = 5
            $footerLines = 2
            $availableLines = $height - $headerLines - $footerLines

            # Scroll window
            $displayCount = [Math]::Min($filtered.Count, $availableLines)
            $startIdx = 0
            if ($selectedIndex -ge $displayCount) {
                $startIdx = $selectedIndex - $displayCount + 1
            }

            $resultLines = 0
            for ($i = $startIdx; $i -lt ($startIdx + $displayCount) -and $i -lt $filtered.Count; $i++) {
                $cmd = $filtered[$i]
                $maxCmdLen = $width - 6
                if ($cmd.Length -gt $maxCmdLen) { $cmd = $cmd.Substring(0, $maxCmdLen - 3) + "..." }

                if ($i -eq $selectedIndex) {
                    $line = "  > $cmd"
                    if ($line.Length -lt $width) { $line = $line + (' ' * ($width - $line.Length)) }
                    $null = $buf.Append("$esc[30;42m$line$esc[0m`n")
                } else {
                    $line = "    $cmd"
                    if ($line.Length -lt $width) { $line = $line + (' ' * ($width - $line.Length)) }
                    $null = $buf.Append("$esc[37m$line$esc[0m`n")
                }
                $resultLines++
            }

            if ($filtered.Count -eq 0) {
                $noResult = "    (no results)"
                if ($noResult.Length -lt $width) { $noResult = $noResult + (' ' * ($width - $noResult.Length)) }
                $null = $buf.Append("$esc[90m$noResult$esc[0m`n")
                $resultLines++
            }

            # Fill remaining empty lines
            $emptyLine = ' ' * $width
            for ($i = $resultLines; $i -lt $availableLines; $i++) {
                $null = $buf.Append("$emptyLine`n")
            }

            # Empty line before footer
            $null = $buf.Append("$esc[K`n")

            # Footer
            $footer = "  [Up/Down] Navigate   [Enter] Select   [Esc] Quit   [PgUp/PgDn] Page   [Del] Clear"
            if ($footer.Length -gt $width) { $footer = $footer.Substring(0, $width) }
            if ($footer.Length -lt $width) { $footer = $footer + (' ' * ($width - $footer.Length)) }
            $null = $buf.Append("$esc[46;30m$footer$esc[0m")

            # Flush to screen
            [Console]::Write($buf.ToString())

            # Read key
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($key.VirtualKeyCode) {
                38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }
                40 { if ($selectedIndex -lt ($filtered.Count - 1)) { $selectedIndex++ } }
                33 { $selectedIndex = [Math]::Max(0, $selectedIndex - $availableLines) }
                34 { $selectedIndex = [Math]::Min($filtered.Count - 1, $selectedIndex + $availableLines) }
                36 { $selectedIndex = 0 }
                35 { $selectedIndex = [Math]::Max(0, $filtered.Count - 1) }
                13 { # Enter
                    if ($filtered.Count -gt 0) {
                        $selected = $filtered[$selectedIndex]
                    }
                    break
                }
                27 { break } # Escape
                8 { # Backspace
                    if ($searchTerm.Length -gt 0) {
                        $searchTerm = $searchTerm.Substring(0, $searchTerm.Length - 1)
                        $selectedIndex = 0
                    }
                }
                46 { # Delete
                    $searchTerm = ""
                    $selectedIndex = 0
                }
                default {
                    $char = $key.Character
                    if ([int]$char -ge 32 -and [int]$char -le 126) {
                        $searchTerm += [string]$char
                        $selectedIndex = 0
                    }
                }
            }

            # Exit on Enter or Escape
            if ($key.VirtualKeyCode -eq 13 -or $key.VirtualKeyCode -eq 27) { break }

        } while ($true)
    }
    finally {
        # Always restore main screen
        [Console]::Write("$esc[?25h")   # Show cursor
        [Console]::Write("$esc[?1049l") # Switch back to main screen buffer
    }

    return $selected
}

# Standalone function (fh): copies to clipboard
function Find-History {
    param([int]$MaxCommands = 1000)
    $result = Invoke-HistorySearch -MaxCommands $MaxCommands
    if ($result) {
        Set-Clipboard -Value $result
        Write-Host "Copied: " -ForegroundColor DarkGray -NoNewline
        Write-Host $result -ForegroundColor Green
        Write-Host "(Ctrl+V to paste)" -ForegroundColor DarkGray
    }
}

# Ctrl+H binding: injects directly onto the prompt
if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Chord 'Ctrl+h' -ScriptBlock {
        $result = Invoke-HistorySearch
        if ($result) {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
        }
    } -Description "Interactive history search"
}

Set-Alias -Name pah -Value Find-History -Scope Global -Force
