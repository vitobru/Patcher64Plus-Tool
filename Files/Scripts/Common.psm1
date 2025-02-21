function SetWiiVCMode([boolean]$Enable) {
    
    if ( ($Enable -eq $IsWiiVC) -and $GameIsSelected) { return }
    $global:IsWiiVC = $Enable

    WriteToConsole "Changing Between Wii VC Mode..."

    SetVCRemap
    EnablePatchButtons (IsSet $GamePath)
    SetModeLabel

}



#==================================================================================================================================================================================================================================================================
function CreateToolTip($Form, $Info) {

    # Create ToolTip
    $ToolTip              = New-Object System.Windows.Forms.ToolTip
    $ToolTip.AutoPopDelay = 32767
    $ToolTip.InitialDelay = 500
    $ToolTip.ReshowDelay  = 0
    $ToolTip.ShowAlways   = $True
    if ( (IsSet $Form) -and (IsSet $Info) ) { $ToolTip.SetToolTip($Form, $Info) }
    return $ToolTip

}



#==============================================================================================================================================================================================
function ChangeConsolesList() {
    
    WriteToConsole "Loading consoles..."

    # Reset
    $CurrentGame.Console.Items.Clear()

    $Items = @()
    foreach ($item in $Files.json.consoles) {
        $Items += $item.title
    }

    $CurrentGame.Console.Items.AddRange($Items)

    # Reset last index
    foreach ($i in 0..($Items.length-1)) {
        if ($GameConsole.title -eq $Items[$i]) {
            $CurrentGame.Console.SelectedIndex = $i
            break
        }
    }

    if ($Items.Length -gt 0 -and $CurrentGame.Console.SelectedIndex -eq -1) {
        try     { $CurrentGame.Console.SelectedIndex = $Settings["Core"][$CurrentGame.Console.Name] }
        catch   { $CurrentGame.Console.SelectedIndex = 0 }
    }

}



#==============================================================================================================================================================================================
function ChangeGamesList() {
    
    WriteToConsole "Loading games..."

    # Set console
    foreach ($item in $Files.json.consoles) {
        if ($item.title -eq $CurrentGame.Console.Text) {
            $global:GameConsole = $item
            break
        }
    }

    # Reset
    $CurrentGame.Game.Items.Clear()
    if (!$IsWiiVC) { $CustomHeader.ROMTitle.MaxLength = $GameConsole.rom_title_length }

    $items = @()
    foreach ($item in $Files.json.games) {
        if ( ($CurrentGame.Console.Text -eq $GameConsole.title) -and ($GameConsole.mode -contains $item.console) ) {
            if ( ( $IsWiiVC -and $item.support_vc -eq 1) -or (!$IsWiiVC) ) { $items += $item.title }
        }
        elseif ($item.console -contains "All") { $items += $item.title }
    }

    $CurrentGame.Game.Items.AddRange($items)

    # Reset last index
    foreach ($i in 0..($Items.Length-1)) {
        if ($GameType.title -eq $items[$i]) {
            $CurrentGame.Game.SelectedIndex = $i
            break
        }
    }

    if ($items.Length -gt 0 -and $CurrentGame.Game.SelectedIndex -eq -1) {
        try { $CurrentGame.Game.SelectedIndex = $Settings["Core"][$CurrentGame.Game.Name] }
        catch { $CurrentGame.Game.SelectedIndex = 0 }
    }

}



#==============================================================================================================================================================================================
function ChangePatchPanel() {
    
    $Patches.Panel.Visible = ($GameType.patches -eq 1 -or ($GameType.patches -eq 2 -and $IsWiiVC) )
    if ($GameType.patches -eq 0 -or ($GameType.patches -eq 2 -and !$IsWiiVC) ) { return }

    WriteToConsole "Loading patches..."

    # Reset
    $Patches.Group.Text = $GameType.mode + " - Patch Options"
    $Patches.Type.Items.Clear()

    # Set combobox for patches
    $items = @()
    foreach ($item in $Files.json.patches) {
        if (!(IsSet $item.patch)) { $Patches.Type.Items.Add($item.title) }
        else {
            if ( ( ($IsWiiVC -and $item.console -eq "Wii VC") -or (!$IsWiiVC -and $item.console -eq "Native") -or ($item.console -eq "Both") -or !(IsSet $item.console) ) ) { $Patches.Type.Items.Add($item.title) }
        }
    }

    # Reset last index
    foreach ($index in $Patches.Type.Items) {
        foreach ($item in $Files.json.patches) {
            if ($item.title -eq $GamePatch.title -and $item.title -eq $index) {
                $Patches.Type.Text = $index
                break
            }
        }
    }

    if ($InputPaths.GameTextBox.Text -notlike '*:\*') { $global:IsActiveGameField = $True }
    if ($Patches.Type.Items.Count -gt 0 -and $Patches.Type.SelectedIndex -eq -1) {
        try { $Patches.Type.SelectedIndex = $Settings["Core"][$Patches.Type.Name] }
        catch { $Patches.Type.SelectedIndex = 0 }
    }

}



