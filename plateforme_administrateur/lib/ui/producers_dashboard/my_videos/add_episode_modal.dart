import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class AddEpisodeModal extends StatefulWidget {
  final int seasonNumber;
  final Function(String, String, int, String) onAddEpisode;

  const AddEpisodeModal({
    super.key,
    required this.seasonNumber,
    required this.onAddEpisode,
  });

  @override
  State<AddEpisodeModal> createState() => _AddEpisodeModalState();
}

class _AddEpisodeModalState extends State<AddEpisodeModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _videoPath = '';
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _videoPath = result.files.single.path!);
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        title: Text('${l10n.addEpisode} (S${widget.seasonNumber})'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: [
                  Tab(text: l10n.detailsTab),
                  Tab(text: l10n.videoTab),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    // Onglet Détails
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: l10n.titleLabel,
                              hintText: l10n.titleHint,
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? l10n.requiredField : null,
                          ),
                          TextFormField(
                            controller: _descController,
                            decoration: InputDecoration(
                              labelText: l10n.descriptionLabel,
                            ),
                            maxLines: 3,
                          ),
                          TextFormField(
                            controller: _durationController,
                            decoration: InputDecoration(
                              labelText: l10n.durationLabel,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return l10n.requiredField;
                              if (int.tryParse(value!) == null) return l10n.invalidNumber;
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    // Onglet Vidéo
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_videoPath.isNotEmpty)
                          Text(
                            '${l10n.selectedFile}: ${_videoPath.split('/').last}',
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: Text(l10n.uploadVideo),
                          onPressed: _isUploading ? null : _pickVideo,
                        ),
                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_videoPath.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.selectVideoFirst)),
                  );
                  return;
                }
                widget.onAddEpisode(
                  _titleController.text,
                  _descController.text,
                  int.parse(_durationController.text),
                  _videoPath,
                );
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
