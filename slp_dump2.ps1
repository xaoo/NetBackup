cd /
cd "C:\Program Files\Veritas\NetBackup\bin\admincmd"

$slps = .\nbstl -b
$container = New-Object System.Collections.ArrayList($null)

foreach ($slp in $slps) {

    #debug
    #$name = ($slp[0].split(":"))[1].trim()
    #Write-Output $name
    #debug-end
    
    
    $slp = .\nbstl $slp -L
    $ops = $slp -match (" Operation  ")
    $matches = ("Use for","Storage","Volume Pool","Server Group","Retention Type","Retention Level",
                    "Alternate Read Server","Preserve Multiplexing","Enable Automatic Remote Import",
                    "Source","Operation ID","Operation Index","Window Name","Window Close Option","Deferred Duplication")
                    
    
    $entry = New-Object PSObject
    $entry | Add-Member -MemberType NoteProperty -Name "Name" -Value ($slp[0].split(":"))[1].trim()
    $entry | Add-Member -MemberType NoteProperty -Name "Data Classification" -Value ($slp[1].split(":"))[1].trim()
    $entry | Add-Member -MemberType NoteProperty -Name "Duplication Job Priority" -Value ($slp[2].split(":"))[1].trim()
    $entry | Add-Member -MemberType NoteProperty -Name "State" -Value ($slp[3].split(":"))[1].trim()
    $entry | Add-Member -MemberType NoteProperty -Name "Version" -Value ($slp[4].split(":"))[1].trim()      
    
    $op1 = $slp[5..20]
    foreach($match in $matches){
    
        $value = (($op1 -match $match -split(":"))[-1]).trim()
        
        if ($value){
            $entry | Add-Member -MemberType NoteProperty -Name "Op1 $match" -Value $value
        }
    }
    
    $op2 = $slp[21..36]
    
    if($op2){
        foreach($match in $matches){
           
            $value = $op2 -match $match
            
            if ($match -eq "Source") {
                $entry | Add-Member -MemberType NoteProperty -Name "Op2 $match" -Value (((($value -split(":"))[1]).trim() -split("\("))[0].trim()+";"+($value -split("\(") -split(":"))[2]+";"+(($value -split(":"))[2] -split("\)"))[0])
            }
            else{
                $value = (($op2 -match $match -split(":"))[-1]).trim()
            
                if ($value){
                    $entry | Add-Member -MemberType NoteProperty -Name "Op2 $match" -Value $value
                }
            }
        }
    }
    
    $op3 = $slp[37..52]
    
    if($op3){
        foreach($match in $matches){
        
            $value = $op3 -match $match
            
            if ($match -eq "Source") {
                $entry | Add-Member -MemberType NoteProperty -Name "Op3 $match" -Value (((($value -split(":"))[1]).trim() -split("\("))[0].trim()+";"+($value -split("\(") -split(":"))[2]+";"+(($value -split(":"))[2] -split("\)"))[0])
            }
            else {
                $value = (($op3 -match $match -split(":"))[-1]).trim()
                
                if ($value){
                    $entry | Add-Member -MemberType NoteProperty -Name "Op3 $match" -Value $value
                }
            }
        }
    }
    else {
        foreach($match in $matches){
        
            $entry | Add-Member -MemberType NoteProperty -Name "Op3 $match" -Value "-"
        }
    }
      
    $container.Add($entry) > $null
    #$container | Export-Csv -Path "c:\Temp\slp.csv" -NoTypeInformatio
    #break
    #$container = New-Object -TypeName PSObject -Property $container
    #$container | Export-Csv -Path "c:\Temp\$name.csv" -NoTypeInformation
}
$container | Export-Csv -Path "c:\Temp\slp4.csv" -NoTypeInformation