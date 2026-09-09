import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProducerOtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autoFocus;
  final bool enabled;

  const ProducerOtpInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.autoFocus = true,
    this.enabled = true,
  });

  @override
  State<ProducerOtpInputField> createState() => _ProducerOtpInputFieldState();
}

class _ProducerOtpInputFieldState extends State<ProducerOtpInputField> {
  late final FocusNode _focusNode;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }

    widget.controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
    widget.onChanged?.call(widget.controller.text);
    if (widget.controller.text.length == 6) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = widget.controller.text;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Hidden accessible TextField capturing system keyboard input & paste
        Opacity(
          opacity: 0.0,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autoFocus,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (val) {
              // Handled by controller listener
            },
          ),
        ),

        // Visual 6-Box Presentation
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.enabled) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive box size with safe spacing
              final availableWidth = constraints.maxWidth;
              const spacing = 8.0;
              const totalSpacing = spacing * 5;
              final boxWidth = ((availableWidth - totalSpacing) / 6).clamp(38.0, 52.0);
              final boxHeight = (boxWidth * 1.15).clamp(46.0, 60.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFilled = index < text.length;
                  final isCurrentFocused = _focusNode.hasFocus &&
                      (index == text.length || (index == 5 && text.length == 6));
                  final char = isFilled ? text[index] : '';

                  Color borderColor;
                  double borderWidth;

                  if (isCurrentFocused) {
                    borderColor = theme.colorScheme.primary;
                    borderWidth = 2.0;
                  } else if (isFilled) {
                    borderColor = theme.colorScheme.primary.withValues(alpha: 0.5);
                    borderWidth = 1.5;
                  } else {
                    borderColor = theme.dividerColor;
                    borderWidth = 1.0;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      boxShadow: isCurrentFocused
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.18),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
