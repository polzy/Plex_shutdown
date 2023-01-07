$PSDefaultParameterValues['*:Encoding'] = 'utf8'
#Module a installer pour les notifications Discord
# Install-Module PSDiscord
# Installez le module BurntToast si ce n'est pas déjà fait
#Install-Module -Name BurntToast
# Importez le module pour les notifications Windows
#Import-Module BurntToast

# Charger le fichier de configuration pour le moment, mettre le chemain ici, je ne trouve pas pour faire autrement .. 
$chemin_du_repertoire_script = "C:\Users\maxim\OneDrive\Documents\plex_scripts\Plex_shutdown"

# Ici on test si config.ini est présent
$config = Get-Content -Path "$chemin_du_repertoire_script\config.ini"
if(!$config ){
    write-host "Impossible de récupérer le fichier de configuration. Contactez votre admin d'amour sur discord avec un petit mot doux."
    pause
}

# Créer un objet de configuration à partir du fichier config.ini
$configObject = New-Object -TypeName System.Collections.Specialized.NameValueCollection
foreach ($line in $config) {
    if ($line -match '^(\w+)\s*=\s*(.*)$') {
        $configObject.Add($matches[1], $matches[2])
    }
}

$name = $configObject.Get('Name')
$webhookUrl = $configObject.Get('webhookUrl')
$token =  $configObject.Get('token')
$start = $configObject.Get('startTime')
$end = $configObject.Get('endTime')
$startTime = Get-Date -Hour $start -Minute 0 -Second 0
$endTime = Get-Date -Hour $end -Minute 0 -Second 0
$checkChrome = $configObject.Get('checkChrome')
# Déclaration de la variable qui indique si la notification a été envoyée
$global:notificationSent = $false
$global:notificationDiscordSent2 = $false
$global:notificationDiscordSent = $false
$url = "http://" + $configObject.Get('PMS_IP') + "/status/sessions?X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$TOKEN"
# Variable pour suivre le délai d'expiration restant
$global:remainingTimeout = $configObject.Get('timeout')
$timeout = $configObject.Get('timeout')
# Fin du fichier config.ini

# Fonction pour envoyer une notification à Discord
function sendNotificationToDiscord($message)
{
    # Vérifier si le webhook est présent dans le config.ini
    if ($webhookUrl  -notlike $null)
    {

# Effectuer la recherche de film
$query = $($movie.movie)
$apiKey = $configObject.Get('apiKey')

# Si c'est une série
if($movie.episode){
    $query = $($movie.movie)
    $searchResults = Invoke-RestMethod -Uri "https://api.themoviedb.org/3/search/tv?api_key=$apiKey&query=$query"  
}
# Si c'est un film
else{
    $query = $($movie.movie)
    $searchResults = Invoke-RestMethod -Uri "https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query"
}
# Récupérer le premier résultat de la recherche
$movie_poster = $searchResults.results[0]

# Récupérer l'URL de l'affiche du film
$posterUrl = "https://image.tmdb.org/t/p/w500/$($movie_poster.poster_path)"
# Créer l'objet auteur
$author = New-DiscordAuthor -Name $name -IconUrl "https://previews.123rf.com/images/axsimen/axsimen1712/axsimen171200017/91263154-ic%C3%B4ne-de-plongeur-ventouse-en-caoutchouc-sur-le-b%C3%A2ton-utilis%C3%A9-pour-lib%C3%A9rer-les-drains-bouch%C3%A9s-outil-.jpg"
# Créer l'objet champ personnalisé
$field = New-DiscordField -Name 'Arret du serveur $name' -Value '' -Inline $true
# Créer l'objet image
$image = New-DiscordImage -Url $posterUrl
# Créer l'objet embed
$embed = New-DiscordEmbed -Title $Message -Description '' -Color BlueViolet -Author $author -Fields $field -Image $image
# Envoyer la notification sur le canal de Discord
Send-DiscordMessage -WebHookUrl $webhookUrl -Embed $embed 

    }
}
# Fonction pour vérifier si un utilisateur regarde un film sur Plex
function checkUserWatchingMovie
{
    $activeSessions = @()
    # Obtenir la liste des sessions actives sur le serveur Plex
    $sessionURL = Invoke-WebRequest -Uri $url
    # Analyser la réponse pour obtenir la liste des sessions actives
    $sessions= [xml]$sessionURL
    $activeSessions = $sessions.MediaContainer.Video
# Initialiser un tableau pour stocker les détails du film
$movies = @()

# Check if any active sessions are movies
foreach($session in $activeSessions)
{
    # Vérifiez si la session est un film ou une série
    if($session.Type -eq 'episode' -or $session.Type -eq 'movie')
    {
        # Obtenir les détails de l'utilisateur et du film ou série
        #Si c'est une série
        if($session.Type -eq 'episode')
        {
        $user = $session.User.title
        $movie = $session.grandparentTitle
        $episode = $session.title
        $thumb = $session.thumb
        $type = $session.Type
        # Ajouter les détails de l'utilisateur et du film au tableau
        $movies += @{'user'=$user; 'movie'=$movie; 'episode'=$episode; 'type'=$type}
        }
        #Si c'est un film
        if($session.Type -eq 'movie'){
            $user = $session.User.title
            $movie = $session.title
            $thumb = $session.thumb
            $type = $session.Type
            # Ajouter les détails de l'utilisateur et du film au tableau
            $movies += @{'user'=$user; 'movie'=$movie}
        }
    }
}
return $movies
}

