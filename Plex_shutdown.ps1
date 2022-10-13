############################################################
# installer les modules dans un powershell admin : 
# install-Module BurntToast
# Install-Module PSDiscord
#A placer dans la planification de tâche. 
# Le script doit se lancer 1 fois par exemple a 00h
##########################################################################
#Config
$chemin_du_repertoire_script = "C:\Users\maxim\OneDrive\Documents\plex_scripts\Plex_shutdown"
#IP plex
$PMS_IP='192.168.1.100:32400'
#Action : s = shutdown  h = Hibernate
$action_pw = "h"
#Si 'true' le script est annulé si Chrome est ouvert
$chrome = "false"
#GIF pour la notification Windows
$image_gif = "$chemin_du_repertoire_script\touz.gif"
#Temps avant l'arrêt du PC (600 = 10mn)
$secondes = "600"
#Config fin
##########################################################################
import-Module PSDiscord
import-Module BurntToast
$TOKEN= get-content "$chemin_du_repertoire_script\TOKEN.txt"
$Uri = get-content "$chemin_du_repertoire_script\WEBHOOK_DISCORD.txt"
$sec_min = $secondes / 60
$notif = "0"
$notif_chrome = "0"
$shutdown = "0"
$url = "http://" + $PMS_IP + "/status/sessions?X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$TOKEN"
#Notification Windows du lancement du script
New-BurntToastNotification -AppLogo $image_gif -Text "Plex", "Lancement du script d'inactivité de Plex."
$message = "Lancement du script d'arret de Plex."
notification
function notification {
#Notification Windows 
            New-BurntToastNotification -AppLogo $image_gif -Text "Plex", $message
            write-host $message
            #Notification Discord
            if ($Uri -notlike $null)
            {
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
        $date_minutes = Get-Date -Format HH:mm
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
    $sessionURL = invoke-webrequest $url
    $xml = [xml]$sessionURL
    $user = $xml.MediaContainer.Video.User.title
    $session = $xml.MediaContainer.Video.title
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
        #Si un utilisateur est sur Plex on passe variable shutdown sur 0
        $shutdown = "0"
        if($notif -eq "0"){
            $message =  "Un utilisateur est sur Plex. Utilisateur : " + $list.user + " - Lecture en cours : " + $list.Movie + " - statut : " + $list.state + ". Pas d'arret de Plex."
            write-host $message 
            notification
            $notif = "1"
        }
        }
        Else {
        #Si pas d'utilisateur sur plex shutdown sur 1
        write-host "Aucun utilisateur sur Plex. Lancement de la procedure d'arret de Plex."
        $notif = "0"
        if($shutdown -eq "0"){
        $shutdown = "1"
    }
        }
    #Si code = 1, lancement de l'arret du PC
    if ($shutdown -eq "1"){
        $Temp_add = (Get-date).AddMinutes($sec_min)
        $temp_off = Get-Date $Temp_add -Format HH:mm
        $message = "Aucun utilisateur sur Plex : Plex va s'eteindre a $temp_off"
        write-host $message
        notification
        $shutdown = "2"
    }
    if ($shutdown -eq "2"){
        write-host "Plex va s'eteindre a $temp_off il est $date_minutes"
        if ($temp_off -le $date_minutes){
        if($action_pw -eq "s"){
            shutdown -s -f
        }
        else{
            shutdown -$action_pw
        }
        }
    }
    }
1 .. 3 | ForEach {			
		}
Start-Sleep -Seconds 10
}