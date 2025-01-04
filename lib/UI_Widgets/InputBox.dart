import 'package:flutter/material.dart';

class InputBox extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;

  const InputBox({
    Key? key,
    required this.hint,
    required this.controller,
    required this.focusNode
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          border: InputBorder.none, // Remove border
          hintText: hint,
        ),
      ),
    );
  }
}