function MainScript
{
                    # Check if a user is watching a movie on Plex
                    $movies = checkUserWatchingMovie
                    # If no movies are found, send a notification to Discord and decrease the remaining timeout period
                    if($movies.Count -eq 0)
                    {
                        if($global:notificationDiscordSent2 -like $false -or $global:remainingTimeout -eq "5" -or $global:remainingTimeout -eq "2" -or $global:remainingTimeout -eq "1"){
                        write-host "[LOG]Attention! Il semble que personne ne regarde de film sur Plex. Le PC va s'arreter dans $global:remainingTimeout minutes."
                        $message_arret = "Attention! Il semble que personne ne regarde de film sur Plex. Le PC va s'arreter dans $global:remainingTimeout minutes."
                        sendNotificationToDiscord($message_arret)

                        $global:notificationDiscordSent = $false
                        $global:notificationDiscordSent2 = $true
                        }
                        $global:remainingTimeout -= 1
                        write-host "[LOG]Compteur a $global:remainingTimeout minutes"
                    }
                    # Si des films sont trouvés, réinitialisez le délai d'attente restant et envoyez une notification avec les détails du film
                    else
                    {
                        # Initialiser une chaîne pour stocker les détails du film
                        $movieString = ''
    
                        # Parcourez les films
                        if ($global:notificationDiscordSent  -eq $false) {
                        foreach($movie in $movies)
                        {
                            # Ajouter les détails du film à la chaîne
                            if($movie.type -eq "episode"){
                                $movieString = "La serie '$($movie.movie) - $($movie.episode)' est en cours de lecture par l'utilisateur $($movie.user). "
                            }else{
                            $movieString = "Le film '$($movie.movie)' est en cours de lecture par l'utilisateur $($movie.user). "
                            }
                            # Envoyer la notification avec les détails du film
                           
                            sendNotificationToDiscord("$movieString L'arret du PC est prolonge.")
                            $global:notificationDiscordSent = $true
                            $global:notificationDiscordSent2 = $false
                            }
                        }
                        write-host "[LOG]Compteur a $global:remainingTimeout minutes"
                        $global:remainingTimeout = $timeout
                    }
}
# Main loop
while(1 -eq 1)
{
  # Vérification si la notification a déjà été envoyée
  if ($global:notificationSent  -eq $false) {
    # Envoi de la notification
    write-host "Début du script d'inactivite."
    # Mise à jour de la variable pour indiquer que la notification a été envoyée
    $global:notificationSent = $true
  }
    $currentTime = Get-Date
    if (($currentTime -ge $startTime) -and ($currentTime -lt $endTime)) {
        if ($checkChrome -eq "$true") {
            $chromeProcess = Get-Process chrome
            if ($chromeProcess -ne $null) {
                # Code à exécuter si Google Chrome est ouvert
                write-host "[LOG]Google Chrome est ouvert."
                #write-host "L'option checkChrome est sur True, si Chrome est ouvert le Serveur ne s'arrete pas."
            } else {
                # Code à exécuter si Google Chrome n'est pas ouvert
                write-host "[LOG]Google Chrome est fermé."
                MainScript
                    }
    }
    else {
        # Code à exécuter si l'option "checkChrome" ne doit pas être prise en compte config.ini
        MainScript
    }
    }else{
        # L'heure actuelle se situe en dehors de la plage horaire de lancement du script dans le config.ini.
    }
# Attendez une minute avant de vérifier à nouveau
Start-Sleep -Seconds 60

# Si le délai d'attente restant a atteint 0, éteignez le PC
if($global:remainingTimeout -eq 0)
{
    sendNotificationToDiscord("Arret du PC.")
    Start-Sleep 1
    Stop-Computer
}
}