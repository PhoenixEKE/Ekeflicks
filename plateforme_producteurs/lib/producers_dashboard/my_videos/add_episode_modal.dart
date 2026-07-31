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

class _AddEpisodeModalState extends State<AddEpisodeModal> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _videoPath = '';
  bool _isUploading = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CORRECTION : Utilisation correcte avec paramètre
              Text(
                l10n.addEpisode(widget.seasonNumber),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.detailsTab),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.videoTab),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet Détails
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: l10n.titleLabel,
                                hintText: l10n.titleHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[800],
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                              style: TextStyle(color: Colors.white),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? l10n.requiredField : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descController,
                              decoration: InputDecoration(
                                labelText: l10n.descriptionLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[800],
                                labelStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              style: TextStyle(color: Colors.white),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _durationController,
                              decoration: InputDecoration(
                                labelText: l10n.durationLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[800],
                                labelStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              style: TextStyle(color: Colors.white),
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
                    ),
                    // Onglet Vidéo
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_videoPath.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.selectedFile,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          _videoPath.split('/').last,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _videoPath = '';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.video_library,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.selectVideo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.supportedFormats,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  icon: _isUploading 
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.upload),
                                  label: Text(
                                    _isUploading ? l10n.uploading : l10n.uploadVideo,
                                  ),
                                  onPressed: _isUploading ? null : _pickVideo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (_videoPath.isEmpty && !_isUploading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                l10n.selectVideoFirst,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_tabController.index == 0) {
                        if (_formKey.currentState!.validate()) {
                          if (_videoPath.isEmpty) {
                            _tabController.animateTo(1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.selectVideoFirst),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _submitEpisode();
                        }
                      } else {
                        if (_videoPath.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.selectVideoFirst),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          _submitEpisode();
                        } else {
                          _tabController.animateTo(0);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.add),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitEpisode() {
    widget.onAddEpisode(
      _titleController.text,
      _descController.text,
      int.parse(_durationController.text),
      _videoPath,
    );
    Navigator.pop(context);
  }
}