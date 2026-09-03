import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(
    MaterialApp(
      home: const UploadPage(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

enum ContentType { serie, film, documentaire, telerealite }

enum LanguageOption { francais, anglais, autres }

class PersonWithImage {
  final String name;
  final String? imagePath;
  PersonWithImage({required this.name, this.imagePath});
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>();
  ContentType? _contentType;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  static const List<String> allGenres = [
    'Action',
    'Aventure',
    'Comédie',
    'Drame',
    'Documentaire',
    'Horreur',
    'Romance',
    'Science-Fiction',
    'Fantastique',
    'Thriller',
    'Animation',
    'Musical',
    'Biopic',
    'Famille',
    'Historique',
    'Policier',
    'Sport',
  ];
  final Set<String> selectedGenres = {};

  LanguageOption? selectedLanguage;
  final languageOtherController = TextEditingController();
  int? releaseYear;
  String? selectedCountry;
  final countryOtherController = TextEditingController();

  final statut = "En attente";
  final directorNameController = TextEditingController();
  String? directorImagePath;
  final screenwriterNameController = TextEditingController();
  String? screenwriterImagePath;
  final List<PersonWithImage> producers = [];
  final List<PersonWithImage> actors = [];

  File? trailerFile;
  VideoPlayerController? trailerPlayerController;

  File? posterFile;
  File? bannerFile;
  File? videoFile;
  VideoPlayerController? videoPlayerController;

  final List<SeasonWrapper> seasons = [];
  final ImagePicker _picker = ImagePicker();

  static const List<String> africanCountries = [
    "Algérie",
    "Angola",
    "Bénin",
    "Botswana",
    "Burkina Faso",
    "Burundi",
    "Cameroun",
    "Cap-Vert",
    "République centrafricaine",
    "Tchad",
    "Comores",
    "République du Congo",
    "République démocratique du Congo",
    "Côte d'Ivoire",
    "Djibouti",
    "Égypte",
    "Guinée équatoriale",
    "Érythrée",
    "Eswatini",
    "Éthiopie",
    "Gabon",
    "Gambie",
    "Ghana",
    "Guinée",
    "Guinée-Bissau",
    "Kenya",
    "Lesotho",
    "Liberia",
    "Libye",
    "Madagascar",
    "Malawi",
    "Mali",
    "Mauritanie",
    "Maurice",
    "Maroc",
    "Mozambique",
    "Namibie",
    "Niger",
    "Nigéria",
    "Rwanda",
    "São Tomé-et-Príncipe",
    "Sénégal",
    "Seychelles",
    "Sierra Leone",
    "Somalie",
    "Afrique du Sud",
    "Soudan du Sud",
    "Soudan",
    "Tanzanie",
    "Togo",
    "Tunisie",
    "Ouganda",
    "Zambie",
    "Zimbabwe",
  ];

  Future<String?> _pickImagePath() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    return picked?.path;
  }

  Future<String?> _pickVideoPath() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    return picked?.path;
  }

  Future<void> _pickTrailer() async {
    final p = await _pickVideoPath();
    if (p == null) return;

    trailerPlayerController?.dispose();

    trailerPlayerController = VideoPlayerController.file(File(p));
    await trailerPlayerController!.initialize();
    trailerPlayerController!.setLooping(true);
    trailerPlayerController!.play();

    setState(() => trailerFile = File(p));
  }

  void _addProducer() {
    final nameC = TextEditingController();
    String? pickedImagePath;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addProducerTitle),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.nameLabel,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final p = await _pickImagePath();
                      if (p != null) setLocal(() => pickedImagePath = p);
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(AppLocalizations.of(context)!.addImageButton),
                  ),
                  const SizedBox(width: 8),
                  if (pickedImagePath != null)
                    Flexible(
                      child: Text(
                        pickedImagePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.trim().isEmpty) return;
              setState(() {
                producers.add(
                  PersonWithImage(
                    name: nameC.text.trim(),
                    imagePath: pickedImagePath,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.addButton),
          ),
        ],
      ),
    );
  }

  void _addActor() {
    final nameC = TextEditingController();
    String? pickedImagePath;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addActorTitle),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.nameLabel,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final p = await _pickImagePath();
                      if (p != null) setLocal(() => pickedImagePath = p);
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(AppLocalizations.of(context)!.addImageButton),
                  ),
                  const SizedBox(width: 8),
                  if (pickedImagePath != null)
                    Flexible(
                      child: Text(
                        pickedImagePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.trim().isEmpty) return;
              setState(() {
                actors.add(
                  PersonWithImage(
                    name: nameC.text.trim(),
                    imagePath: pickedImagePath,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.addButton),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPersonImageFor(String which) async {
    final p = await _pickImagePath();
    if (p == null) return;
    setState(() {
      if (which == 'director') directorImagePath = p;
      if (which == 'screenwriter') screenwriterImagePath = p;
    });
  }

  void _addSeason() {
    final nextNumber = seasons.length + 1;
    final key = GlobalKey<SeasonState>();
    final wrapper = SeasonWrapper(
      key: key,
      season: SeasonForm(
        key: key,
        seasonNumber: nextNumber,
        onRemove: () {
          setState(() => seasons.removeWhere((w) => w.key == key));
        },
      ),
    );
    setState(() => seasons.add(wrapper));
  }

  Future<void> _pickGlobalPoster(bool isPoster) async {
    final p = await _pickImagePath();
    if (p == null) return;
    setState(() {
      if (isPoster) {
        posterFile = File(p);
      } else {
        bannerFile = File(p);
      }
    });
  }

  Future<void> _pickGlobalVideo() async {
    final p = await _pickVideoPath();
    if (p == null) return;
    videoPlayerController?.dispose();
    videoPlayerController = VideoPlayerController.file(File(p));
    await videoPlayerController!.initialize();
    videoPlayerController!.setLooping(true);
    videoPlayerController!.play();
    setState(() => videoFile = File(p));
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.formValidationError),
        ),
      );
      return;
    }

    if (selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.genreSelectionError),
        ),
      );
      return;
    }

    if (selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageSelectionError),
        ),
      );
      return;
    }
    if (selectedLanguage == LanguageOption.autres &&
        languageOtherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageSpecifyError),
        ),
      );
      return;
    }

    if (selectedCountry == null || selectedCountry!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.countrySelectionError),
        ),
      );
      return;
    }
    if (selectedCountry == "Autres" &&
        countryOtherController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.countrySpecifyError),
        ),
      );
      return;
    }

    if (releaseYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.yearSelectionError),
        ),
      );
      return;
    }

    if (directorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.directorNameError),
        ),
      );
      return;
    }
    if (screenwriterNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.screenwriterNameError),
        ),
      );
      return;
    }

    if (_contentType != ContentType.serie) {
      if (posterFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.posterSelectionError),
          ),
        );
        return;
      }
      if (bannerFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bannerSelectionError),
          ),
        );
        return;
      }
      if (videoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.videoSelectionError),
          ),
        );
        return;
      }
    } else {
      if (seasons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.seasonSelectionError),
          ),
        );
        return;
      }
      for (final w in seasons) {
        final valid = w.key.currentState?.validateSeason() ?? false;
        if (!valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.seasonValidationError,
              ),
            ),
          );
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.formSubmissionSuccess),
      ),
    );
  }

  Future<void> _confirmRemovePerson<T>(List<T> list, T item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmationTitle),
        content: Text(AppLocalizations.of(context)!.confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.deleteButton),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => list.remove(item));
  }

  List<int> get years {
    final currentYear = DateTime.now().year;
    return [for (var y = 1980; y <= currentYear; y++) y];
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    languageOtherController.dispose();
    countryOtherController.dispose();
    directorNameController.dispose();
    screenwriterNameController.dispose();
    videoPlayerController?.dispose();
    trailerPlayerController?.dispose();
    for (final w in seasons) {
      w.key.currentState?.disposeControllers();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.uploadFormTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contentTypeLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ContentType>(
                value: _contentType,
                items: ContentType.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _contentType = v),
                validator: (v) => v == null ? l10n.requiredFieldError : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TITLE
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l10n.titleLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.requiredFieldError : null,
              ),
              const SizedBox(height: 16),

              // DESCRIPTION
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.descriptionLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.requiredFieldError : null,
              ),
              const SizedBox(height: 16),

              // GENRES
              Text(
                l10n.genresLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allGenres.map((g) {
                  final selected = selectedGenres.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        selectedGenres.add(g);
                      } else {
                        selectedGenres.remove(g);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // LANGUE
              Text(
                l10n.languageLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<LanguageOption>(
                value: selectedLanguage,
                items: LanguageOption.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedLanguage = v),
                validator: (v) => v == null ? l10n.requiredFieldError : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              if (selectedLanguage == LanguageOption.autres) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: languageOtherController,
                  decoration: InputDecoration(
                    labelText: l10n.languageSpecifyLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (selectedLanguage == LanguageOption.autres &&
                        (v == null || v.isEmpty)) {
                      return l10n.requiredFieldError;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              // PAYS
              Text(
                l10n.countryLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCountry,
                items: [
                  ...africanCountries.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                  DropdownMenuItem(
                    value: "Autres",
                    child: Text(l10n.otherOption),
                  ),
                ],

                onChanged: (v) => setState(() => selectedCountry = v),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.requiredFieldError : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              if (selectedCountry == "Autres") ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: countryOtherController,
                  decoration: InputDecoration(
                    labelText: l10n.countrySpecifyLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (selectedCountry == "Autres" &&
                        (v == null || v.isEmpty)) {
                      return l10n.requiredFieldError;
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Année
              Text(
                l10n.releaseYearLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: releaseYear,
                items: years
                    .map(
                      (y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())),
                    )
                    .toList(),
                onChanged: (v) => setState(() => releaseYear = v),
                validator: (v) => v == null ? l10n.requiredFieldError : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Équipe de production
              Text(
                l10n.productionTeamTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Réalisateur
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: directorNameController,
                      decoration: InputDecoration(
                        labelText: l10n.directorLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? l10n.requiredFieldError
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickPersonImageFor('director'),
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(l10n.addImageButton),
                      ),
                      if (directorImagePath != null) const SizedBox(height: 6),
                      if (directorImagePath != null)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Image.file(
                            File(directorImagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Scénariste
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: screenwriterNameController,
                      decoration: InputDecoration(
                        labelText: l10n.screenwriterLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? l10n.requiredFieldError
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickPersonImageFor('screenwriter'),
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(l10n.addImageButton),
                      ),
                      if (screenwriterImagePath != null)
                        const SizedBox(height: 6),
                      if (screenwriterImagePath != null)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Image.file(
                            File(screenwriterImagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Producteurs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.producersLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addProducer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(l10n.addButton),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...producers.map(
                (p) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: p.imagePath != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(File(p.imagePath!)),
                            radius: 20,
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(p.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmRemovePerson(producers, p),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Acteurs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.actorsLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addActor,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(l10n.addButton),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...actors.map(
                (p) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: p.imagePath != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(File(p.imagePath!)),
                            radius: 20,
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(p.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmRemovePerson(actors, p),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Saisons (si série) ---
              if (_contentType == ContentType.serie) ...[
                Text(
                  l10n.seasonManagementTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.seasonsLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: _addSeason,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(l10n.addSeasonButton),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...seasons.map((w) => w.season),
                const SizedBox(height: 16),
              ],

              // Bande annonce
              if (_contentType != ContentType.serie) ...[
                Text(
                  l10n.trailerLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickTrailer,
                      child: Text(l10n.addTrailerButton),
                    ),
                    const SizedBox(width: 16),
                    if (trailerFile != null &&
                        trailerPlayerController != null &&
                        trailerPlayerController!.value.isInitialized)
                      Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio:
                                trailerPlayerController!.value.aspectRatio,
                            child: VideoPlayer(trailerPlayerController!),
                          ),
                        ),
                      ),
                    if (trailerFile != null &&
                        (trailerPlayerController == null ||
                            !trailerPlayerController!.value.isInitialized))
                      Text(trailerFile!.path.split('/').last),
                  ],
                ),
                if (trailerFile != null &&
                    trailerPlayerController != null &&
                    trailerPlayerController!.value.isInitialized) ...[
                  const SizedBox(height: 8),
                  VideoProgressIndicator(
                    trailerPlayerController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      trailerPlayerController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        if (trailerPlayerController!.value.isPlaying) {
                          trailerPlayerController!.pause();
                        } else {
                          trailerPlayerController!.play();
                        }
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],

              if (_contentType != ContentType.serie) ...[
                // Fichiers multimédias (pour film)
                Text(
                  l10n.mediaFilesTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  l10n.posterLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _pickGlobalPoster(true),
                      child: Text(l10n.addPosterButton),
                    ),
                    const SizedBox(width: 16),
                    if (posterFile != null)
                      Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(posterFile!, fit: BoxFit.cover),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.bannerLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _pickGlobalPoster(false),
                      child: Text(l10n.addBannerButton),
                    ),
                    const SizedBox(width: 16),
                    if (bannerFile != null)
                      Container(
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(bannerFile!, fit: BoxFit.cover),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  l10n.mainVideoLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickGlobalVideo,
                      child: Text(l10n.addVideoButton),
                    ),
                    const SizedBox(width: 16),
                    if (videoFile != null &&
                        videoPlayerController != null &&
                        videoPlayerController!.value.isInitialized)
                      Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio:
                                videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(videoPlayerController!),
                          ),
                        ),
                      ),
                    if (videoFile != null &&
                        (videoPlayerController == null ||
                            !videoPlayerController!.value.isInitialized))
                      Text(videoFile!.path.split('/').last),
                  ],
                ),
                if (videoFile != null &&
                    videoPlayerController != null &&
                    videoPlayerController!.value.isInitialized) ...[
                  const SizedBox(height: 8),
                  VideoProgressIndicator(
                    videoPlayerController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      videoPlayerController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        if (videoPlayerController!.value.isPlaying) {
                          videoPlayerController!.pause();
                        } else {
                          videoPlayerController!.play();
                        }
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],

              // BOUTON SUBMIT
              Center(
                child: ElevatedButton(
                  onPressed: _saveForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Text(
                      l10n.submitButton.toUpperCase(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class SeasonWrapper {
  final GlobalKey<SeasonState> key;
  final SeasonForm season;
  SeasonWrapper({required this.key, required this.season});
}

class SeasonForm extends StatefulWidget {
  final int seasonNumber;
  final VoidCallback onRemove;
  const SeasonForm({
    super.key,
    required this.seasonNumber,
    required this.onRemove,
  });

  @override
  SeasonState createState() => SeasonState();
}

class SeasonState extends State<SeasonForm> {
  final TextEditingController seasonDescController = TextEditingController();
  String? posterPath;
  String? bannerPath;
  File? trailerFile;
  VideoPlayerController? trailerPlayerController;

  final List<EpisodeWrapper> episodes = [];
  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    return picked?.path;
  }

  Future<String?> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    return picked?.path;
  }

  Future<void> _pickTrailer() async {
    final p = await _pickVideo();
    if (p == null) return;

    trailerPlayerController?.dispose();

    trailerPlayerController = VideoPlayerController.file(File(p));
    await trailerPlayerController!.initialize();
    trailerPlayerController!.setLooping(true);
    trailerPlayerController!.play();

    setState(() => trailerFile = File(p));
  }

  void _addEpisode() {
    final nextNum = episodes.length + 1;
    final key = GlobalKey<EpisodeState>();
    final wrapper = EpisodeWrapper(
      key: key,
      episode: EpisodeForm(
        key: key,
        episodeNumber: nextNum,
        onRemove: () {
          setState(() => episodes.removeWhere((w) => w.key == key));
        },
      ),
    );
    setState(() => episodes.add(wrapper));
  }

  bool validateSeason() {
    if (posterPath == null || bannerPath == null) return false;
    if (episodes.isEmpty) return false;
    for (final w in episodes) {
      if (!(w.key.currentState?.validateEpisode() ?? false)) return false;
    }
    return true;
  }

  void disposeControllers() {
    seasonDescController.dispose();
    trailerPlayerController?.dispose();
    for (final w in episodes) {
      w.key.currentState?.disposeControllers();
    }
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.seasonLabel} ${widget.seasonNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addEpisode,
                      tooltip: l10n.addEpisodeTooltip,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onRemove,
                      tooltip: l10n.removeSeasonTooltip,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: seasonDescController,
              decoration: InputDecoration(
                labelText: l10n.seasonDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 8),

            // Poster
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final p = await _pickImage();
                    if (p != null) setState(() => posterPath = p);
                  },
                  child: Text(l10n.addSeasonPosterButton),
                ),
                const SizedBox(width: 12),
                if (posterPath != null)
                  SizedBox(
                    width: 80,
                    height: 120,
                    child: Image.file(File(posterPath!), fit: BoxFit.cover),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Banner
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final p = await _pickImage();
                    if (p != null) setState(() => bannerPath = p);
                  },
                  child: Text(l10n.addSeasonBannerButton),
                ),
                const SizedBox(width: 12),
                if (bannerPath != null)
                  SizedBox(
                    width: 160,
                    height: 80,
                    child: Image.file(File(bannerPath!), fit: BoxFit.cover),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Trailer
            Text(
              l10n.seasonTrailerLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickTrailer,
                  child: Text(l10n.addTrailerButton),
                ),
                const SizedBox(width: 16),
                if (trailerFile != null &&
                    trailerPlayerController != null &&
                    trailerPlayerController!.value.isInitialized)
                  Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: trailerPlayerController!.value.aspectRatio,
                        child: VideoPlayer(trailerPlayerController!),
                      ),
                    ),
                  ),
                if (trailerFile != null &&
                    (trailerPlayerController == null ||
                        !trailerPlayerController!.value.isInitialized))
                  Text(trailerFile!.path.split('/').last),
              ],
            ),
            if (trailerFile != null &&
                trailerPlayerController != null &&
                trailerPlayerController!.value.isInitialized) ...[
              const SizedBox(height: 8),
              VideoProgressIndicator(
                trailerPlayerController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.grey,
                ),
              ),
              IconButton(
                icon: Icon(
                  trailerPlayerController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 36,
                ),
                onPressed: () {
                  setState(() {
                    if (trailerPlayerController!.value.isPlaying) {
                      trailerPlayerController!.pause();
                    } else {
                      trailerPlayerController!.play();
                    }
                  });
                },
              ),
            ],

            const SizedBox(height: 12),
            Text(
              l10n.episodesLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...episodes.map((w) => w.episode),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class EpisodeWrapper {
  final GlobalKey<EpisodeState> key;
  final EpisodeForm episode;
  EpisodeWrapper({required this.key, required this.episode});
}

class EpisodeForm extends StatefulWidget {
  final int episodeNumber;
  final VoidCallback onRemove;
  const EpisodeForm({
    super.key,
    required this.episodeNumber,
    required this.onRemove,
  });

  @override
  EpisodeState createState() => EpisodeState();
}

class EpisodeState extends State<EpisodeForm> {
  final TextEditingController descController = TextEditingController();
  String? videoPath;
  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    return picked?.path;
  }

  bool validateEpisode() {
    if (descController.text.trim().isEmpty) return false;
    if (videoPath == null) return false;
    return true;
  }

  void disposeControllers() {
    descController.dispose();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.episodeLabel} ${widget.episodeNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: descController,
              decoration: InputDecoration(
                labelText: l10n.episodeDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.isEmpty ? l10n.requiredFieldError : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final p = await _pickVideo();
                    if (p != null) setState(() => videoPath = p);
                  },
                  child: Text(l10n.addVideoButton),
                ),
                const SizedBox(width: 12),
                if (videoPath != null)
                  Expanded(
                    child: Text(
                      videoPath!.split('/').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
