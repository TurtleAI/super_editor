import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/src/default_editor/super_editor.dart';
import 'package:super_editor/src/infrastructure/attributed_text.dart';
import 'package:super_editor/src/infrastructure/super_selectable_text.dart';
import 'package:super_editor/src/infrastructure/super_textfield/android/android_textfield.dart';
import 'package:super_editor/src/infrastructure/super_textfield/desktop/desktop_textfield.dart';
import 'package:super_editor/src/infrastructure/super_textfield/infrastructure/attributed_text_editing_controller.dart';
import 'package:super_editor/src/infrastructure/super_textfield/infrastructure/hint_text.dart';
import 'package:super_editor/src/infrastructure/super_textfield/input_method_engine/_ime_text_editing_controller.dart';
import 'package:super_editor/src/infrastructure/super_textfield/ios/ios_textfield.dart';

export 'desktop/desktop_textfield.dart';
export 'android/android_textfield.dart';
export 'ios/ios_textfield.dart';
export 'input_method_engine/_ime_text_editing_controller.dart';
export 'infrastructure/attributed_text_editing_controller.dart';
export 'infrastructure/hint_text.dart';
export 'infrastructure/magnifier.dart';
export 'infrastructure/text_scrollview.dart';
export '_test_tools.dart';

/// Custom text field implementations that offer greater control than traditional
/// Flutter text fields.
///
/// For example, the custom text fields in this package use [AttributedText]
/// instead of regular `String`s or `InlineSpan`s, which makes it easier style
/// text and add other text metadata.

/// Text field that supports styled text.
///
/// [SuperTextField] adapts to the expectations of the current platform, or
/// conforms to a specified [configuration].
///
///  - desktop uses physical keyboard handlers with a blinking cursor and
///    mouse gestures
///  - Android uses IME text input with draggable handles in the Android style
///  - iOS uses IME text input with draggable handles in the iOS style
///
/// [SuperTextField] is built on top of platform-specific text field implementations,
/// which may offer additional customization beyond that of [SuperTextField]:
///
///  - [SuperDesktopTextField], which uses physical keyboard handlers and mouse
///    gestures
///  - [SuperAndroidTextField], which uses IME text input with Android-style handles
///  - [SuperIOSTextField], which uses IME text input with iOS-style handles
class SuperTextField extends StatefulWidget {
  const SuperTextField({
    Key? key,
    this.focusNode,
    this.configuration,
    this.textController,
    this.textAlign = TextAlign.left,
    this.textStyleBuilder = defaultStyleBuilder,
    this.hintBehavior = HintBehavior.displayHintUntilFocus,
    this.hintBuilder,
    this.controlsColor,
    this.selectionColor,
    this.minLines,
    this.maxLines = 1,
    this.lineHeight,
    this.keyboardHandlers = defaultTextFieldKeyboardHandlers,
  })  : assert(minLines == null || minLines == 1 || lineHeight != null, 'minLines > 1 requires a non-null lineHeight'),
        assert(maxLines == null || maxLines == 1 || lineHeight != null, 'maxLines > 1 requires a non-null lineHeight'),
        super(key: key);

  final FocusNode? focusNode;

  /// The platform-style configuration for this text field, or `null` to
  /// automatically configure for the current platform.
  final SuperTextFieldPlatformConfiguration? configuration;

  /// Controller that holds the current text and selection for this field,
  /// similar to a standard Flutter `TextEditingController`.
  final AttributedTextEditingController? textController;

  /// The alignment of the text in this text field.
  final TextAlign textAlign;

  /// Text style factory that creates styles for the content in
  /// [textController] based on the attributions in that content.
  final AttributionStyleBuilder textStyleBuilder;

  /// Policy for when the hint should be displayed.
  final HintBehavior hintBehavior;

  /// Builder that creates the hint widget, when a hint is displayed.
  ///
  /// To easily build a hint with styled text, see [StyledHintBuilder].
  final WidgetBuilder? hintBuilder;

  /// The color of the caret, drag handles, and other controls.
  final Color? controlsColor;

  /// The color of selection rectangles that appear around selected text.
  final Color? selectionColor;

  /// The minimum height of this text field, represented as a
  /// line count.
  ///
  /// If [minLines] is non-null and greater than `1`, [lineHeight]
  /// must also be provided because there is no guarantee that all
  /// lines of text have the same height.
  ///
  /// See also:
  ///
  ///  * [maxLines]
  ///  * [lineHeight]
  final int? minLines;