#==============================================================================================================================================================================================
function SetMainScreenSize() {
    
    WriteToConsole "Changing main screen display..."

    # Show / Hide Custom Header
    if ($IsWiiVC)   { $CustomHeader.Group.Text = " Custom Channel Title and GameID " }
    else            { $CustomHeader.Group.Text = " Custom Game Title and GameID " }

    # Set Paths Panels Visibility and sizes
    $InputPaths.GamePanel.Top = (DPISize 80)

    if ($GameType.inject -eq 1 -and $IsWiiVC) {
        $InputPaths.InjectPanel.Visible = $True
        $InputPaths.InjectPanel.Height  = (DPISize 50)
        $InputPaths.InjectPanel.Top     = $InputPaths.GamePanel.Bottom + (DPISize 5)
    }
    else {
        $InputPaths.InjectPanel.Visible = $False
        $InputPaths.InjectPanel.Height  = 0
    }

    if ($GameType.custom_patch -eq 1) {
        $InputPaths.PatchPanel.Visible = $True;
        $InputPaths.PatchPanel.Height  = (DPISize 50)
        if ($GameType.inject -eq 1 -and $IsWiiVC)   { $InputPaths.PatchPanel.Top = $InputPaths.InjectPanel.Bottom + (DPISize 5) }
        else                                        { $InputPaths.PatchPanel.Top = $InputPaths.GamePanel.Bottom   + (DPISize 5) }
    }
    else {
        $InputPaths.PatchPanel.Visible = $False
        $InputPaths.PatchPanel.Height  = 0
    }

    # Custom Header Panel Visibility and Size
    $CustomHeader.Panel.Visible     = ($GameConsole.rom_title -gt 0) -or ($GameConsole.rom_gameID -gt 0)  -or $IsWiiVC
    $CustomHeader.ROMTitle.Visible  = $CustomHeader.ROMTitleLabel.Visible  = ($GameConsole.rom_title -gt 0)  -and !$IsWiiVC
    $CustomHeader.ROMGameID.Visible = $CustomHeader.ROMGameIDLabel.Visible = ($GameConsole.rom_gameID -eq 1) -and !$IsWiiVC
    $CustomHeader.VCTitle.Visible   = $CustomHeader.VCTitleLabel.Visible   = $CustomHeader.VCGameID.Visible     = $CustomHeader.VCGameIDLabel.Visible     = $IsWiiVC
    $CustomHeader.Region.Visible    = $CustomHeader.RegionLabel.Visible    = $CustomHeader.EnableRegion.Visible = $CustomHeader.EnableRegionLabel.Visible = ($GameConsole.rom_gameID -eq 2)

    if ($GameConsole.rom_gameID -eq 2)   { $CustomHeader.Panel.Height = (DPISize 80) }
    else                                 { $CustomHeader.Panel.Height = (DPISize 50) }
    $CustomHeader.Group.Height = $CustomHeader.Panel.Height

    $InputPaths.InjectPanel.Visible = $IsWiiVC
    $VC.Panel.Visible = $IsWiiVC

    # Positioning
    if ($GameType.custom_patch -eq 1)   { $CurrentGame.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($InputPaths.PatchPanel.Bottom + (DPISize 5))) }
    else                                { $CurrentGame.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($InputPaths.GamePanel.Bottom  + (DPISize 5))) }
    $CustomHeader.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($CurrentGame.Panel.Bottom + (DPISize 5)))
    
    # Set VC Panel Size
    if ($GameConsole.t64 -eq 1 -or $GameConsole.expand_memory -eq 1 -or $GameConsole.remove_filter -eq 1 -or (IsSet $Files.json.controls) )   { $VC.Panel.Height = $VC.Group.Height = (DPISize 90) }
    else                                                                                                                                      { $VC.Panel.Height = $VC.Group.Height = (DPISize 70) }

    # Arrange Panels
    if ($IsWiiVC) {
        if ( ($GameType.patches -eq 1) -or ($GameType.patches -eq 2 -and $IsWiiVC) ) {
            $Patches.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($CustomHeader.Panel.Bottom + (DPISize 5)))
            $VC.Panel.Location      = New-Object System.Drawing.Size((DPISize 10), ($Patches.Panel.Bottom      + (DPISize 5)))
        }
        else { $VC.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($CustomHeader.Panel.Bottom   + (DPISize 5))) }
        $StatusPanel.Location       = New-Object System.Drawing.Size((DPISize 10), ($VC.Panel.Bottom             + (DPISize 5)))
    }
    else {
        if ( ($GameConsole.rom_title -eq 0) -and ($GameConsole.rom_gameID -eq 0) ) {
            if ($GameType.patches) { $Patches.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($CurrentGame.Panel.Bottom   + (DPISize 5))) }
            else                   { $StatusPanel.Location   = New-Object System.Drawing.Size((DPISize 10), ($CurrentGame.Panel.Bottom   + (DPISize 5))) }
        }
        else {
            if ( ($GameType.patches -eq 1) -or ($GameType.patches -eq 2 -and $IsWiiVC) )   { $Patches.Panel.Location = New-Object System.Drawing.Size((DPISize 10), ($CustomHeader.Panel.Bottom + (DPISize 5))) }
            else                                                                           { $StatusPanel.Location   = New-Object System.Drawing.Size((DPISize 10), ($CustomHeader.Panel.Bottom + (DPISize 5))) }
        }
        if ( ($GameType.patches -eq 1) -or ($GameType.patches -eq 2 -and $IsWiiVC) )       { $StatusPanel.Location   = New-Object System.Drawing.Size((DPISize 10), ($Patches.Panel.Bottom      + (DPISize 5))) }
    }
    
    $MainDialog.Height = $StatusPanel.Bottom + (DPISize 50)

}



#==============================================================================================================================================================================================
function ResetReduxSettings() {
    
    # Reset Options
    $global:Redux = @{}
    $Redux.Box    = @{}
    $Redux.Groups = @()
    $Last.Group   = $Last.Panel = $Last.GroupName = $null
    $Last.Half    = $False
    SetVCRemap

}



#==============================================================================================================================================================================================
function SetVCRemap() {
    
    if ( (TestFile $GameFiles.controls) -and $GameSettings -ne $null -and $IsWiiVC) {
        $Files.json.controls = SetJSONFile $GameFiles.controls
        CreateVCRemapDialog # Create VC remap settings
    }
    else { $Files.json.controls  = $null }

    SetVCPanel

}



#==============================================================================================================================================================================================
function ChangeGameMode() {
    
    WriteToConsole "Changing game mode..."

    if (IsSet $GamePatch.script) { if (Get-Module -Name $GamePatch.script)   { Remove-Module -Name $GamePatch.script } }

    foreach ($item in $Files.json.games) {
        if ($item.title -eq $CurrentGame.Game.Text) {
            $global:GameType = $item
            $global:GamePatch = $null
            break
        }
    }

    $GameFiles.base         = $Paths.Games      + "\" + $GameType.mode
    $GameFiles.binaries     = $GameFiles.Base   + "\Binaries"
    $GameFiles.export       = $GameFiles.Base   + "\Export"
    $GameFiles.compressed   = $GameFiles.Base   + "\Compressed"
    $GameFiles.decompressed = $GameFiles.Base   + "\Decompressed"
    $GameFiles.languages    = $GameFiles.Base   + "\Languages"
    $GameFiles.banks        = $GameFiles.Base   + "\Audio Banks"
    $GameFiles.models       = $Paths.Models     + "\" + $GameType.mode
    $GameFiles.downgrade    = $GameFiles.Base   + "\Downgrade"
    $GameFiles.textures     = $GameFiles.Base   + "\Textures"
    $GameFiles.editor       = $GameFiles.Base   + "\Editor"
    $GameFiles.customText   = $GameFiles.Base   + "\Custom Text"
    $GameFiles.info         = $GameFiles.Base   + "\Info.txt"
    $GameFiles.patches      = $GameFiles.Base   + "\Patches.json"
    $GameFiles.controls     = $GameFiles.Base   + "\Controls.json"
    $GameFiles.textEditor   = $GameFiles.Base   + "\Text Editor.json"
    $GameFiles.sceneEditor  = $GameFiles.Base   + "\Scene Editor.json"
    $GameFiles.scenesPatch  = $GameFiles.editor + "\scenes.bps"

    # JSON Files
    if ( ($GameType.patches -eq 1) -or ($GameType.patches -eq 2 -and $IsWiiVC) )   { $Files.json.patches   = SetJSONFile $GameFiles.patches }                         else { $Files.json.patches   = $null }
    if (TestFile ($GameFiles.languages + "\Languages.json"))                       { $Files.json.languages = SetJSONFile ($GameFiles.languages + "\Languages.json") } else { $Files.json.languages = $null }
    if (TestFile ($Paths.Models        + "\Models.json"))                          { $Files.json.models    = SetJSONFile ($Paths.Models        + "\Models.json")    } else { $Files.json.models    = $null }
    if (TestFile ($Paths.shared        + "\Sequences.json"))                       { $Files.json.sequences = SetJSONFile ($Paths.shared        + "\Sequences.json") } else { $Files.json.sequences = $null }
    if (TestFile ($GameFiles.base      + "\Music.json"))                           { $Files.json.music     = SetJSONFile ($GameFiles.base      + "\Music.json")     } else { $Files.json.music     = $null }
    if (TestFile ($GameFiles.base      + "\Items.json"))                           { $Files.json.items     = SetJSONFile ($GameFiles.base      + "\Items.json")     } else { $Files.json.items     = $null }
    if (TestFile ($GameFiles.base      + "\Moves.json"))                           { $Files.json.moves     = SetJSONFile ($GameFiles.base      + "\Moves.json")     } else { $Files.json.moves     = $null }
    if (TestFile ($GameFiles.base      + "\Blocks.json"))                          { $Files.json.blocks    = SetJSONFile ($GameFiles.base      + "\Blocks.json")    } else { $Files.json.blocks    = $null }
    if (TestFile ($GameFiles.base      + "\Enemies.json"))                         { $Files.json.enemies   = SetJSONFile ($GameFiles.base      + "\Enemies.json")   } else { $Files.json.enemies   = $null }

    SetCreditsSections
    ChangePatchPanel
    SetModeLabel

}



