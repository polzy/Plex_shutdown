## Plex_shutdown_V2

Le script est lancé sur un PC de bureau avec Plex Server depuis le planificateur de tâche Windows.
Le but est d'arrêter le PC quand aucun utilisateur n'est sur Plex avec une heure définie. 
Une option est aussi présente pour ne pas arrêter le serveur si Chrome est ouvert sur le PC

'Pour le moment je ne sais pas comment faire autrement, mais il faut mettre le chemin du script dans le Plex_shutdown_V2 ligne 9 (Je regarde plus tard)'

config.ini

```
#Nom du serveur Plex (Pour affichage)
Name=Plex Serveur
#Remplacer la clé d'API www.themoviedb.org
apiKey=#############################################
# Remplacer l'URL du webhook Discord par la valeur appropriée
webhookUrl=https://discord.com/api/webhooks/#############################################
# Remplacer par l'IP du serveur Plex
PMS_IP=192.168.1.100:32400
# Remplacer le token Plex
token=#############################################
#Temps en minutes pour l'arrêt du PC
timeout=20
# Définir l'option qui permet de prendre en compte ou non la condition "Chrome Ouvert"
checkChrome=$false
#Heure de début et de fin du script 0 = minuit, cette option permet de définir des heures de fonctionnements.
startTime=0
endTime=19
```
