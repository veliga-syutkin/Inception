# 📋 Renommage du Dossier secrets → .secrets

## ✅ Changements Effectués

### 1. **Dossier Renommé**
```bash
secrets/ → .secrets/
```

**Avantages :**
- ✅ Convention UNIX : les fichiers/dossiers commençant par `.` sont cachés
- ✅ Plus difficile à voir accidentellement avec `ls`
- ✅ Convention pour les fichiers de configuration sensibles

### 2. **Fichiers Mis à Jour**

#### **Makefile**
```makefile
# Avant
docker-compose --env-file ./secrets/.env ...

# Après
docker-compose --env-file ./.secrets/.env ...
```

**Lignes modifiées :**
- Ligne 31 : `up` target
- Ligne 71 : `db` target (3 occurrences)
- Ligne 76 : `db-root` target
- Ligne 87 : vérification de l'existence du fichier

#### **docker-compose.yml**
```yaml
# Avant
env_file:
  - ../secrets/.env

# Après
env_file:
  - ../.secrets/.env
```

**Services mis à jour :**
- ft_mariadb
- ft_wordpress
- ft_nginx

#### **.gitignore**
```bash
# Avant
/secrets/

# Après
.secrets/
```

**Note :** Pas besoin de `/` au début car le dossier commence déjà par `.`

### 3. **Vérification**

```bash
# Vérifier que le dossier existe
ls -la .secrets/

# Contenu attendu
.secrets/
├── .env
└── this file shouldn't be visible in github
```

## 🎯 **Pourquoi Ce Changement ?**

### **Sécurité par Obscurité (Bonus)**
- Les dossiers cachés ne s'affichent pas avec `ls` simple
- Faut utiliser `ls -a` ou `ls -la` pour les voir
- Réduit le risque de commit accidentel

### **Convention Standard**
```bash
.secrets/     # ← Dossiers de secrets (convention)
.env          # ← Fichiers d'environnement
.config/      # ← Configuration cachée
.ssh/         # ← Clés SSH
.git/         # ← Données Git
```

### **Git Ignore**
Avec `.secrets/`, le dossier est :
- ✅ Ignoré par Git
- ✅ Caché dans les listings
- ✅ Convention reconnue par les développeurs

## 🧪 **Tester**

```bash
# Vérifier que tout compile
make fclean
make up

# Vérifier les logs
make logs

# Se connecter à la DB
make db
```

## ⚠️ **Important**

Si vous avez d'autres fichiers qui référencent `secrets/.env`, il faudra aussi les mettre à jour :
```bash
# Chercher d'autres références
grep -r "secrets/.env" .
```

## 📚 **Checklist**

- [x] Dossier renommé (`mv secrets .secrets`)
- [x] Makefile mis à jour (5 occurrences)
- [x] docker-compose.yml mis à jour (3 services)
- [x] .gitignore mis à jour
- [ ] Tester la compilation (`make up`)
- [ ] Vérifier les logs (`make logs`)
- [ ] Tester la connexion DB (`make db`)

## 🎓 **Résumé**

| Fichier | Changement | Status |
|---------|------------|--------|
| `secrets/` → `.secrets/` | Renommage du dossier | ✅ |
| `Makefile` | 5 références mises à jour | ✅ |
| `docker-compose.yml` | 3 services mis à jour | ✅ |
| `.gitignore` | Pattern mis à jour | ✅ |

**Tout est prêt !** 🚀
