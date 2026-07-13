# Autenticação nativa

O projeto oferece somente cadastro e login por e-mail e senha. O backend emite
um access token JWT de curta duração e um refresh token opaco, persistido no
banco apenas como hash. O Flutter armazena os tokens usando armazenamento seguro.

## Cadastro

`POST /api/v1/auth/register`

```json
{
  "full_name": "Maria Silva",
  "nickname": "maria",
  "email": "maria@example.com",
  "password": "segredo123",
  "birth_date": "2000-01-01",
  "cep": "13000-000"
}
```

O backend valida os campos, normaliza e-mail, nickname e CEP, impede duplicatas
sem diferenciar maiúsculas de minúsculas e armazena a senha com Argon2.

## Login

`POST /api/v1/auth/login`

```json
{
  "email": "maria@example.com",
  "password": "segredo123"
}
```

Cadastro e login retornam a sessão no mesmo formato:

```json
{
  "access_token": "JWT",
  "refresh_token": "TOKEN_OPACO",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "full_name": "Maria Silva",
    "nickname": "maria",
    "email": "maria@example.com",
    "birth_date": "2000-01-01",
    "cep": "13000000"
  }
}
```

## Sessão

- `POST /api/v1/auth/refresh` revoga o refresh token recebido e emite outro;
- `POST /api/v1/auth/logout` revoga o refresh token recebido;
- endpoints privados exigem `Authorization: Bearer <access_token>`;
- ao receber uma sessão inválida, o frontend limpa os tokens locais e volta à
  tela de login.

## Configuração e execução

Crie `backend/.env` a partir de `backend/.env.example`, defina um `JWT_SECRET`
forte e execute:

```bash
cd backend
alembic upgrade head
uvicorn app.main:app --reload
```

Em outro terminal:

```bash
cd frontend
flutter pub get
flutter run
```

## Testes

```bash
cd backend
pytest
```

Os testes de autenticação cobrem cadastro, hash de senha, login válido e
inválido, duplicatas, validação, proteção de rotas, renovação e logout.

## Guia para desenvolvedores: acessando o usuário autenticado

### Campos disponíveis

O modelo `User`, definido em `backend/app/domain/users/models.py`, possui as
seguintes colunas:

| Coluna no banco | Campo público na API | Descrição |
| --- | --- | --- |
| `id` | `id` | UUID do usuário. É o identificador usado nas relações e no JWT. |
| `username` | `nickname` | Nome público escolhido pelo usuário. |
| `username_normalized` | — | Versão normalizada usada internamente para detectar duplicatas. |
| `email` | `email` | E-mail exibido pela aplicação. |
| `email_normalized` | — | Versão normalizada usada internamente para buscas e duplicatas. |
| `full_name` | `full_name` | Nome completo. |
| `cep` | `cep` | CEP normalizado, somente com os oito dígitos. |
| `birth_date` | `birth_date` | Data de nascimento. |
| `password_hash` | — | Hash Argon2 da senha; nunca deve ser enviado ao frontend. |
| `created_at` | — | Data de criação do registro. |
| `updated_at` | — | Data da última atualização. |

O usuário também possui os relacionamentos `announcements`, com seus anúncios,
e `sessions`, com suas sessões de autenticação. As sessões contêm somente o hash
do refresh token, sua validade e eventual data de revogação.

### No backend

Em endpoints privados, obtenha o usuário da requisição com a dependência
`get_current_user`. Não receba o ID do próprio usuário pelo corpo da requisição,
pois o usuário autenticado já é identificado pelo access token:

```python
from fastapi import APIRouter, Depends

from app.domain.auth.security import get_current_user
from app.domain.users.models import User

router = APIRouter()


@router.get("/exemplo")
def exemplo(current_user: User = Depends(get_current_user)):
    return {
        "user_id": current_user.id,
        "nickname": current_user.username,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "birth_date": current_user.birth_date,
        "cep": current_user.cep,
    }
```

Se o serviço precisar consultar outros dados do usuário, passe também uma
sessão SQLAlchemy e use o `current_user.id` como chave:

```python
from fastapi import Depends
from sqlalchemy.orm import Session

from app.core.database import get_db


def exemplo(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = db.get(User, current_user.id)
    return user.announcements
```

Para devolver dados pessoais, prefira o schema `UserResponse`. Ele impede que
campos internos, como `password_hash`, sejam incluídos acidentalmente. O endpoint
já disponível `GET /api/v1/users/me` retorna os dados públicos do usuário do
access token.

### No Flutter

Depois do cadastro, login ou restauração da sessão, o usuário público fica em
`AuthRepository.instance.user`, como um objeto `AuthUser`:

```dart
final user = AuthRepository.instance.user;

if (user != null) {
  print(user.id);
  print(user.fullName);
  print(user.nickname);
  print(user.email);
  print(user.birthDate);
  print(user.cep);
}
```

Dentro de um widget abaixo de `AuthScope`, também é possível acessar o
repositório pelo controller. Usar `AuthScope.of(context)` faz o widget acompanhar
as notificações de login e logout:

```dart
final auth = AuthScope.of(context);
final user = auth.repository.user;

return Text(user == null ? 'Visitante' : 'Olá, ${user.nickname}!');
```

Para buscar novamente os dados no servidor, faça `GET /api/v1/users/me` usando
`ApiClient`. O cliente adiciona automaticamente o cabeçalho
`Authorization: Bearer <access_token>` e tenta renovar a sessão uma vez quando
recebe `401`.

## Estrutura do sistema de login

O fluxo está dividido em camadas para separar interface, estado, comunicação
HTTP, regras de autenticação e persistência:

1. As telas de login e cadastro coletam os dados e chamam o `AuthController`.
2. O `AuthController` controla `initializing` e `loading`, notifica a interface e
   delega a operação ao `AuthRepository`.
3. O `AuthRepository` chama `/api/v1/auth/register` ou `/api/v1/auth/login`.
4. O backend valida o payload com os schemas Pydantic e executa as regras em
   `domain/auth/services.py`.
5. No cadastro, a senha é transformada em hash Argon2. No login, a senha
   recebida é comparada com esse hash.
6. Após autenticar, o backend cria uma linha em `auth_sessions` e devolve um
   access token JWT, um refresh token opaco e um `UserResponse`.
7. O Flutter converte a resposta em `AuthUser`, mantém o usuário em memória e
   grava os dois tokens no `FlutterSecureStorage`.
8. O `AuthGate` mostra a aplicação quando `repository.user` existe e mostra a
   tela de login quando não existe.

O access token contém o ID do usuário no claim `sub`, tem duração curta e é
validado por `get_current_user` nos endpoints privados. O backend consulta o
usuário pelo `sub`; portanto, uma rota protegida não deve confiar em um ID de
usuário enviado pelo cliente para decidir quem está autenticado.

O refresh token tem duração maior. Apenas seu hash é salvo em `auth_sessions`.
Ao renovar a sessão, o token anterior é revogado e um novo par de tokens é
emitido. Ao sair, o refresh token atual é revogado e o Flutter apaga o usuário e
os tokens locais.

Na inicialização, `AuthController.initialize()` pede ao repositório para
restaurar os tokens. Se houver refresh token válido, uma nova sessão é emitida e
o usuário volta a ser preenchido. Se a renovação falhar, o armazenamento local é
limpo e a aplicação retorna ao login.
