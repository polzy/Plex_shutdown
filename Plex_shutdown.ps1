############################################################
#Condition : 
# installer le module dans un powershell admin : 
# install-Module BurntToast
# Install-Module PSDiscord
#A placer dans la planification de tâche. 
# Le script doit se lancer 1 fois par exemple a 00h
##########################################################################
#Config
$chemin_du_repertoire_script = ".\Plex_shutdown"
$PMS_IP='192.168.1.100:32400'
$TOKEN=''
#Si Chrome est ouvert, le shutdown est annulé
$chrome = "true"
#Webhook Discord
$Uri = ""
#GIF pour la notification Windows
$image_gif = "touz.gif"
#Temps avant l'arrêt du PC (600 = 10mn)
$secondes = "600"
##########################################################################
#Module pour les notification Windows
import-Module PSDiscord
import-Module BurntToast
$sec_min = $secondes / 60
$notif = "0"
$notif_chrome = "0"
$notif_cancel = "0"
$url = "http://" + $PMS_IP + "/status/sessions?X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$TOKEN"
#Notification Windows du lancement du script
New-BurntToastNotification -AppLogo $image_gif -Text "Plex", "Lancement du script d'inactivité de Plex."
$message = "Lancement du script d'inactivité de Plex."
notification
function notification {
#Notification Windows 
            New-BurntToastNotification -AppLogo $image_gif -Text "Plex", $message
            write-host $message
            #Notification Discord
            if ($Uri -notlike $null)
            {
        $nom_machine = [system.environment]::MachineName
		Send-DiscordMessage -WebHookUrl $Uri -Text $message
            }
}
function Show-Message {
#Popup 
            $Message = "Arrêt du PC dans $secondes secondes. Appuyer sur Annuler pour prolonger de $sec_min minutes."
            $Titre = "Plex"
            $btn = 1
            $Icon = 48
            [System.Windows.Forms.MessageBox]::Show($Message, $Titre , $Btn, $Icon)
            Return $Reponse
}
#Début de la boucle 
while (1)
	{
        $Chrome_app = get-process "chrome" -ea SilentlyContinue
        if(($chrome -eq "true") -And ($Chrome_app -eq $Null) -or ($chrome -eq "false")){
        $in = "0"
        }
        else {
                $in = "1"
                shutdown /a
                if($notif_chrome -eq "0"){
                $message = "Chrome est ouvert, pas de shutdown du serveur."
                notification
                $notif_chrome = "1"
                }
        }
if ($in -eq "0"){
$date = get-date
$sessionURL = invoke-webrequest $url
$xml = [xml]$sessionURL
$user = $xml.MediaContainer.Video.User.title
$session = $xml.MediaContainer.Video.grandparentTitle
$state = $xml.MediaContainer.video.Player.state
$object2 = ""
$list = @()
#Si il y a plus d'un utilisateur on fait cette boucle (a cause d'un bug 1 utilisateur)
if ($session.count -gt "1"){
    for ($i = 0; $i -lt $session.count; $i++) {
        $object2 = New-Object PSObject
        $object2 | Add-Member Noteproperty -Name User -Value $user[$i] 
        $object2 | Add-Member Noteproperty -Name Movie -Value $session[$i]
        $object2 | Add-Member Noteproperty -Name State -Value $state[$i]
        $list += $object2
    }
    }
    #Si il y a un utilisateur on fait cette boucle (a cause d'un bug 1 utilisateur)
    else{
        $object2 = New-Object PSObject
        $object2 | Add-Member Noteproperty -Name User -Value $user
        $object2 | Add-Member Noteproperty -Name Movie -Value $session
        $object2 | Add-Member Noteproperty -Name State -Value $state
        $list += $object2
    }
    if ($list -like "*playing*"){ 
        #Si un utilisateur relance un film, on passe variable code sur 0
        write-host "Un utilisateur est sur Plex. Utilisateur : " + $list.user + " - Lecture en cours : " + $list.Movie + " - statut : " + $list.state
        $code = "0"
        }
        Else {
        #Si Chrome est coupé et si 0 utilisateur sur Plex passage code = 1
        write-host "Aucun utilisateur sur Plex."
        $code = "1"
        }
    #Si code = 1, lancement de l'arret du PC
    if ($code -eq "1"){
        shutdown -s -f -t $secondes -c "Aucun utilisateur sur Plex, l'ordinateur va s'eteindre dans $sec_min minutes."
        $code = "2"
        if ($notif -eq "0"){
        $message = "Aucun utilisateur sur Plex :  Arret de " + $nom_machine + " dans " + $sec_min + " minutes."
        notification
        $notif = "1"
        $notif_cancel = "0"
        }
        else {
        #Notification déjà envoyée
        }
    }
#Si code = 0, on annule l'arret du PC et on reset les notifications
if ($code -eq "0")
{
shutdown /a
if($notif_cancel -eq "0"){
$message = "Un utilisateur est sur Plex. Utilisateur : " + $list.user + " - Lecture en cours : " + $list.Movie + " - statut : " + $list.state
notification
$notif_cancel = "1"
}
else {
    #Notification déjà envoyée
    }
}
}
get-date -erroraction SilentlyContinue
1 .. 3 | ForEach {			
		}
Start-Sleep -Seconds 10
}