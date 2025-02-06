import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedChatMessage extends StatefulWidget {
  final String message;
  final bool isUser;
  final void Function(String)? onEdit; // Callback for live-edit updates

  const AnimatedChatMessage({
    super.key,
    required this.message,
    required this.isUser,
    this.onEdit,
  });

  @override
  State<AnimatedChatMessage> createState() => _AnimatedChatMessageState();
}

class _AnimatedChatMessageState extends State<AnimatedChatMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  bool _editing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message);
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _elevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.message));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _copyText,
      onTap: () {
        setState(() {
          _editing = !_editing;
          if (_editing) {
            _controller.forward();
          } else {
            _controller.reverse();
            if (widget.onEdit != null) {
              widget.onEdit!(_editController.text);
            }
          }
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Material(
            elevation: _elevationAnimation.value,
            borderRadius: BorderRadius.circular(12),
            color: widget.isUser ? Colors.blue[100] : Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _editing
                  ? TextField(
                      controller: _editController,
                      autofocus: true,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    )
                  : Text(widget.message),
            ),
          );
        },
      ),
    );
  }
}
