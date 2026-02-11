import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/revision_service.dart';

/// Request revision: reason 20–500 chars. First 3 free, then ₹50 each.
class RevisionRequestScreen extends StatefulWidget {
  const RevisionRequestScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<RevisionRequestScreen> createState() => _RevisionRequestScreenState();
}

class _RevisionRequestScreenState extends State<RevisionRequestScreen> {
  final RevisionService _revisionService = RevisionService();
  final TextEditingController _reasonController = TextEditingController();
  final FocusNode _reasonFocus = FocusNode();

  bool _loading = false;
  String? _error;
  String? _fieldError;

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  int get _reasonLength => _reasonController.text.trim().length;

  bool get _reasonValid =>
      _reasonLength >= AppConstants.revisionReasonMinLength &&
      _reasonLength <= AppConstants.revisionReasonMaxLength;

  void _validateField() {
    setState(() {
      if (_reasonController.text.trim().isEmpty) {
        _fieldError = null;
        return;
      }
      if (_reasonLength < AppConstants.revisionReasonMinLength) {
        _fieldError =
            'Reason must be at least ${AppConstants.revisionReasonMinLength} characters (${_reasonLength}/${AppConstants.revisionReasonMinLength})';
      } else if (_reasonLength > AppConstants.revisionReasonMaxLength) {
        _fieldError =
            'Reason must be at most ${AppConstants.revisionReasonMaxLength} characters (${_reasonLength}/${AppConstants.revisionReasonMaxLength})';
      } else {
        _fieldError = null;
      }
    });
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _error = 'Please enter a reason for the revision';
        _fieldError = 'Reason is required';
      });
      _reasonFocus.requestFocus();
      return;
    }
    if (reason.length < AppConstants.revisionReasonMinLength) {
      setState(() {
        _error = 'Reason must be at least ${AppConstants.revisionReasonMinLength} characters';
        _fieldError =
            '${AppConstants.revisionReasonMinLength}–${AppConstants.revisionReasonMaxLength} characters required';
      });
      _reasonFocus.requestFocus();
      return;
    }
    if (reason.length > AppConstants.revisionReasonMaxLength) {
      setState(() {
        _error = 'Reason must be at most ${AppConstants.revisionReasonMaxLength} characters';
        _fieldError = 'Maximum ${AppConstants.revisionReasonMaxLength} characters';
      });
      _reasonFocus.requestFocus();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _fieldError = null;
    });

    try {
      final result = await _revisionService.requestRevision(
        orderId: widget.orderId,
        reason: reason,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result.success) {
        final amountMsg = result.amountInr > 0
            ? ' This revision costs ₹${result.amountInr.toStringAsFixed(0)}.'
            : '';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Revision #${result.revisionNumber} requested.$amountMsg',
              ),
            ),
          );
          context.pop(true);
        }
        return;
      } else {
        setState(() {
          _error = 'Unable to submit revision. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request revision'),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'First ${AppConstants.freeRevisionsPerOrder} revisions free, then ₹${AppConstants.revisionFeeAfterFreeInr.toStringAsFixed(0)} each.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reason for revision',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    focusNode: _reasonFocus,
                    maxLength: AppConstants.revisionReasonMaxLength,
                    maxLines: 5,
                    minLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Describe what needs to be changed (${AppConstants.revisionReasonMinLength}–${AppConstants.revisionReasonMaxLength} characters)',
                      border: const OutlineInputBorder(),
                      errorText: _fieldError,
                      counterText: '${_reasonController.text.length} / ${AppConstants.revisionReasonMaxLength}',
                    ),
                    onChanged: (_) => _validateField(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Material(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit revision request'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loading ? null : () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
    );
  }
}
