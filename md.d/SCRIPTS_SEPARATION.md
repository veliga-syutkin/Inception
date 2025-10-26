# 🔄 Séparation des Responsabilités : entrypoint.sh vs init.sh

## 📋 Vue d'ensemble

Après optimisation, les deux scripts ont des rôles **bien distincts** :

```
┌─────────────────────────────────────────────────────────┐
│               ENTRYPOINT.SH                             │
│  Responsable de l'infrastructure système               │
├─────────────────────────────────────────────────────────┤
│  ✅ Initialisation de la structure DB (mysql_install_db)│
│  ✅ Configuration du compte root                        │
│  ✅ Création de la base de données                      │
│  ✅ Gestion du cycle de vie du serveur                  │
│  ✅ Sécurisation (suppression users anonymes)           │
└─────────────────────────────────────────────────────────┘
                          │
                          │ Appelle
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    INIT.SH                              │
│  Responsable de la configuration applicative            │
├─────────────────────────────────────────────────────────┤
│  ✅ Génération de init.sql                              │
│  ✅ Création du user applicatif (l0c4l_g0d)             │
│  ✅ Attribution des privilèges sur la DB app            │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Responsabilités Détaillées

### **ENTRYPOINT.SH - Infrastructure Système**

| Tâche | Description | Quand |
|-------|-------------|-------|
| **Détection première exécution** | Vérifie si `/var/lib/mysql/mysql` existe | Toujours |
| **Installation DB** | `mysql_install_db` crée la structure | 1ère fois uniquement |
| **Configuration root** | Définit le mot de passe root via `mysql.global_priv` | 1ère fois uniquement |
| **Création base** | `CREATE DATABASE vsyutkin_inception_db` | 1ère fois uniquement |
| **Nettoyage sécurité** | Supprime users anonymes et root distant | 1ère fois uniquement |
| **Démarrage production** | Lance `mysqld` en PID 1 | Toujours |

### **INIT.SH - Configuration Applicative**

| Tâche | Description | Quand |
|-------|-------------|-------|
| **Génération init.sql** | Crée le fichier SQL avec les commandes | Appelé par entrypoint.sh |
| **User applicatif** | Crée `l0c4l_g0d` avec mot de passe | Exécuté par entrypoint.sh |
| **Privilèges** | `GRANT ALL ON vsyutkin_inception_db.*` | Exécuté par entrypoint.sh |

## 📊 Flux d'Exécution Optimisé

```
Container démarre
       │
       ▼
┌──────────────────┐
│  entrypoint.sh   │
└────────┬─────────┘
         │
         ├─► [Phase 1] DB existe ? NON → mysql_install_db
         │
         ├─► [Phase 2] init.sql existe ? NON → appelle init.sh
         │                                      │
         │                                      └─► Génère init.sql
         │                                          (UNIQUEMENT user app)
         │
         ├─► [Phase 3] Démarrage temp #1 (skip-grant-tables)
         │
         ├─► [Phase 4] CREATE DATABASE (commande directe)
         │
         ├─► [Phase 5] Arrêt + Redémarrage #2
         │
         ├─► [Phase 6] Configuration ROOT (UPDATE mysql.global_priv)
         │             Suppression users anonymes
         │
         ├─► [Phase 7] Arrêt + Redémarrage #3 (avec auth)
         │
         ├─► [Phase 8] Exécution de init.sql
         │             └─► Création user applicatif
         │                 Attribution privilèges
         │
         ├─► [Phase 9] Nettoyage init.sql (sécurité)
         │
         └─► [Phase 10] exec mysqld (PRODUCTION)
```

## ✅ Ce qui a été Corrigé

### **AVANT (Redondances)**

```sql
-- Dans entrypoint.sh (Phase 8)
UPDATE mysql.global_priv ... WHERE User='root';  ← Configure root

-- Dans init.sql (Phase 10)
ALTER USER 'root'@'localhost' IDENTIFIED BY '...';  ← Reconfigure root ❌
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' ...;    ← Réaccorde tout ❌
CREATE DATABASE IF NOT EXISTS ...;                 ← Recrée la DB ❌
```

**Problèmes :**
- ❌ Root configuré 2 fois (risque d'incohérence)
- ❌ Base de données créée 2 fois
- ❌ Tentative d'ouvrir root au réseau (dangereux)
- ❌ Code dupliqué difficile à maintenir

### **APRÈS (Optimisé)**

```sql
-- entrypoint.sh gère UNIQUEMENT l'infrastructure
UPDATE mysql.global_priv ... WHERE User='root';
CREATE DATABASE vsyutkin_inception_db;
DELETE FROM mysql.user WHERE User='';

