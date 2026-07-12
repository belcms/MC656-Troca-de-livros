import 'package:flutter/material.dart';

/// Reusable search bar used across the search flow.
class CustomSearchBar extends StatefulWidget {
  /// Creates a new [CustomSearchBar].
  const CustomSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    this.hintText = 'Buscar',
  });

  /// Optional controller for external text manipulation.
  final TextEditingController? controller;

  /// Optional focus node for external focus control.
  final FocusNode? focusNode;

  /// Whether the field should autofocus when built.
  final bool autofocus;

  /// Whether the field should be read-only and act like a launcher.
  final bool readOnly;

  /// Optional tap handler used by the Home launcher state.
  final VoidCallback? onTap;

  /// Called whenever the text changes.
  final ValueChanged<String> onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String> onSubmitted;

  /// Called after the clear action is triggered.
  final VoidCallback onClear;

  /// Hint text shown when the field is empty.
  final String hintText;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller?.removeListener(_handleControllerChanged);

    if (_ownsController) {
      _controller.dispose();
    }

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {});
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear();
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 16,
      color: Colors.black,
    );

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      showCursor: !widget.readOnly,
      enableInteractiveSelection: !widget.readOnly,
      style: textStyle,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: const Color(0xFF727272),
        ),
        filled: true,
        fillColor: const Color(0xFFE9E0D5),
        prefixIcon: const Icon(Icons.search, color: Colors.black),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF727272)),
                onPressed: _handleClear,
                splashRadius: 20,
              ),
        border: InputBorder.none,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
