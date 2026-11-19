import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Toast flutuante no topo da tela — card escuro com ícone de confirmação,
/// título, descrição e uma ação opcional (ex.: "Desfazer"), replicando o
/// componente "App / Toast" do design system. Com [erro], o ícone vira o de
/// alerta, pra uma falha não parecer confirmação.
class AppToast {
  static void show(
    BuildContext context, {
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
    bool erro = false,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    final controller = _ToastController();

    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        title: title,
        description: description,
        erro: erro,
        actionLabel: actionLabel,
        topInset: MediaQuery.of(ctx).padding.top,
        controller: controller,
        onAction: onAction == null
            ? null
            : () {
                onAction();
                controller.dismiss();
              },
        onDismissed: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _ToastController {
  VoidCallback? _dismiss;
  void dismiss() => _dismiss?.call();
}

class _ToastWidget extends StatefulWidget {
  final String title;
  final String description;
  final bool erro;
  final String? actionLabel;
  final double topInset;
  final _ToastController controller;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.title,
    required this.description,
    required this.erro,
    required this.actionLabel,
    required this.topInset,
    required this.controller,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, -1.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    widget.controller._dismiss = _dismiss;
    _tocar();
  }

  Future<void> _tocar() async {
    await _anim.forward();
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) _dismiss();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _anim.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topInset + 8,
      left: 16,
      right: 16,
      // Sem ação, o toast só informa: o toque passa direto pra tela de baixo.
      // Senão, por 4 s ele "come" os toques no topo da tela — por exemplo, no
      // botão de bater ponto quando o Início está rolado pra baixo.
      child: IgnorePointer(
        ignoring: widget.onAction == null,
        child: SlideTransition(
          position: _offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.sidebarBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  widget.erro
                      ? const Icon(LucideIcons.circleAlert, size: 24, color: AppColors.danger)
                      : const Icon(LucideIcons.circleCheck, size: 24, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTextStyles.valorResumo(color: AppColors.white)),
                        const SizedBox(height: 2),
                        Text(
                          widget.description,
                          style: AppTextStyles.captionRegular12(color: AppColors.whiteOverlay80),
                        ),
                      ],
                    ),
                  ),
                  if (widget.actionLabel != null)
                    GestureDetector(
                      onTap: widget.onAction,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          widget.actionLabel!,
                          style: AppTextStyles.smallMedium14(color: AppColors.primaryLight),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
