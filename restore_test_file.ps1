#----------------------------------------------
# Name:           restore_test_file
# Version:        1.0.0.0
# Start date:     16.03.2015
# Release date:   01.04.2015
# Description:    
#
# Author:         George Dicu
# Department:     Cloud, Backup  
#----------------------------------------------

cd\

$nbadmin = "D:\Program Files\Veritas\NetBackup\bin\admincmd"
$nbbin = "D:\Program Files\Veritas\NetBackup\bin"

if (Test-Path $nbbin) {
    
    cd $nbbin
    
    $logfile = "D:\restore\file.log" #the file MUST exist
    $logfileen = "D:\restore\file.log_en" #will be created automaticly
    $changefile = "D:\restore\file.change"
    $filelist = "D:\restore\file.filelist"

    if (!(Test-Path $logfile)) {
        New-Item $logfile -ItemType file
    }
    if (!(Test-Path $changefile)) {
        New-Item $changefile -ItemType file
    }
    if (!(Test-Path $filelist)) {
        New-Item $filelist -ItemType file
    }

    #randomly pick a server from a set-up client
    $serverlist = "fidc.sisab.sapagroup.com","fidc2.sisab.sapagroup.com","FIMAT","FLINTA","mgmnt","npuss_bim","vision"
    $source = $serverlist | Get-Random

    #randomly pick a date from today`s date - 21 days
    $date = Get-date
    $restoredate = (($date.adddays(-(Get-Random -Minimum 1 -Maximum 21)).ToString('dd/MM/yyyy')).replace(".","/"))

    #base set-ups
    $masterserver = "adm-master01"
    #destination is the source in thgis care, but it can be restored in any valid location
    $destination = $source
    $priority = 99999
    $policytype = 13 #MS-Windows

    #randomly pick some files from backup from the date and server picked above
    $bplist = .\bplist.exe -B -c -C $source -S $masterserver -s $restoredate -e $restoredate -unix_files -R -l 'C:\Program Files\Veritas\NetBackup\*'

    $i = 0
    $j = @()
    #we restore only files, and bplist cannot search just files but it can show what we have.
    #in this loop we save all bplist indexes that are files
    foreach($item in $bplist){
        
        $splititem = ($item -replace "\s+", "^")

        $isfile = $splititem.Split("^")[0]
        $filesize = $splititem.Split("^")[3]

        if($isfile -Contains "-rwx------"){
            if([int]$filesize -le 5242880){
                $j += $i
            }
        }

        $i++
    }
    #as we have a random file selection algorith we now save the file path
    #because the fullpath that we want to save its in a different array after we split one arary item
    #from bplist we must save the random index so we concatenate(create the full path) the same file
    $rndI = $j | get-random

    $splititem = ($bplist[$rndI] -replace "\s+", "^")

    $filepath = $splititem.Split("^")[-2] + " " + $splititem.Split("^")[-1]

    #one space in the end of the filepath is not getting out with trimend() so we do itthis way
    $filepath = $filepath.Substring(0,$filepath.Length-1)
    $filesize = $splititem.Split("^")[3]

    #we do not want to restore what we`ve restored the last time, so we clear out the files
    Clear-Content $filelist,$changefile,$logfile,$logfileen
    Add-Content $filelist $filepath

    #adding file name to changefile, to a differ path, the restore path
    $filename = $filepath.Split("/")[-1]
    Add-Content $changefile "change $filepath to /C/_restore_test/$filename"
    
    #restore command
    .\bprestore.exe -s $restoredate -S $masterserver  -C $source -D $destination -L $logfile -en -priority $priority -t $policytype -R $changefile -f $filelist

    #now after the restore is ongoing, we need to see when it`s finished, and then to send status mail
    #getting the restore id, to investigate if the restore finished.
    $rstid = ([string](Get-Content -Path $logfileen | Select-String -pattern "Restore Job Id")).split("=")[-1]
    
    cd $nbadmin

    #creating a infinite loop until the status is 0, which means the job`s done and we send the mail
    while($true){
        
        #with the restore id, we search the job to investigate the status.
        $rstinfo = .\bpdbjobs -jobid $rstid
        $rststs = ($rstinfo[1] -replace "\s+", "^").Split("^")[3]
        $rststate = ($rstinfo[1] -replace "\s+", "^").Split("^")[2]

        #
        $SF = @{$true="Success";$false="Fail"}[$rststs -eq 0]

        if($rststs -eq 0) {
            blat.exe -attach $logfileen -subject "OpenFile Monthly Automated Restore Sweden - $SF" -body "Restore Details:

Restored File: $filepath
Size: $filesize bytes
Source: $source
Destination: $destination
Timeframe: $restoredate - $restoredate

Attached you can find the restore log.

//Swe Backup Team" -to george.dicu@atos.net
            break
        }
        #wait 10 secs until going trough the loop again
        Start-Sleep -s 10
    }
}
else {
    write-host "This script can only run on Netbackup Windows Servers, $nbbin path incorrect"
}