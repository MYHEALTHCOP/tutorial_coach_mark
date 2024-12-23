import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/src/clipper/circle_clipper.dart';
import 'package:tutorial_coach_mark/src/clipper/rect_clipper.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint.dart';
import 'package:tutorial_coach_mark/src/paint/light_paint_rect.dart';
import 'package:tutorial_coach_mark/src/target/target_focus.dart';
import 'package:tutorial_coach_mark/src/target/target_position.dart';
import 'package:tutorial_coach_mark/src/target/target_content.dart';
import 'package:tutorial_coach_mark/src/util.dart';

class AnimatedFocusLight extends StatefulWidget {
  final List<TargetFocus> targets;
  final Function(TargetFocus)? focus;
  final FutureOr Function(TargetFocus)? clickTarget;
  final FutureOr Function(TargetFocus, TapDownDetails)?
      clickTargetWithTapPosition;
  final FutureOr Function(TargetFocus)? clickOverlay;
  final Function? removeFocus;
  final Function()? finish;
  final double paddingFocus;
  final Color colorShadow;
  final double opacityShadow;
  final Duration? focusAnimationDuration;
  final Duration? unFocusAnimationDuration;
  final Duration? pulseAnimationDuration;
  final Tween<double>? pulseVariation;
  final bool pulseEnable;
  final bool rootOverlay;
  final ImageFilter? imageFilter;
  final int initialFocus;
  final List<GlobalKey> targetKeys;
  final List<String> titles;
  final List<String> descriptions;
  final List<ContentAlign> aligns;
  final List<ShapeLightFocus> targetShapes;
  final Function() close;

  const AnimatedFocusLight({
    Key? key,
    required this.targets,
    required this.targetKeys,
    required this.descriptions,
    required this.titles,
    required this.aligns,
    required this.targetShapes,
    this.focus,
    this.finish,
    this.removeFocus,
    this.clickTarget,
    this.clickTargetWithTapPosition,
    this.clickOverlay,
    this.paddingFocus = 10,
    this.colorShadow = Colors.black,
    this.opacityShadow = 0.8,
    this.focusAnimationDuration,
    this.unFocusAnimationDuration,
    this.pulseAnimationDuration,
    this.pulseVariation,
    this.imageFilter,
    this.pulseEnable = true,
    this.rootOverlay = false,
    this.initialFocus = 0,
    required this.close,
  })  : assert(titles.length == descriptions.length &&
            titles.length == targetKeys.length &&
            targetKeys.length > 0),
        super(key: key);

  @override
  // ignore: no_logic_in_create_state
  AnimatedFocusLightState createState() => pulseEnable
      ? AnimatedPulseFocusLightState()
      : AnimatedStaticFocusLightState();
}

