import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/utils/focus_utils.dart';
import 'package:app_ekeflicks/utils/keyboard_navigation_utils.dart';
import 'package:app_ekeflicks/utils/keyboard_text_manager.dart';

class TvVirtualKeyboard extends StatefulWidget {
  final Function(String) onTextInput;
  final Function() onBackspace;
  final Function() onEnter;
  final FocusNode? focusNode;
  final String selectedLanguage;
  final Color? backgroundColor;
  final Color? keyColor;
  final Color? selectedKeyColor;
  final double? maxWidth;
  final TextEditingController? textController;

  const TvVirtualKeyboard({
    super.key,
    required this.onTextInput,
    required this.onBackspace,
    required this.onEnter,
    this.focusNode,
    required this.selectedLanguage,
    this.backgroundColor,
    this.keyColor,
    this.selectedKeyColor,
    this.maxWidth,
    this.textController,
  });

  @override
  State<TvVirtualKeyboard> createState() => _TvVirtualKeyboardState();
}

class _TvVirtualKeyboardState extends State<TvVirtualKeyboard>
    with KeyboardNavigationMixin {
  final List<List<String>> _englishKeys = [
    ['1','2','3','4','5','6','7','8','9','0'],
    ['q','w','e','r','t','y','u','i','o','p'],
    ['a','s','d','f','g','h','j','k','l'],
    ['z','x','c','v','b','n','m','@','.','-','_'],
    ['space','backspace','enter']
  ];

  final List<List<String>> _frenchKeys = [
    ['1','2','3','4','5','6','7','8','9','0'],
    ['a','z','e','r','t','y','u','i','o','p'],
    ['q','s','d','f','g','h','j','k','l','m'],
    ['w','x','c','v','b','n',',','@','.','-','_'],
    ['space','backspace','enter']
  ];

  int _selectedRow = 0;
  int _selectedKey = 0;
  bool _isUpperCase = false;
  bool _isShiftLock = false;
  late FocusNode _keyboardFocusNode;
  late KeyboardTextManager _textManager;

  List<List<String>> get _currentKeys =>
      widget.selectedLanguage == 'fr' ? _frenchKeys : _englishKeys;

  Color get _backgroundColor => widget.backgroundColor ?? Colors.grey[900]!;
  Color get _keyColor => widget.keyColor ?? Colors.grey[800]!;
  Color get _selectedKeyColor => widget.selectedKeyColor ?? AppTheme.primaryOrange;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = widget.focusNode ?? FocusNode();

    if (widget.textController != null) {
      _textManager = KeyboardTextManager(widget.textController!);
    }

    // Setup keyboard shortcuts
    addKeyHandler(LogicalKeyboardKey.shiftLeft, _toggleUpperCase);
    addKeyHandler(LogicalKeyboardKey.shiftRight, _toggleUpperCase);
    addKeyHandler(LogicalKeyboardKey.capsLock, _toggleShiftLock);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    if (widget.textController != null) {
      _textManager.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    final result = KeyboardNavigationService.handleListNavigation(
      event,
      currentIndex: _selectedRow * 10 + _selectedKey,
      itemCount: _currentKeys.fold(0, (sum, row) => sum + row.length),
      onIndexChange: (newIndex) {
        int remaining = newIndex;
        for (int row = 0; row < _currentKeys.length; row++) {
          if (remaining < _currentKeys[row].length) {
            setState(() {
              _selectedRow = row;
              _selectedKey = remaining;
            });
            break;
          }
          remaining -= _currentKeys[row].length;
        }
      },
      columns: _currentKeys[0].length,
      onSelect: _pressKey,
      onBack: () {},
    );

    if (result == KeyEventResult.ignored && event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.shiftLeft:
        case LogicalKeyboardKey.shiftRight:
          _toggleUpperCase();
          break;
        case LogicalKeyboardKey.capsLock:
          _toggleShiftLock();
          break;
        default:
          break;
      }
    }
  }

  void _toggleUpperCase() {
    setState(() {
      if (_isShiftLock) {
        _isShiftLock = false;
        _isUpperCase = false;
      } else {
        _isUpperCase = !_isUpperCase;
      }
    });
  }

  void _toggleShiftLock() {
    setState(() {
      _isShiftLock = !_isShiftLock;
      _isUpperCase = _isShiftLock;
    });
  }

  void _pressKey() {
    final key = _currentKeys[_selectedRow][_selectedKey];
    String value;

    if (key.length == 1) {
      value = _isUpperCase ? key.toUpperCase() : key;
    } else {
      value = key;
    }

    switch (key) {
      case 'space':
        widget.onTextInput(' ');
        if (!_isShiftLock && _isUpperCase) setState(() => _isUpperCase = false);
        break;
      case 'backspace':
        widget.onBackspace();
        break;
      case 'enter':
        widget.onEnter();
        break;
      default:
        widget.onTextInput(value);
        if (!_isShiftLock && _isUpperCase) setState(() => _isUpperCase = false);
    }
  }

  Widget _buildKey(BuildContext context, String key, bool isSelected) {
    final loc = AppLocalizations.of(context);
    String displayText = key;

    if (key == 'space') displayText = loc?.espaceClavier ?? 'Espace';
    else if (key == 'backspace') {
      return Icon(Icons.backspace, size: _getKeyFontSize(context) * 1.5, color: Colors.white);
    } else if (key == 'enter') displayText = loc?.entreeClavier ?? 'Entrée';
    else if (_isUpperCase && key.length == 1) displayText = displayText.toUpperCase();

    return Container(
      padding: _getKeyPadding(context, key),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: _getKeyFontSize(context),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  double _getKeySize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 36;
    if (width < 900) return 42;
    if (width < 1200) return 48;
    return 54;
  }

  double _getKeyFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 12;
    if (width < 900) return 14;
    if (width < 1200) return 16;
    return 18;
  }

  EdgeInsets _getKeyPadding(BuildContext context, String key) {
    final base = _getKeySize(context) * 0.15;
    if (key == 'space') return EdgeInsets.symmetric(horizontal: base * 2, vertical: base);
    return EdgeInsets.symmetric(horizontal: base, vertical: base);
  }

  EdgeInsets _getKeyboardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return const EdgeInsets.all(8);
    if (width < 900) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  double _getKeyboardMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return widget.maxWidth ??
        (width < 600 ? width * 0.95 :
         width < 900 ? width * 0.85 :
         width < 1200 ? width * 0.75 :
         width * 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = _getKeyboardMaxWidth(context);
    final keyboardPadding = _getKeyboardPadding(context);

    return FocusUtils.buildFocusIndicator(
      focusNode: _keyboardFocusNode,
      child: RawKeyboardListener(
        focusNode: _keyboardFocusNode,
        onKey: (event) {
          _handleKeyEvent(event);
          handleKeyEvent(_keyboardFocusNode, event);
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: keyboardPadding,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0,5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUpperCase || _isShiftLock)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Icon(
                    _isShiftLock ? Icons.keyboard_capslock : Icons.arrow_upward,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
              ...List.generate(_currentKeys.length, (rowIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_currentKeys[rowIndex].length, (keyIndex) {
                      final key = _currentKeys[rowIndex][keyIndex];
                      final isSelected = rowIndex == _selectedRow && keyIndex == _selectedKey;
                      final isSpecialKey = key == 'space' || key == 'backspace' || key == 'enter';
                      final flex = isSpecialKey ? (key == 'space' ? 4 : 2) : 1;

                      return Expanded(
                        flex: flex,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: Material(
                            color: isSelected ? _selectedKeyColor : _keyColor,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedRow = rowIndex;
                                  _selectedKey = keyIndex;
                                });
                                _pressKey();
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: _buildKey(context, key, isSelected),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
