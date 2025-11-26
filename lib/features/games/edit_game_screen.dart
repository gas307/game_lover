import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/di/service_locator.dart';
import '../../core/models/game.dart';

class EditGameScreen extends StatefulWidget {
  final Game? game;
  const EditGameScreen({super.key, this.game});

  @override
  State<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _platformsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverUrlController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final game = widget.game;
    if (game != null) {
      _titleController.text = game.title;
      _yearController.text = game.year.toString();
      _genreController.text = game.genre;
      _platformsController.text = game.platforms.join(', ');
      _descriptionController.text = game.description;
      _coverUrlController.text = game.coverUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _platformsController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final year = int.tryParse(_yearController.text.trim()) ?? 0;
    final platforms = _platformsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final game = Game(
      id: widget.game?.id ?? '',
      title: _titleController.text.trim(),
      year: year,
      genre: _genreController.text.trim(),
      description: _descriptionController.text.trim(),
      coverUrl: _coverUrlController.text.trim(),
      platforms: platforms,
    );

    try {
      if (widget.game == null) {
        await gamesRepository.addGame(game);
      } else {
        await gamesRepository.updateGame(game);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('edit_game.error_save'.tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.game != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'edit_game.title_edit'.tr() : 'edit_game.title_add'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'edit_game.label_title'.tr()),
            ),
            TextField(
              controller: _yearController,
              decoration: InputDecoration(labelText: 'edit_game.label_year'.tr()),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _genreController,
              decoration: InputDecoration(labelText: 'edit_game.label_genre'.tr()),
            ),
            TextField(
              controller: _platformsController,
              decoration: InputDecoration(
                labelText: 'edit_game.label_platforms'.tr(),
              ),
            ),
            TextField(
              controller: _coverUrlController,
              decoration: InputDecoration(
                labelText: 'edit_game.label_cover_url'.tr(),
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'edit_game.label_description'.tr()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'edit_game.button_save'.tr() : 'edit_game.button_add'.tr()),
                  ),
          ],
        ),
      ),
    );
  }
}
