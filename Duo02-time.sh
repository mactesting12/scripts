#!/bin/zsh

jamf="/usr/local/bin/jamf"
start=$(date +%s)
profileID="${4:-"35EF8BA8-7051-48C6-BC3C-1EC1CDD2E369"}"                              # Parameter 4: Duo Cert Profile ID [ /var/log/com.coalitioninc.log ] (i.e., Your organization's default location for client-side logs)
scriptLog="/var/tmp/com.duoInstall.log"

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
    updateScriptLog "Starting Script."
fi

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}


createCertManagement() {
    mkdir -p "/Library/Application Support/Duo/Duo Device Health"
    if [[ -e "/Library/Application Support/Duo/Duo Device Health" ]]; then
        updateScriptLog "Directory now exists"
    else
        updateScriptLog "Directory doesn't exist"
    fi
    touch "/Library/Application Support/Duo/Duo Device Health/DisableMacOS11CertManagement"
    if [[ -e "/Library/Application Support/Duo/Duo Device Health/DisableMacOS11CertManagement" ]]; then
        updateScriptLog "File exists"
    else
        updateScriptLog "File doesn't exist"
    fi
    updateScriptLog "Calling Recon"
    $jamf recon
}


# Checks to see if the Duo Profile is installed.
checkDuoProfileInstalled(){
    enrolled="$(/usr/bin/profiles -C | /usr/bin/grep "$profileID")" 
    if [[ "$enrolled" != "" ]]; then
        updateScriptLog "Duo Cert Profile present..."
        duoPresent=0
    else

        updateScriptLog "Duo Profile not installed..."
        duoPresent=1
    fi
}

# Calls the Duo DHA installer
installDuo(){
    $jamf policy -trigger enrollmentDuoInstall
    updateScriptLog "Duo is installed."
    end=$(date +%s)
    updateScriptLog "Elapsed Time: $(($end-$start)) seconds"
}

createCertManagement
until [[ "$duoPresent" -eq "0" ]]; do
    updateScriptLog "Checking for Duo Cert... waiting 5 seconds to re-check..."
    sleep 5
    checkDuoProfileInstalled
done
installDuo