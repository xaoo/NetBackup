#----------------------------------------------
# Name:           export_all_clients
# Version:        1.0.0.0
# Start date:     04.04.2014
# Release date:   04.04.2014
# Description:    
#
# Author:         George Dicu
# Department:     Cloud, Backup  
#----------------------------------------------

cd\

$nbpath = "C:\Program Files\Veritas\NetBackup\bin\admincmd"

if (Test-Path $nbpath) {

    cd $nbpath
    
    write-host "Provide full path of .csv file exported by export_all_policies script"
    $path = read-host
    $allpoliciesinfo = Import-Csv -Path $path 
    
    Write-Host "chose full-path where to save the csv file"
    $path = Read-Host
    
    $ClientsResult = @()
    $policyinfo = @()
    
    foreach ($policyinfo in $allpoliciesinfo ){
        
        $policy = $policyinfo | select -ExpandProperty PolicyName
        
        Write-Host "crawling after policy $policy"
        
        $clients = .\bpplclients  $policy
        
        for($i=2;$i -le ($clients.Length)-1;$i++){
        
            $PropertyHash = @{}
            $PropertyHash +=  @{
            
                "Client" = ($clients[$i] -replace "\s+",";").split(";")[2]
                "OS" = ($clients[$i] -replace "\s+",";").split(";")[1]
                "Hardware" = ($clients[$i] -replace "\s+",";").split(";")[0]
                "Policy" = $policyinfo | select -ExpandProperty PolicyName
                "PolicyStatus" = $policyinfo | select -ExpandProperty Active
                #@{$true="Active";$false="Inactive"}[($policyinfo | select -ExpandProperty Active) -eq "yes"] 
            }
            
            $ClientsResult += New-Object -TypeName PSObject -Property $PropertyHash 
        }
    }
    
    $ClientsResult | Export-Csv -Path "$path" -NoTypeInformation
}
else {
    write-host "This script can only run on Netbackup Windows Servers"
}