#==============================================================================================================================================================================================
function SetCreditsSections() {

    if (!(IsSet $CreditsDialog)) { return }

     # Info
     if (TestFile $GameFiles.info)   { AddTextFileToTextbox -TextBox $Credits.Sections[0] -File $GameFiles.info }
     else                            { AddTextFileToTextbox -TextBox $Credits.Sections[0] -File $null }

    # Credits
    if (TestFile $Files.Text.credits) {
        if ($GameType.mode -ne "Free") {
            AddTextFileToTextbox -TextBox $Credits.Sections[1] -File $Files.Text.credits -MainCredits
            AddTextFileToTextbox -TextBox $Credits.Sections[1] -File $Files.Text.credits -GameCredits -Add
        }
        else { AddTextFileToTextbox -TextBox $Credits.Sections[1] -File $Files.Text.credits -MainCredits }
    }

}



#==============================================================================================================================================================================================
function ChangeGameRev() {
    
    if (!(IsSet $GameType)) { return }

    $global:GameRev = $GameType.version[0]

    if (IsSet $GamePatch.version) {
        foreach ($version in $GameType.version) {
            if ($version.name -eq $GamePatch.version) {
                $global:GameRev = $version
                break
            }
        }
    }

    if (IsSet $GameRev.Name)   { $CurrentGame.Rev.Text = $GameRev.Name }
    else                       { $CurrentGame.Rev.Text = ""            }

}



#==============================================================================================================================================================================================
function ChangePatch() {
    
    EnableGUI $False
    $lastMessage = $StatusLabel.Text
    UpdateStatusLabel "Changing patch..."

    if (IsSet $GamePatch.script) { if (Get-Module -Name $GamePatch.script) { Remove-Module -Name $GamePatch.script } }
    
    foreach ($item in $Files.json.patches) {
        if ($item.title -eq $Patches.Type.Text -and ( ($IsWiiVC -and $item.console -eq "Wii VC") -or (!$IsWiiVC -and $item.console -eq "Native") -or ($item.console -eq "Both") -or !(IsSet $item.console) ) ) {
                $global:GamePatch = $item
                $PatchToolTip.SetToolTip($Patches.Button, ([string]::Format($item.tooltip, [Environment]::NewLine)))
                GetHeader
                GetRegion
                ResetReduxSettings

                if ($GameSettings -ne $null) {
                    Out-IniFile -FilePath $GameSettingsFile -InputObject $GameSettings | Out-Null
                    $global:GameSettings = $global:GameSettingsFile = $null
                }

                DisablePatches
                SetVCRemap
                ChangeGameRev

                if (IsSet $GamePatch.script) {
                    $script = $Paths.Scripts + "\Options\" + $GamePatch.script + ".psm1"
                    if (TestFile $script) {
                        $global:GameSettingsFile = GetGameSettingsFile
                        $global:GameSettings     = GetSettings $GameSettingsFile
                        Import-Module -Name $script -Global
                        if (GetCommand "CreateOptions") { CreateOptions }
                    }
                }

                break
        }
    }

    EnableGUI $True
    UpdateStatusLabel "Ready to patch..." -NoConsole

}



#==============================================================================================================================================================================================
function SetVCPanel() {
    
    # Reset VC panel visibility
    foreach ($item in $VC.Group.Controls) { EnableElem -Elem $item -Active $False -Hide }
    EnableElem -Elem @($VC.ActionsLabel, $VC.ExtractROMButton) -Active $True -Hide
    
    # Enable VC panel visiblity
    if ($IsWiiVC) {
        if ($GameConsole.t64 -eq 1)                                                { EnableElem -Elem @($VC.OptionsLabel, $VC.RemoveT64,     $VC.RemoveT64Label)                              -Active $True -Hide }
        if ($GameConsole.expand_memory -eq 1 -and $GameType.expansion_pak -ne 0)   { EnableElem -Elem @($VC.OptionsLabel, $VC.ExpandMemory,  $VC.ExpandMemoryLabel)                           -Active $True -Hide }
        if ($GameConsole.remove_filter -eq 1 -and $GameType.filter        -ne 0)   { EnableElem -Elem @($VC.OptionsLabel, $VC.RemoveFilter,  $VC.RemoveFilterLabel)                           -Active $True -Hide }
        if (IsSet $Files.json.controls)                                            { EnableElem -Elem @($VC.OptionsLabel, $VC.RemapControls, $VC.RemapControlsLabel, $VC.RemapControlsButton) -Active $True -Hide }
        $VC.RemapControlsButton.Enabled = $VC.RemapControls.checked -and $VC.RemapControls.Active
    }

}



#==============================================================================================================================================================================================
function UpdateStatusLabel([string]$Text, [switch]$Main, [switch]$Editor, [switch]$NoConsole) {
    
    if (!$NoConsole) { WriteToConsole $Text }

    if (!$Editor) {
        $StatusLabel.Text = $Text
        $StatusLabel.Refresh()
    }
    elseif (!$Main -and (IsSet $TextEditor.StatusLabel) ) {
        $TextEditor.StatusLabel.Text = $Text
        $TextEditor.StatusLabel.Refresh()
    }
    elseif (!$Main -and (IsSet $SceneEditor.StatusLabel) ) {
        $SceneEditor.StatusLabel.Text = $Text
        $SceneEditor.StatusLabel.Refresh()
    }

}



