#----------------------------------------------
# Name:           get_policy_details
# Version:        1.0.0.0
# Start date:     20.12.2014
# Release date:   20.12.2014
# Description:    
#
# Author:         George Dicu
# Department:     Cloud, Backup  
#----------------------------------------------

cd\

$nbpath = "C:\Program Files\Veritas\NetBackup\bin\admincmd"

#$policies = Read-Host
#$policies = Import-Csv "C:\EH tapes test\tapes.csv"

if (Test-Path $nbpath) {
    
    cd $nbpath
    
    #creating $pc array for all trimmed items from $policycontainer and the final container:$PolicyHash
    $pc = @()
    $PolicyHash = @{}
    $policycontainer = .\bppllist emr_windows_srv -U
    
    #Iterating the policy items without 1st two items
    foreach($item in $policycontainer[2..($policycontainer.Count)]){
    
        #if on item is null eliminate it
        if ($item.Trim() -eq ""){
            continue
        }
        #recreating the array for new item in $policycontainer
        $pc += $item.Trim()
    }
    
    #creating final container(a hash table) with special Column that need special formating/manipulating
    $PolicyHash +=  @{
        
        #Column that needs special splitting/formatting after matching it
        "Effective date" =  $pc -match "^Effective date:" | ForEach-Object { $_.Split("")[-2].trim() }
        "Effective time" =  $pc -match "^Effective date:" | ForEach-Object { $_.Split("")[-1].trim() }
        "Volume Pool" = ($pc -match "^Volume Pool:")[0].Split(":")[-1].trim()
        "Server Group" = ($pc -match "^Server Group:")[0].Split(":")[-1].trim()
        "Residence" = ($pc -match "^Residence:")[0].Split(":")[-1].trim()
        "Residence is Storage Lifecycle Policy" = ($pc -match "^Residence is Storage Lifecycle Policy:")[0].Split(":")[-1].trim()

    }
    
    #new array with all columns from $pc array that are same nd unique for all policy types
    $matches = ("Policy Name","Policy Type","Active","File Restore Raw","Mult. Data Streams",
    "Client Encrypt","Checkpoint","Policy Priority","Max Jobs/Policy","Disaster Recovery",
    "Collect BMR info","Keyword","Data Classification","Application Discovery","Discovery Lifetime",
    "ASC Application and attributes","Granular Restore Info","Ignore Client Direct","Client Compress",
    "Enable Metadata Indexing","Index server name","Use Accelerator","Collect TIR info",
    "File Restore Raw","Interval","Optimized Backup","Application Consistent","Block Incremental",
    "Cross Mount Points","Follow NFS Mounts","Exchange DAG Preferred Server","Exchange Source passive db if available")
    
    #iterrating $Matches array and adding new hash item intoo the table with its value
    foreach ($match in $matches){
    
        $value = $pc -match ("^"+[regex]::escape($match)+":") | ForEach-Object { $_.Split(":")[-1].trim() }
        
        #save each column/policy properties with its value in hashtable
        if ($value) {
            $PolicyHash[$match] = $value
        }
        #if the policy type doesnt have a propertie(column) save its value as "-"
        else {
            $PolicyHash[$match] = "-"
        }
    }
     
    #Include Column/Property has different aspects for different policy types
    #getting index interval from Include Column  to 1st Schedule-1 where resided last Include item
    $allinclude = $pc[([array]::IndexOf($pc,($pc -match "Include:")[0]))..(([array]::IndexOf($pc,($pc -match "Schedule:")[0]))-1)]
    
    #after finding all Include items, saveing them intoo our hastable
    #1st item in Include array starting with "Include: " so we eliminate this and save it outside foreach
    $PolicyHash["Include_0"] = $allinclude[0].substring(8).trim()
    $i=1
    foreach($includeitem in $allinclude[1..($allinclude.Count)]){
        if($includeitem -eq "NEW_STREAM"){
            continue
        }
        $PolicyHash["Include_$i"] = $includeitem
        $i++
    }
    
    #saveing the policy clients in saparate array
    $allservers = $pc[([array]::IndexOf($pc,($pc -match "HW/OS/Client:")[0]))..(([array]::IndexOf($pc,($pc -match "Include:")[0]))-1)]
    
    #after finding all servers items, saveing them intoo our hastable
    #1st item in servers array starting with "HW/OS/Client:" so we eliminate it
    $servers = @()
    #save all items into other array except the 1st one who we add after
    #we elimintate "HW/OS/Client:" from it
    $newallservers = $allservers[1..($allservers.Count)]
    $newallservers += $allservers[0].substring(14).trim()
    
    foreach($server in $newallservers){
        $servers +=  ($server -replace "\s+",";").split(";")[2] 
    }
    $PolicyHash["Clients"] = $servers
    
    #Since every policy has different number of schedules and Columns/Propierties in them are named 
    #same we have to separate them in order to save them gracefully into hash table
    
    #because $schedules will always be an array, even if we have 1 item we will iterate the array, 
    #this way will lose a if statement before foreach statement whos iteratting the $schedules
    $schedules = $pc -match "^Schedule:"
    $indexno = @()
    foreach($schedule in $schedules){
        $indexno += [array]::IndexOf($pc,$schedule)
    }
    $indexno += ($pc.Count)
    
    $submatches = ("Schedule","Type","Calendar sched","Frequency","Synthetic",
    "Checksum Change Detection","PFI Recovery","Maximum MPX","Retention Level",
    "Number Copies","Fail on Error","Residence","Volume Pool","Server Group",
    "Residence is Storage Lifecycle Policy","Schedule indexing")
    
    for($i=1;$i -le ($indexno.Count-1);$i++){
    
        $subpc = @()
        $subpc = $pc[$indexno[$i-1]..(@{$true=$indexno[$i];$false=($indexno[$i])-1}[$i -eq ($indexno.Count-1)])]
        $policyname = $subpc[0].Split(":")[-1].trim()
        
        #iterrating $submatches array and adding new hash item intoo the table with its value
        foreach ($submatch in $submatches){
        
            $subvalue = $subpc -match ("^"+[regex]::escape($submatch)+":") | ForEach-Object { $_.Split(":")[-1].trim() }
            
            #save each column/policy properties with its value in hashtable
            if ($subvalue) {
                $PolicyHash["Schedule_$i $submatch"] = $subvalue
            }
            #if the policy type doesnt have a propertie(column) save its value as "-"
            else {
                $PolicyHash["Schedule_$i $submatch"] = "-"
            }
        }
        
        $PolicyHash["Include Dates of $policyname"] += $subpc[([array]::IndexOf($subpc,"Included Dates-----------")+1)..([array]::IndexOf($subpc,"Excluded Dates----------")-1)]
        $PolicyHash["Daily Windows of $policyname"] += $subpc[([array]::IndexOf($subpc,"Daily Windows:")+1)..($subpc.Count)]
    }
}
else {
    write-host "This script can only run on Netbackup Windows Servers, $nbpath path incorrect"
}



#[array]::IndexOf($test,$text)
#foreach ($item in $match){  }
#$ndx = [array]::IndexOf($test,$item)
#$pc -match ("^"+[regex]::escape($matches[0])+":") | ForEach-Object { $_.Split(":")[-1].trim() }
#$pc[[array]::IndexOf($pc,($pc -match "Include:")[0])]