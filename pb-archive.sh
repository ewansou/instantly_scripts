#!/usr/bin/bash

#CHANGE BELOW FOR SCRIPT CONFIGURATION
dropboxPhotoBootNewFolder="D:/Dropbox/Operations/#thisweek/NEWRADEN/photobooth-new"
mainPathToArchive="C:/Users/ewans/Desktop" #Path where Display, Hold, Done, Edited, ARC are
displayFolderName="Display"
holdFolderName="Hold"
doneFolderName="Done"
editedFolderName="Edited"
arcFolderName="ARC"

day=$(date +"%d")
month=$(date +"%m")
year=$(date +"%Y")
date="$day""$month""$year"

while true

do
	echo "==============================="
	echo " *** STEP 1: Please enter the eventID of your event. You can get this eventID from calendar. *** "
	echo " ***  Once done, press ENTER *** "
	echo "==============================="
	read -p $'' eventId

	if [[ -z "$eventId" ]]; then
		echo "==============================="
		echo " *** You did not enter any eventID. Please try again. *** "
		echo "==============================="
		continue
	else
		echo "==============================="
		echo " *** The eventID you've entered is ---> $eventId *** "
		echo " *** STEP 2: Please double confirm that this eventID is correct. *** "
		echo " *** IMPORTANT NOTE: If you've made a mistake, you may be subjected to penalty (salary deduction). *** "
		echo " *** Type y and press ENTER if correct. Type n and press ENTER if wrong. *** "
		echo "==============================="
		read -p $'' confirm

		case $confirm in
			y|Y)
			echo "==============================="
			echo " *** Archiving files in progress now... *** "
			echo "==============================="

			photoboothnewFolderName="$date"_"${eventId}"

			Sleep 2
			echo "==============================="
			echo " *** Archiving Display folder on Desktop now *** "
			mkdir -p ${dropboxPhotoBootNewFolder}/$photoboothnewFolderName/${displayFolderName}
			find ${mainPathToArchive}/${displayFolderName} -maxdepth 1 -not -type d -exec mv -t ${dropboxPhotoBootNewFolder}/${photoboothnewFolderName}/${displayFolderName} -- '{}' +
			echo " *** Archiving of Display folder on Desktop completed *** "
			echo "==============================="

			Sleep 2
			echo "==============================="
			echo " *** Archiving Hold folder on Desktop now *** "
			mkdir -p ${dropboxPhotoBootNewFolder}/$photoboothnewFolderName/${holdFolderName}
			find ${mainPathToArchive}/${holdFolderName} -maxdepth 1 -not -type d -exec mv -t ${dropboxPhotoBootNewFolder}/${photoboothnewFolderName}/${holdFolderName} -- '{}' +
			echo " *** Archiving of Hold folder on Desktop completed *** "
			echo "==============================="

			Sleep 2
			echo "==============================="
			echo " *** Archiving Done folder on Desktop now *** "
			mkdir -p ${dropboxPhotoBootNewFolder}/$photoboothnewFolderName/${doneFolderName}
			find ${mainPathToArchive}/${doneFolderName} -maxdepth 1 -not -type d -exec mv -t ${dropboxPhotoBootNewFolder}/${photoboothnewFolderName}/${doneFolderName} -- '{}' +
			echo " *** Archiving of Done folder on Desktop completed *** "
			echo "==============================="

			Sleep 2
			echo "==============================="
			echo " *** Archiving Edited folder on Desktop now *** "
			mkdir -p ${dropboxPhotoBootNewFolder}/$photoboothnewFolderName/${editedFolderName}
			find ${mainPathToArchive}/${editedFolderName} -maxdepth 1 -not -type d -exec mv -t ${dropboxPhotoBootNewFolder}/${photoboothnewFolderName}/${editedFolderName} -- '{}' +
			echo " *** Archiving of Edited folder on Desktop completed *** "
			echo "==============================="

			Sleep 2
			echo "==============================="
			echo " *** Archiving ARC folder on Desktop now *** "
			mkdir -p ${dropboxPhotoBootNewFolder}/$photoboothnewFolderName/${arcFolderName}
			find ${mainPathToArchive}/${arcFolderName} -maxdepth 1 -not -type d -exec mv -t ${dropboxPhotoBootNewFolder}/${photoboothnewFolderName}/${arcFolderName} -- '{}' +
			echo " *** Archiving of ARC folder on Desktop completed *** "
			echo "==============================="

			echo "==============================="
			echo " *** Archiving completed *** "
			echo " *** IMPORTANT NOTE: If you think you've made a mistake (for eg., entered the wrong eventID), please update us accordingly. *** "
			echo " *** IMPORTANT NOTE: Please ensure Dropbox completely syncs finish before you off this computer. You can observe the Dropbox icon on the bottom right. *** "
			echo " *** Script will exit in 5 seconds *** "
			Sleep 1
			echo " *** In 5... *** "
			Sleep 1
			echo " *** In 4... *** "
			Sleep 1
			echo " *** In 3... *** "
			Sleep 1
			echo " *** In 2... *** "
			Sleep 1
			echo " *** In 1... *** "
			Sleep 1
			exit
			;;

			n|N)
			echo "==============================="
			echo " *** Please enter eventID again *** "
			echo "==============================="
			continue
			;;
			*)
			echo "==============================="
			echo " *** Please enter either y or n *** "
			echo "==============================="
			;;
		esac
	fi
done
