// lib/widgets/exercise_card.dart

import 'package:flutter/material.dart';
import '../models/exercise_item.dart';

class ExerciseCard extends StatefulWidget {
  final ExerciseItem exercise;
  final VoidCallback onDelete;

  const ExerciseCard({Key? key, required this.exercise, required this.onDelete}) : super(key: key);

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        elevation: 4,
        child: ListTile(
          leading: const Icon(Icons.fitness_center, color: Colors.orange),
          title: Text(widget.exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${widget.exercise.sets} x ${widget.exercise.reps} @ ${widget.exercise.weight}kg',
            style: const TextStyle(height: 1.4),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await _controller.reverse();
              widget.onDelete();
            },
          ),
        ),
      ),
    );
  }
}
