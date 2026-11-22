import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/enums/procedure_enums.dart';
import '../../data/repositories/gop_y_repository_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final TextEditingController _contentController = TextEditingController();
  LoaiGopY _selectedType = LoaiGopY.gopY;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        if (_errorMessage != null) _errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final length = _contentController.text.trim().length;
    return length >= 10 && length <= 1000;
  }

  Future<void> _submitFeedback() async {
    if (!_isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(gopYRepositoryProvider);
      await repo.submit(
        loai: _selectedType,
        noiDung: _contentController.text.trim(),
        thuTucId: null,
        coQuanId: null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.feedbackSubmitSuccess),
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentLength = _contentController.text.trim().length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.feedbackScreenTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chọn loại: Góp ý / Báo lỗi
              Text(
                AppStrings.feedbackTypeChoice,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<LoaiGopY>(
                key: const ValueKey('feedback_type_segmented_button'),
                segments: const [
                  ButtonSegment<LoaiGopY>(
                    value: LoaiGopY.gopY,
                    label: Text(AppStrings.feedbackTypeFeedback),
                    icon: Icon(Icons.feedback_outlined),
                  ),
                  ButtonSegment<LoaiGopY>(
                    value: LoaiGopY.baoLoi,
                    label: Text(AppStrings.feedbackTypeError),
                    icon: Icon(Icons.bug_report_outlined),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Ô nội dung 10 - 1000 ký tự có đếm chữ
              TextField(
                key: const ValueKey('feedback_content_input'),
                controller: _contentController,
                minLines: 5,
                maxLines: 8,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: AppStrings.feedbackContentHint,
                  border: const OutlineInputBorder(),
                  helperText: contentLength > 0 && contentLength < 10
                      ? AppStrings.feedbackContentLengthError
                      : null,
                  helperStyle: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Báo lỗi (nếu có)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('feedback_retry_button'),
                        onPressed: _submitFeedback,
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Nút Gửi
              FilledButton(
                key: const ValueKey('feedback_submit_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                onPressed: (_isValid && !_isSubmitting) ? _submitFeedback : null,
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text(AppStrings.sendFeedbackButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
