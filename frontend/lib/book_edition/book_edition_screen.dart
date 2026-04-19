import 'package:flutter/material.dart';
import 'book_edition_viewmodel.dart';

class BookEditionPage extends StatefulWidget {
  final String id;

  const BookEditionPage({
    super.key,
    required this.id,
  });

  @override
  State<BookEditionPage> createState() => _BookEditionPageState();
}

class _BookEditionPageState extends State<BookEditionPage> {
  final vm = BookEditionViewModel();

  bool isLoading = true;
  bool hasError = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final success = await vm.loadFromServer(widget.id);

    if (!mounted) return;

    setState(() {
      isLoading = false;
      hasError = !success;
    });
  }

  Future<void> _saveBook() async {
    setState(() {
      isSaving = true;
    });

    final success = await vm.submit(widget.id);

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Livro atualizado com sucesso.'
              : 'Não foi possível atualizar o livro.',
        ),
      ),
    );
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
        title: const Text("Editar livro"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
                  child: vm.coverUrl != null && vm.coverUrl!.isNotEmpty
                      ? Image.network(
                          vm.coverUrl!,
                          fit: BoxFit.cover,
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
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Editar foto da capa'),
                ),
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
                _input(vm.titleController, "Título"),
                _input(vm.authorController, "Autor"),
                _input(vm.publisherController, "Editora"),

                Row(
                  children: [
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
                    Expanded(
                      child: _input(vm.yearController, "Ano"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _input(vm.pagesController, "Páginas"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

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

          /// DESCRIÇÃO
          const Text(
            "Descrição",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _card(
            _multiline(vm.descriptionController, "Descrição"),
          ),

          const SizedBox(height: 30),

          /// BOTÃO
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
        ],
      ),
    );
  }

  Widget _statusChip(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(value),
        selected: vm.status == value,
        selectedColor: const Color(0xFF416956),
        labelStyle: TextStyle(
          color: vm.status == value ? Colors.white : Colors.black87,
        ),
        onSelected: (_) {
          setState(() {
            vm.setStatus(value);
          });
        },
      ),
    );
  }

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

  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
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
          value: items.contains(value) ? value : items.first,
          hint: Text(hint),
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget conditionText(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: description,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}