#!/bin/bash
# this script automates updating an pack at a minecraft server usign packwiz. 
# creating backups where senseful.
version="0.1"

# config
serverPath="server"
worldPath="${serverPath}/world"
backupPath="${serverPath}/backups"

serverBranch="server-live"
serverBackupBranch="server-backup"

packURI="http://localhost:8080/pack.toml"
args=""

# runntime vars
newVersion="$1"
workingDir="$(pwd)"
backupFileName="$(basename ${worldPath})_$(date +%Y-%m-%d-%H%M)"
fullBackupPath="${backupPath}/${backupFileName}.tar.gz"

# init
echo "Start server updater v$version"
set -e
shopt -s dotglob

function onExit() {
    shopt -u dotglob
}
function onError() {
    echo "ERROR: Something went wrong!"
}
trap onError ERR
trap onExit EXIT

if [ -z $newVersion ]; then
    echo "ERROR: No version specified"
    exit 1
fi
if [ ! -d "${backupPath}" ]; then 
    mkdir -p ${backupPath}
fi

# prog start
echo "Create world backup"
tar -cz ${worldPath} -f ${fullBackupPath}
echo "Push server backup"
cd $serverPath
git add .
git commit -m "Server backup before: ${newVersion}"
git push origin ${serverBranch}:${serverBackupBranch}
echo "Download server pack"
java -jar ${workingDir}/packwiz-installer-bootstrap.jar -g -s server $args $packURI
echo "Copying server files"
mv mods-server/* mods
mv conf-server/* config
echo "Push server repo"
git add .
git commit -m "Server update to: ${newVersion}"
git push
echo "Cleanup server dir"
rm -r mods-server mods-client conf-server conf-client
cd $workingDir

echo "Done"