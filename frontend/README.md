# Instalação do Flutter (Foco em Android)

Este guia cobre a instalação manual do Flutter SDK e a configuração do ambiente para o nosso projeto. O tutorial é feito para rodar o aplicativo no emulador Android.

## Passo 1: Baixar o Flutter SDK

* Acesse a página oficial de arquivos do Flutter: https://docs.flutter.dev/install/archive
* Selecione a aba do seu Sistema Operacional (Windows, macOS ou Linux).
* Na tabela Stable channel, clique no link azul da primeira linha (a versão mais recente) para baixar o arquivo .zip(ou .tar.xz no Linux).
* **Atenção usuários de Mac:** Escolham o arquivo que termina em arm64 se o seu Mac tiver processador Apple Silicon (M1, M2, M3, M4), ou x64 se for Intel.

## Passo 2: Extrair e Configurar o PATH

**Para Mac / Linux:**

* Crie uma pasta chamada development na sua pasta de usuário (no mac é a pasta do finder com seu nome e uma casinha de ícone) e coloque o arquivo baixado lá. O caminho ficará assim: ~/development/flutter.
* Abra o terminal e abra o arquivo de configuração do seu shell. Se você usa zsh (padrão do Mac atual), digite:

*(Se usar bash no Linux, nano ~/.bashrc)*

```bash
nano ~/.zshrc 
```
Se estiver usando linux:

```bash
nano ~/.bashrc
```
* Vá até o final do arquivo (usar o teclado para ir para baixo) e cole esta linha:

```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

* Salve (Control + O, Enter) e saia (Control + X).

* Atualize o terminal rodando: `source ~/.zshrc` (ou reinicie o terminal).

**Para Windows:**

* Extraia o arquivo .zip na raiz do disco C, dentro de uma pasta src. O caminho deve ficar exatamente assim: `C:\src\flutter`. (Não instale dentro de Arquivos de Programas).
* Aperte a tecla Windows e digite "Variáveis de Ambiente". Clique em "Editar as variáveis de ambiente do sistema".
* Clique no botão "Variáveis de Ambiente..." na parte de baixo.
* Na lista de cima (Variáveis de usuário), procure pela variável chamada Path e clique em Editar.
* Clique em Novo e adicione o seguinte caminho: `C:\src\flutter\bin`
* Dê OK em todas as janelas e feche os terminais abertos.

## Passo 3: Preparar o Android Studio

Nós escrevemos o código no VS Code, mas o Android Studio é obrigatório para compilar o projeto para Android e gerenciar o emulador.

* Baixe e instale o https://developer.android.com/studio?hl=pt-br – Android Studio Panda 3
* Abra o programa pela primeira vez e vá clicando em "Next" na instalação padrão (Standard). Ele fará o download do Android SDK.
* **Importante:** Na tela inicial do Android Studio, clique em More Actions (ou no ícone de 3 pontos) e vá em SDK Manager.
* Selecione a aba SDK Tools.
* Marque a caixinha Android SDK Command-line Tools (latest).
* Clique em Apply e deixe ele baixar. (Sem isso, o Flutter não consegue se comunicar com o Android).
* Volte à tela inicial, clique em More Actions, vá em Virtual Device Manager (ou Device Manager) e clique em Create Device para baixar e configurar um celular virtual (Emulador). Escolha a opção Pixel 7. Selecione a API 34 e clique para baixar.

## Passo 4: VS Code e Flutter Doctor

* Baixe o VS Code. Nele, vá na aba de Extensões e instale as extensões oficiais **Flutter** e **Dart** (caso ela não tenha sido ativada automaticamente ao instalar a flutter).
* Abra o seu terminal e rode a ferramenta de diagnóstico do Flutter:

```bash
flutter doctor
```

* O terminal vai listar o status da sua máquina. O objetivo é que a parte do Flutter e do Android não tenham nenhum "X" vermelho.
* **Aceitando as Licenças:** É normal o diagnóstico reclamar de licenças do Android não aceitas. Para resolver, rode:

```bash
flutter doctor --android-licenses
```

* Vá apertando `y` (yes) e Enter para todas as perguntas.

### Como rodar o aplicativo no dia a dia

* **No terminal**, certifique-se de estar na pasta `frontend` do projeto.
* **Ligue o emulador:** No Android Studio, clique em More Actions → Virtual Device Manager. Na aba de Device Manager, ache o device criado e clique no símbolo de play. Espere o simulador carregar totalmente.
* **Execute o App:** No terminal (garanta que você está dentro da pasta `frontend`), digite:

```bash
flutter run
```

* **obs:** (na primeira vez pode demorar um pouco)
* Para encerrar a execução no terminal, pressione a tecla `q`.




A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

