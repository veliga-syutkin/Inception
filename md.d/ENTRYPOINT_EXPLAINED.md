# 🔧 MariaDB Entrypoint Script - Explication Détaillée

## 📋 Vue d'ensemble

Le fichier `entrypoint.sh` est le **point d'entrée** du container MariaDB. Il est exécuté au démarrage du container et a pour responsabilités :

1. ✅ Initialiser la base de données si elle n'existe pas
2. ✅ Créer les utilisateurs et définir leurs privilèges
3. ✅ Démarrer le serveur MariaDB en mode production

## 🏗️ Architecture Générale

```
┌─────────────────────────────────────────────────────┐
│         Container MariaDB démarre                    │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│  Est-ce que /var/lib/mysql/mysql existe ?          │
├─────────────────┬───────────────────────────────────┤
│      OUI        │              NON                   │
│  (déjà init)    │         (1ère fois)               │
└────────┬────────┴───────────┬───────────────────────┘
         │                    │
         │                    ▼
         │    ┌─────────────────────────────────────┐
         │    │  1. Initialiser la structure DB     │
         │    │     (mysql_install_db)              │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  2. Générer init.sql                │
         │    │     (script init.sh)                │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  3. Démarrer serveur temporaire     │
         │    │     (mode skip-grant-tables)        │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  4. Créer la base de données        │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  5. Redémarrer en mode sécurisé     │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  6. Configurer root password        │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  7. Appliquer init.sql              │
         │    │     (créer users, privilèges)       │
         │    └──────────────┬──────────────────────┘
         │                   │
         │                   ▼
         │    ┌─────────────────────────────────────┐
         │    │  8. Nettoyer init.sql (sécurité)    │
         │    └──────────────┬──────────────────────┘
         │                   │
         └───────────────────┴────────────────────────┐
                             │                         │
                             ▼                         │
              ┌──────────────────────────────┐        │
              │  Démarrer MariaDB (prod)     │        │
              │  exec mysqld                 │        │
              │  (processus principal)       │        │
              └──────────────────────────────┘        │
                                                       │
```

## 📖 Analyse Ligne par Ligne

### **Phase 0 : Variables et Vérifications Initiales**

```bash
DATADIR="/var/lib/mysql"
INIT_SQL="/docker-entrypoint-initdb.d/init.sql"
```

**Pourquoi ?**
- `DATADIR` : Emplacement standard où MariaDB stocke ses données
- `INIT_SQL` : Fichier SQL généré contenant les commandes d'initialisation

---

### **Phase 1 : Vérification de l'Initialisation**

```bash
if [ ! -d "$DATADIR/mysql" ]; then
    echo "[ENTRYPOINT] Initializing MariaDB data directory..."
    mysql_install_db --datadir="$DATADIR" --user=mysql >/dev/null
fi
```

**Logique :**
- Si le dossier `mysql/` n'existe pas dans `/var/lib/mysql/`
- Alors c'est la **première fois** que le container démarre
- On initialise la structure de la base avec `mysql_install_db`

**Résultat :**
- Création des tables système (`mysql.user`, `mysql.db`, etc.)
- Structure de base pour que MariaDB puisse fonctionner

---

### **Phase 2 : Génération du Script SQL**

```bash
if [ ! -f "$INIT_SQL" ]; then
    echo "[ENTRYPOINT] init.sql not found, generating a new one..."
    sh /docker-entrypoint-initdb.d/init.sh
```

**Logique :**
- Si `init.sql` n'existe pas encore (ou a été effacé)
- Appeler `init.sh` qui génère le fichier SQL avec :
  - Mot de passe root
  - Création de la base de données
  - Création des utilisateurs applicatifs
  - Attribution des privilèges

**Contenu typique d'init.sql :**
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
CREATE DATABASE vsyutkin_inception_db;
CREATE USER 'l0c4l_g0d'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON vsyutkin_inception_db.* TO 'l0c4l_g0d'@'%';
FLUSH PRIVILEGES;
```

---

### **Phase 3 : Démarrage Temporaire #1 (Mode Skip-Grant-Tables)**

```bash
mysqld_safe --skip-networking --skip-grant-tables --socket=/var/run/mysqld/mysqld.sock &
MYSQL_PID=$!
```

**Pourquoi ce mode ?**
- `--skip-grant-tables` : Ignore les permissions, permet de se connecter sans mot de passe
- `--skip-networking` : N'écoute pas sur le réseau (sécurité pendant l'init)
- `&` : Lance en arrière-plan
- `MYSQL_PID=$!` : Sauvegarde le PID pour pouvoir l'arrêter plus tard

**But :**
- Créer la base de données sans avoir besoin d'authentification
- Temporaire, uniquement pour l'initialisation

---

### **Phase 4 : Attente de la Disponibilité**

```bash
_ready=0
for i in {1..30}; do
    if mysqladmin ping -u root --silent; then
        echo "[ENTRYPOINT] MariaDB is ready"
        _ready=1
        break
    fi
    echo "[ENTRYPOINT] Still waiting... attempt $i/30"
    sleep 1
