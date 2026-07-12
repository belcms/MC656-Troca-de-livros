# Configuração de autenticação

## Backend

Copie `backend/.env.example` para `backend/.env`, substitua `JWT_SECRET` e configure
`GOOGLE_CLIENT_ID` com o **Web OAuth Client ID** usado como server client ID pelo
aplicativo Android. Execute as migrações antes de iniciar a API:

```bash
cd backend
alembic upgrade head
uvicorn app.main:app --reload
```

O arquivo `.env` não deve ser versionado.

## Google Sign-In no Android

No Google Cloud Console, configure a tela de consentimento e crie:

1. Um cliente OAuth Android para o package `com.example.frontend`, com os fingerprints
   SHA-1 e SHA-256 das chaves usadas em debug/release.
2. Um cliente OAuth do tipo Web. Use seu ID tanto em `GOOGLE_CLIENT_ID` no backend
   quanto no `--dart-define` abaixo.

Obtenha os fingerprints locais com `cd frontend/android && ./gradlew signingReport`.
Inicie o app sem incluir credenciais no repositório:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=seu-id.apps.googleusercontent.com
```

O login por e-mail funciona sem essa configuração. Se o Google Client ID estiver
ausente, a API responde `503` somente para o endpoint Google.
