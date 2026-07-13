# Configuração de autenticação

O projeto usa exclusivamente cadastro e login nativos por e-mail e senha.

## Backend

Copie `backend/.env.example` para `backend/.env`, substitua `JWT_SECRET` por um
segredo forte e execute as migrações antes de iniciar a API:

```bash
cd backend
alembic upgrade head
uvicorn app.main:app --reload
```

O arquivo `.env` não deve ser versionado.

As configurações disponíveis são:

- `DATABASE_URL`: conexão com o banco de dados;
- `JWT_SECRET`: assinatura dos access tokens;
- `ACCESS_TOKEN_MINUTES`: validade do access token;
- `REFRESH_TOKEN_DAYS`: validade do refresh token.

## Endpoints

- `POST /api/v1/auth/register`: cria uma conta e uma sessão;
- `POST /api/v1/auth/login`: autentica por e-mail e senha;
- `POST /api/v1/auth/refresh`: rotaciona o refresh token;
- `POST /api/v1/auth/logout`: revoga a sessão atual.

As rotas privadas recebem o access token no cabeçalho
`Authorization: Bearer <token>`.

## Frontend

Inicie o aplicativo Flutter normalmente:

```bash
cd frontend
flutter pub get
flutter run
```

O aplicativo persiste access e refresh tokens no armazenamento seguro do
dispositivo e tenta restaurar a sessão ao iniciar.
