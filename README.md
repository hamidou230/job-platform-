# JobStage — Plateforme de stages & d'emplois pour étudiants

Application complète (mobile + API) permettant aux **étudiants** de trouver des
stages/emplois, de postuler et de gérer leurs favoris, aux **entreprises** de
publier des offres et de suivre les candidatures, et à un **administrateur** de
superviser la plateforme.

> Interface **en français**, pensée pour être ouverte **sur un téléphone**.

---

## 🧱 Stack technique

| Côté | Technologies |
|------|--------------|
| **Frontend** | Flutter, Clean Architecture, Riverpod, Material 3, UI responsive |
| **Backend** | NestJS, Prisma ORM, JWT, REST, Swagger, Docker |
| **Base de données** | MySQL 8 |

---

## 📂 Structure du projet

```
job-platform/
├── docker-compose.yml        # MySQL + API backend
├── backend/                  # API NestJS (45 fichiers TypeScript)
│   ├── prisma/
│   │   ├── schema.prisma     # Modèle de données MySQL
│   │   └── seed.ts           # Données de démonstration
│   ├── src/
│   │   ├── main.ts           # Bootstrap (CORS, Swagger, validation, /uploads)
│   │   ├── common/           # Décorateurs, guards, filtre d'exceptions, pagination
│   │   ├── auth/             # Inscription / connexion / JWT
│   │   ├── students/         # Profil étudiant + UPLOAD DE CV
│   │   ├── companies/        # Profil entreprise
│   │   ├── offers/           # Offres + recherche & filtres + pagination
│   │   ├── applications/     # Candidatures
│   │   ├── favorites/        # Favoris
│   │   ├── notifications/    # Notifications
│   │   └── admin/            # Tableau de bord administrateur
│   ├── Dockerfile
│   └── uploads/              # CV stockés (servis en statique)
└── frontend/                 # Application Flutter (45 fichiers Dart)
    ├── pubspec.yaml
    └── lib/
        ├── main.dart         # Point d'entrée + restauration de session
        ├── core/             # Thème, constantes, réseau (Dio), erreurs, routeur
        └── features/         # Un dossier par module (data / domain / presentation)
            ├── auth/  offers/  applications/  favorites/
            ├── profile/  notifications/  admin/  home/
```

L'architecture **Clean** côté Flutter sépare chaque fonctionnalité en trois couches :
`data` (repositories + appels API), `domain` (modèles métier), `presentation`
(écrans + providers Riverpod).

---

## 🚀 Démarrage rapide (backend + base de données)

Le plus simple est d'utiliser Docker (rien d'autre à installer) :

```bash
cd job-platform
docker compose up --build
```

Cela démarre :
- **MySQL 8** (base `jobplatform`)
- L'**API NestJS** sur le port **3000**, qui applique automatiquement les
  migrations Prisma au démarrage.

### Charger les données de démonstration (comptes + offres)

Une fois les conteneurs lancés :

```bash
docker compose exec backend npx prisma db seed
```

### 📖 Documentation Swagger

Une fois l'API démarrée, la documentation interactive est disponible sur :

```
http://localhost:3000/api/docs
```

Toutes les routes sont préfixées par `/api`.

### Lancer le backend sans Docker (optionnel)

```bash
cd backend
cp .env.example .env          # adapter DATABASE_URL si besoin
npm install
npx prisma migrate deploy     # ou: npx prisma migrate dev
npx prisma db seed
npm run start:dev
```

---

## 👤 Comptes de démonstration

Tous les comptes utilisent le mot de passe : **`Password123`**

| Rôle | Email | Description |
|------|-------|-------------|
| 👨‍💼 Administrateur | `admin@jobplatform.ma` | Accès au tableau de bord admin |
| 🏢 Entreprise | `rh@techcorp.ma` | TechCorp — peut publier des offres |
| 🎓 Étudiant | `etudiant@example.com` | Yassine El Amrani — peut postuler |

L'écran de connexion est pré-rempli avec le compte étudiant pour tester rapidement.

---

## 📱 Ouvrir l'application sur un téléphone