abstract class AnimatedFocusLightState extends State<AnimatedFocusLight>
    with TickerProviderStateMixin {
  final borderRadiusDefault = 10.0;
  final defaultFocusAnimationDuration = const Duration(milliseconds: 600);
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;

  late TargetFocus _targetFocus;
  Offset _positioned = const Offset(0.0, 0.0);
  TargetPosition? _targetPosition;

  double _sizeCircle = 100;
  int _currentFocus = 0;
  double _progressAnimated = 0;
  int nextIndex = 0;

  Future _revertAnimation();
  void _listener(AnimationStatus status);

  @override
  void initState() {
    super.initState();
    initTargets();
    _currentFocus = widget.initialFocus;
    _targetFocus = widget.targets[_currentFocus];
    _controller = AnimationController(
      vsync: this,
      duration: _targetFocus.focusAnimationDuration ??
          widget.focusAnimationDuration ??
          defaultFocusAnimationDuration,
    )..addStatusListener(_listener);

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.ease,
    );

    Future.delayed(Duration.zero, _runFocus);
  }

  TargetFocus mainTargetFocus({
    required String title,
    required String body,
    required String identify,
    required GlobalKey keyTarget,
    required ShapeLightFocus shape,
    required int current,
    String nextText = "NEXT",
    ContentAlign align = ContentAlign.bottom,
    bool showPrevous = true,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      shape: shape,
      contents: [
        TargetContent(
          align: align,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 21,
                            fontFamily: "poppins",
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00AEEF),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                           _finish();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFB4B6B9).withOpacity(0.3),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 26,
                              color: const Color(0xFF019BEA),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontFamily: "poppins",
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 1.5,
                              color: Colors.black45,
                            ),
                          ),
                          child: Text(
                            current.toString(),
                            style: TextStyle(
                              fontFamily: "poppins",
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          "  of  ${widget.titles.length}",
                          style: TextStyle(
                            fontFamily: "poppins",
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showPrevous)
                          GestureDetector(
                            onTap: () {
                              previous();
                            },
                            child: Container(
                              width: 130,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xFFCDF1FF),
                              ),
                              child: Center(
                                child: Text(
                                  "PREVIOUS",
                                  style: TextStyle(
                                      fontFamily: "poppins",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF0085C8)),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            next();
                          },
                          child: Container(
                            width: 130,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF00ACE9),
                                  Color(0xFF0095E9),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                nextText,
                                style: TextStyle(
                                    fontFamily: "poppins",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // CustomPaint(
              //   painter: ArrowPainter(),
              //   child: SizedBox(width: 50, height: 50),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  void initTargets() {
    widget.targets.clear();
    for (int i = 0; i < widget.targetKeys.length; i++) {
      widget.targets.add(mainTargetFocus(
        title: widget.titles[i],
        shape: widget.targetShapes[i],
        body: widget.descriptions[i],
        nextText:
            widget.targetKeys[i] == widget.targetKeys.last ? "FINISH" : "NEXT",
        identify: "Target",
        current: i + 1,
        keyTarget: widget.targetKeys[i],
        showPrevous: i > 0,
        align: widget.aligns[i],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void next() => _tapHandler();

  void previous() {
    nextIndex--;
    _revertAnimation();
  }

  void goTo(int index) {
    nextIndex = index;
    _revertAnimation();
  }

  Future _tapHandler({
    bool targetTap = false,
    bool overlayTap = false,
  }) async {
    nextIndex++;
    if (targetTap) {
      await widget.clickTarget?.call(_targetFocus);
    }
    if (overlayTap) {
      await widget.clickOverlay?.call(_targetFocus);
    }
    return _revertAnimation();
  }

  Future _tapHandlerForPosition(TapDownDetails tapDetails) async {
    await widget.clickTargetWithTapPosition?.call(_targetFocus, tapDetails);
  }

  void _runFocus() {
    if (_currentFocus < 0) return;
    _targetFocus = widget.targets[_currentFocus];

    _controller.duration = _targetFocus.focusAnimationDuration ??
        widget.focusAnimationDuration ??
        defaultFocusAnimationDuration;

    TargetPosition? targetPosition;
    try {
      targetPosition = getTargetCurrent(
        _targetFocus,
        rootOverlay: widget.rootOverlay,
      );
    } on NotFoundTargetException catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
    }

    if (targetPosition == null) {
      _finish();
      return;
    }

    safeSetState(() {
      _targetPosition = targetPosition!;

      _positioned = Offset(
        targetPosition.offset.dx + (targetPosition.size.width / 2),
        targetPosition.offset.dy + (targetPosition.size.height / 2),
      );

      if (targetPosition.size.height > targetPosition.size.width) {
        _sizeCircle = targetPosition.size.height * 0.6 + _getPaddingFocus();
      } else {
        _sizeCircle = targetPosition.size.width * 0.6 + _getPaddingFocus();
      }
    });

    _controller.duration = _targetFocus.unFocusAnimationDuration ??
        widget.unFocusAnimationDuration ??
        _targetFocus.focusAnimationDuration ??
        widget.focusAnimationDuration ??
        defaultFocusAnimationDuration;
    _controller.forward();
  }

  void _goToFocus(int index) {
    if (index >= 0 && index < widget.targets.length) {
      _currentFocus = index;
      _runFocus();
    } else {
      _finish();
    }
  }

  void _finish() {
    safeSetState(() => _currentFocus = 0);
    widget.finish!();
  }

  Widget _getLightPaint(TargetFocus targetFocus) {
    if (widget.imageFilter != null) {
      return ClipPath(
        clipper: _getClipper(targetFocus.shape),
        child: BackdropFilter(
          filter: widget.imageFilter!,
          child: _getSizedPainter(targetFocus),
        ),
      );
    } else {
      return _getSizedPainter(targetFocus);
    }
  }

  SizedBox _getSizedPainter(TargetFocus targetFocus) {
    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: CustomPaint(
        painter: _getPainter(targetFocus),
      ),
    );
  }

  CustomClipper<Path> _getClipper(ShapeLightFocus? shape) {
    return shape == ShapeLightFocus.RRect
        ? RectClipper(
            progress: _progressAnimated,
            offset: _getPaddingFocus(),
            target: _targetPosition ?? TargetPosition(Size.zero, Offset.zero),
            radius: _targetFocus.radius ?? 0,
            borderSide: BorderSide(
              color: Colors.red,
              style: BorderStyle.solid,
              width: 4,
            ),
          )
        : CircleClipper(
            _progressAnimated,
            _positioned,
            _sizeCircle,
            BorderSide(
              color: Colors.red,
              style: BorderStyle.solid,
              width: 4,
            ),
          );
  }

  CustomPainter _getPainter(TargetFocus target) {
    if (target.shape == ShapeLightFocus.RRect) {
      return LightPaintRect(
        colorShadow: target.color ?? widget.colorShadow,
        progress: _progressAnimated,
        offset: _getPaddingFocus(),
        target: _targetPosition ?? TargetPosition(Size.zero, Offset.zero),
        radius: target.radius ?? 0,
        borderSide: BorderSide(
          color: Colors.red,
          style: BorderStyle.solid,
          width: 4,
        ),
        opacityShadow: widget.opacityShadow,
      );
    } else {
      return LightPaint(
        _progressAnimated,
        _positioned,
        _sizeCircle,
        colorShadow: target.color ?? widget.colorShadow,
        borderSide: BorderSide(
          color: Colors.red,
          style: BorderStyle.solid,
          width: 4,
        ),
        opacityShadow: widget.opacityShadow,
      );
    }
  }

  double _getPaddingFocus() {
    return _targetFocus.paddingFocus ?? (widget.paddingFocus);
  }

  BorderRadius _betBorderRadiusTarget() {
    double radius = _targetFocus.shape == ShapeLightFocus.Circle
        ? _targetPosition?.size.width ?? borderRadiusDefault
        : _targetFocus.radius ?? borderRadiusDefault;
    return BorderRadius.circular(radius);
  }

  Widget closeGuidePrompt({
    required BuildContext context,
  }) {
    return AlertDialog(
        shape: ShapeBorder.lerp(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          1,
        ),
        backgroundColor: const Color(0xFFF2F2F2),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                "Close Use Guide",
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                "Are sure you want to cancel the app use guide?",
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff000000),
                  letterSpacing: -0.078,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: MediaQuery.sizeOf(context).width,
              height: 1.0,
              color: const Color(0xFF3C3C43).withOpacity(0.36),
            ),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.385,
                  child: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "No",
                        style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w400,
                            color: Color(0XFF007AFF)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 51.0,
                  color: const Color(0xFF3C3C43).withOpacity(0.36),
                ),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.385,
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        _finish();
                      },
                      child: const Text(
                        "Yes",
                        style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w600,
                            color: Color(0XFFE74C3C)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }
}

class AnimatedStaticFocusLightState extends AnimatedFocusLightState {
  double get left => (_targetPosition?.offset.dx ?? 0) - _getPaddingFocus() * 2;

  double get top => (_targetPosition?.offset.dy ?? 0) - _getPaddingFocus() * 2;

  double get width {
    return (_targetPosition?.size.width ?? 0) + _getPaddingFocus() * 4;
  }

  double get height {
    return (_targetPosition?.size.height ?? 0) + _getPaddingFocus() * 4;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _targetFocus.enableOverlayTab
          ? () => _tapHandler(overlayTap: true)
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          _progressAnimated = _curvedAnimation.value;
          return Stack(
            children: <Widget>[
              _getLightPaint(_targetFocus),
              // Positioned(
              //   left: left,
              //   top: top,
              //   child: InkWell(
              //     borderRadius: _betBorderRadiusTarget(),
              //     onTapDown: _tapHandlerForPosition,
              //     onTap: _targetFocus.enableTargetTab
              //         ? () => _tapHandler(targetTap: true)

              //         /// Essential for collecting [TapDownDetails]. Do not make [null]
              //         : () {},
              //     child: Container(
              //       color: Colors.transparent,
              //       width: width,
              //       height: height,
              //     ),
              //   ),
              // )
            ],
          );
        },
      ),
    );
  }

  @override
  Future _revertAnimation() {
    return _controller.reverse();
  }

  @override
  void _listener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.focus?.call(_targetFocus);
    }
    if (status == AnimationStatus.dismissed) {
      _goToFocus(nextIndex);
    }

    if (status == AnimationStatus.reverse) {
      widget.removeFocus?.call();
    }
  }
}

