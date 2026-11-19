import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/content_provider.dart';
import 'package:app_ekeflicks/widgets/keyboards/tv_virtual_keyboard.dart';
import 'package:app_ekeflicks/utils/keyboard_text_manager.dart';

class TVSearchPage extends StatefulWidget {
  final String? initialQuery;

  const TVSearchPage({super.key, this.initialQuery});

  @override
  State<TVSearchPage> createState() => _TVSearchPageState();
}

class _TVSearchPageState extends State<TVSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  late final KeyboardTextManager _textManager;

  List<String> _searchSuggestions = [];
  List<String> _searchResults = [];
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _textManager = KeyboardTextManager(_searchController);

    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _textManager.controller.text = widget.initialQuery!;
    }

    _searchFocusNode.requestFocus();
    _searchController.addListener(_onSearchTextChanged);
    _loadPopularSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() {
      _textManager.currentText = _searchController.text;
      _updateSuggestions();
    });
  }

  void _updateSuggestions() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _searchSuggestions = _getPopularSearches();
    } else {
      _searchSuggestions =
          _getAllSuggestions()
              .where((suggestion) => suggestion.toLowerCase().contains(query))
              .toList();
    }
  }

  List<String> _getPopularSearches() {
    return [
      'Action',
      'Comédie',
      'Drame',
      'Science-fiction',
      'Horreur',
      'Romance',
      'Thriller',
      'Documentaire',
      'Animation',
      'Aventure',
    ];
  }

  List<String> _getAllSuggestions() {
    return [
      ..._getPopularSearches(),
      'Policier',
      'Fantastique',
      'Historique',
      'Guerre',
      'Western',
      'Musical',
      'Biographie',
      'Sport',
      'Familial',
      'Crime',
    ];
  }

  void _loadPopularSearches() {
    _searchSuggestions = _getPopularSearches();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchResults = [];
      });
      try {
        final results = await context.read<ContentProvider>().searchRemote(
          query,
        );
        if (mounted) {
          setState(
            () => _searchResults = results.map((item) => item.title).toList(),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La recherche est momentanément indisponible.'),
            ),
          );
        }
      }
    }
  }

  void _onTextInput(String text) {
    setState(() {
      _textManager.addText(text);
      _searchController.text = _textManager.currentText;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    });
  }

  void _onBackspace() {
    setState(() {
      _textManager.removeLastCharacter();
      _searchController.text = _textManager.currentText;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    });
  }

  void _onEnter() {
    _performSearch();
  }

  void _clearSearch() {
    setState(() {
      _textManager.clear();
      _searchController.clear();
      _showSuggestions = true;
      _searchResults.clear();
    });
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _textManager.currentText = suggestion;
      _searchController.text = suggestion;
      _performSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context);
    final bool isTV = deviceInfoProvider.isTV;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FocusableActionDetector(
        autofocus: true,
        descendantsAreFocusable: true,
        child: Stack(
          children: [
            // Background avec effet de flou
            _buildBackground(),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 60.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec champ de recherche
                  _buildSearchHeader(theme),

                  const SizedBox(height: 30),

                  // Contenu selon l'état
                  Expanded(
                    child:
                        _showSuggestions && _searchController.text.isEmpty
                            ? _buildPopularSearches(theme)
                            : _showSuggestions
                            ? _buildSearchSuggestions(theme)
                            : _buildSearchResults(theme, size),
                  ),

                  const SizedBox(height: 20),

                  // Clavier virtuel
                  if (isTV) _buildVirtualKeyboard(),
                ],
              ),
            ),

            // Bouton de fermeture
            _buildCloseButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rechercher',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.7),
                size: 32,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Films, séries, genres...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 32,
                  ),
                  onPressed: _clearSearch,
                ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSearches(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recherches populaires',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              _searchSuggestions.map((suggestion) {
                return Focus(
                  autofocus: suggestion == _searchSuggestions.first,
                  child: ActionChip(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    label: Text(
                      suggestion,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    onPressed: () => _selectSuggestion(suggestion),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: _searchSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _searchSuggestions[index];
              return Focus(
                autofocus: index == 0,
                child: ListTile(
                  leading: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    suggestion,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(ThemeData theme, Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résultats pour "${_searchController.text}"',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 32,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.7,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return Focus(
                autofocus: index == 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://picsum.photos/300/400?random=$index',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _searchResults[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualKeyboard() {
    return TvVirtualKeyboard(
      onTextInput: _onTextInput,
      onBackspace: _onBackspace,
      onEnter: _onEnter,
      focusNode: _keyboardFocusNode,
      selectedLanguage: 'fr',
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      keyColor: Colors.white.withValues(alpha: 0.1),
      selectedKeyColor: Colors.white.withValues(alpha: 0.3),
      maxWidth: MediaQuery.of(context).size.width * 0.8,
      textController: _searchController,
    );
  }

  Widget _buildCloseButton(ThemeData theme) {
    return Positioned(
      top: 40,
      right: 40,
      child: Focus(
        autofocus: true,
        child: IconButton(
          icon: Icon(Icons.close, color: Colors.white, size: 36),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