  /// The maximum height of this text field, represented as a
  /// line count.
  ///
  /// If text exceeds the maximum line height, scrolling dynamics
  /// are added to accommodate the overflowing text.
  ///
  /// If [maxLines] is non-null and greater than `1`, [lineHeight]
  /// must also be provided because there is no guarantee that all
  /// lines of text have the same height.
  ///
  /// See also:
  ///
  ///  * [minLines]
  ///  * [lineHeight]
  final int? maxLines;

  /// The height of a single line of text in this text field, used
  /// with [minLines] and [maxLines] to size the text field.
  ///
  /// An explicit [lineHeight] is required because rich text in this
  /// text field might have lines of varying height, which would
  /// result in a constantly changing text field height during scrolling.
  /// To avoid that situation, a single, explicit [lineHeight] is
  /// provided and used for all text field height calculations.
  final double? lineHeight;

  /// Priority list of handlers that process all physical keyboard
  /// key presses, for text input, deletion, caret movement, etc.
  ///
  /// Only used on desktop.
  final List<TextFieldKeyboardHandler>? keyboardHandlers;

  @override
  State<SuperTextField> createState() => _SuperTextFieldState();
}

class _SuperTextFieldState extends State<SuperTextField> {
  late ImeAttributedTextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.textController != null
        ? ImeAttributedTextEditingController(controller: widget.textController, disposeClientController: false)
        : ImeAttributedTextEditingController();
  }

  @override
  void didUpdateWidget(SuperTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.textController != oldWidget.textController) {
      _controller = widget.textController != null
          ? ImeAttributedTextEditingController(controller: widget.textController, disposeClientController: false)
          : ImeAttributedTextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_configuration) {
      case SuperTextFieldPlatformConfiguration.desktop:
        return SuperDesktopTextField(
          focusNode: widget.focusNode,
          textController: _controller,
          textAlign: widget.textAlign,
          textStyleBuilder: widget.textStyleBuilder,
          hintBehavior: widget.hintBehavior,
          hintBuilder: widget.hintBuilder,
          textSelectionDecoration: TextSelectionDecoration(
            selectionColor: widget.selectionColor ?? _defaultSelectionColor,
          ),
          textCaretFactory: TextCaretFactory(
            color: widget.controlsColor ?? _defaultDesktopCaretColor,
            width: 1,
            borderRadius: BorderRadius.zero,
          ),
          minLines: widget.minLines,
          maxLines: widget.maxLines,
        );
      case SuperTextFieldPlatformConfiguration.android:
        return SuperAndroidTextField(
          focusNode: widget.focusNode,
          textController: _controller,
          textAlign: widget.textAlign,
          textStyleBuilder: widget.textStyleBuilder,
          hintBehavior: widget.hintBehavior,
          hintBuilder: widget.hintBuilder,
          caretColor: widget.controlsColor ?? _defaultAndroidControlsColor,
          selectionColor: widget.selectionColor ?? _defaultSelectionColor,
          handlesColor: widget.controlsColor ?? _defaultAndroidControlsColor,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          lineHeight: widget.lineHeight,
        );
      case SuperTextFieldPlatformConfiguration.iOS:
        return SuperIOSTextField(
          focusNode: widget.focusNode,
          textController: _controller,
          textAlign: widget.textAlign,
          textStyleBuilder: widget.textStyleBuilder,
          hintBehavior: widget.hintBehavior,
          hintBuilder: widget.hintBuilder,
          caretColor: widget.controlsColor ?? _defaultIOSControlsColor,
          selectionColor: widget.selectionColor ?? _defaultSelectionColor,
          handlesColor: widget.controlsColor ?? _defaultIOSControlsColor,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          lineHeight: widget.lineHeight,
        );
    }
  }

  SuperTextFieldPlatformConfiguration get _configuration {
    if (widget.configuration != null) {
      return widget.configuration!;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return SuperTextFieldPlatformConfiguration.android;
      case TargetPlatform.iOS:
        return SuperTextFieldPlatformConfiguration.iOS;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return SuperTextFieldPlatformConfiguration.desktop;
    }
  }
}

const _defaultSelectionColor = Color(0xFFACCEF7);
const _defaultDesktopCaretColor = Color(0xFF000000);

const _defaultAndroidControlsColor = Color(0xFFA4C639);

const _defaultIOSControlsColor = Color(0xFF2196F3);

/// Configures a [SuperTextField] for the given platform.
///
/// Desktop uses physical keyboard handlers, while mobile uses the IME.
///
/// Desktop uses a blinking caret, while mobile uses a draggable caret
/// and selection handles, styled per platform.
enum SuperTextFieldPlatformConfiguration {
  desktop,
  android,
  iOS,
}
