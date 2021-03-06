cd /
cd "C:\Program Files\Veritas\NetBackup\bin\admincmd"

$slps = .\nbstl -b


$container = @()

foreach ($slp in $slps) {
    
    $Hash = @{}
    $slp = .\nbstl $slp -L
    $ops = $slp -match (" Operation  ")
    $matches = ("Use for","Storage","Volume Pool","Server Group","Retention Type","Retention Level",
                    "Alternate Read Server","Preserve Multiplexing","Enable Automatic Remote Import",
                    "Source","Operation ID","Operation Index","Window Name","Window Close Option","Deferred Duplication")
                    
    $name = (($slp -match "  Name:") -split(":"))[1].trim()
    Write-Output $name
    $Hash = @{
        "1;Name" = ($slp[0].split(":"))[1].trim()
        "1;Data Classification" = ($slp[1].split(":"))[1].trim()
        "1;Duplication Job Priority" = ($slp[2].split(":"))[1].trim()
        "1;State" = ($slp[3].split(":"))[1].trim()
        "1;Version" = ($slp[4].split(":"))[1].trim()      
    }
    
    $op1 = $slp[5..20]
    foreach($match in $matches){
    
        $value = (($op1 -match $match -split(":"))[-1]).trim()
        
        if ($value){
            $Hash["1;$match"] = $value
        }
    }
    
    $op2 = $slp[21..36]
    
    if($op2){
        foreach($match in $matches){
           
            $value = $op2 -match $match
            
            if ($match -eq "Source") {
                $Hash["2;$match"] = ((($value -split(":"))[1]).trim() -split("\("))[0].trim()+";"+($value -split("\(") -split(":"))[2]+";"+(($value -split(":"))[2] -split("\)"))[0]
            }
            else{
                $value = (($op2 -match $match -split(":"))[-1]).trim()
            
                if ($value){
                    $Hash["2;$match"] = $value
                }
            }
        }
    }
    
    $op3 = $slp[37..52]
    
    if($op3){
        foreach($match in $matches){
        
            $value = $op3 -match $match
            
            if ($match -eq "Source") {
                $Hash["3;$match"] = ((($value -split(":"))[1]).trim() -split("\("))[0].trim()+";"+($value -split("\(") -split(":"))[2]+";"+(($value -split(":"))[2] -split("\)"))[0]
            }
            else {
                $value = (($op3 -match $match -split(":"))[-1]).trim()
                
                if ($value){
                    $Hash["3;$match"] = $value
                }
            }
        }
    }
    
    $container = New-Object -TypeName PSObject -Property $Hash
    
}
$container | Export-Csv -Path "c:\Temp\csv.csv" -NoTypeInformation