done
```

**Logique :**
- Boucle jusqu'à 30 secondes
- Teste avec `mysqladmin ping` si le serveur répond
- Si succès : sort de la boucle
- Si échec après 30s : arrête tout et signale une erreur

**Pourquoi ?**
- MariaDB prend quelques secondes pour démarrer
- Impossible d'exécuter des commandes SQL avant qu'il soit prêt

---

### **Phase 5 : Création de la Base de Données**

```bash
mysql --skip-password --protocol=socket -h localhost -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"
```

**Détails :**
- `--skip-password` : Pas besoin de mot de passe (mode skip-grant-tables)
- `--protocol=socket` : Utilise le socket Unix (plus rapide et sécurisé)
- `-e` : Exécute une commande SQL directement

**Résultat :**
- Base de données `vsyutkin_inception_db` créée

---

### **Phase 6 : Arrêt du Serveur Temporaire**

```bash
mysqladmin --skip-password --protocol=socket -h localhost shutdown
```

**Pourquoi ?**
- On doit redémarrer sans `--skip-grant-tables`
- Pour pouvoir définir le mot de passe root en toute sécurité

---

### **Phase 7 : Redémarrage #2 (Toujours en Skip-Grant-Tables)**

```bash
mysqld_safe --skip-networking --skip-grant-tables --socket=/var/run/mysqld/mysqld.sock &
```

**But :**
- Définir le mot de passe root
- En mode skip-grant-tables pour pouvoir modifier `mysql.global_priv`

---

### **Phase 8 : Configuration du Mot de Passe Root**

```bash
mysql --skip-password --protocol=socket -h localhost <<-EOSQL
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    
    UPDATE mysql.global_priv 
    SET priv=JSON_SET(
        COALESCE(priv,'{}'),
        '$.plugin', 'mysql_native_password',
        '$.authentication_string', CONCAT('*', UPPER(SHA1(UNHEX(SHA1('${MYSQL_ROOT_PASSWORD}')))))
    )
    WHERE User='root';
    
    FLUSH PRIVILEGES;
EOSQL
```

**Explication SQL :**

1. **Nettoyage des utilisateurs anonymes**
   ```sql
   DELETE FROM mysql.user WHERE User='';
   ```
   Supprime les comptes sans nom (sécurité)

2. **Restriction de root**
   ```sql
   DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
   ```
   Root ne peut se connecter que localement

3. **Définition du mot de passe**
   ```sql
   UPDATE mysql.global_priv SET priv=JSON_SET(...)
   ```
   - MariaDB 10.11+ utilise `mysql.global_priv` (pas `mysql.user`)
   - Stocke les privilèges en JSON
   - Hash le mot de passe avec SHA1 double (méthode `mysql_native_password`)

4. **Application des changements**
   ```sql
   FLUSH PRIVILEGES;
   ```
   Recharge les tables de privilèges en mémoire

---

### **Phase 9 : Redémarrage #3 (Mode Normal avec Authentification)**

```bash
mysqladmin --skip-password --protocol=socket -h localhost shutdown

mysqld_safe --bind-address=0.0.0.0 --port=3306 --user=mysql --datadir=/var/lib/mysql --socket=/var/run/mysqld/mysqld.sock &
```

**Changements :**
- ✅ `--bind-address=0.0.0.0` : Écoute sur toutes les interfaces réseau
- ✅ `--port=3306` : Port standard MySQL
- ❌ Plus de `--skip-grant-tables` : Authentification activée

**Pourquoi ?**
- Maintenant que root a un mot de passe, on peut démarrer normalement
- Le serveur accepte les connexions réseau (pour WordPress)

---

### **Phase 10 : Application de init.sql**

```bash
mysql -u root -p"$MYSQL_ROOT_PASSWORD" --protocol=socket -h localhost < "$INIT_SQL"
```

**Action :**
- Se connecte avec le mot de passe root
- Exécute tout le contenu de `init.sql` :
  - Création des utilisateurs (`l0c4l_g0d`)
  - Attribution des privilèges
  - Configuration des accès réseau

---

### **Phase 11 : Nettoyage du Fichier SQL**

```bash
echo "" > $INIT_SQL
```

**Sécurité :**
- Efface le contenu de `init.sql` (contient des mots de passe en clair)
- Le fichier vide servira de "marqueur" : s'il existe (même vide), on ne refait pas l'init

---

### **Phase 12 : Démarrage Production**

```bash
echo "[ENTRYPOINT] Starting MariaDB..."
rm -f /var/run/mysqld/mysqld.pid

exec mysqld \
    --user=mysql \
    --datadir=/var/lib/mysql \
    --bind-address=0.0.0.0 \
    --port=3306 \
    --socket=/var/run/mysqld/mysqld.sock