-- init.sql gère UNIQUEMENT l'application
CREATE USER 'l0c4l_g0d'@'localhost' IDENTIFIED BY '...';
CREATE USER 'l0c4l_g0d'@'%' IDENTIFIED BY '...';
GRANT ALL PRIVILEGES ON vsyutkin_inception_db.* TO 'l0c4l_g0d'@'%';
```

**Avantages :**
- ✅ Séparation claire des responsabilités
- ✅ Pas de duplication
- ✅ Root reste local uniquement (sécurité)
- ✅ Plus facile à débugger

## 🔒 Sécurité Améliorée

### **Configuration Root (entrypoint.sh uniquement)**

```sql
-- Root ne peut se connecter QUE localement
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Mot de passe root défini une seule fois
UPDATE mysql.global_priv SET priv=JSON_SET(...) WHERE User='root';
```

**Résultat :**
- ✅ Root accessible UNIQUEMENT depuis le container lui-même
- ✅ Pas d'accès root depuis le réseau Docker
- ✅ Conforme aux best practices de sécurité

### **Utilisateur Applicatif (init.sql)**

```sql
-- User app accessible depuis n'importe quel host Docker
CREATE USER 'l0c4l_g0d'@'%' IDENTIFIED BY '...';

-- Privilèges LIMITÉS à la base applicative
GRANT ALL PRIVILEGES ON vsyutkin_inception_db.* TO 'l0c4l_g0d'@'%';
```

**Résultat :**
- ✅ WordPress peut se connecter depuis son container
- ✅ Privilèges limités à sa propre base de données
- ✅ Pas d'accès aux tables système (`mysql.*`)

## 📝 Contenu Final de init.sql

```sql
-- ========================================
-- Application User Setup
-- ========================================
-- Note: Database and root user are already configured by entrypoint.sh
-- This script only handles the application user for WordPress

-- Clean up any existing application users
DROP USER IF EXISTS 'l0c4l_g0d'@'localhost';
DROP USER IF EXISTS 'l0c4l_g0d'@'%';

-- Create application user with access from anywhere
CREATE USER 'l0c4l_g0d'@'localhost' IDENTIFIED BY 's1mple_DB_pw';
CREATE USER 'l0c4l_g0d'@'%' IDENTIFIED BY 's1mple_DB_pw';

-- Grant privileges on the application database only
GRANT ALL PRIVILEGES ON vsyutkin_inception_db.* TO 'l0c4l_g0d'@'localhost';
GRANT ALL PRIVILEGES ON vsyutkin_inception_db.* TO 'l0c4l_g0d'@'%';

-- Apply privileges
FLUSH PRIVILEGES;
```

**Caractéristiques :**
- ✅ Beaucoup plus simple (10 lignes vs 30)
- ✅ Commenté et clair
- ✅ Pas de redondance
- ✅ Focus sur l'application uniquement

## 🧪 Vérification

### **Tester la Séparation**

```bash
# Reconstruire proprement
make reinit

# Vérifier les utilisateurs créés
make db-root

# Dans MySQL
SELECT User, Host FROM mysql.user;
```

**Résultat attendu :**
```
+-------------+-----------+
| User        | Host      |
+-------------+-----------+
| l0c4l_g0d   | %         |
| l0c4l_g0d   | localhost |
| root        | localhost |
+-------------+-----------+
```

**Notez :**
- ✅ Pas de `root@%` (sécurisé)
- ✅ `l0c4l_g0d` accessible depuis le réseau
- ✅ Root uniquement local

### **Tester les Privilèges**

```sql
-- Privilèges de l0c4l_g0d
SHOW GRANTS FOR 'l0c4l_g0d'@'%';
```

**Résultat attendu :**
```
GRANT USAGE ON *.* TO `l0c4l_g0d`@`%`
GRANT ALL PRIVILEGES ON `vsyutkin_inception_db`.* TO `l0c4l_g0d`@`%`
```

**Signification :**
- ✅ `USAGE ON *.*` : Peut se connecter (minimum)
- ✅ `ALL PRIVILEGES ON vsyutkin_inception_db.*` : Tous droits sur sa DB
- ✅ Pas d'accès aux autres bases

## 🎓 Principes de Design

### **1. Separation of Concerns (SoC)**
- **Infrastructure** (entrypoint.sh) : MariaDB système
- **Application** (init.sh) : Configuration WordPress

### **2. Single Responsibility Principle (SRP)**
- Chaque script a **une seule raison de changer**
- Plus facile à tester et maintenir

### **3. Principle of Least Privilege**
- Root = local uniquement
- User app = privilèges minimaux nécessaires

### **4. Idempotence**
- `DROP USER IF EXISTS` : Peut être exécuté plusieurs fois
- Pas d'erreur si l'utilisateur existe déjà

## 📚 Résumé

| Aspect | Avant | Après |
|--------|-------|-------|
| Lignes init.sql | ~30 | ~20 |
| Redondances | 3 (root, DB, privileges) | 0 |
| Sécurité root | ⚠️ Exposé réseau | ✅ Local only |
| Clarté | ⚠️ Confusion rôles | ✅ Séparation nette |
| Maintenabilité | ⚠️ Difficile | ✅ Facile |

**Conclusion :** La nouvelle version est plus **propre**, **sécurisée**, et **maintenable** ! 🎉
