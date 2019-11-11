param(
[string]$Server
) 

if (!$Server)
{
    $Server = $env:computername 
}

$DomainName = (Get-ADDomain).DNSRoot
$str_DC = "Get-ADDomainController -Filter * | Where-Object {`$_.Hostname -eq `"" + $Server  + "." + $DomainName + "`"}"

$DC = Get-ADDomainController -Filter * | Where-Object {$_.Hostname -eq "$Server.$DomainName"}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

if (!$DC)
{
    [System.Windows.Forms.MessageBox]::Show("Der lokale Computer ist kein Domain Controller! Bitte mit dem Parameter -Server einen Domain Controller (Kurzname) angeben!","Info",0,64)
    exit
}

function fill_listview ($listbox,$aduser,$g) {
    #$g Hilfs-Flag für AD-Gruppen    
    if ($g)
    {
        $adgroups = Get-ADPrincipalGroupMembership -Identity (Get-ADGroup -Filter * | Where-Object {$_.Name -eq $aduser}) -Server $Server | select name | sort name
    }
    else
    {
        $adgroups = Get-ADPrincipalGroupMembership -Identity $aduser -Server $Server | select name | sort name
    }
    
    $listbox.items.clear()
    foreach ($adgroup in $adgroups)
    {
        $listbox.items.add($adgroup.Name)
    }

    $listbox.Refresh()
}

function fill_listview_fileserver ($listbox,$aduser) {
    $connection = new-object System.Data.SqlClient.SQLConnection("Data Source=mssqllab\mssqllab01;Integrated Security=False;Initial Catalog=IDM-DB;User ID = ; Password = ")
    $sql = "SELECT Root,Path,IdentityReference,FileSystemRights FROM [IDM-DB].[dbo].[ACE] WHERE IdentityReference = 'INTERN\$aduser'"
    $cmd = new-object System.Data.SqlClient.SqlCommand($sql, $connection)

    $connection.Open()
    
    $datatb = New-Object System.Data.DataTable
    $datatb.Load($cmd.ExecuteReader())
    

    $connection.Close()

    $listbox.items.clear()
    
    foreach ($row in $datatb.Rows) 
    {
        $item = $row.Root
        $item = New-Object System.Windows.Forms.ListViewItem
        $item.SubItems.add($row.Root)
        $item.SubItems.add($row.Path)
        $item.SubItems.add($row.identityReference)
        $item.SubItems.add($row.FileSystemRights)
        $listbox.items.add($item)
    }

    $listbox.Refresh()

}

function fill_listview_member ($listbox,$aduser) {
    $adgroups = Get-ADGroupMember -Identity (Get-ADGroup -Filter * | Where-Object {$_.Name -eq $aduser}) -Server $Server | select name | sort name
    $listbox.items.clear()
    foreach ($adgroup in $adgroups)
    {
        $listbox.items.add($adgroup.Name)
    }

    $listbox.Refresh()
}

function get_group_info ($group,$desc,$member,$memberof) {
    $str_ret = "Information für Active Directory Gruppe " + $group + "`r`n"
    $str_ret += "`r`n" + "Description: " + $desc.text + "`r`n"
    $str_ret += "`r`n" + "Member: " + "`r`n"
    foreach ($item in $member.items)
    {
        $str_ret += $item.Text + "`r`n"
    }
    $str_ret += "`r`n" + "MemberOf: " + "`r`n"
    foreach ($item in $memberof.items)
    {
        $str_ret += $item.Text + "`r`n"
    }
    $str_ret
}


function form_info ($current_selection) {
    $Form_info                       = New-Object system.Windows.Forms.Form
    $Form_info.ClientSize                 = '800,800'
    $Form_info.text                       = "Form"
    $Form_info.TopMost                    = $false
    $Form_info.AutoSize = $true
    $Form_info.Text = $current_selection
        
    $listview_member = New-Object System.Windows.Forms.ListView
    $listview_member.Columns.add("Member",-2)
    $listview_member.View = "Details"
    $listview_member.GridLines = $True
    $listview_member.FullRowSelect = $true
    $listview_member.width              = 350
    $listview_member.height             = 500
    $listview_member.location           = New-Object System.Drawing.Point(12,50)
    $listview_member.Font = 'Microsoft Sans Serif,10'
    $listview_member.Scrollable = $true

    $listview_memberof = New-Object System.Windows.Forms.ListView
    $listview_memberof.Columns.add("Memberof",-2)
    $listview_memberof.View = "Details"
    $listview_memberof.GridLines = $True
    $listview_memberof.FullRowSelect = $true
    $listview_memberof.width              = 350
    $listview_memberof.height             = 500
    $listview_memberof.location           = New-Object System.Drawing.Point(412,50)
    $listview_memberof.Font = 'Microsoft Sans Serif,10'
    $listview_memberof.Scrollable = $true

    $listview_fileserver = New-Object System.Windows.Forms.ListView
    $listview_fileserver.Columns.add("#",-2)
    $listview_fileserver.Columns.add("Root",-1)
    $listview_fileserver.Columns.add("Path",-1)
    $listview_fileserver.Columns.add("IdentityReference",-1)
    $listview_fileserver.Columns.add("FileSystemRights",-1)
    $listview_fileserver.View = "Details"
    $listview_fileserver.GridLines = $True
    $listview_fileserver.FullRowSelect = $true
    $listview_fileserver.width              = 750
    $listview_fileserver.height             = 190
    $listview_fileserver.location           = New-Object System.Drawing.Point(12,600)
    $listview_fileserver.Font = 'Microsoft Sans Serif,10'
    $listview_fileserver.Scrollable = $true

    $label_desc = New-Object System.Windows.Forms.Label
    $label_desc.Width = 500
    $label_desc.Height = 30
    $label_desc.Location = New-Object System.Drawing.Point(12,10)
    $label_desc.Font = 'Microsoft Sans Serif,10,style=Bold'

    $ttip_clip = New-Object System.Windows.Forms.ToolTip
    $ttip_clip.ToolTipTitle = "CTRL + C"
    
    $ttip_save = New-Object System.Windows.Forms.ToolTip
    $ttip_save.ToolTipTitle = "Save"
    

    $btn_clipinfo                        = New-Object system.Windows.Forms.Button
    $btn_clipinfo.text                   = "C"
    $btn_clipinfo.width                  = 30
    $btn_clipinfo.height                 = 30
    $btn_clipinfo.location               = New-Object System.Drawing.Point(350,560)
    $btn_clipinfo.Font                   = 'Microsoft Sans Serif,10,style=Bold'

    $btn_saveinfo                        = New-Object system.Windows.Forms.Button
    $btn_saveinfo.text                   = "S"
    $btn_saveinfo.width                  = 30
    $btn_saveinfo.height                 = 30
    $btn_saveinfo.location               = New-Object System.Drawing.Point(390,560)
    $btn_saveinfo.Font                   = 'Microsoft Sans Serif,10,style=Bold'

    $ttip_clip.SetToolTip($btn_clipinfo,"Copy to Clipboard")
    $ttip_save.SetToolTip($btn_saveinfo,"Save to file")

    $btn_clipinfo.Add_Click(
        {
           $str_info = get_group_info $current_selection $label_desc $listview_member $listview_memberof 
           # doesn't work on all systems:
           #Set-Clipboard -Value $str_info
           $str_info | c:\windows\system32\clip.exe
        }    
    )

    $btn_saveinfo.Add_Click(
        {
           $str_info = get_group_info $current_selection $label_desc $listview_member $listview_memberof 
           $saveto = New-Object System.Windows.Forms.SaveFileDialog
           $saveto.InitialDirectory = "C:"
           $saveto.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*"
           $saveto.ShowDialog()
           if ($saveto.FileName)
           {
                $str_info | Out-File -FilePath $saveto.FileName -Append
           }
        }    
    )


    $str_desc = get-adgroup (Get-ADGroup -Filter * | Where-Object {$_.Name -eq $current_selection}) -Properties description | select description
    $label_desc.Text = $str_desc.description

    fill_listview_member $listview_member $current_selection
    fill_listview $listview_memberof $current_selection "g"
    fill_listview_fileserver $listview_fileserver $current_selection

    $Form_info.Controls.AddRange(@($listview_member,$listview_memberof,$listview_fileserver,$label_desc,$btn_clipinfo,$btn_saveinfo))
    $Form_info.ShowDialog()
}


function addadgroupmember($adgroups,$aduser) {
    foreach ($adgroup in $adgroups) {
        Add-ADGroupMember -Identity (Get-ADGroup -Filter * | Where-Object {$_.Name -eq $adgroup.text}) -Members $aduser -Server $Server
    }
}

function removeadgroupmember ($adgroups,$aduser) {
    foreach ($adgroup in $adgroups) {
        Remove-ADGroupMember -Identity (Get-ADGroup -Filter * | Where-Object {$_.Name -eq $adgroup.text}) -Members $aduser -Server $Server -Confirm:$false
    }
}

function comparegroups {
    foreach ($item_right in $listview_right.items)
    {
        $listview_right.items[$item_right.index].backcolor = [system.Drawing.Color]::White
    }
    if ($listview_left.items.count -gt 0 -and $listview_right.items.count -gt 0)
    {
        foreach ($item_left in $listview_left.items)
        {
            $listview_left.items[$item_left.index].backcolor = [system.Drawing.Color]::White
            foreach ($item_right in $listview_right.items)
            {
                if ($item_left.text -eq $item_right.text)
                {
                    $listview_left.items[$item_left.index].backcolor = [system.Drawing.Color]::Yellow
                    $listview_right.items[$item_right.index].backcolor = [system.Drawing.Color]::Yellow
                } 
            }
        }
    }
}

function setloadstate($text) {
    if ($text -eq "L") {
        $label_Loading.text = "L"
        $label_loading.forecolor = "#f70b0b"
        $label_loading.refresh()
    }
    if ($text -eq "D") {
        $label_Loading.text = "D"
        $label_Loading.forecolor = "#04bc08"
        $label_loading.Refresh()
    }
    if ($text -eq "E") {
        $label_Loading.text = ""
        $label_Loading.forecolor = ""
        $label_loading.refresh()
    }
}

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '1200,800'
$Form.text                       = "Form"
$Form.TopMost                    = $false
$form.AutoSize = $true

$ComboBox_left                   = New-Object system.Windows.Forms.ComboBox
$ComboBox_left.text              = ""
$ComboBox_left.width             = 550
$ComboBox_left.height            = 20
$ComboBox_left.location          = New-Object System.Drawing.Point(12,20)
$ComboBox_left.Font              = 'Microsoft Sans Serif,10'

$ComboBox_right                  = New-Object system.Windows.Forms.ComboBox
$ComboBox_right.text             = ""
$ComboBox_right.width            = 550
$ComboBox_right.height           = 20
$ComboBox_right.location         = New-Object System.Drawing.Point(612,20)
$ComboBox_right.Font             = 'Microsoft Sans Serif,10'

$listview_left = New-Object System.Windows.Forms.ListView
$listview_left.Columns.add("AD-Groups",-2)
$listview_left.View = "Details"
$listview_left.GridLines = $True
$listview_left.FullRowSelect = $true
$listview_left.width              = 550
$listview_left.height             = 680
$listview_left.location           = New-Object System.Drawing.Point(12,80)
$listview_left.Font = 'Microsoft Sans Serif,10'
$listview_left.Scrollable = $true

$listview_right = New-Object System.Windows.Forms.ListView
$listview_right.Columns.add("AD-Groups",-2)
$listview_right.View = "Details"
$listview_right.GridLines = $True
$listview_right.FullRowSelect = $true
$listview_right.width              = 550
$listview_right.height             = 680
$listview_right.location           = New-Object System.Drawing.Point(612,80)
$listview_right.Font = 'Microsoft Sans Serif,10'

$btn_left                        = New-Object system.Windows.Forms.Button
$btn_left.text                   = "Load"
$btn_left.width                  = 60
$btn_left.height                 = 30
$btn_left.location               = New-Object System.Drawing.Point(502,45)
$btn_left.Font                   = 'Microsoft Sans Serif,10'

$btn_right                        = New-Object system.Windows.Forms.Button
$btn_right.text                   = "Load"
$btn_right.width                  = 60
$btn_right.height                 = 30
$btn_right.location               = New-Object System.Drawing.Point(1102,45)
$btn_right.Font                   = 'Microsoft Sans Serif,10'

$btn_left_to_right                        = New-Object system.Windows.Forms.Button
$btn_left_to_right.text                   = ">>"
$btn_left_to_right.width                  = 30
$btn_left_to_right.height                 = 30
$btn_left_to_right.location               = New-Object System.Drawing.Point(572,350)
$btn_left_to_right.Font                   = 'Microsoft Sans Serif,10,style=Bold'

$btn_right_to_left                        = New-Object system.Windows.Forms.Button
$btn_right_to_left.text                   = "<<"
$btn_right_to_left.width                  = 30
$btn_right_to_left.height                 = 30
$btn_right_to_left.location               = New-Object System.Drawing.Point(572,400)
$btn_right_to_left.Font                   = 'Microsoft Sans Serif,10,style=Bold'

$btn_compare                        = New-Object system.Windows.Forms.Button
$btn_compare.text                   = "C"
$btn_compare.width                  = 30
$btn_compare.height                 = 30
$btn_compare.location               = New-Object System.Drawing.Point(572,450)
$btn_compare.Font                   = 'Microsoft Sans Serif,10,style=Bold'

$btn_delete_left                        = New-Object system.Windows.Forms.Button
$btn_delete_left.text                   = "X"
$btn_delete_left.width                  = 30
$btn_delete_left.height                 = 30
$btn_delete_left.location               = New-Object System.Drawing.Point(532,765)
$btn_delete_left.Font                   = 'Microsoft Sans Serif,10,style=Bold'
$btn_delete_left.ForeColor              = "#f70b0b"

$btn_delete_right                       = New-Object system.Windows.Forms.Button
$btn_delete_right.text                   = "X"
$btn_delete_right.width                  = 30
$btn_delete_right.height                 = 30
$btn_delete_right.location               = New-Object System.Drawing.Point(1132,765)
$btn_delete_right.Font                   = 'Microsoft Sans Serif,10,style=Bold'
$btn_delete_right.ForeColor              = "#f70b0b"

$count_left                     = New-Object System.Windows.Forms.Label
$count_left.width                  = 100
$count_left.height                 = 20
$count_left.location               = New-Object System.Drawing.Point(12,765)
$count_left.Font                   = 'Microsoft Sans Serif,10'
$count_left.Text = "Gesamt: 0"

$count_right                     = New-Object System.Windows.Forms.Label
$count_right.width                  = 100
$count_right.height                 = 20
$count_right.location               = New-Object System.Drawing.Point(612,765)
$count_right.Font                   = 'Microsoft Sans Serif,10'
$count_right.Text = "Gesamt: 0"

$ttip = New-Object System.Windows.Forms.ToolTip
$ttip.ToolTipTitle = "LOAD STATE"

$label_Loading = New-Object System.Windows.Forms.Label
$label_Loading.Width = 30
$label_Loading.Height = 30
$label_Loading.Location = New-Object System.Drawing.Point(572,300)
$label_Loading.Font = 'Microsoft Sans Serif,10,style=Bold'
$label_Loading.TextAlign = "MiddleCenter"
$ttip.SetToolTip($label_Loading,"L - Loading --- D - Done")



$btn_left.Add_Click(
    {
        if ($ComboBox_left.SelectedItem)
        {
            setloadstate "L"
            fill_listview $listview_left $ComboBox_left.SelectedItem ""
            $count_left.text = "Gesamt: " + $listview_left.Items.Count
            setloadstate "D"
        } else
        {
            [System.Windows.Forms.MessageBox]::Show("Bitte einen Nutzer auswählen!","Fehler",0,16)
        }
    }
)

$btn_right.Add_Click(
    {
        if ($ComboBox_right.SelectedItem)
        {
            setloadstate "L"
            fill_listview $listview_right $ComboBox_right.SelectedItem ""
            $count_right.text = "Gesamt: " + $listview_right.Items.Count
            setloadstate "D"
        } else
        {
            [System.Windows.Forms.MessageBox]::Show("Bitte einen Nutzer auswählen!","Fehler",0,16)
        }
    }
)

$btn_left_to_right.Add_Click(
    {
        if ($listview_left.SelectedItems)
        {
            if ($ComboBox_right.SelectedItem)
            {
                if ($ComboBox_left.SelectedItem -ne $ComboBox_right.SelectedItem) 
                {
                    setloadstate "L"
                    write-host $listview_left.SelectedItems
                    addadgroupmember $listview_left.SelectedItems $ComboBox_right.SelectedItem
                    fill_listview $listview_right $ComboBox_right.SelectedItem ""
                    $count_right.text = "Gesamt: " + $listview_right.Items.Count
                    setloadstate "D"
                    [System.Windows.Forms.MessageBox]::Show("Der ausgewählt Nutzer wurde den AD-Gruppen hinzugefügt. Bitte ggf. nochmals den Nutzer laden!","Info",0,64)
                } else
                {
                    [System.Windows.Forms.MessageBox]::Show("Bitte unterschiedliche Nutzer auswählen!","Fehler",0,16)
                }
            } else
            {
            [System.Windows.Forms.MessageBox]::Show("Bitte rechts einen Nutzer auswählen!","Fehler",0,16)
            }

        } else
        {
            [System.Windows.Forms.MessageBox]::Show("Bitte eine AD-Gruppe auswählen!","Fehler",0,16)
        }
    }
)

$btn_right_to_left.Add_Click(
    {
        if ($listview_right.SelectedItems)
        {
            if ($ComboBox_left.SelectedItem)
            {
                if ($ComboBox_right.SelectedItem -ne $ComboBox_left.SelectedItem) 
                {
                    setloadstate "L"
                    write-host $listview_right.SelectedItems
                    addadgroupmember $listview_right.SelectedItems $ComboBox_left.SelectedItem
                    fill_listview $listview_left $ComboBox_left.SelectedItem ""
                    $count_left.text = "Gesamt: " + $listview_left.Items.Count
                    setloadstate "D"
                    [System.Windows.Forms.MessageBox]::Show("Der ausgewählt Nutzer wurde den AD-Gruppen hinzugefügt. Bitte ggf. nochmals den Nutzer laden!","Info",0,64)
                } else
                {
                    [System.Windows.Forms.MessageBox]::Show("Bitte unterschiedliche Nutzer auswählen!","Fehler",0,16)
                }
            } else
            {
            [System.Windows.Forms.MessageBox]::Show("Bitte links einen Nutzer auswählen!","Fehler",0,16)
            }

        } else
        {
            [System.Windows.Forms.MessageBox]::Show("Bitte eine AD-Gruppe auswählen!","Fehler",0,16)
        }
    }
)

$btn_delete_left.Add_Click(
    {
        if ($listview_left.SelectedItems)
        {
            if ($ComboBox_left.SelectedItem)
            {
                if ([System.Windows.Forms.MessageBox]::Show("Soll der ausgewählte Nutzer aus den markierten AD-Gruppen gelöscht werden?","Löschen der AD-Gruppe",4,32) -eq "Yes")
                {
                    setloadstate "L"
                    Write-Host $listview_left.SelectedItems
                    removeadgroupmember $listview_left.SelectedItems $ComboBox_left.SelectedItem
                    fill_listview $listview_left $ComboBox_left.SelectedItem ""
                    $count_left.text = "Gesamt: " + $listview_left.Items.Count
                    setloadstate "D"
                    [System.Windows.Forms.MessageBox]::Show("Der ausgewählt Nutzer wurde aus der AD-Gruppe entfernt. Bitte ggf. nochmals den Nutzer laden!","Info",0,64)
                } else
                {
                    [System.Windows.Forms.MessageBox]::Show("Aktion abgebrochen!","Info",0,64)
                }
            } else
            {
                [System.Windows.Forms.MessageBox]::Show("Bitte rechts einen Nutzer auswählen!","Fehler",0,16)
            }
        } else
        {
            [System.Windows.Forms.MessageBox]::Show("Bitte eine AD-Gruppe auswählen!","Fehler",0,16)
        }
    }
)

$btn_delete_right.Add_Click(
    {
        if ($listview_right.SelectedItems)
        {
            if ($ComboBox_right.SelectedItem)
            {
                if ([System.Windows.Forms.MessageBox]::Show("Soll der ausgewählte Nutzer aus den markierten AD-Gruppen gelöscht werden?","Löschen der AD-Gruppe",4,32) -eq "Yes")
                {
                    setloadstate "L"
                    Write-Host $listview_right.SelectedItems
                    removeadgroupmember $listview_right.SelectedItems $ComboBox_right.SelectedItem
                    fill_listview $listview_right $ComboBox_right.SelectedItem ""
                    $count_right.text = "Gesamt: " + $listview_right.Items.Count
                    setloadstate "D"
                    [System.Windows.Forms.MessageBox]::Show("Der ausgewählt Nutzer wurde aus der AD-Gruppe entfernt. Bitte ggf. nochmals den Nutzer laden!","Info",0,64)
                } else
                {
                    [System.Windows.Forms.MessageBox]::Show("Aktion abgebrochen!","Info",0,64)
                }
            } else
            {
                [System.Windows.Forms.MessageBox]::Show("Bitte rechts einen Nutzer auswählen!","Fehler",0,16)
            }
        } else
        {
            [System.Windows.Forms.MessageBox]::Show("Bitte eine AD-Gruppe auswählen!","Fehler",0,16)
        }
    }
)

$btn_compare.Add_Click(
    {
        setloadstate "L"
        comparegroups
        setloadstate "D"
    }
)

$listview_left.Add_MouseDoubleClick(
    {
        setloadstate "L"
        form_info $listview_left.SelectedItems.Text
        setloadstate "D"
    }

)

$listview_right.Add_MouseDoubleClick(
    {
        setloadstate "L"
        form_info $listview_right.SelectedItems.Text
        setloadstate "D"
    }

)


$Form.controls.AddRange(@($ComboBox_left,$ComboBox_right,$listview_left,$listview_right,$btn_left,$btn_right,$count_left,$count_right,$btn_left_to_right,$btn_right_to_left,$btn_delete_left,$btn_delete_right,$btn_compare,$label_Loading))

$Users = get-aduser -filter * -Properties SamaccountName | Select SamaccountName | Sort SamAccountName
setloadstate "L"
foreach ($User in $Users)
{
    $ComboBox_left.Items.Add($User.SamAccountName)
    $ComboBox_right.items.add($User.SamAccountName)
}
setloadstate "D"

$form.ShowDialog()