```

**Important : `exec`**
- Remplace le processus du shell par `mysqld`
- `mysqld` devient le **PID 1** du container
- Quand `mysqld` s'arrête, le container s'arrête
- Respecte les bonnes pratiques Docker (pas de processus parent inutile)

**Configuration :**
- `--user=mysql` : Tourne avec l'utilisateur non-root `mysql`
- `--bind-address=0.0.0.0` : Accessible depuis le réseau Docker
- `--port=3306` : Port standard
- `--socket=...` : Socket Unix pour connexions locales

---

## 🔄 Diagramme de Flux Simplifié

```
┌──────────────────────────────────────────┐
│  Container démarre                       │
└────────────┬─────────────────────────────┘
             │
             ▼
    ┌─────────────────┐
    │ DB existe ?     │
    └────┬────────┬───┘
         │ NON    │ OUI
         │        │
         ▼        │
    ┌─────────────┴──────────┐
    │ INITIALISATION         │
    │                        │
    │ 1. mysql_install_db    │
    │ 2. Générer init.sql    │
    │ 3. Serveur temp #1     │
    │ 4. CREATE DATABASE     │
    │ 5. Arrêt               │
    │ 6. Serveur temp #2     │
    │ 7. SET root password   │
    │ 8. Arrêt               │
    │ 9. Serveur temp #3     │
    │ 10. Appliquer init.sql │
    │ 11. Effacer init.sql   │
    │ 12. Arrêt              │
    └────────────┬───────────┘
                 │
                 ▼
    ┌────────────────────────┐
    │  PRODUCTION            │
    │  exec mysqld           │
    │  (PID 1, foreground)   │
    └────────────────────────┘
```

---

## 🎯 Concepts Clés

### **1. Idempotence**
Le script peut être exécuté plusieurs fois sans problème :
- Si la DB existe déjà → skip l'initialisation
- Si `init.sql` existe (vide) → skip la configuration

### **2. Sécurité**
- Suppression des utilisateurs anonymes
- Restriction de root à localhost seulement
- Effacement de `init.sql` après utilisation
- Pas de mot de passe en clair dans les logs

### **3. Mode Skip-Grant-Tables**
- Permet de bootstrapper la sécurité
- Utilisé UNIQUEMENT pendant l'init
- Jamais exposé sur le réseau (`--skip-networking`)

### **4. PID 1 et `exec`**
- Le dernier `exec mysqld` remplace le shell
- `mysqld` devient le processus principal du container
- Garantit que les signaux (SIGTERM) sont correctement gérés
- Conforme aux best practices Docker

---

## ⚠️ Points d'Attention

### **Erreurs Possibles**

1. **Timeout pendant l'attente**
   ```
   MariaDB did not become ready in time
   ```
   → Le serveur n'a pas démarré en 30s (disque lent, RAM insuffisante)

2. **Erreur de connexion**
   ```
   Connection failed
   ```
   → Socket non accessible, permissions incorrectes

3. **Échec de création de DB**
   ```
   Failed to create database
   ```
   → Nom de DB invalide, ou problème de permissions

### **Volume Persistence**

Le dossier `/var/lib/mysql` est monté en volume :
- **Avantage** : Les données persistent entre redémarrages
- **Conséquence** : L'initialisation ne se fait qu'UNE FOIS
- Pour réinitialiser : `make fclean` ou `make reinit`

---

## 🔍 Debug et Logs

Le script inclut beaucoup de `echo` :
```bash
docker logs inception_mariadb
```

Vous verrez chaque étape :
- `[ENTRYPOINT] Initializing MariaDB data directory...`
- `[ENTRYPOINT] MariaDB is ready`
- `[ENTRYPOINT] Setting root password...`
- etc.

---

## 📚 Commandes Utiles pour Comprendre

```bash
# Voir le processus principal du container
docker top inception_mariadb

# Entrer dans le container
docker exec -it inception_mariadb bash

# Vérifier que mysqld est bien PID 1
ps aux

# Voir les fichiers de la DB
ls -la /var/lib/mysql/

# Vérifier le socket
ls -la /var/run/mysqld/mysqld.sock
```

---

## 🎓 Résumé

Le script `entrypoint.sh` orchestre l'initialisation complète d'un serveur MariaDB sécurisé :

1. ✅ Détecte si c'est la première fois
2. ✅ Initialise la structure de base
3. ✅ Configure root avec un mot de passe
4. ✅ Crée la base de données applicative
5. ✅ Crée les utilisateurs avec privilèges
6. ✅ Nettoie les secrets temporaires
7. ✅ Démarre en production avec `exec`

**Résultat final :**
- Serveur MariaDB sécurisé
- Base de données prête
- Utilisateurs configurés
- Accessible par WordPress via le réseau Docker
- Processus principal (PID 1) pour une gestion propre du container
