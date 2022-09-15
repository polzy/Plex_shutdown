############################################################
#Condition : 
#
# installer le module dans un powershell admin : 

# install-Module BurntToast
# Install-Module PSDiscord
#A placer dans la planification de tâche. 
# Le script doit se lancer 1 fois par exemple a 00h
##########################################################################
#Config
$chemin_du_repertoire_script = "C:\Users\maxim\OneDrive\Documents\plex_scripts\Plex_shutdown"
$token = ""
$Plex = "http://127.0.0.1:32400/status/sessions?X-Plex-Token=$token"
#Webhook plex
$Uri = ""
$image_gif = "touz.gif"
$secondes = "600"
##########################################################################
#Module pour les notification Windows
import-Module PSDiscord
import-Module BurntToast
cd $chemin_du_repertoire_script

$code = "0"
$notif = "0"

#Notification Windows du lancement du script
New-BurntToastNotification -AppLogo $image_gif -Text "Plex", "Lancement du script d'inactivité de Plex."


function Shutdown_PC {   
shutdown -s -f -t $secondes -c "Plex est inactif, l'ordinateur va s'eteindre dans $secondes secondes."           
}

function notification {
#Notification Windows 
            New-BurntToastNotification -AppLogo $image_gif -Text "Plex", "Plex inactif, arrêt du PC dans $secondes secondes"
            write-host "Plex est inactif, l'ordinateur va s'eteindre dans $secondes secondes."
            #Notification Discord
            if ($Uri -notlike $null)
            {
        $nom_machine = [system.environment]::MachineName
		$messageDiscord = "Plex inactif :  Arret de $nom_machine en cours : $date"
		Send-DiscordMessage -WebHookUrl $Uri -Text $messageDiscord
            }
}

function Show-Message {
#Popup 
            $Message = "Arrêt du PC dans $secondes secondes. Appuyer sur Annuler pour prolonger de $secondes secondes."
            $Titre = "Plex"
            $btn = 1
            $Icon = 48
            [System.Windows.Forms.MessageBox]::Show($Message, $Titre , $Btn, $Icon)
            Return $Reponse
}

#Début de la boucle 
while (1)
	{
$date = get-date
$Chrome = get-process "chrome" -ea SilentlyContinue
$Plex2 = curl $Plex

if ( -Not ( $Plex2 | Select-String -Pattern 'state="playing"' ) -And ($Chrome -eq $Null) ) 
#If (($Plex2 -match 'MediaContainer size="0"') -And ($Chrome -eq $Null))
    { 
    #Si Chrome est coupé et si 0 utilisateur sur Plex passage code = 1
	write-host "Chrome n'est pas ouvert et aucun utilisateur sur Plex."
	
    $code = "1"
    }

    Else {
    #Si un utilisateur relance un film, on repasse a 0
	write-host "Chrome est ouvert ou un utilisateur est sur Plex. Pas d'arret du PC."
    $code = "0"
    }

    #Si code = 1, lancement de l'arret du PC
if ($code -eq "1"){
    Shutdown_PC
    $code = "2"
   
    if ($notif -eq "0"){
    notification
    $notif = "1"
    }

    else {
    #Notification déjà envoyée
    }
}

 #Si code = 0, on annule l'arret du PC et on reset les notifications
if ($code -eq "0")
{
shutdown /a
$notif = "0"
}
get-date -erroraction silen

1 .. 3 | ForEach {
			
		}
Start-Sleep -Seconds 10
}
