import 'package:flutter/material.dart';
import 'book_edition_viewmodel.dart';
import 'package:flutter/cupertino.dart';

class BookEditionPage extends StatefulWidget {
  final String id;
  final BookEditionViewModel? viewModel;

  const BookEditionPage({super.key, required this.id, this.viewModel});

  @override
  State<BookEditionPage> createState() => _BookEditionPageState();
}

class _BookEditionPageState extends State<BookEditionPage> {
  late final BookEditionViewModel vm;

  bool isLoading = true;
  bool hasError = false;
  bool isSaving = false;

  /// called when the screen is created
  /// loads book data from backend using the id
  @override
  void initState() {
    super.initState();
    vm = widget.viewModel ?? BookEditionViewModel();
    _loadBook();
  }

  // change the color of book status
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

  /// fetches book data from server
  /// updates loading and error states
  Future<void> _loadBook() async {
    final success = await vm.loadFromServer(widget.id);

    if (!mounted) return;

    setState(() {
      isLoading = false;
      hasError = !success;
    });
  }

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

  /// sends updated book information to backend
  /// shows feedback message to the user
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

    final success = await vm.submit(widget.id);

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o livro.')),
      );
    }
  }

  /// disposes viewmodel to avoid memory leak
  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  /// builds main structure of the page
  /// defines background and app bar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EA),
      appBar: AppBar(
        title: const Text("Editar livro"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  /// decides which content should be shown
  /// loading spinner, error state or form
  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Não foi possível carregar os dados do livro.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    hasError = false;
                  });
                  _loadBook();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// book cover preview and edit button
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

                  /// loads image from url if available
                  /// fallback icon if no image
                  child: vm.coverUrl != null && vm.coverUrl!.isNotEmpty
                      ? Image.network(
                          vm.coverUrl!,
                          fit: BoxFit.cover,

                          /// handles image loading error
                          errorBuilder: (context, error, stackTrace) {
                            print("ERRO IMAGEM: $error");
                            return const Center(
                              child: Text("Erro ao carregar"),
                            );
                          },
                        )
                      : const Icon(Icons.book, size: 42),
                ),
                const SizedBox(height: 12),

                /// button to edit cover image
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Editar foto da capa'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// book trade status selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusChip("Disponível"),
              _statusChip("Negociando"),
              _statusChip("Trocado"),
            ],
          ),

          const SizedBox(height: 20),

          /// book basic information section
          const Text(
            "Sobre o livro",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// card groups related inputs visually
          _card(
            Column(
              children: [
                /// basic metadata inputs
                _input(vm.titleController, "Título"),
                _input(vm.authorController, "Autor"),
                _input(vm.publisherController, "Editora"),

                Row(
                  children: [
                    /// dropdown for genre selection
                    Expanded(
                      child: _dropdown(
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

                    /// dropdown for language selection
                    Expanded(
                      child: _dropdown(
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
                    /// publication year input
                    Expanded(
                      child: _inputAnoSelecionavel(vm.yearController, "Ano"),
                    ),

                    const SizedBox(width: 10),

                    /// number of pages input
                    Expanded(
                      child: _input(
                        vm.pagesController,
                        "Páginas",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// book synopsis multiline field
                _multiline(vm.synopsisController, "Sinopse"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// book physical condition section
          const Text(
            "Condição",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// selectable radio options
                _condition("Novo"),
                _condition("Muito bom"),
                _condition("Bom"),
                _condition("Desgastado"),

                const SizedBox(height: 6),

                /// explanatory texts for each condition
                conditionText(
                  "Novo",
                  "Nunca usado, sem marcas, sem dobras, sem grifos. Estado perfeito.",
                ),

                conditionText(
                  "Muito bom",
                  "Pouco usado, pode ter sinais mínimos de manuseio, sem rasgos ou danos relevantes.",
                ),

                conditionText(
                  "Bom",
                  "Sinais visíveis de uso, pode ter pequenos grifos ou leve desgaste na capa, totalmente legível.",
                ),

                conditionText(
                  "Desgastado",
                  "Bastante usado, pode ter manchas, páginas amareladas ou dobras, ainda possível de ler.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// additional description section
          const Text(
            "Descrição",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          _card(_multiline(vm.descriptionController, "Descrição")),

          const SizedBox(height: 30),

          /// save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF416956),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),

              onPressed: isSaving ? null : _saveBook,

              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Editar anúncio"),
            ),
          ),

          const SizedBox(height: 12),

          // cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text(
                "Cancelar",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// chip used to select announcement status
  Widget _statusChip(String value) {
    final color = _statusColor(value);
    final isSelected = vm.status == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        checkmarkColor: Colors.white,

        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) const SizedBox(width: 4),

            Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        selected: isSelected,

        selectedColor: color,

        backgroundColor: Colors.transparent,

        shape: StadiumBorder(side: BorderSide(color: color)),

        onSelected: (_) {
          setState(() {
            vm.setStatus(value);
          });
        },
      ),
    );
  }

  /// radio option for book condition
  Widget _condition(String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: vm.condition,
      contentPadding: EdgeInsets.zero,

      /// updates selected condition
      onChanged: (v) {
        setState(() {
          vm.setCondition(v!);
        });
      },

      title: Text(value),
    );
  }

  /// reusable text input field
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

  /// multiline text field for longer content
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

  /// reusable dropdown component
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
          /// ensures value is always valid
          value: items.contains(value) ? value : items.first,

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

  /// styled container used as visual group
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

      child: Material(color: Colors.transparent, child: child),
    );
  }

  /// helper text explaining each condition option
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
}
