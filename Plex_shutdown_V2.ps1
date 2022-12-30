#Module a installer pour les notifications Discord
# Install-Module PSDiscord
# Installez le module BurntToast si ce n'est pas déjà fait
#Install-Module -Name BurntToast
# Importez le module
Import-Module BurntToast
# Charger le fichier de configuration
$config = Get-Content -Path .\config.ini

# Créer un objet de configuration à partir du fichier
$configObject = New-Object -TypeName System.Collections.Specialized.NameValueCollection
foreach ($line in $config) {
    if ($line -match '^(\w+)\s*=\s*(.*)$') {
        $configObject.Add($matches[1], $matches[2])
    }
}
$name = $configObject.Get('Name')
$webhookUrl = $configObject.Get('webhookUrl')
$token =  $configObject.Get('token')
#Heure de début et de fin du script
$start = $configObject.Get('startTime')
$end = $configObject.Get('endTime')
$startTime = Get-Date -Hour $start -Minute 0 -Second 0
$endTime = Get-Date -Hour $end -Minute 0 -Second 0
$checkChrome = $configObject.Get('checkChrome')
# Déclaration de la variable qui indique si la notification a été envoyée
$notificationSent = $false
$notificationDiscordSent = $false
$url = "http://" + $configObject.Get('PMS_IP') + "/status/sessions?X-Plex-Client-Identifier=$CLIENT_IDENT&X-Plex-Token=$TOKEN"
# Variable to track the remaining timeout period
$remainingTimeout = $configObject.Get('timeout')

# Function to send a notification to Discord
function sendNotificationToDiscord($message)
{
   # Send-DiscordMessage -WebHookUrl $apiKey -Text $message
    #Notification Discord
    if ($webhookUrl  -notlike $null)
    {
# Effectuer la recherche de film
$query = $($movie.movie)
$apiKey = $configObject.Get('apiKey')
if($query){
$searchResults = Invoke-RestMethod -Uri "https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query"
# Récupérer le premier résultat de la recherche
$movie = $searchResults.results[0]
}
# Récupérer l'URL de l'affiche du film
$posterUrl = "https://image.tmdb.org/t/p/w500/$($movie.poster_path)"
# Créer l'objet auteur
$author = New-DiscordAuthor -Name $name -IconUrl "https://previews.123rf.com/images/axsimen/axsimen1712/axsimen171200017/91263154-ic%C3%B4ne-de-plongeur-ventouse-en-caoutchouc-sur-le-b%C3%A2ton-utilis%C3%A9-pour-lib%C3%A9rer-les-drains-bouch%C3%A9s-outil-.jpg"
# Créer l'objet champ personnalisé
$field = New-DiscordField -Name 'Arret du serveur $name' -Value '' -Inline $true
# Créer l'objet image
$image = New-DiscordImage -Url $posterUrl
# Créer l'objet embed
$embed = New-DiscordEmbed -Title $message -Description '' -Color BlueViolet -Author $author -Fields $field -Image $image
# Envoyer la notification sur le canal de Discord
Send-DiscordMessage -WebHookUrl $webhookUrl -Embed $embed
    }
}
# Function to check if a user is watching a movie on Plex
function checkUserWatchingMovie
{
    # Get the list of active sessions on the Plex server
    $sessionURL = Invoke-WebRequest -Uri $url
    # Parse the response to get the list of active sessions
    $sessions= [xml]$sessionURL
    $activeSessions = $sessions.MediaContainer.Video
# Initialize an array to store the movie details
$movies = @()

# Check if any active sessions are movies
foreach($session in $activeSessions)
{
    # Check if the session is a movie
    if($session.Type -eq 'episode' -or $session.Type -eq 'movie')
    {
        # Get the user and movie details
        $user = $session.User.title
        $movie = $session.title
        $thumb = $session.thumb

        # Add the user and movie details to the array
        $movies += @{'user'=$user; 'movie'=$movie}
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
                        write-host "Attention! Il semble que personne ne regarde de film sur Plex. Le PC va s'arreter dans $remainingTimeout minutes."
                        sendNotificationToDiscord("Attention! Il semble que personne ne regarde de film sur Plex. Le PC va s'arreter dans $remainingTimeout minutes.")
                       
                        $remainingTimeout -= 1
                        $notificationDiscordSent = $false
                    }
                    # If movies are found, reset the remaining timeout period and send a notification with the movie details
                    else
                    {
                        # Initialize a string to store the movie details
                        $movieString = ''
    
                        # Loop through the array of movies
                        foreach($movie in $movies)
                        {
                            # Add the movie details to the string
                            $movieString = "Le film $($movie.movie) est en cours de lecture par l'utilisateur $($movie.user). "
    
                            # Send the notification with the movie details
                            if (!$notificationDiscordSent) {
                            sendNotificationToDiscord("$movieString L'arrêt du PC a été prolongé.")
                            $notificationDiscordSent = $true
                            }
                        }
                        $remainingTimeout = $timeout
                    }
}
# Main loop
while(1 -eq 1)
{
    
  # Vérification si la notification a déjà été envoyée
  if (!$notificationSent) {
    # Envoi de la notification
    write-host "Début du script d'inactivité."
    New-BurntToastNotification -Text $name, "Début du script d'inactivité."
    # Mise à jour de la variable pour indiquer que la notification a été envoyée
    $notificationSent = $true
  }
    $currentTime = Get-Date
    if (($currentTime -ge $startTime) -and ($currentTime -lt $endTime)) {
        if ($checkChrome -eq "$true") {
            $chromeProcess = Get-Process chrome
            if ($chromeProcess -ne $null) {
                # Code à exécuter si Google Chrome est ouvert
                write-host "Google Chrome est ouvert"
                #write-host "L'option checkChrome est sur True, si Chrome est ouvert le Serveur ne s'arrete pas."
            } else {
                # Code à exécuter si Google Chrome n'est pas ouvert
                write-host "Google Chrome est fermé"
                MainScript
                    }
                    
    }
    else {
        # Code à exécuter si l'option "checkChrome" ne doit pas être prise en compte
        #write-host "Google Chrome non pris en compte."
        MainScript
    }
    }else{
        #write-host "L'heure actuelle se situe en dehors de la plage horaire de lancement du script."
    }
# Wait for one minute before checking again
Start-Sleep -Seconds 60

# If the remaining timeout period has reached 0, shut down the PC
if($remainingTimeout -eq 0)
{
    Stop-Computer
}
}