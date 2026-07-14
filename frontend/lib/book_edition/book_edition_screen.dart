import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'book_edition_viewmodel.dart';
import '../services/location_service.dart';
import 'package:frontend/components/photo_carousel_picker.dart';
import 'package:frontend/services/upload_service.dart';

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
  String _locationInfo = "Buscando localização...";

  // 1. Variáveis para gerenciamento de fotos (URLs do servidor e XFiles locais)
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _selectedImages = [];
  List<String> _deletedPhotosUrls = [];

  @override
  void initState() {
    super.initState();
    vm = widget.viewModel ?? BookEditionViewModel();
    _loadBook();
  }

  // Define a cor baseada no status do livro
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

  // Carrega os dados iniciais do livro e as fotos que já estão no servidor
  Future<void> _loadBook() async {
    final success = await vm.loadFromServer(widget.id);

    if (!mounted) return;
    if (success && vm.cepController.text.isNotEmpty) {
      await _buscarLocalizacao(vm.cepController.text);
    }

    setState(() {
      isLoading = false;
      hasError = !success;

      // Popula o carrossel com as fotos que já existem no backend
      if (vm.photoUrls.isNotEmpty) {
        // Passa todas as fotos que vieram do banco para o seu carrossel
        _selectedImages = List.from(vm.photoUrls);
      }
    });
  }

  // Funções do Carrossel de Imagens
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já adicionou o limite máximo de 5 fotos.'),
        ),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);

    if (images.isNotEmpty) {
      setState(() {
        for (var img in images) {
          if (_selectedImages.length < 5) {
            _selectedImages.add(img);
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      final itemRemovido = _selectedImages[index];

      // Se for uma String (URL que veio do banco), guarda na lista de exclusão!
      if (itemRemovido is String) {
        _deletedPhotosUrls.add(itemRemovido);
      }

      _selectedImages.removeAt(index);
    });
  }

  // Busca e exibe o endereço baseado no CEP
  Future<void> _buscarLocalizacao(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    setState(() {
      _locationInfo = "Buscando localização...";
    });

    final loc = await LocationService.fetchLocation(cleanCep);
    if (!mounted) return;

    setState(() {
      if (loc != null) {
        final district = loc['district'] ?? "";
        _locationInfo =
            "${loc['city']} - ${loc['state']}" +
            (district.isNotEmpty ? ", $district" : "");
      } else {
        _locationInfo = "CEP não encontrado ou inválido.";
      }
    });
  }

  // Mostra a roleta para selecionar o ano
  void _mostrarRoletaDeAno(TextEditingController controller) {
    final int anoAtual = DateTime.now().year;
    final List<int> anos = List.generate(
      anoAtual - 1900 + 1,
      (index) => anoAtual - index,
    );

    int anoSelecionado = int.tryParse(controller.text) ?? anoAtual;
    int indexInicial = anos.indexOf(anoSelecionado);
    if (indexInicial == -1) indexInicial = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
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
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: indexInicial,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
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

  // Salva o livro editado no backend
  Future<void> _saveBook() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É obrigatório manter pelo menos uma foto do livro.'),
        ),
      );
      return;
    }

    final cleanCep = vm.cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (vm.cepController.text.trim().isNotEmpty) {
      if (cleanCep.length != 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um CEP com 8 dígitos.')),
        );
        return;
      }

      final loc = await LocationService.fetchLocation(cleanCep);
      if (loc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CEP não encontrado ou inválido.')),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    vm.photoUrls = _selectedImages.whereType<String>().toList();

    // 1. Atualiza os dados do texto no backend
    final success = await vm.submit(widget.id);

    // 2. Upload das NOVAS fotos
    bool uploadSuccess = true;
    if (success) {
      final uploadService = UploadService();

      for (var image in _selectedImages) {
        if (image is XFile) {
          // Só faz upload dos arquivos novos (XFile)
          bool result = await uploadService.uploadBookPhoto(widget.id, image);
          if (!result) {
            uploadSuccess = false; // Marca que deu erro em alguma foto
          }
        }
      }

      for (var urlParaDeletar in _deletedPhotosUrls) {
        bool result = await uploadService.deleteBookPhoto(
          widget.id,
          urlParaDeletar,
        );
        if (!result) {
          uploadSuccess = false; // Se der erro, avisa a tela!
        }
      }
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    if (success && uploadSuccess) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salvo com ressalvas. Houve falha ao atualizar algumas fotos.',
          ),
        ),
      );
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
        title: const Text("Editar anúncio"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

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
          /// Galeria de Fotos Editável
          PhotoCarouselPicker(
            images: _selectedImages,
            onAddImage: _pickImages,
            onRemoveImage: _removeImage,
          ),

          const SizedBox(height: 24),

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

          /// LOCALIZAÇÃO
          const Text(
            "Localização",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: vm.cepController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: "CEP",
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 8) {
                      _buscarLocalizacao(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationInfo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// INFORMAÇÕES BÁSICAS
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
                      child: _inputAnoSelecionavel(vm.yearController, "Ano"),
                    ),
                    const SizedBox(width: 10),
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

          /// DESCRIÇÃO ADICIONAL
          const Text(
            "Descrição",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _card(
            _multiline(vm.descriptionController, "Sua descrição do anúncio..."),
          ),

          const SizedBox(height: 30),

          /// BOTÃO DE SALVAR (Com validação em tempo real)
          ListenableBuilder(
            listenable: Listenable.merge([
              vm.titleController,
              vm.authorController,
              vm.publisherController,
              vm.yearController,
              vm.pagesController,
            ]),
            builder: (context, child) {
              final bool isFormValid =
                  _selectedImages.isNotEmpty &&
                  vm.titleController.text.trim().isNotEmpty &&
                  vm.authorController.text.trim().isNotEmpty &&
                  vm.publisherController.text.trim().isNotEmpty &&
                  vm.yearController.text.trim().isNotEmpty &&
                  vm.pagesController.text.trim().isNotEmpty;

              final bool canSubmit = isFormValid && !isSaving;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF416956),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: canSubmit ? _saveBook : null,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Editar anúncio"),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          /// BOTÃO CANCELAR
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context, false),
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

  // ==================== COMPONENTES AUXILIARES ==================== //

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
        readOnly: true,
        onTap: () => _mostrarRoletaDeAno(controller),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: Colors.grey,
            size: 20,
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
              .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Material(color: Colors.transparent, child: child),
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