class AnimatedPulseFocusLightState extends AnimatedFocusLightState {
  final defaultPulseAnimationDuration = const Duration(milliseconds: 500);
  final defaultPulseVariation = Tween(begin: 1.0, end: 0.99);
  late AnimationController _controllerPulse;
  late Animation _tweenPulse;

  bool _finishFocus = false;
  bool _initReverse = false;

  get left => (_targetPosition?.offset.dx ?? 0) - _getPaddingFocus() * 2;

  get top => (_targetPosition?.offset.dy ?? 0) - _getPaddingFocus() * 2;

  get width => (_targetPosition?.size.width ?? 0) + _getPaddingFocus() * 4;

  get height => (_targetPosition?.size.height ?? 0) + _getPaddingFocus() * 4;

  @override
  void initState() {
    super.initState();
    _controllerPulse = AnimationController(
      vsync: this,
      duration: widget.pulseAnimationDuration ?? defaultPulseAnimationDuration,
    );

    _tweenPulse = _createTweenAnimation(
      _targetFocus.pulseVariation ??
          widget.pulseVariation ??
          defaultPulseVariation,
    );

    _controllerPulse.addStatusListener(_listenerPulse);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _targetFocus.enableOverlayTab
          ? () => _tapHandler(overlayTap: true)
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          _progressAnimated = _curvedAnimation.value;
          return AnimatedBuilder(
            animation: _controllerPulse,
            builder: (_, child) {
              if (_finishFocus) {
                _progressAnimated = _tweenPulse.value;
              }
              return Stack(
                children: <Widget>[
                  _getLightPaint(_targetFocus),
                  // Positioned(
                  //   left: left,
                  //   top: top,
                  //   child: InkWell(
                  //     borderRadius: _betBorderRadiusTarget(),
                  //     onTap: _targetFocus.enableTargetTab
                  //         ? () => _tapHandler(targetTap: true)

                  //         /// Essential for collecting [TapDownDetails]. Do not make [null]
                  //         : () {},
                  //     onTapDown: _tapHandlerForPosition,
                  //     child: Container(
                  //       color: Colors.transparent,
                  //       width: width,
                  //       height: height,
                  //     ),
                  //   ),
                  // )
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  void _runFocus() {
    _tweenPulse = _createTweenAnimation(
      _targetFocus.pulseVariation ??
          widget.pulseVariation ??
          defaultPulseVariation,
    );
    _finishFocus = false;
    super._runFocus();
  }

  @override
  Future _revertAnimation() {
    safeSetState(() {
      _initReverse = true;
    });

    return _controllerPulse.reverse(from: _controllerPulse.value);
  }

  @override
  void dispose() {
    _controllerPulse.dispose();
    super.dispose();
  }

  @override
  void _listener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      safeSetState(() => _finishFocus = true);

      widget.focus?.call(_targetFocus);

      _controllerPulse.forward();
    }
    if (status == AnimationStatus.dismissed) {
      safeSetState(() {
        _finishFocus = false;
        _initReverse = false;
      });
      _goToFocus(nextIndex);
    }

    if (status == AnimationStatus.reverse) {
      widget.removeFocus?.call();
    }
  }

  void _listenerPulse(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controllerPulse.reverse();
    }

    if (status == AnimationStatus.dismissed) {
      if (_initReverse) {
        safeSetState(() => _finishFocus = false);
        _controller.reverse();
      } else if (_finishFocus) {
        _controllerPulse.forward();
      }
    }
  }

  Animation _createTweenAnimation(Tween<double> tween) {
    return tween.animate(
      CurvedAnimation(parent: _controllerPulse, curve: Curves.ease),
    );
  }
}
