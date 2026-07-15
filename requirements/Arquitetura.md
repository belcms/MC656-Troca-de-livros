# Arquitetura

## Diagrama C4

![arquitetura](assets/Untitled%20(3).png)


## Descrição
### Arquitetura do Sistema

#### Estilos Arquiteturais Adotados
- **REST (Representational State Transfer)**: A comunicação entre o aplicativo e o servidor ocorre via requisições HTTP sem estado (stateless). As entidades do domínio (como livros, feed e perfis de usuário) são expostas como recursos manipuláveis por métodos padronizados (GET, POST, PUT, DELETE), com intercâmbio de dados em formato JSON.
- **Arquitetura em Camadas (Layering) no Backend**: O servidor (construído em FastAPI) adota uma estruturação hierárquica por camadas lógicas. Ele divide-se em: camada de API (comunicação e validação de rotas), camada de Domain (serviços, regras de negócio e mapeamento objeto-relacional via SQLAlchemy) e camada de Core (configurações globais e infraestrutura).
- **Modularização por Funcionalidade (Feature-Based) no Frontend**: O aplicativo (construído em Flutter) organiza sua estrutura de diretórios guiada pelo domínio de negócio (ex: feed, book_details, my_books, user_profile). Essa modularização mantém os componentes altamente coesos.


#### Descrição dos Principais Componentes

- **Aplicativo Flutter**: responsável pela interface com o usuário e pela navegação entre as funcionalidades do sistema, como feed de livros, busca, criação e edição de anúncios, perfil do usuário, favoritos, autenticação e solicitações de troca.

- **Módulos de Interface por Funcionalidade**: o frontend é organizado por funcionalidades, como `feed`, `book_creation`, `book_edition`, `book_details`, `search`, `favorites`, `trade_requests`, `user_profile` e `auth`. Cada módulo concentra as telas, view models, widgets e modelos relacionados à sua responsabilidade principal.

- **Services do Frontend**: responsáveis por isolar a comunicação com a API REST. Esses componentes constroem as requisições HTTP, enviam dados para o backend e convertem as respostas recebidas para estruturas utilizadas pela interface.

- **API FastAPI**: camada de entrada do backend. Expõe os endpoints REST utilizados pelo aplicativo, valida parâmetros de requisição, recebe dados do frontend e encaminha as operações para os serviços de domínio.

- **Camada de Domínio do Backend:** concentra as entidades, regras de negócio e operações principais da aplicação. Essa camada é organizada por módulos de domínio, como usuários, autenticação, livros, edições, anúncios, busca, localização, favoritos e propostas de troca. Em cada módulo, os `models` representam as entidades persistidas no banco de dados, os `schemas` definem os contratos de entrada e saída de dados, e os `services` concentram a lógica de negócio executada pelas rotas da API.

- **Modelos e Schemas**: representam as entidades persistidas no banco de dados e os contratos de entrada e saída da API. Os modelos SQLAlchemy descrevem a estrutura relacional, enquanto os schemas Pydantic definem os dados trafegados pelas rotas.

- **Banco de Dados PostgreSQL**: responsável pela persistência das informações da aplicação, incluindo usuários, livros, edições, anúncios, localizações, favoritos, sessões de autenticação e propostas de troca.

- **Banco de dados Supabase**: responsável pelo armazenamento dos arquivos de imagem.

- **Serviços Externos de Localização/CEP**: utilizados para obter ou validar informações de localização a partir de CEPs, permitindo funcionalidades como exibição de cidade/estado e ordenação ou filtragem de anúncios por distância.





