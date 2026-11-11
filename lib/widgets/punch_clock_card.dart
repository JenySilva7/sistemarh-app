import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/ponto_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/horario_brasilia.dart';
import 'status_chip.dart';

/// Card do Relógio — relógio ao vivo, status do expediente, progresso da
/// jornada e botão de ação principal (próximo ponto a registrar).
class PunchClockCard extends StatefulWidget {
  final PontoController controller;
  final VoidCallback onRegistrar;

  const PunchClockCard({super.key, required this.controller, required this.onRegistrar});

  @override
  State<PunchClockCard> createState() => _PunchClockCardState();
}

class _PunchClockCardState extends State<PunchClockCard> {
  late Timer _tick;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = agoraBrasilia();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final agora = agoraBrasilia();
      if (agora.hour != _now.hour || agora.minute != _now.minute) {
        setState(() => _now = agora);
      }
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final concluida = c.jornadaConcluida;
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              concluida
                  ? StatusChip.registrado(c.statusLabel)
                  : c.emAlmoco
                  ? StatusChip.emIntervalo(c.statusLabel)
                  : StatusChip.registrado(c.statusLabel),
              const Spacer(),
              Text(
                'Escala 08:00 – 17:00',
                style: AppTextStyles.captionRegular12(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('$hh:$mm', style: AppTextStyles.relogio(), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trabalhado hoje', style: AppTextStyles.captionRegular12()),
              Text(
                '${c.trabalhadoHojeLabel} de ${c.metaLabel}',
                style: AppTextStyles.captionMedium12(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.progresso,
              minHeight: 8,
              backgroundColor: AppColors.gray100,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: concluida
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.success10,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.circleCheck, size: 20, color: AppColors.successText),
                        const SizedBox(width: 8),
                        Text(
                          'Jornada de hoje concluída',
                          style: AppTextStyles.botaoGrande(color: AppColors.successText),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: widget.onRegistrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          c.proximo!.isEntrada ? LucideIcons.logIn : LucideIcons.logOut,
                          size: 20,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            c.proximo!.acaoBotao,
                            style: AppTextStyles.botaoGrande(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            c.ultimoRegistroLabel,
            style: AppTextStyles.captionRegular12(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