#==============================================================================================================================================================================================
function WriteToConsole([string]$Text) {
    
    if ($ExternalScript) { Write-Host $Text }
    if ($Settings.Debug.Logging -eq $True  -and !$ExternalScript) {
        if (!(TestFile -Path $Paths.Logs -Container)) { CreatePath $Paths.Logs }
        Add-Content -LiteralPath ($Paths.Logs + "\" + $TranscriptTime + ".log") -Value $Text
    }
    elseif ($Settings.Debug.Logging -eq $False -and !$ExternalScript) { $global:ConsoleHistory += $Text }

}



#==============================================================================================================================================================================================
function SetModeLabel() {
	
    $CurrentModeLabel.Text = "Current  Mode  :  " + $GameType.mode
    if ($IsWiiVC) { $CurrentModeLabel.Text += "  (Wii  VC)" } else { $CurrentModeLabel.Text += "  (" + $GameConsole.Mode + ")" }
    $CurrentModeLabel.Location = New-Object System.Drawing.Size(([Math]::Floor($MainDialog.Width / 2) - [Math]::Floor($CurrentModeLabel.Width / 2)), 50)
    $CurrentModeLabel.Refresh()

}



#==================================================================================================================================================================================================================================================================
function EnablePatchButtons([boolean]$Enable) {
    
    # Set the status that we are ready to roll... Or not...
    if ($Enable)        { UpdateStatusLabel "Ready to patch!" }
    else                { UpdateStatusLabel "Select your ROM or Wii VC WAD file to continue." }

    # Enable patcher buttons
    $Patches.Button.Enabled = $CustomHeader.Panel.Enabled = $VC.ExtractROMButton.Enabled = $Enable

}



#==================================================================================================================================================================================================================================================================
function GamePath_Finish([object]$TextBox, [string]$Path) {
    
    # Set the "GamePath" variable that tracks the path
    $global:GamePath = (Get-Item -LiteralPath $Path)

    # Update the textbox with the current game
    $TextBox.Text = $GamePath

    # Check if the game is a WAD
    $DroppedExtn = $GamePath.Extension

    $changed = $false
    if ( ($DroppedExtn -eq '.wad') -and !$IsWiiVC)              { $changed = $true; SetWiiVCMode $True  }
    elseif ( ($DroppedExtn -ne '.wad') -and $IsWiiVC)           { $changed = $true; SetWiiVCMode $False }
    elseif ( ($DroppedExtn -ne '.wad') -and !$GameIsSelected)   { $changed = $true; SetWiiVCMode $False }
    $global:GameIsSelected = $True

    if ($IsWiiVC)   { WriteToConsole ("WAD Path:       " + $GamePath) }
    else            { WriteToConsole ("ROM Path:       " + $GamePath) }
    
    CalculateHashSum

    if (!$changed) { return }

    $InputPaths.ClearGameButton.Enabled = $True
    $InputPaths.PatchPanel.Visible      = $True
    $CustomHeader.EnableHeader.checked -or $CustomHeader.EnableRegion.checked

    ChangeGamesList
    SetMainScreenSize

}



#==================================================================================================================================================================================================================================================================
function CalculateHashSum() {
    
    if (!(IsSet $CreditsDialog) -or $GamePath -eq $null) { return }

    # Calculate checksum if Native Mode
    if (!$IsWiiVC) {
        # Update hash
        $VerificationInfo.HashField.Text = (Get-FileHash -Algorithm MD5 -LiteralPath $GamePath).Hash

        # Verify ROM
        $VerificationInfo.GameField.Text = $VerificationInfo.RegionField.Text = $VerificationInfo.RevField.Text = $VerificationInfo.SupportField.Text = "No Valid ROM Selected"
        foreach ($item in $Files.json.games) {
            for ($i=0; $i -lt $item.version.Count; $i++) {
                if ($VerificationInfo.HashField.Text -eq $item.version[$i].hash) {
                    $VerificationInfo.GameField.Text   = $item.title
                    $VerificationInfo.RegionField.Text = $item.version[$i].region
                    $VerificationInfo.RevField.Text    = $item.version[$i].rev
                    if ($i -eq 0 -or (IsSet $item.version[$i].downgrade) -or (IsSet $item.version[$i].upgrade) -or $item.version[$i].supported -eq 1)   { $VerificationInfo.SupportField.Text = "This ROM is supported"                                                    }
                    else                                                                                                                                { $VerificationInfo.SupportField.Text = "This ROM is NOT supported! Please use a different ROM that is supported!" }
                    break
                }
            }
        }
    }
    else {
        $VerificationInfo.HashField.Text    = ""
        $VerificationInfo.GameField.Text    = "No validation for WAD files"
        $VerificationInfo.RegionField.Text  = "No validation for WAD files"
        $VerificationInfo.RevField.Text     = "No validation for WAD files"
        $VerificationInfo.SupportField.Text = "No validation for WAD files"
    }

}



#==================================================================================================================================================================================================================================================================
function InjectPath_Finish([object]$TextBox, [string]$Path) {
    
    # Set the "InjectPath" variable that tracks the path
    $global:InjectPath = $Path
    WriteToConsole ("Inject Path:   " + $InjectPath)

    # Update the textbox to the current injection ROM
    $TextBox.Text = $InjectPath

    $InputPaths.ApplyInjectButton.Enabled = $True

}



#==================================================================================================================================================================================================================================================================
function PatchPath_Finish([object]$TextBox, [string]$Path) {
    
    # Set the "PatchPath" variable that tracks the path
    $global:PatchPath = $Path
    WriteToConsole ("Patch Path:    " + $PatchPath)

    # Update the textbox to the current patch
    $TextBox.Text = $PatchPath

    $InputPaths.ApplyPatchButton.Enabled = $True

}



#==============================================================================================================================================================================================
function IsDefault([object]$Elem, $Value, [switch]$Not) {
    
    if (!(IsSet $Elem)) { return $False }
    if (!(IsSet $Value)) {
        if ($Elem.GetType() -eq [System.Windows.Forms.TrackBar])   { $Value = $Elem.Value }
        else                                                       { $Value = $Elem.Text  }
    }

    if ($Elem.GetType() -eq [System.Windows.Forms.ComboBox])   { $Default = $Elem.Items[$Elem.Default] }
    else                                                       { $Default = $Elem.Default              }

    if (!$Elem.Active)         { return $False }
    if ($Default -eq $Value)   { return !$Not  }
    if ($Default -ne $Value)   { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsChecked([object]$Elem, [switch]$Not) {
    
    if (!(IsSet $Elem))   { return $False }
    if (!$Elem.Active)    { return $False }
    if ($Elem.Checked)    { return !$Not  }
    if (!$Elem.Checked)   { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsRevert([object]$Elem) {
    
    if (!(IsSet $Elem)) { return $True }
    if ($Elem.GetType() -eq [System.Windows.Forms.CheckBox]) {
        return !( (IsChecked $Elem) -and $Patches.Options.Checked)
    }
    elseif ($Elem.GetType() -eq [System.Windows.Forms.ComboBox]) {
        return !( (IsDefault $Elem -Not) -and $Patches.Options.Checked)
    }

}



#==============================================================================================================================================================================================
function IsLanguage([object]$Elem, [int]$Lang=0, [switch]$Not) {
    
    if (IsSet $Redux.Language) {
        if (!$Redux.Language[$Lang].Checked)   { return $False }
    }
    if (IsChecked $Elem)                       { return !$Not  }
    if (IsChecked $Elem -Not)                  { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsText([object]$Elem, [string]$Compare, [switch]$Active, [switch]$Not) {
    
    if (!(IsSet $Elem))                 { return $False }
    $Text = $Elem.Text.replace(" (default)", "")
    if ($Active -and !$Elem.Visible)    { return $False }
    if (!$Active -and !$Elem.Enabled)   { return $False }
    if ($Text -eq $Compare)             { return !$Not  }
    if ($Text -ne $Compare)             { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsLangText([object]$Elem, [string]$Compare, [int]$Lang=0, [switch]$Not) {
    
    if (IsSet $Redux.Language) {
        if (!$Redux.Language[$Lang].Checked)         { return $False }
    }
    if (IsText -Elem $Elem -Compare $Compare)        { return !$Not  }
    if (IsText -Elem $Elem -Compare $Compare -Not)   { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsValue([object]$Elem, [int16]$Value, [switch]$Active, [switch]$Not) {
    
    if (!(IsSet $Value))                 { $Value = $Elem.Default }
    if ($Active -and !$Elem.Visible)     { return $False }
    if (!$Active -and !$Elem.Enabled)    { return $False }
    if ($Elem.GetType().name -eq "TextBox") {
        if ([int16]$Elem.text  -eq $Value)   { return !$Not }
        if ([int16]$Elem.text  -ne $Value)   { return  $Not }
    }
    else {
        if ([int16]$Elem.value -eq $Value)   { return !$Not }
        if ([int16]$Elem.value -ne $Value)   { return  $Not }
    }
    return $False

}



#==============================================================================================================================================================================================
function IsIndex([object]$Elem, [int16]$Index=1, [string]$Text, [switch]$Active, [switch]$Not) {
    
    if (!(IsSet $Elem))                 { return $False }
    if ( $Active -and !$Elem.Visible)   { return $False }
    if (!$Active -and !$Elem.Enabled)   { return $False }
    if ($Index -lt 1) { $Index = 1 }

    if (IsSet $Text) {
        if ($Elem.Text.replace(" (default)", "") -eq $Text)   { return !$Not  }
        if ($Elem.Text.replace(" (default)", "") -ne $Text)   { return  $Not  }
    }

    if ($Elem.SelectedIndex -eq ($Index-1))   { return !$Not  }
    if ($Elem.SelectedIndex -ne ($Index-1))   { return  $Not  }

    return $False

}



#==============================================================================================================================================================================================
function IsLangIndex([object]$Elem, [int16]$Index=1, [int]$Lang=0, [switch]$Not) {
    
    if (!$Redux.Language[$Lang].Checked)          { return $False }
    if (IsIndex -Elem $Elem -Index $Index)        { return !$Not  }
    if (IsIndex -Elem $Elem -Index $Index -Not)   { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsColor([System.Windows.Forms.ColorDialog]$Elem, [string]$Color, [switch]$Not) {
    
    if (!(IsSet $Elem))         { return $False }
    if (!$Elem.Button.Active)   { return $False }
    $c = (Get8Bit $Elem.Color.R) + (Get8Bit $Elem.Color.G) + (Get8Bit $Elem.Color.B)
    if ($c -eq $Color)          { return !$Not  }
    if ($c -ne $Color)          { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsDefaultColor([System.Windows.Forms.ColorDialog]$Elem, [switch]$Not) {
    
    if (!(IsSet $Elem))         { return $False }
    if (!$Elem.Button.Active)   { return $False }
    $c = (Get8Bit $Elem.Color.R) + (Get8Bit $Elem.Color.G) + (Get8Bit $Elem.Color.B)
    if ($c -eq $Elem.Default)   { return !$Not  }
    if ($c -ne $Elem.Default)   { return  $Not  }
    return $False

}



#==============================================================================================================================================================================================
function IsSet([object]$Elem, [int16]$Min, [int16]$Max, [int16]$MinLength, [int16]$MaxLength, [switch]$HasInt) {

    if ($Elem -eq $null -or $Elem -eq "")                                               { return $False }
    if ($HasInt) {
        if ($Elem -NotMatch "^\d+$" )                                                   { return $False }
        if ($Min -ne $null -and $Min -ne "" -and [int16]$Elem -lt $Min)                 { return $False }
        if ($Max -ne $null -and $Max -ne "" -and [int16]$Elem -gt $Max)                 { return $False }
    }
    if ($MinLength -ne $null -and $MinLength -ne "" -and $Elem.Length -lt $MinLength)   { return $False }
    if ($MaxLength -ne $null -and $MaxLength -ne "" -and $Elem.Length -gt $MaxLength)   { return $False }

    return $True

}



#==============================================================================================================================================================================================
function BoxCheck([object]$Elem)     { if ($Elem -ne $null) { $Elem.Checked = $True          } }
function BoxUncheck([object]$Elem)   { if ($Elem -ne $null) { $Elem.Checked = $False         } }
function BoxToggle([object]$Elem)    { if ($Elem -ne $null) { $Elem.Checked = !$Elem.Checked } }



#==============================================================================================================================================================================================
function CompareArray([array]$Elem, [array]$Compare) {
    
    if ($Elem.length -eq 0 -or $Compare.length -eq 0)   { return $False }
    if ($Elem.length -ne $Compare.length)               { return }

    foreach ($i in 0..($Elem.length-1)) {
        if ($Elem[$i] -ne $Compare[$i]) { return $False }
    }

    return $True

}



#==============================================================================================================================================================================================
function AddTextFileToTextbox([object]$TextBox, [string]$File, [switch]$Add, [switch]$GameCredits, [switch]$MainCredits) {
    
    if (!(IsSet $File) -or !(TestFile $File)) {
        $TextBox.Text = ""
        return
    }
    
    if ($GameCredits -or $MainCredits)   { $Start = $False }
    else                                 { $Start = $True }
    $content = (Get-Content $File -Raw)

    if ($GameCredits) {
        if (!(IsSet $GameType.mode)) { return }
        $match = "<<< " + $GameType.mode.ToUpper() + " >>>"
    }
    elseif ($MainCredits) { $match = "<<< PATCHER64+ TOOL >>>" }
    if ($GameCredits -or $MainCredits) {
        # Start
        $start = $content.indexOf($match)
        $content = $content.substring($start)

        # End
        $match = "======"
        $end = $content.indexOf($match)
        if ($end -gt 0) { $content = $content.substring(0, $end) }
    }
    if ($GameCredits) {
        if ( ([int]$content[$content.length-2]) -eq 13 -and ([int]$content[$content.length-1]) -eq 10) {
            if ( ([int]$content[$content.length-4]) -eq 13 -and ([int]$content[$content.length-3]) -eq 10) {
                if ( ([int]$content[$content.length-6]) -eq 13 -and ([int]$content[$content.length-5]) -eq 10) {
                    if ( ([int]$content[$content.length-8]) -eq 13 -and ([int]$content[$content.length-7]) -eq 10) {
                        $content = $content.substring(0, $content.length-8)
                    }
                }
            }
        }
    }

    $content = [string]::Format($content, [Environment]::NewLine)
    if ($Add) { $TextBox.Text += $content }
    else      { $TextBox.Text  = $content }

}



#==============================================================================================================================================================================================
function GetFilePaths() {
    
    if (IsSet $Settings["Core"][$InputPaths.GameTextBox.Name]) {
        if (TestFile $Settings["Core"][$InputPaths.GameTextBox.Name]) {
            GamePath_Finish $InputPaths.GameTextBox -VarName $InputPaths.GameTextBox.Name -Path $Settings["Core"][$InputPaths.GameTextBox.Name]
        }
        else { $InputPaths.GameTextBox.Text = "Select your ROM or Wii VC WAD file..." }
    }

    if (IsSet $Settings["Core"][$InputPaths.InjectTextBox.Name]) {
        if (TestFile $Settings["Core"][$InputPaths.InjectTextBox.Name]) {
            InjectPath_Finish $InputPaths.InjectTextBox -VarName $InputPaths.InjectTextBox.Name -Path $Settings["Core"][$InputPaths.InjectTextBox.Name]
        }
        else { $InputPaths.InjectTextBox.Text = "Select your ROM for injection..." }
    }

    if (IsSet $Settings["Core"][$InputPaths.PatchTextBox.Name]) {
        if (TestFile $Settings["Core"][$InputPaths.PatchTextBox.Name]) {	
            PatchPath_Finish $InputPaths.PatchTextBox -VarName $InputPaths.PatchTextBox.Name -Path $Settings["Core"][$InputPaths.PatchTextBox.Name]
        }
        else { $InputPaths.PatchTextBox.Text = "Select your custom patch file..." }
    }

}



#==============================================================================================================================================================================================
function GetHeader() {
    
    if (IsChecked $CustomHeader.EnableHeader) { return }

    # ROM Title
    if   ( (IsSet $GamePatch.redux.rom_title) -and (IsChecked $Patches.Redux) )    { $CustomHeader.ROMTitle.Text  = $GamePatch.redux.rom_title }
    elseif (IsSet $GamePatch.rom_title)                                            { $CustomHeader.ROMTitle.Text  = $GamePatch.rom_title       }
    elseif (IsSet $GameType.rom_title)                                             { $CustomHeader.ROMTitle.Text  = $GameType.rom_title        }
    else                                                                           { $CustomHeader.ROMTitle.Text  = ""                         }

    # ROM GameID
    if   ( (IsSet $GamePatch.redux.rom_gameID) -and (IsChecked $Patches.Redux) )   { $CustomHeader.ROMGameID.Text = $GamePatch.redux.rom_gameID }
    elseif (IsSet $GamePatch.rom_gameID)                                           { $CustomHeader.ROMGameID.Text = $GamePatch.rom_gameID       }
    elseif (IsSet $GameType.rom_gameID)                                            { $CustomHeader.ROMGameID.Text = $GameType.rom_gameID        }
    else                                                                           { $CustomHeader.ROMGameID.Text = ""                          }

    # VC Title
    if   ( (IsSet $GamePatch.redux.vc_title) -and (IsChecked $Patches.Redux) )     { $CustomHeader.VCTitle.Text   = $GamePatch.redux.vc_title }
    elseif (IsSet $GamePatch.vc_title)                                             { $CustomHeader.VCTitle.Text   = $GamePatch.vc_title       }
    elseif (IsSet $GameType.vc_title)                                              { $CustomHeader.VCTitle.Text   = $GameType.vc_title        }
    else                                                                           { $CustomHeader.VCTitle.Text   = ""                        }

    # VC GameID
    if   ( (IsSet $GamePatch.redux.vc_gameID) -and (IsChecked $Patches.Redux) )    { $CustomHeader.VCGameID.Text  = $GamePatch.redux.vc_gameID }
    elseif (IsSet $GamePatch.vc_gameID)                                            { $CustomHeader.VCGameID.Text  = $GamePatch.vc_gameID       }
    elseif (IsSet $GameType.vc_gameID)                                             { $CustomHeader.VCGameID.Text  = $GameType.vc_gameID        }
    else                                                                           { $CustomHeader.VCGameID.Text  = ""                         }
    
}



#==============================================================================================================================================================================================
function GetRegion() {
    
    if     (IsSet $GamePatch.rom_region)           { $CustomHeader.Region.SelectedIndex = $GamePatch.rom_region }
    elseif (IsSet $GameType.rom_region)            { $CustomHeader.Region.SelectedIndex = $GameType.rom_region }
    elseif (!$CustomHeader.EnableRegion.Checked)   { $CustomHeader.Region.SelectedIndex = 1 }

}



#==============================================================================================================================================================================================
function RestoreCustomHeader() {
    
    if (IsChecked $CustomHeader.EnableHeader) {
        if (IsSet $Settings["Core"]["CustomHeader.ROMTitle"])    { $CustomHeader.ROMTitle.Text  = $Settings["Core"]["CustomHeader.ROMTitle"]  }
        if (IsSet $Settings["Core"]["CustomHeader.ROMGameID"])   { $CustomHeader.ROMGameID.Text = $Settings["Core"]["CustomHeader.ROMGameID"] }
        if (IsSet $Settings["Core"]["CustomHeader.VCTitle"])     { $CustomHeader.VCTitle.Text   = $Settings["Core"]["CustomHeader.VCTitle"]   }
        if (IsSet $Settings["Core"]["CustomHeader.VCGameID"])    { $CustomHeader.VCGameID.Text  = $Settings["Core"]["CustomHeader.VCGameID"]  }
    }
    else { GetHeader }

    $CustomHeader.ROMTitle.Enabled = $CustomHeader.ROMGameID.Enabled = $CustomHeader.VCTitle.Enabled = $CustomHeader.VCGameID.Enabled = $CustomHeader.EnableHeader.Checked

}



#==============================================================================================================================================================================================
function RestoreCustomRegion() {

    if (IsChecked $CustomHeader.EnableRegion) {
        if (IsSet $Settings["Core"]["CustomHeader.Region"]) {
            $CustomHeader.Region.SelectedIndex = $Settings["Core"]["CustomHeader.Region"]
        }
    }
    else { GetRegion }

    $CustomHeader.Region.Enabled = $CustomHeader.EnableRegion.Checked

}



#==============================================================================================================================================================================================
function StrLike([string]$Str, [string]$Val, [switch]$Not) {
    
    if     (!$Not -and $str.ToLower() -like "*"    + $val.ToLower() + "*")   { return $True }
    elseif ( $Not -and $str.ToLower() -notlike "*" + $val.ToLower() + "*")   { return $True }
    return $False

}



#==============================================================================================================================================================================================
function StrStarts([string]$Str, [string]$Val, [switch]$Not) {
    
    if ($Str -eq $null -or $Str -eq "")                              { return $False }
    if     (!$Not -and  $Str.ToLower().StartsWith($Val.ToLower()))   { return $True }
    elseif ( $Not -and !$Str.ToLower().StartsWith($Val.ToLower()))   { return $True }
    return $False

}



#==============================================================================================================================================================================================
function EnableGUI([boolean]$Enable) {
    
    $InputPaths.GamePanel.Enabled = $InputPaths.InjectPanel.Enabled = $InputPaths.PatchPanel.Enabled = $CurrentGame.Panel.Enabled = $CustomHeader.Panel.Enabled = $Patches.Panel.Enabled = $VC.Panel.Enabled = $Enable
    SetModernVisualStyle $GeneralSettings.ModernStyle.Checked

    if ($IsWiiVC -and $GameConsole.support_vc -eq 0) { $Patches.Panel.Enabled = $VC.Panel.Enabled = $False }

    if (IsSet $TextEditor.Dialog)    { $TextEditor.Dialog.Enabled  = $Enable }
    if (IsSet $SceneEditor.Dialog)   { $SceneEditor.Dialog.Enabled = $Enable }

}



#==============================================================================================================================================================================================
function EnableForm([object]$Form, [boolean]$Enable, [switch]$Not) {
    
    if ($Form -eq $null) { return }

    if ($Not) { $Enable = !$Enable }
    if ($Form.Controls.length -eq $True) {
        foreach ($item in $Form.Controls) { $item.Enabled = $Enable }
    }
    else { $Form.Enabled = $Enable }

}



#==============================================================================================================================================================================================
function EnableElem([object]$Elem, [boolean]$Active=$True, [switch]$Hide) {
    
    if ($Elem -is [system.Array]) {
        foreach ($item in $Elem) {
            if ($item -eq $null) { return }
            $item.Enabled = $item.Active = $Active
            if ($Hide) { $item.Visible = $Active }
        }
    }
    else {
        if ($Elem -eq $null) { return }
        $Elem.Enabled = $Elem.Active = $Active
        if ($Hide) { $Elem.Visible = $Active }
    }

}



#==============================================================================================================================================================================================
function GetFileName([string]$Path, [string]$Description, [string[]]$FileNames) {
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $Path
    
    $FilterString = $Description + "|"
    foreach ($i in 0..($FileNames.Count-1)) {
        $FilterString += $FileNames[$i] + ';'
    }
    $FilterString += "|All Files|(*.*)"

    $OpenFileDialog.Filter = $FilterString.TrimEnd('|')
    $OpenFileDialog.ShowDialog() | Out-Null
    
    return $OpenFileDialog.FileName

}



#==============================================================================================================================================================================================
function RemovePath([string]$Path) {
    
    if ($Path -ne '') { # Make sure the path isn't null to avoid errors
        if (TestFile -Path $Path -Container) { # Check to see if the path exists
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null # Remove the path
        }
    }

}



#==============================================================================================================================================================================================
function CreatePath([string]$Path) {
    
    # Make sure the path is not null to avoid errors
    if ($Path -ne '') {
        if (!(TestFile -Path $Path -Container)) { New-Item -Path $Path -ItemType 'Directory' | Out-Null } # Check to see if the path does not exist, then create the path
    }

    # Return the path so it can be set to a variable when creating
    return $Path

}



#==============================================================================================================================================================================================
function RemoveFile([string]$Path) {
    
    if (TestFile $Path) { Remove-Item -LiteralPath $Path -Force }

}



#==============================================================================================================================================================================================
function TestFile([string]$Path, [switch]$Container) {
    
    if ($Path -eq "")   { return $False }
    if ($Container)     { return Test-Path -LiteralPath $Path -PathType Container }
    else                { return Test-Path -LiteralPath $Path -PathType Leaf }

}



#==============================================================================================================================================================================================
function CountFiles([string]$Path) {
    
    if (!(TestFile -Path $Path -Container)) { return -1 }
    return (Get-ChildItem -Recurse -File -LiteralPath $Path | Measure-Object).Count

}



#==============================================================================================================================================================================================
function CreateSubPath([string]$Path) {

    if (!(TestFile -Path $Path -Container)) {
        New-Item -Path $Path.substring(0, $Path.LastIndexOf('\')) -Name $Path.substring($Path.LastIndexOf('\') + 1) -ItemType Directory | Out-Null
    }

}



#==============================================================================================================================================================================================
function ShowPowerShellConsole([bool]$Show) {
    
    if (!$ExternalScript) { return }

    # Shows or hide the console window
    switch ($Show) {
        $True   { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 5) | Out-Null }
        $False  { [Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0) | Out-Null }
    }

}



#==================================================================================================================================================================================================================================================================
function TogglePowerShellOpenWithClicks([boolean]$Enable) {
    
    # Create a temporary folder to create the registry entry and and set the path to it
    RemovePath $Paths.Registry
    CreatePath $Paths.Registry
    $RegFile = $Paths.Registry + "\Double Click.reg"

    # Create the registry file.
    Add-Content -LiteralPath $RegFile -Value 'Windows Registry Editor Version 5.00'
    Add-Content -LiteralPath $RegFile -Value ''
    Add-Content -LiteralPath $RegFile -Value '[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Microsoft.PowerShellScript.1\Shell]'

    # Get the current state of the value in the registry.
    $PS_DC_State = (Get-ItemProperty -LiteralPath "HKLM:\Software\Classes\Microsoft.PowerShellScript.1\Shell").'(default)'

    # Check the current state and add the value to the registry
    switch ($PS_DC_State) {
        # A "0" means that a script won't automatically launch with PowerShell so change it to "Open"
        '0'     { Add-Content -LiteralPath $RegFile -Value '@="Open"' }
        default { Add-Content -LiteralPath $RegFile -Value '@="0"' }
    }

    # Execute the registry file.
    & regedit /s $RegFile

}


#==================================================================================================================================================================================================================================================================
function SetModernVisualStyle([boolean]$Enable) {

    if ($Enable) {
        [Windows.Forms.Application]::EnableVisualStyles()
        [Windows.Forms.Application]::VisualStyleState = [Windows.Forms.VisualStyles.VisualStyleState]::ClientAndNonClientAreasEnabled
    }
    else { [Windows.Forms.Application]::VisualStyleState = [Windows.Forms.VisualStyles.VisualStyleState]::NonClientAreaEnabled }

}



#==============================================================================================================================================================================================
function SetLogging([boolean]$Enable) {
    
    if (!$ExternalScript) {
        if ($Enable -and $ConsoleHistory.length -gt 0) {
            if (!(TestFile -Path $Paths.Logs -Container)) { CreatePath $Paths.Logs }
            foreach ($entry in $ConsoleHistory) { Add-Content -LiteralPath ($Paths.Logs + "\" + $TranscriptTime + ".log") -Value $entry }
            $global:ConsoleHistory = @()
        }
        return
    }

    if ($Enable) {
        $global:TranscriptTime = Get-Date -Format yyyy-MM-dd
        if (!(TestFile -Path $Paths.Logs -Container)) { CreatePath $Paths.Logs }

        $file = $Paths.Logs + "\" + $TranscriptTime + ".log"
        if (!(TestFile $file)) { Start-Transcript -LiteralPath $file }
        else {
            Add-Content -LiteralPath $file -Value "`n`n`n"
            Start-Transcript -LiteralPath $file -Append
        }
    }
    else {
        if ($TranscriptTime -ne $null) {
            Stop-Transcript
            $global:TranscriptTime = $null
        }
    }

}



#==================================================================================================================================================================================================================================================================
function SetBitmap($Path, $Box, [int]$Width, [int]$Height) {

    $imgObject = [Drawing.Image]::FromFile( ( Get-Item $Path ) )

    if (!(IsSet $Width))    { $Width  = $Box.Width }
    else                    { $Width  = (DPISize $Width) }
    if (!(IsSet $Height))   { $Height = $Box.Height }
    else                    { $Height = (DPISize $Height) }

    $imgBitmap = New-Object Drawing.Bitmap($imgObject, $Width, $Height)
    $imgObject.Dispose()
    $Box.Image = $imgBitmap

}



#==================================================================================================================================================================================================================================================================
function IsRestrictedFolder([string]$Path) {
    
    if ($Path -like $env:APPDATA)                  { return $False }
    if ($Path -eq    "C:\")                        { return $True }
    if ($Path -like "*C:\Users\*")                 { return $True }
    if ($Path -like "*C:\Program Files\*")         { return $True }
    if ($Path -like "*C:\Program Files (x86)\*")   { return $True }
    if ($Path -like "*C:\ProgramData\*")           { return $True }
    if ($Path -like "*C:\Windows\*")               { return $True }
    return $False

}



#==================================================================================================================================================================================================================================================================
function GetWindowsVersion() {

    # Get the current version of windows
    $getWinVersion = ([Environment]::OSVersion.Version).ToString().Split('.')
    $getWinVersion = $GetWinVersion[0] + '.' + $GetWinVersion[1]

    switch ($getWinVersion) { # Set the version of windows, shared versions for Vista/7 and for 8/8.1
        '6.0'   { return 7 } # Windows Vista
        '6.1'   { return 7 } # Windows 7
        '6.2'   { return 8 } # Windows 8
        '6.3'   { return 8 } # Windows 8.1
        '10.0'  {            # Windows 10 / 11
            $WinTitle = ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption).Split(' ') # Get the full name of the operating system and split on the spaces
            return [int]($WinTitle[2])                                                        # Get the version from the split string
        }
        default { return 50 }  # Any other future version
    }

}



#==================================================================================================================================================================================================================================================================
function StopJobs() {
    
    if ( (Get-Process "playsmf" -ea SilentlyContinue) -ne $null) { Stop-Process -Name "playsmf" }
    Get-Job | Stop-Job
    Get-Job | Remove-Job
    [System.GC]::Collect() | Out-Null

}



#==============================================================================================================================================================================================
function GetCommand([string]$Command) { return (Get-Command $Command -errorAction SilentlyContinue) }



#==============================================================================================================================================================================================

Export-ModuleMember -Function SetWiiVCMode
Export-ModuleMember -Function SetVCPanel
Export-ModuleMember -Function CreateToolTip
Export-ModuleMember -Function ChangeConsolesList
Export-ModuleMember -Function ChangeGamesList
Export-ModuleMember -Function SetMainScreenSize
Export-ModuleMember -Function ResetReduxSettings
Export-ModuleMember -Function SetVCRemap
Export-ModuleMember -Function ChangeGameMode
Export-ModuleMember -Function SetCreditsSections
Export-ModuleMember -Function ChangeGameRev
Export-ModuleMember -Function ChangePatch
Export-ModuleMember -Function UpdateStatusLabel
Export-ModuleMember -Function WriteToConsole
Export-ModuleMember -Function SetModeLabel
Export-ModuleMember -Function EnablePatchButtons

Export-ModuleMember -Function GamePath_Finish
Export-ModuleMember -Function CalculateHashSum
Export-ModuleMember -Function InjectPath_Finish
Export-ModuleMember -Function PatchPath_Finish

Export-ModuleMember -Function IsDefault
Export-ModuleMember -Function IsChecked
Export-ModuleMember -Function IsRevert
Export-ModuleMember -Function IsLanguage
Export-ModuleMember -Function IsText
Export-ModuleMember -Function IsLangText
Export-ModuleMember -Function IsValue
Export-ModuleMember -Function IsIndex
Export-ModuleMember -Function IsLangIndex
Export-ModuleMember -Function IsColor
Export-ModuleMember -Function IsDefaultColor
Export-ModuleMember -Function IsSet

Export-ModuleMember -Function BoxCheck
Export-ModuleMember -Function BoxUncheck
Export-ModuleMember -Function BoxToggle

Export-ModuleMember -Function CompareArray
Export-ModuleMember -Function AddTextFileToTextbox
Export-ModuleMember -Function StrLike
Export-ModuleMember -Function StrStarts
Export-ModuleMember -Function GetFilePaths

Export-ModuleMember -Function GetHeader
Export-ModuleMember -Function GetRegion
Export-ModuleMember -Function RestoreCustomHeader
Export-ModuleMember -Function RestoreCustomRegion

Export-ModuleMember -Function EnableGUI
Export-ModuleMember -Function EnableForm
Export-ModuleMember -Function EnableElem

Export-ModuleMember -Function GetFileName
Export-ModuleMember -Function RemoveFile
Export-ModuleMember -Function RemovePath
Export-ModuleMember -Function CreatePath
Export-ModuleMember -Function RemoveFile
Export-ModuleMember -Function TestFile
Export-ModuleMember -Function CountFiles
Export-ModuleMember -Function CreateSubPath

Export-ModuleMember -Function ShowPowerShellConsole
Export-ModuleMember -Function TogglePowerShellOpenWithClicks
Export-ModuleMember -Function SetModernVisualStyle
Export-ModuleMember -Function SetLogging
Export-ModuleMember -Function SetBitmap
Export-ModuleMember -Function IsRestrictedFolder
Export-ModuleMember -Function GetCommand
Export-ModuleMember -Function StopJobs
Export-ModuleMember -Function GetWindowsVersion