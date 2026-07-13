import 'package:flutter/material.dart';
import 'book_creation_viewmodel.dart';
import 'package:flutter/cupertino.dart';

class BookCreationPage extends StatefulWidget {
  const BookCreationPage({super.key});

  @override
  State<BookCreationPage> createState() => _BookCreationPageState();
}

class _BookCreationPageState extends State<BookCreationPage> {
  final vm = BookCreationViewModel();

  bool isSaving = false;

  // Variável para guardar a URL que o usuário digitar
  String? _imagemCapaUrl;

  // Controller temporário só para o pop-up de colar o link
  final _urlCapaController = TextEditingController();

  /// Displays an alert dialog prompting the user to paste a URL for the book cover image.
  /// Updates the state with the provided URL upon confirmation.
  void _pedirUrlDaImagem() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("URL da Capa"),
          content: TextField(
            controller: _urlCapaController,
            decoration: const InputDecoration(
              hintText: "Cole o link da imagem aqui...",
              filled: true,
              fillColor: Color(0xFFF5F5F5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Atualiza a tela com o novo link digitado
                  _imagemCapaUrl = _urlCapaController.text;
                });
                Navigator.of(context).pop(); // Fecha o pop-up
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  /// Displays a bottom sheet with a CupertinoPicker (roulette) for year selection.
  ///
  /// [controller] is the text controller that will be updated with the selected year.
  void _mostrarRoletaDeAno(TextEditingController controller) {
    // Gera uma lista de anos: do ano atual descendo até 1900
    final int anoAtual = DateTime.now().year;
    final List<int> anos = List.generate(
      anoAtual - 1900 + 1,
      (index) => anoAtual - index,
    );

    // Tenta pegar o ano que já está no controller, ou usa o ano atual como padrão
    int anoSelecionado = int.tryParse(controller.text) ?? anoAtual;
    int indexInicial = anos.indexOf(anoSelecionado);
    if (indexInicial == -1) indexInicial = 0; // fallback de segurança

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              // Barra superior com o botão de "Concluído"
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Concluído',
                      style: TextStyle(color: Color(0xFF416956)),
                    ),
                  ),
                ],
              ),
              // A Roleta em si
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40.0, // Altura de cada item na roleta
                  scrollController: FixedExtentScrollController(
                    initialItem: indexInicial,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      // Atualiza o TextField automaticamente enquanto gira a roleta
                      controller.text = anos[index].toString();
                    });
                  },
                  children: anos.map((int ano) {
                    return Center(
                      child: Text(
                        ano.toString(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Validates the form fields and initiates the book announcement creation process.
  ///
  /// Displays snackbars for validation errors or the final success/failure result.
  /// If successful, it clears the form and resets the UI state.
  Future<void> _saveBook() async {
    // Validações básicas (exemplo: título e autor não podem ser vazios)
    if (vm.titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('O título é obrigatório.')));
      return;
    }
    if (vm.authorController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('O autor é obrigatório.')));
      return;
    }
    if (vm.publisherController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A editora é obrigatória.')));
      return;
    }
    if (vm.yearController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('O ano é obrigatório.')));
      return;
    }
    if (vm.pagesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O número de páginas é obrigatório.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });
    // Sugestão: Passe o _imagemCapa como parâmetro para que o ViewModel faça o upload.
    final success = await vm.submit(_imagemCapaUrl);

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Anúncio criado com sucesso.'
              : 'Não foi possível criar o anúncio.',
        ),
      ),
    );

    if (success) {
      // Volta para a tela anterior se salvou com sucesso
      DefaultTabController.of(
        context,
      ).animateTo(0); // Volta para a primeira aba (home)
      // Limpa os campos do formulário para a próxima criação
      vm.titleController.clear();
      vm.authorController.clear();
      vm.publisherController.clear();
      vm.yearController.clear();
      vm.pagesController.clear();
      vm.synopsisController.clear();
      vm.descriptionController.clear();
      vm.condition = "Novo";
      vm.genre = "";
      vm.language = "";
      vm.status = "Disponível";
      vm.condition = "Muito bom";
      _imagemCapaUrl = null;
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EA),
      appBar: AppBar(
        title: const Text("Criar anúncio"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  /// Builds the main scrollable body of the book creation screen, containing
  /// all the input fields, image picker, status selectors, and the submit button.
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CAPA
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagemCapaUrl != null && _imagemCapaUrl!.isNotEmpty
                      ? Image.network(
                          _imagemCapaUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.red),
                                  Text(
                                    "Link inválido",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link, size: 42, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "Colar Link",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _pedirUrlDaImagem, // Chama o pop-up aqui!
                  child: Text(
                    _imagemCapaUrl == null
                        ? 'Adicionar foto da capa'
                        : 'Trocar link',
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusChip("Disponível"),
              _statusChip("Negociando"),
              _statusChip("Trocado"),
            ],
          ),

          const SizedBox(height: 20),

          /// SOBRE
          const Text(
            "Sobre o livro",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _card(
            Column(
              children: [
                // TODO: [ViewModel] Crie TextEditingControllers para cada um destes
                _input(vm.titleController, "Título"),
                _input(vm.authorController, "Autor"),
                _input(vm.publisherController, "Editora"),

                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        // TODO: [ViewModel] Crie uma variável String genre (ex: inicializada vazia ou com valor padrão)
                        value: vm.genre,
                        hint: "Gênero",
                        items: const [
                          "Romance",
                          "Fantasia",
                          "Distopia",
                          "Ficção científica",
                          "Biografia",
                          "Terror",
                          "Drama",
                          "Autoajuda",
                          "Acadêmico",
                        ],
                        onChanged: (v) {
                          setState(() {
                            vm.genre = v!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dropdown(
                        // TODO: [ViewModel] Crie uma variável String language
                        value: vm.language,
                        hint: "Idioma",
                        items: const [
                          "Português",
                          "Inglês",
                          "Espanhol",
                          "Francês",
                          "Alemão",
                          "Italiano",
                        ],
                        onChanged: (v) {
                          setState(() {
                            vm.language = v!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      // TODO: [ViewModel] Crie TextEditingController para o year
                      child: _inputAnoSelecionavel(vm.yearController, "Ano"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // TODO: [ViewModel] Crie TextEditingController para pages
                      child: _input(
                        vm.pagesController,
                        "Páginas",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // TODO: [ViewModel] Crie TextEditingController para a synopsis
                _multiline(vm.synopsisController, "Sinopse"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// CONDIÇÃO
          const Text(
            "Condição",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _condition("Novo"),
                _condition("Muito bom"),
                _condition("Bom"),
                _condition("Desgastado"),
                const SizedBox(height: 6),
                conditionText(
                  "Novo",
                  "Nunca usado, sem marcas, sem dobras, sem grifos. Estado perfeito.",
                ),
                conditionText(
                  "Muito bom",
                  "Pouco usado, pode ter sinais mínimos de manuseio, sem danos.",
                ),
                conditionText(
                  "Bom",
                  "Sinais visíveis de uso, pode ter pequenos grifos ou leve desgaste.",
                ),
                conditionText(
                  "Desgastado",
                  "Bastante usado, pode ter manchas, páginas amareladas ou dobras.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// DESCRIÇÃO
          const Text(
            "Descrição",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _card(
            _multiline(vm.descriptionController, "Sua descrição do anúncio..."),
          ),

          const SizedBox(height: 30),

          /// BOTÃO SALVAR
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF416956),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isSaving
                  ? null
                  : _saveBook, //o isSaving desabilita o botão e mostra o loading enquanto salva
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Criar anúncio"),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a selectable [ChoiceChip] widget for the book status.
  ///
  /// [value] is the localized status string representing this chip.
  Widget _statusChip(String value) {
    final color = _statusColor(value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        checkmarkColor: Colors.white,
        label: Text(value),
        selected: vm.status == value,
        selectedColor: vm.status == value ? color : null,
        labelStyle: TextStyle(color: vm.status == value ? Colors.white : color),
        onSelected: (_) {
          setState(() {
            vm.setStatus(value);
          });
        },
        shape: StadiumBorder(side: BorderSide(color: color)),
      ),
    );
  }

  /// Builds a [RadioListTile] for selecting the physical condition of the book.
  ///
  /// [value] is the localized condition string representing this radio button.
  Widget _condition(String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: vm.condition,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) {
        setState(() {
          vm.setCondition(v!);
        });
      },
      title: Text(value),
    );
  }

  /// Builds a standard styled [TextField] for single-line text input.
  ///
  /// [controller] manages the text being edited.
  /// [hint] is the placeholder text displayed when the field is empty.
  /// [keyboardType] determines the layout of the on-screen keyboard.
  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Builds a read-only [TextField] specifically tailored for year selection.
  /// Tapping it triggers the year selection bottom sheet instead of the keyboard.
  ///
  /// [controller] manages the text representing the selected year.
  /// [hint] is the placeholder text displayed when the field is empty.
  Widget _inputAnoSelecionavel(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: true, // OBRIGATÓRIO: Impede que o teclado suba!
        onTap: () {
          // Quando o usuário tocar no campo, abre a nossa roleta
          _mostrarRoletaDeAno(controller);
        },
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          // Um ícone de calendário ou seta indica pro usuário que é um menu
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: Colors.grey,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Builds a multi-line [TextField] suitable for longer text like synopses or descriptions.
  ///
  /// [controller] manages the text being edited.
  /// [hint] is the placeholder text displayed when the field is empty.
  Widget _multiline(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Builds a custom-styled [DropdownButton] wrapped in a container.
  ///
  /// [value] is the currently selected item.
  /// [hint] is the placeholder text displayed when no item is selected.
  /// [items] is the list of available string options.
  /// [onChanged] is the callback triggered when a new item is selected.
  Widget _dropdown({
    required String value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          // Garante que se o valor inicial estiver vazio, ele não quebre
          value: items.contains(value) ? value : null,
          hint: Text(hint),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Wraps a given [child] widget inside a styled container with a white background,
  /// rounded corners, and a subtle drop shadow to create a card-like appearance.
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }

  /// Builds a rich text widget to display a condition title alongside its description.
  ///
  /// [title] is the bolded name of the condition.
  /// [description] is the lighter text explaining the condition details.
  Widget conditionText(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: description,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the corresponding [Color] for a given book status string.
  ///
  /// [value] is the localized status string used to determine the color.
  Color _statusColor(String value) {
    switch (value) {
      case "Disponível":
        return const Color(0xFF24523C);

      case "Negociando":
        return const Color(0xFFDB8F44);

      case "Trocado":
        return const Color(0xFF7B2518);

      default:
        return const Color(0xFF24523C);
    }
  }
}
