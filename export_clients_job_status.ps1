#----------------------------------------------
# Name:           export_clients_job_status.ps1
# Version:        1.0.0.0
# Start date:     21.11.2013
# Release date:   27.11.2013
#
# Author:         George Dicu
# Department:     Cloud 
#----------------------------------------------

//use bpdbm -ctime to convert from unix time

$clients = @()
$objResult = @()
$result = @()

write-host "Chose Date, eg. mm/dd/yyyy, specifies a start date and time for the listing. 
The resulting list shows only images in back ups or archives that occurred at or after the specified date and time."

$d = Read-Host
$date = if($d -match "\d*/\d*/\d{4}"){ $d }else{""}

write-host "Chose Policy"
$policy = Read-Host

cd\
cd "Program Files\Veritas\NetBackup\bin\admincmd"

$clients = .\bpplclients $policy

foreach ($client in $clients[2..($clients.Length)]){
    
    write-host "Getting $clinet info"
    
    $t1, $t2, $t3 = ($client -replace "\s+",";").split(";")
    $list = .\bperror -l -backstat -d $d -client $t3

    foreach ($row in $list){

        $cels = $row.split(" ")
        $PropertyHash = @{}
        $i = 0
        
        foreach ($cel in $cels) {
            
            if ($cel -eq "") { 
                continue 
            }
            
            if ($i -eq 19) { 
                break 
            }
            $PropertyHash +=  @{
                "T$i" = $cel
            }
            $i++
        } 
      $PropertyHash +=  @{
        "Description" = ((($row.split("("))[-1]).split(")"))[0]
      }
      $objResult += New-Object -TypeName PSObject -Property $PropertyHash
    }
}

Write-Host "Chose the fs full path for the CSV file. Eg.: C:\temp\ the result will be: C:\temp\<policy name>"
$location = Read-Host
Write-Host "Report saved in $location\$policy.csv"

$objResult | Select-Object @{Name="Time";Expression={$_.T0}},@{Name="Server";Expression={$_.T4}},
@{Name="Job Id";Expression={$_.T5}},@{Name="Job Group ID";Expression={$_.T6}},
@{Name="Client";Expression={$_.T8}},@{Name="Policy";Expression={$_.T13}},
@{Name="Status";Expression={$_.T18}},@{Name="Schedule";Expression={$_.T15}},Description | Export-Csv "$location\$policy.csv" -NoTypeInformation

Write-Host "Report saved in $location$policy.csv"