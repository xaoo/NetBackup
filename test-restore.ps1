#----------------------------------------------
# Name:           test-restore
# Version:        1.0.0.0
# Start date:     16.03.2015
# Release date:   16.03.2015
# Description:    
#
# Author:         George Dicu
# Department:     Cloud, Backup  
#----------------------------------------------

cd\

$nbadmin = "C:\Program Files\Veritas\NetBackup\bin\admincmd"
$nbbin = "C:\Program Files\Veritas\NetBackup\bin"

if (Test-Path $nbbin) {
    
    cd $nbbin
    
    $logfile = "C:\restore\log" #the file MUST exist
    $changefile = "C:\restore\change"
    $filelist = "C:\restore\filelist"
    $masterserver = "adm-master01"
    $source = "em-ctx02"
    $destination = "adm-media04"
    $startdate = "20/02/2015"
    $priority = 99999
    $policytype = 40
    $media_server = "adm-media04"
        
    
    .\bprestore.exe -s $startdate -S $masterserver  -C $source -D $destination -L $logfile -en -priority $priority -t $policytype -R $changefile -f $filelist
    
}
else {
    write-host "This script can only run on Netbackup Windows Servers, $nbbin path incorrect"
}