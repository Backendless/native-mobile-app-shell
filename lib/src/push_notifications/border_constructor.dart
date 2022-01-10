import 'package:flutter/material.dart';

BoxDecoration border() {
  Border borders = Border(
    bottom: createBorder(),
    left: createBorder(),
    right: createBorder(),
  );
  return BoxDecoration(border: borders);
}

BorderSide createBorder() {
  return BorderSide(color: Colors.grey.shade700);
}
