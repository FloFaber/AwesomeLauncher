Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$global:arrowup = [char]0x2B61
$global:arrowdown = [char]0x2B63
#$DebugPreference = "Continue"
$DebugPreference = "SilentlyContinue"
$scriptpath=[Environment]::GetCommandLineArgs()[0]
Write-Debug $scriptpath
$global:version = (Get-Item "$scriptpath").VersionInfo.FileVersion
Write-Debug $global:version

try
{
  $global:settings = Get-Content $ENV:APPDATA\AwesomeLauncher.conf -ErrorAction stop | ConvertFrom-Json
}
catch
{
$standardsettings = @"
[
    {
        "ApplicationName":  "CMD",
        "ApplicationPath":  "C:\\Windows\\system32\\cmd.exe"
    },
    {
        "ApplicationName":  "Powershell",
        "ApplicationPath":  "C:\\Windows\\system32\\WindowsPowerShell\\v1.0\\powershell.exe"
    },
    {
        "ApplicationName":  "SCCM Management Console",
        "ApplicationPath":  "ii `'C:\\Program Files (x86)\\Microsoft Endpoint Manager\\AdminConsole\\bin\\Microsoft.ConfigurationManagement.exe`'
    },
    {
        "ApplicationName":  "AD Users and Computers",
        "ApplicationPath":  "cmd /c `'mmc C:\\Windows\\System32\\dsa.msc`'"
    }
]
"@
$standardsettings | Out-File $ENV:APPDATA\AwesomeLauncher.conf -Encoding utf8
$global:settings = Get-Content $ENV:APPDATA\AwesomeLauncher.conf | ConvertFrom-Json
}



function populateListView () {
    [CmdletBinding()]
    param (
       [Parameter(Mandatory=$false)][string] $sorting,
       [Parameter(Mandatory=$false)][string] $selectedcolumn
    )
    $listviewnames = @("Application", "Path")
    $ListView.BeginUpdate()
    $ListView.Clear()
      foreach($item in $listviewnames)
      {
        if($selectedcolumn -eq $item)
        {
        switch ($sorting){
          "asc"{
            $item = $global:arrowdown+" "+$item
          }
          "desc"{
            $item = $global:arrowup+" "+$item
          }
        }
      }
        [void]$ListView.Columns.Add($item)
      }
    $listview.Columns[0].Width = 150
    $listview.Columns[1].Width = 235
    $ListView.EndUpdate();
  }
  
function RunApplication()
{
    [CmdletBinding()]
    param (
       [Parameter(Mandatory=$false)]$path
    )
      if($path){
        Write-Debug "Path to application: $path"

        Write-Debug "Command: $command"
        if($global:credential)
        {
            Write-Debug "Credentials found for $($global:credential.UserName)"
            start-process  -ArgumentList @("$path") powershell -WorkingDirectory "C:\" -Credential $global:credential 
        }
        else{
            Write-Debug "No Credentials found, executing with logged in user"
            start-process  -ArgumentList @("$path") powershell -WorkingDirectory "C:\"
        }
      }
}

$AwesomeLauncher                 = New-Object system.Windows.Forms.Form
$AwesomeLauncher.ClientSize      = New-Object System.Drawing.Point(400,400)
$AwesomeLauncher.text            = "AwesomeLauncher"
$AwesomeLauncher.TopMost         = $false
$AwesomeLauncher.FormBorderStyle = "FixedDialog"

$ListView                       = New-Object system.Windows.Forms.ListView
$ListView.text                  = "listView"
$ListView.width                 = 393
$ListView.height                = 298
$ListView.location              = New-Object System.Drawing.Point(3,3)
$ListView.View = "Details"
$ListView.AutoSize = $true
$listView.MultiSelect = $true
$ListView.FullRowSelect = $true
$ListView.Scrollable = $true
populateListView

$ChangeUserButton                = New-Object system.Windows.Forms.Button
$ChangeUserButton.text           = "Change User"
$ChangeUserButton.width          = 109
$ChangeUserButton.height         = 58
$ChangeUserButton.location       = New-Object System.Drawing.Point(12,327)
$ChangeUserButton.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$LaunchButton                    = New-Object system.Windows.Forms.Button
$LaunchButton.text               = "Launch that stuff!"
$LaunchButton.width              = 109
$LaunchButton.height             = 58
$LaunchButton.location           = New-Object System.Drawing.Point(279,327)
$LaunchButton.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CurrentUserLabel                = New-Object system.Windows.Forms.Label
$CurrentUserLabel.text           = "Current User: $($env:USERNAME)"
$CurrentUserLabel.AutoSize       = $true
$CurrentUserLabel.width          = 25
$CurrentUserLabel.height         = 10
$CurrentUserLabel.location       = New-Object System.Drawing.Point(96,305)
$CurrentUserLabel.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ProgramButton                   = New-Object system.Windows.Forms.Button
$ProgramButton.text              = "Add / Remove Applications"
$ProgramButton.width             = 109
$ProgramButton.height            = 58
$ProgramButton.location          = New-Object System.Drawing.Point(149,327)
$ProgramButton.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Versionlabel                   = New-Object system.Windows.Forms.Label
$Versionlabel.text              = "Version: $global:version"
$Versionlabel.AutoSize          = $true
$Versionlabel.width             = 25
$Versionlabel.height            = 10
$Versionlabel.location          = New-Object System.Drawing.Point(310,385)
$Versionlabel.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

# GUI Events

$ChangeUserButton.Add_Click({
    $global:credential = Get-Credential -Message "domain\username"
    if($global:credential)
    {
        $CurrentUserLabel.text = "Current User: $($global:credential.UserName)"
    }

})

$listView.Add_DoubleClick({
  foreach($lvitem in $ListView.SelectedItems){
    $path = $lvitem.Subitems.Text[1]
    RunApplication($path)
  }
  })

$ProgramButton.Add_Click({
    Start-Process -ArgumentList "$ENV:APPDATA\AwesomeLauncher.conf" notepad -Wait
    populateListView
    Write-Debug "Updating settings!"
    $global:settings = Get-Content $ENV:APPDATA\AwesomeLauncher.conf | ConvertFrom-Json
    foreach($object in $global:settings)
{
    $itemname = New-Object System.Windows.Forms.ListViewItem ($object.ApplicationName)
    [void]$itemname.Subitems.Add($object.ApplicationPath)
    [void]$ListView.Items.Add($itemname)
}
})

$LaunchButton.Add_Click({
  foreach($lvitem in $ListView.SelectedItems){
    $path = $lvitem.Subitems.Text[1]
    RunApplication($path)
  }

})

$ListView.Add_KeyDown({
  if ($_.KeyCode -eq "Enter" -and $listview.SelectedItems.count -gt 0) {
    foreach($lvitem in $ListView.SelectedItems){
      $path = $lvitem.Subitems.Text[1]
      RunApplication($path)
    }
  }
})

  [void]$AwesomeLauncher.controls.AddRange(@($ListView,$ChangeUserButton,$LaunchButton,$CurrentUserLabel,$ProgramButton,$Versionlabel))

foreach($object in $global:settings)
{
    $itemname = New-Object System.Windows.Forms.ListViewItem ($object.ApplicationName)
    [void]$itemname.Subitems.Add($object.ApplicationPath)
    [void]$ListView.Items.Add($itemname)
}

[void]$AwesomeLauncher.ShowDialog()
if($global:credential)
{
    Remove-Variable -Scope Global credential
}
if(Test-Path "$ENV:APPDATA\AwesomeLauncher.cmd")
{
    rm $ENV:APPDATA\AwesomeLauncher.cmd
}
