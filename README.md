# Powershell-Advanced-History

Interactive full-screen search through PowerShell command history.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Windows Terminal](https://img.shields.io/badge/Windows%20Terminal-recommended-brightgreen)

![PowerShell-Advanced-History](PowerShell-Advanced-History.png)

## Demo

https://github.com/user-attachments/assets/6cb0ff0d-eee3-4604-875c-e4add1891059

## Features

- **Real-time search** with regex support across your entire PSReadLine history
- **Full-screen display** using alternate screen buffer (like `vim`, `less`, `htop`)
- **Smooth keyboard navigation** with arrows, PageUp/PageDown, Home/End
- **Direct injection** onto the prompt via `Ctrl+H` — no copy-paste needed
- **Clean restore**: your previous screen is restored exactly as it was after searching
- **Most recent first**: results are sorted with newest commands at the top

## Installation

### Automatic

```powershell
git clone https://github.com/<your-user>/Powershell-find-history.git
cd Powershell-find-history
.\Install.ps1
```

The install script will:

1. Copy `PowerShell-Advanced-History.ps1` to `~/Documents/PowerShell/Scripts/`
2. Add auto-loading to your PowerShell profile
3. Available in every new session

### Manual

Add this line to your PowerShell profile (`$PROFILE`):

```powershell
. "path\to\PowerShell-Advanced-History.ps1"
```

## Usage

| Shortcut | Action |
|----------|--------|
| `Ctrl+H` | Search and **inject the command directly onto the prompt** |
| `pah` | Search and **copy to clipboard** (Ctrl+V to paste) |

### Inside the search interface

| Key | Action |
|-----|--------|
| Up / Down | Navigate through results |
| PageUp / PageDown | Jump by page |
| Home / End | Go to first / last result |
| Enter | Select the command |
| Escape | Quit without selecting |
| Delete | Clear the search |
| Backspace | Remove last character |

Type directly to filter — the filter supports **regular expressions**.

## Why Ctrl+H instead of pah?

`Ctrl+H` runs inside the PSReadLine context, which allows **injecting** the command directly onto the prompt line. Just press Enter to execute it.

`pah` is a regular command — once it finishes, PowerShell displays a fresh prompt. There is no way to write to that new prompt from the previous command, hence the clipboard fallback.

## Compatibility

- **PowerShell 5.1** (Windows PowerShell) and **PowerShell 7+**
- **Windows Terminal** recommended for best rendering
- Requires the **PSReadLine** module (included by default)
