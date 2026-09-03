/*modal season*/
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class AddSeasonModal extends StatefulWidget {
  final int nextSeasonNumber;
  final Function(String, String, String, String, String) onAddSeason;

  const AddSeasonModal({
    super.key,
    required this.nextSeasonNumber,
    required this.onAddSeason,
  });

  @override
  State<AddSeasonModal> createState() => _AddSeasonModalState();
}

class _AddSeasonModalState extends State<AddSeasonModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _posterPath = '';
  String _bannerPath = '';
  String _trailerPath = '';

  bool _isUploadingPoster = false;
  bool _isUploadingBanner = false;
  bool _isUploadingTrailer = false;

  @override
  void initState() {
    super.initState();
    // Titre par défaut
    _titleController.text = 'Saison ${widget.nextSeasonNumber}';
  }

  Future<void> _pickImage(String type) async {
    switch (type) {
      case 'poster':
        setState(() => _isUploadingPoster = true);
        break;
      case 'banner':
        setState(() => _isUploadingBanner = true);
        break;
      case 'trailer':
        setState(() => _isUploadingTrailer = true);
        break;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: type == 'trailer' ? FileType.video : FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          switch (type) {
            case 'poster':
              _posterPath = result.files.single.path!;
              break;
            case 'banner':
              _bannerPath = result.files.single.path!;
              break;
            case 'trailer':
              _trailerPath = result.files.single.path!;
              break;
          }
        });
      }
    } finally {
      setState(() {
        switch (type) {
          case 'poster':
            _isUploadingPoster = false;
            break;
          case 'banner':
            _isUploadingBanner = false;
            break;
          case 'trailer':
            _isUploadingTrailer = false;
            break;
        }
      });
    }
  }

  void _removeFile(String type) {
    setState(() {
      switch (type) {
        case 'poster':
          _posterPath = '';
          break;
        case 'banner':
          _bannerPath = '';
          break;
        case 'trailer':
          _trailerPath = '';
          break;
      }
    });
  }

  Widget _buildFileUploadSection({
    required String title,
    required String filePath,
    required bool isUploading,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    required IconData icon,
    required String fileType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        if (filePath.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.success, width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fichier sélectionné:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        filePath.split('/').last,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.error, size: 18),
                  onPressed: onRemove,
                ),
              ],
            ),
          ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(
                filePath.isEmpty ? 'Ajouter $fileType' : 'Remplacer $fileType',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: isUploading ? null : onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Sélectionner'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajouter la Saison ${widget.nextSeasonNumber}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Informations de base
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Titre de la saison',
                            hintText: 'Ex: Saison ${widget.nextSeasonNumber}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppTheme.cardBackground,
                            labelStyle: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          style: TextStyle(color: AppTheme.textPrimary),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le titre est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Description de la saison...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppTheme.cardBackground,
                            labelStyle: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          style: TextStyle(color: AppTheme.textPrimary),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // Upload des médias
                        _buildFileUploadSection(
                          title: 'Affiche (Poster)',
                          filePath: _posterPath,
                          isUploading: _isUploadingPoster,
                          onUpload: () => _pickImage('poster'),
                          onRemove: () => _removeFile('poster'),
                          icon: Icons.photo,
                          fileType: 'l\'affiche',
                        ),

                        _buildFileUploadSection(
                          title: 'Bannière',
                          filePath: _bannerPath,
                          isUploading: _isUploadingBanner,
                          onUpload: () => _pickImage('banner'),
                          onRemove: () => _removeFile('banner'),
                          icon: Icons.photo_library,
                          fileType: 'la bannière',
                        ),

                        _buildFileUploadSection(
                          title: 'Bande-annonce',
                          filePath: _trailerPath,
                          isUploading: _isUploadingTrailer,
                          onUpload: () => _pickImage('trailer'),
                          onRemove: () => _removeFile('trailer'),
                          icon: Icons.video_library,
                          fileType: 'la bande-annonce',
                        ),
                      ],
                    ),
                  ),
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
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onAddSeason(
                          _titleController.text,
                          _descController.text,
                          _posterPath,
                          _bannerPath,
                          _trailerPath,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    child: Text('Ajouter la saison'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
