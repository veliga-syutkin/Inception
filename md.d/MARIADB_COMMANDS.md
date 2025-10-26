# 🗄️ Guide MariaDB - Projet Inception

## Connexion

```bash
# En tant qu'utilisateur normal
make db

# En tant que root
make db-root
```

## Commandes Basiques

### Navigation

```sql
-- Lister toutes les bases de données
SHOW DATABASES;

-- Sélectionner la base de données
USE vsyutkin_inception_db;

-- Voir quelle base est active
SELECT DATABASE();

-- Lister les tables
SHOW TABLES;

-- Voir la structure d'une table
DESCRIBE wp_users;
DESCRIBE wp_posts;
DESCRIBE wp_options;
```

### Utilisateurs

```sql
-- Voir les utilisateurs WordPress
SELECT ID, user_login, user_email, user_registered, user_status 
FROM wp_users;

-- Voir les rôles des utilisateurs
SELECT u.user_login, m.meta_value as role
FROM wp_users u
JOIN wp_usermeta m ON u.ID = m.user_id
WHERE m.meta_key = 'wp_capabilities';

-- Voir tous les utilisateurs MariaDB
SELECT User, Host FROM mysql.user;

-- Voir les privilèges d'un utilisateur
SHOW GRANTS FOR 'l0c4l_g0d'@'%';
SHOW GRANTS FOR 'root'@'localhost';
```

### Contenu WordPress

```sql
-- Compter les posts par type
SELECT post_type, post_status, COUNT(*) as count 
FROM wp_posts 
GROUP BY post_type, post_status;

-- Voir les articles publiés
SELECT ID, post_title, post_date, post_status 
FROM wp_posts 
WHERE post_type = 'post' AND post_status = 'publish'
ORDER BY post_date DESC;

-- Voir les pages
SELECT ID, post_title, post_status 
FROM wp_posts 
WHERE post_type = 'page';

-- Voir les options WordPress importantes
SELECT option_name, option_value 
FROM wp_options 
WHERE option_name IN ('siteurl', 'home', 'blogname', 'admin_email');
```

### Statistiques

```sql
-- Taille de la base de données
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'vsyutkin_inception_db'
GROUP BY table_schema;

-- Taille par table
SELECT 
    table_name AS 'Table',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables
WHERE table_schema = 'vsyutkin_inception_db'
ORDER BY (data_length + index_length) DESC;

-- Nombre d'enregistrements par table
SELECT 
    table_name, 
    table_rows 
FROM information_schema.tables 
WHERE table_schema = 'vsyutkin_inception_db'
ORDER BY table_rows DESC;
```

### Administration

```sql
-- Voir les processus actifs
SHOW PROCESSLIST;

-- Voir les variables du serveur
SHOW VARIABLES LIKE '%version%';
SHOW VARIABLES LIKE '%character%';
SHOW VARIABLES LIKE '%bind%';

-- Voir le statut du serveur
SHOW STATUS;
SHOW STATUS LIKE 'Threads%';
SHOW STATUS LIKE 'Connections';
```

## Commandes Utiles pour le Debugging

```sql
-- Vérifier que les 2 utilisateurs WordPress existent
SELECT user_login, user_email, display_name 
FROM wp_users 
ORDER BY ID;

-- Vérifier les métadonnées utilisateurs (rôles)
SELECT u.user_login, m.meta_key, m.meta_value
FROM wp_users u
JOIN wp_usermeta m ON u.ID = m.user_id
WHERE m.meta_key LIKE '%capabilities%' OR m.meta_key LIKE '%user_level%';

-- Vérifier les connexions autorisées
SELECT User, Host, authentication_string 
FROM mysql.user 
WHERE User IN ('root', 'l0c4l_g0d');
```

## Raccourcis Clavier dans MySQL CLI

- `Ctrl + L` : Clear screen
- `Ctrl + C` : Annuler la commande en cours
- `Ctrl + D` ou `EXIT` : Quitter
- `↑` / `↓` : Naviguer dans l'historique des commandes
- `Tab` : Auto-complétion (parfois)

## Tips

- Toutes les commandes SQL doivent se terminer par `;`
- Utilisez `\G` au lieu de `;` pour un affichage vertical :
  ```sql
  SELECT * FROM wp_users\G
  ```
- Pour voir l'aide :
  ```sql
  HELP;
  ```

## Exemples de Modifications (À NE PAS FAIRE EN PROD)

```sql
-- Changer le mot de passe d'un utilisateur WordPress
UPDATE wp_users 
SET user_pass = MD5('nouveau_mot_de_passe') 
WHERE user_login = 'l0c4l_g0d';

-- Changer l'email admin
UPDATE wp_users 
SET user_email = 'newemail@example.com' 
WHERE user_login = 'l0c4l_g0d';

-- Réinitialiser tous les mots de passe (DANGER!)
-- NE FAITES CECI QUE EN DEV!
```

## Sortie / Exit

```sql
EXIT;
-- ou
\q
-- ou
QUIT;
-- ou simplement
Ctrl + D
```
