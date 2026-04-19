# Backend

Esta API foi construída utilizando **FastAPI (Python)** e utiliza **PostgreSQL** (via Docker) como banco de dados.

---

## Tecnologias Utilizadas
* **Python 3.10+**
* **FastAPI** (Framework Web e Contrato de API)
* **SQLAlchemy** (ORM)
* **PostgreSQL** (Banco de Dados)
* **Docker** (Infraestrutura)
* **Pydantic** (Validação de Dados)

---

## Pré-requisitos
Antes de começar, você **precisa** ter instalado na sua máquina:
1. [Python](https://www.python.org/downloads/) (Versão 3.10 ou superior).
2. [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Obrigatório para rodar o banco de dados localmente).

---

## Passo a Passo para Rodar o Projeto

Siga os passos abaixo exatamente nesta ordem para garantir que o ambiente funcione corretamente.

### 1. Subir o Banco de Dados (Docker)
Nós não instalamos o PostgreSQL na máquina, vamos utilizar o Docker para criar um contêiner isolado.
Abra o terminal, navegue até a pasta backend e rode:
```bash
docker-compose up -d
```

*(Isso fará o download da imagem do Postgres e criará o banco `books_db` na porta `5433`).*

### 2\. Criar o Ambiente Virtual
  * **No Windows:**
    ```bash
    python -m venv venv
    ```
  * **No Mac/Linux:**
    ```bash
    python3 -m venv venv
    ```

### 3\. Ativar o Ambiente Virtual

  * **No Windows:**
    ```bash
    .\venv\Scripts\activate
    ```
  * **No Mac/Linux:**
    ```bash
    source venv/bin/activate
    ```

*(Se der certo, você verá um `(venv)` escrito no início da linha do seu terminal).*

### 4\. Instalar as Dependências

Com o `(venv)` ativado, instale as bibliotecas que o projeto precisa (FastAPI, SQLAlchemy, psycopg, etc):

```bash
pip install -r requirements.txt
```

### 5\. Ligar o Servidor

Por fim, inicie a API com o comando:

```bash
uvicorn app.main:app --reload
```

*(O `--reload` faz com que o servidor reinicie sozinho sempre que você salvar um arquivo).*

### 6\. Rodar os Testes Automatizados

Com o ambiente virtual ativado, execute:

```bash
pytest -q
```

Os testes de "meus livros" estão na pasta `tests/` e usam banco em memória (SQLite), sem depender do PostgreSQL do Docker.

-----

## Acessando a Documentação (Swagger)

O FastAPI gera a documentação da API.
Com o servidor rodando, abra o seu navegador e acesse:
**[http://localhost:8000/docs](https://www.google.com/search?q=http://localhost:8000/docs)**

-----

## Comandos Úteis e Resolução de Problemas

**1. O banco de dados está dando erro ou quero resetar tudo:**
Como estamos no início do desenvolvimento pode ser útil resetar tudo no banco de dados

```bash
docker-compose down -v
```

Depois, basta rodar `docker-compose up -d` novamente.

**2. Desligar o banco de dados no fim do dia:**

```bash
docker-compose down
```

-----

## Arquitetura de Pastas

Para manter o projeto escalável, utilizamos uma separação por Domínios:

  * `app/core/`: Configurações do sistema (Conexão com o banco, variáveis globais).
  * `app/domain/`: O coração do sistema. Modelos de banco de dados (SQLAlchemy) e as regras de negócio (`services.py`).
  * `app/api/`: A comunicação com o frontend. Rotas (`router.py`) e validadores de JSON (`schemas.py`).


## Alguns guias úteis
Para tarefas específicas de desenvolvimento, consulte esses guias:
* [Como conectar no Banco de Dados com DBeaver](./docs/dbeaver-setup.md)
