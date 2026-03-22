import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/assets/shared_models.dart';

class LoginHandoffScreen extends StatefulWidget {
  const LoginHandoffScreen({
    super.key,
    this.loginCopy,
    this.appMarkAssetPath,
    this.errorMessage,
    this.isSubmitting = false,
    required this.onSubmitPhoneNumber,
    required this.onInputChanged,
  });

  final LoginCopy? loginCopy;
  final String? appMarkAssetPath;
  final String? errorMessage;
  final bool isSubmitting;
  final Future<void> Function(String phoneNumber) onSubmitPhoneNumber;
  final VoidCallback onInputChanged;

  @override
  State<LoginHandoffScreen> createState() => _LoginHandoffScreenState();
}

class _LoginHandoffScreenState extends State<LoginHandoffScreen> {
  late final TextEditingController _phoneController;
  late final FocusNode _phoneFocusNode;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _phoneFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LoginCopy copy = widget.loginCopy ?? LoginCopy.fallback();
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (widget.appMarkAssetPath != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Center(
                                  child: SvgPicture.asset(
                                    widget.appMarkAssetPath!,
                                    width: 72,
                                    height: 72,
                                  ),
                                ),
                              ),
                            Text(
                              copy.brandTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              copy.headline,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              copy.body,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              enabled: !widget.isSubmitting,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: copy.phoneLabel,
                                hintText: copy.phoneHint,
                                errorText: widget.errorMessage,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onChanged: (_) => widget.onInputChanged(),
                              onSubmitted: _submitPhoneNumber,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: widget.isSubmitting
                                    ? null
                                    : () => unawaited(
                                        widget.onSubmitPhoneNumber(
                                          _phoneController.text,
                                        ),
                                      ),
                                child: widget.isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(copy.continueLabel),
                              ),
                            ),
                            const SizedBox(height: 20),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  copy.footer,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitPhoneNumber(String _) {
    return widget.onSubmitPhoneNumber(_phoneController.text);
  }
}