C'est l'étape la plus importante : par défaut, l'application mobile cherche l'API
sur `http://10.0.2.2:3000/api` (adresse spéciale de **l'émulateur Android**).
Sur un **vrai téléphone**, il faut la faire pointer vers l'ordinateur qui exécute
le backend.

### 1. Trouver l'adresse IP locale de votre PC

- **Windows** : `ipconfig` → cherchez « Adresse IPv4 » (ex. `192.168.1.10`)
- **macOS / Linux** : `ifconfig` ou `ip addr` (ex. `192.168.1.10`)

### 2. Modifier l'URL de l'API dans Flutter

Ouvrez `frontend/lib/core/constants/app_constants.dart` et remplacez :

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

par l'IP de votre PC, par exemple :

```dart
static const String baseUrl = 'http://192.168.1.10:3000/api';
```

### 3. Conditions à respecter

- 📶 Le **téléphone et le PC doivent être sur le même réseau Wi-Fi**.
- 🔌 Le backend écoute déjà sur `0.0.0.0:3000` (accessible depuis le réseau local).
- 🔥 Autorisez le port **3000** dans le **pare-feu** de votre PC si la connexion échoue.

### 4. Lancer l'application

```bash
cd frontend
flutter pub get
flutter run            # téléphone branché en USB (débogage activé) ou émulateur
```

> Pour générer un APK installable : `flutter build apk` puis récupérez le fichier
> dans `build/app/outputs/flutter-apk/app-release.apk`.

---

## ✅ Correspondance avec les 20 livrables demandés

| # | Livrable | Où le trouver |
|---|----------|----------------|
| 1 | Architecture du système | Ce README + structure des dossiers |
| 2 | Conception base MySQL | `backend/prisma/schema.prisma` |
| 3 | Schéma Prisma (MySQL) | `backend/prisma/schema.prisma` |
| 4 | Structure backend NestJS | `backend/src/` (modules par domaine) |
| 5 | Controllers | `*.controller.ts` de chaque module |
| 6 | Services | `*.service.ts` de chaque module |
| 7 | DTOs | `dto/` de chaque module + validation |
| 8 | Middleware | Guards, intercepteurs, filtre d'exceptions (`src/common/`) |
| 9 | Authentification JWT | `backend/src/auth/` (Passport + stratégie JWT) |
| 10 | API REST | Toutes les routes sous `/api` (voir Swagger) |
| 11 | Structure Flutter | `frontend/lib/` (core + features) |
| 12 | Modèles Flutter | `features/*/domain/*.dart` |
| 13 | Écrans Flutter | `features/*/presentation/screens/` |
| 14 | Providers Riverpod | `features/*/presentation/providers/` |
| 15 | Intégration API | `core/network/` (Dio) + repositories |
| 16 | Gestion des erreurs | `core/errors/` + `dio_error_mapper.dart` + filtre backend |
| 17 | Pagination | `core/network/paginated.dart` + `PaginationDto` backend |
| 18 | Recherche & filtres | Offres : barre de recherche + `filter_sheet.dart` / `offers.service` |
| 19 | Upload de CV | `students.controller` (`POST /api/students/me/cv`) + `profile_repository` |
| 20 | Configuration Docker | `docker-compose.yml` + `backend/Dockerfile` |

---

## 🧩 Modules fonctionnels

- **Authentification** — inscription (étudiant ou entreprise), connexion, JWT, session persistante.
- **Étudiants** — profil, compétences, **upload de CV** (PDF/DOC/DOCX, 5 Mo max).
- **Entreprises** — profil, publication et gestion des offres.
- **Offres** — création, recherche plein-texte, filtres (type, ville, télétravail,
  niveau d'expérience, compétences), pagination infinie.
- **Candidatures** — postuler avec lettre de motivation, suivi du statut, retrait ;
  côté entreprise : accepter / refuser / marquer comme examinée.
- **Favoris** — ajout/retrait optimiste, liste dédiée.
- **Notifications** — alertes (candidature reçue, statut mis à jour…), compteur de non-lus.
- **Tableau de bord admin** — statistiques globales + gestion (activation/désactivation) des comptes.

---

## 🛠️ Étendre l'application

Chaque fonctionnalité suit le même patron, facile à dupliquer :

1. **Modèle** dans `features/<module>/domain/` (avec `fromJson`).
2. **Repository** dans `features/<module>/data/` (prend un `Dio`, gère les erreurs
   via `mapDioError`, expose un `Provider`).
3. **État + logique** dans `presentation/providers/` (Riverpod `Notifier` /
   `NotifierProvider`).
4. **Écran** dans `presentation/screens/`, ajouté au routeur
   (`core/router/app_router.dart`).

---

## ⚠️ Remarque honnête sur les tests

Le code a été écrit et vérifié par relecture, et les conventions sont cohérentes
d'un bout à l'autre. En revanche, il **n'a pas pu être compilé/exécuté de bout en
bout** dans l'environnement de génération (ni MySQL, ni SDK Flutter, ni runtime
NestJS disponibles). Avant une mise en production, pensez à :

- lancer `flutter analyze` et `flutter pub get` côté frontend ;
- exécuter les migrations Prisma et tester les routes via Swagger ;
- ajuster l'`baseUrl` (voir section téléphone ci-dessus).
