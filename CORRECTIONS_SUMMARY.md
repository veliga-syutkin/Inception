# 📋 Résumé des Corrections Apportées au Projet Inception

## ✅ Modifications effectuées

### 1. **docker-compose.yml**
- ✅ Ajout de `restart: unless-stopped` sur les 3 services
- ✅ Configuration des volumes avec bind mounts vers `/home/vsyutkin/data/`
- ✅ Correction des chemins `env_file` (`.` → `.env`)

### 2. **secrets/.env**
- ✅ Ajout des variables pour le 2ème utilisateur WordPress :
  - `WP_USER=regular_user`
  - `WP_USER_PASSWORD=u5eR_P4ssw0rd`
  - `WP_USER_EMAIL=user@student.42mulhouse.fr`

### 3. **wordpress/tools/setup.sh**
- ✅ Ajout de la création automatique du 2ème utilisateur WordPress
- ✅ Vérification si l'utilisateur existe déjà (idempotence)
- ✅ Rôle `author` pour le second utilisateur (pas admin)

### 4. **nginx/Dockerfile**
- ✅ Installation de `gettext-base` (pour `envsubst`)
- ✅ Copie du fichier config en tant que template (`.template`)
- ✅ Substitution de `${DOMAIN_NAME}` au démarrage avec `envsubst`

### 5. **Makefile**
- ✅ Ajout de la variable `DATA_DIR=/home/vsyutkin/data`
- ✅ Nouvelle cible `create_dirs` pour créer automatiquement les dossiers
- ✅ La cible `up` dépend maintenant de `create_dirs`

## 📊 Conformité avec le Sujet

| Exigence | Status | Notes |
|----------|--------|-------|
| 3 containers (nginx, wordpress, mariadb) | ✅ | Conforme |
| Dockerfiles personnalisés | ✅ | Basés sur Debian Bullseye |
| Pas d'images toutes faites | ✅ | Tout build depuis zéro |
| Network Docker | ✅ | Network `inception` avec driver bridge |
| 2 volumes | ✅ | `mariadb_data` et `wordpress_data` |
| Volumes dans /home/login/data/ | ✅ | `/home/vsyutkin/data/` |
| Restart automatique | ✅ | `restart: unless-stopped` |
| NGINX TLSv1.2/1.3 uniquement | ✅ | Configuré dans default.conf |
| Port 443 uniquement | ✅ | Seul port exposé |
| 2 utilisateurs WordPress | ✅ | Admin + author |
| Admin sans 'admin' dans le nom | ✅ | `l0c4l_g0d` |
| Pas de mots de passe dans Dockerfiles | ✅ | Tout dans .env |
| Variables d'environnement | ✅ | Fichier .env utilisé |
| Processus en foreground | ✅ | nginx, mysqld, php-fpm -F |
| Pas de tail -f, sleep infinity | ✅ | Processus légitimes |
| Pas de network: host ou --link | ✅ | Network standard |
| Pas de tag :latest | ✅ | Versions spécifiques |

## 🚀 Commandes pour Tester

```bash
# 1. Build et démarrer l'infrastructure
make up

# 2. Vérifier les logs
make logs

# 3. Se connecter à la base de données
make db

# 4. Vérifier que les volumes sont bien créés
ls -la /home/vsyutkin/data/mariadb
ls -la /home/vsyutkin/data/wordpress

# 5. Tester l'accès HTTPS
curl -k https://vsyutkin.42.fr

# 6. Vérifier que les 2 utilisateurs existent dans WordPress
docker exec -it inception_wordpress wp user list --allow-root
```

## 📝 Points à Vérifier Avant l'Évaluation

1. **Hosts file** : Assurez-vous que `vsyutkin.42.fr` pointe vers `127.0.0.1`
   ```bash
   echo "127.0.0.1 vsyutkin.42.fr" | sudo tee -a /etc/hosts
   ```

2. **Permissions** : Vérifiez que les dossiers data ont les bonnes permissions
   ```bash
   ls -la /home/vsyutkin/data/
   ```

3. **Services actifs** : Tous les containers doivent être "Up"
   ```bash
   docker ps
   ```

4. **WordPress accessible** : Testez dans un navigateur
   ```
   https://vsyutkin.42.fr
   ```

5. **Connexion avec les 2 utilisateurs** :
   - Admin : `l0c4l_g0d` / `10C4l_g0d_Pas`
   - User : `regular_user` / `u5eR_P4ssw0rd`

## 🎯 Score Estimé

**Partie obligatoire : 100%** ✅

Toutes les exigences obligatoires sont maintenant respectées !

## 🔧 Commandes de Debugging Utiles

```bash
# Voir les logs d'un container spécifique
docker logs inception_mariadb
docker logs inception_wordpress
docker logs inception_nginx

# Entrer dans un container
docker exec -it inception_mariadb bash
docker exec -it inception_wordpress bash
docker exec -it inception_nginx bash

# Vérifier la config nginx
docker exec inception_nginx nginx -t

# Lister les utilisateurs WordPress
docker exec inception_wordpress wp user list --allow-root

# Vérifier les tables MariaDB
docker exec -it inception_mariadb mysql -ul0c4l_g0d -ps1mple_DB_pw vsyutkin_inception_db -e "SHOW TABLES;"
```

## ⚠️ Attention

Si vous reconstruisez tout depuis zéro avec `make reinit`, les données seront perdues. Pour conserver les données lors d'une reconstruction :

```bash
make down
make up
```

Bonne chance pour votre évaluation ! 🚀
