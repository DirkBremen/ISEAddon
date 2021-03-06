﻿if ($host.Name -ne 'Windows PowerShell ISE Host'){
    Write-Warning "This Module can be only run from within ISE"
    exit
}

#load libraries and functions
Add-Type -Path "$PSScriptRoot\resources\CommonMark.dll"
Add-Type -Path "$PSScriptRoot\resources\Strike.IE.dll"
Get-ChildItem $psscriptroot\functions\*.ps1 | ForEach-Object { 
	#write-host $_.FullName
	. $_.FullName 
}

#menu items
#compiled functions
#region
Add-Type -Path $PSScriptRoot\resources\ISEUtils.dll
if (-not (Test-Path "C:\Program Files (x86)\Reference Assemblies\Microsoft\FSharp\.NETCore\3.3.1.0\FSharp.Core.dll")){
	$a = new-object -comobject wscript.shell
	$answer = $a.popup("The File tree add-on requires the FShare.Core assembly to be installed on your machine do you want to do download and install it now?", `
	0,"Download",4)
	If ($answer -eq 6) {
		 $webclient = New-Object Net.WebClient
		 $url = 'http://download.microsoft.com/download/E/A/3/EA38D9B8-E00F-433F-AAB5-9CDA28BA5E7D/FSharp_Bundle.exe'
         $path = "$env:TEMP\FSharp_Bundle.exe"
		 $webclient.DownloadFile($url, $path)
         $arguments = '/install /quiet'
         Start-Process $path $arguments -Wait
	} else {
		Write-Warning "In order to use the File tree you need manually download and install the FSharp.Core tools via https://www.microsoft.com/en-us/download/details.aspx?id=44011"
	}
}
Import-Module $PSScriptRoot\resources\DirectorySearcher.dll

$newISEMenu = {
    #check if the AddOn is loaded if yes unload and re-load it
    $currentNameIndex = -1
    $name = 'New-ISEMenu'
    $currentNames = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Name
    if ($currentNames){
        $currentNameIndex = $currentNames.IndexOf($name)
        if ($currentNameIndex -ne -1){
            $psISE.CurrentPowerShellTab.VerticalAddOnTools.RemoveAt($currentNameIndex)
        }
    }
    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add($name,[ISEUtils.NewISEMenu],$true)
    ($psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object {$_.Name -eq $name}).IsVisible=$true
}
$newISESnippet = {
    #check if the AddOn is loaded if yes unload and re-load it
    $currentNameIndex = -1
    $name = 'New-ISESnippet'
    $currentNames = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Name
    if ($currentNames){
        $currentNameIndex = $currentNames.IndexOf($name)
        if ($currentNameIndex -ne -1){
            $psISE.CurrentPowerShellTab.VerticalAddOnTools.RemoveAt($currentNameIndex)
        }
    }
    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add($name,[ISEUtils.NewISESnippet],$true)
    ($psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object {$_.Name -eq $name}).IsVisible=$true
}
$fileTree = {
    #check if the AddOn is loaded if yes unload and re-load it
    $currentNameIndex = -1
    $name = 'FileTree'
    $currentNames = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Name
    if ($currentNames){
        $currentNameIndex = $currentNames.IndexOf($name)
        if ($currentNameIndex -ne -1){
            $psISE.CurrentPowerShellTab.VerticalAddOnTools.RemoveAt($currentNameIndex)
        }
    }
    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add($name,[ISEUtils.FileTree],$true)
    ($psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object {$_.Name -eq $name}).IsVisible=$true
}
$addScriptHelp = {
    #check if the AddOn is loaded if yes unload and re-load it
    $currentNameIndex = -1
    $name = 'Add-ScriptHelp'
    $currentNames = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Name
    if ($currentNames){
        $currentNameIndex = $currentNames.IndexOf($name)
        if ($currentNameIndex -ne -1){
            $psISE.CurrentPowerShellTab.VerticalAddOnTools.RemoveAt($currentNameIndex)
        }
    }
    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add($name,[ISEUtils.AddScriptHelp],$true)
    ($psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object {$_.Name -eq $name}).IsVisible=$true
}

$spellCheck = {
    #check if the AddOn is loaded if yes unload and re-load it
    $currentNameIndex = -1
    $name = 'SpellCheck'
    $currentNames = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Name
    if ($currentNames){
        $currentNameIndex = $currentNames.IndexOf($name)
        if ($currentNameIndex -ne -1){
            $psISE.CurrentPowerShellTab.VerticalAddOnTools.RemoveAt($currentNameIndex)
        }
    }
    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add($name,[ISEUtils.SpellCheck],$true)
    ($psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object {$_.Name -eq $name}).IsVisible=$true
}
$markDown = {
    #check if the AddOn is loaded if yes unload and re-load it
    $currentNameIndex = -1
    $name = 'Markdown Editor'
    $currentNames = $psISE.CurrentPowerShellTab.VerticalAddOnTools.Name
    if ($currentNames){
        $currentNameIndex = $currentNames.IndexOf($name)
        if ($currentNameIndex -ne -1){
            $psISE.CurrentPowerShellTab.VerticalAddOnTools.RemoveAt($currentNameIndex)
        }
    }
    $psISE.CurrentPowerShellTab.VerticalAddOnTools.Add($name,[ISEUtils.MarkDownEditor],$true)
    ($psISE.CurrentPowerShellTab.VerticalAddOnTools | Where-Object {$_.Name -eq $name}).IsVisible=$true
}


#endregion

#inline functions 
#region

###ISE Session###
<#
    Modified version of ISE Session Tools Module 1.0
    
    Oisin Grehan (MVP)    
    http://www.nivot.org/
#>
#region
$SCRIPT:defaultSessionFile = "$(Split-Path $profile)\psISE.session.clixml"


$exportISESession = {
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.Title = "Save PS session file"
    $SaveFileDialog.InitialDirectory = (Split-Path $profile)
    $SaveFileDialog.Filter = "All files (PowerShell session file)| *.session.clixml"
    if ($SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        $sessionFile = $SaveFileDialog.FileName        $psise.CurrentPowerShellTab.files | Where-Object { -not $_.IsUntitled } | ForEach-Object {
            $_.save(); $_ } | Export-Clixml -Force $sessionFile
    } 
}

$ImportISESession = {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Open PS session file"
    $openFileDialog.InitialDirectory = (Split-Path $profile)
    $openFileDialog.Filter = "All files (PowerShell session file)| *.session.clixml"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        $sesionFile = $openFileDialog.FileName
        import-clixml $sessionFile | ForEach-Object {
            try {
                $psise.CurrentPowerShellTab.files.Add($_.fullpath)
            } catch { write-error $_ }
        }
    }
}

function Edit-ISETemplate{
    $ISETemplatePath = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\ISETemplate.ps1"
    if (!(Test-Path $ISETemplatePath)){
        New-Item $ISETemplatePath -ItemType File
    }
    psedit "$ISETemplatePath"
}




$MessageData = New-Object PSObject -Property @{defaultSessionFile = $defaultSessionFile}
Register-ObjectEvent $psise.CurrentPowerShellTab.Files CollectionChanged -Action {
    # files collection
    try {
        $sender | Where-Object {-not $_.IsUntitled} | ForEach-Object { $_.save(); $_ } | Export-Clixml -Force $event.MessageData.defaultSessionFile
        #default template
        $ISETemplate = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\ISETemplate.ps1"
	    if (Test-Path $ISETemplate){
            $sender | 
                Where-Object {$_.IsUntitled -and $_.Editor.Text.Length -eq 0 } | 
		        ForEach-Object { 
                    $_.Editor.Text = Get-Content $ISETemplate -Raw
                }
        }
    } 
    catch {
        # convert terminating errors to non-terminating
        write-error $_
    }
} -sourceidentifier AutoSaveSession -MessageData $MessageData > $null


if ((test-path $defaultSessionFile)) {      
    $files = Import-Clixml $defaultSessionFile    
    # only load if we've got something to load       
    if ($files.count -gt 0) {
        # just show first two of the last files in the session as a reminder
        $hint = ($files|Select-Object -first 2 -expand displayname) -join ","
            
        # default to YES
        if ($host.ui.PromptForChoice("Session Restore",
            ("Load last session of {0} file(s) into current tab?`n`nHint: {1}, ..." -f $files.count, $hint),
            [Management.Automation.Host.ChoiceDescription[]]@("&Yes", "&No"), 0) -eq 0) {
            Import-CliXML $defaultSessionFile | ForEach-Object {
                try {
                    $psise.CurrentPowerShellTab.files.Add($_.fullpath)
                } catch { write-error $_ }
            }
        }
    }
}

#endregion
$openScriptFolder = { Invoke-Item (Split-Path $psISE.CurrentFile.FullPath) }
$expandZenCode = {
    $currEditor = $psISE.CurrentFile.Editor
    $col = $currEditor.CaretLineText.Length - $currEditor.CaretLineText.TrimStart().Length
    $currEditor.SelectCaretLine()
    $line = $currEditor.CaretLineText.Trim()
    if ($line -like '*|*'){
        $sb = [scriptblock]::Create($line.Insert($line.IndexOf('|') + 2, "zenCode '") + "'")
        $txt = $sb.Invoke()
    }
    else{
        $txt = (Get-ZenCode $line)
    }

    $offset = " " * $col 
    $txt = $offset + (($txt-split "`r`n") -join "`r`n" + $offset)
    $currEditor.InsertText($txt)
}   
         
$runLine={
    ([scriptblock]::Create($psISE.CurrentFile.Editor.CaretLineText.Trim())).Invoke()
}

$splitSelectionByLastChar={
    $currEditor = $psISE.CurrentFile.Editor
    $selText = $currEditor.SelectedText
    $splitChar = $selText[-1]
    $currEditor.InsertText($selText.Remove($selText.LastIndexOf($splitChar),1).Split($splitChar) -join "`n")
}

$removeMenu = {
    $menu = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object DisplayName -eq 'ISEUtils'
    [void]$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Remove($menu)
    [Microsoft.VisualBasic.Interaction]::Msgbox('To completly remove ISEUtils you will also need to delete the entry from your profile',"Exclamation","")
}

#endregion

#add Menu items
Add-Type -AssemblyName Microsoft.VisualBasic
function Add-SubMenu($menu,$displayName,$code,$shortCut=$null){
    try{
        [void]$menu.Submenus.Add($displayName, $code,  $shortCut)
    }
    catch{
        $shortCut = [Microsoft.VisualBasic.Interaction]::InputBox("The shortcut ($shortCut) is already assigned. Please enter another combination.", "ShortCut", $shortCut)
        [void]$menu.Submenus.Add($displayName, $code,  $shortCut)
    }
}
        
$menu = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('ISEUtils', $null, $null)
Add-SubMenu $menu 'Expand-Alias' { Expand-Alias } 'CTRL+SHIFT+X'
Add-SubMenu $menu 'GoTo-Definition' { Find-Definition } 'F12'
Add-SubMenu $menu 'Expand ZenCode' $expandZenCode 'CTRL+SHIFT+J'
Add-SubMenu $menu 'Run Line' $runLine 'F2'
Add-SubMenu $menu 'Split Selection by last char' $splitSelectionByLastChar $null
Add-SubMenu $menu 'New-ISESnippet' $newISESnippet $null
Add-SubMenu $menu 'New-ISEMenu' $newISEMenu $null
Add-SubMenu $menu 'FileTree' $fileTree $null
Add-SubMenu $menu 'Add-ScriptHelp' $addScriptHelp $null
Add-SubMenu $menu 'Open-ScriptFolder' $openScriptFolder $null
Add-SubMenu $menu 'Export-ISESession' $exportISESession $null
Add-SubMenu $menu 'Import-ISESession' $importISESession $null
Add-SubMenu $menu 'Remove ISEUtils' $removeMenu $null
Add-SubMenu $menu 'Spell check selection' $spellCheck 'F7'
Add-SubMenu $menu 'Markdown Editor' $markDown
Add-SubMenu $menu 'Export-SelectionToRTF' ((Get-Command Export-SelectionToRTF).ScriptBlock) $null
Add-SubMenu $menu 'Export-SelectionToHTML' ((Get-Command Export-SelectionToHTML).ScriptBlock) $null

Export-ModuleMember -Function ("Find-Definition","Expand-Alias","Get-ZenCode","Get-ISEShortCuts","Get-ISESnippet","Remove-ISESnippet","Add-ISESnippet","Get-File","Export-SelectionToHTML","Export-SelectionToRTF", "Edit-ISETemplate") -Alias zenCode


$ExecutionContext.SessionState.Module.OnRemove = {
    Unregister-Event -SourceIdentifier AutoSaveession -ErrorAction silentlycontinue
    Get-EventSubScriber | Where-Object {$_.SourceIdentifier -like 'AutoComplete*'} | Unregister-Event
}
