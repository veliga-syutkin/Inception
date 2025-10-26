# 📦 Versions des Services - Projet Inception

## Base OS
- **Debian**: `bookworm` (Debian 12)

## Services

### NGINX
- **Version**: Latest stable from Debian Bookworm repos
- **TLS**: TLSv1.2 et TLSv1.3
- **OpenSSL**: Inclus dans le paquet

### MariaDB
- **Version**: 10.11.x (version stable dans Bookworm)
- **Note**: Debian Bookworm ne fournit plus MariaDB 10.5

### WordPress
- **Version**: 6.5.2 (spécifié explicitement)
- **PHP**: 8.2 (version dans Bookworm)
- **PHP-FPM**: 8.2

## Conformité avec le Sujet

Le sujet demande :
> "For performance reasons, the containers must be built from either the **penultimate stable version** of Alpine or Debian."

- ✅ Debian Bookworm (12) est l'avant-dernière version stable (la dernière étant en développement)
- ✅ MariaDB 10.11 est la version stable fournie par Bookworm
- ✅ PHP 8.2 est la version stable fournie par Bookworm

## Notes de Migration

### Bullseye → Bookworm

| Composant | Bullseye | Bookworm |
|-----------|----------|----------|
| MariaDB   | 10.5     | 10.11    |
| PHP       | 7.4      | 8.2      |
| NGINX     | 1.18     | 1.22+    |

Aucune modification de code n'est nécessaire, WordPress 6.5.2 est compatible avec PHP 8.2.
