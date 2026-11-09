import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cabeçalho de Perfil — avatar grande, nome, cargo e selo "na empresa
/// desde", sobre o gradiente da marca. Usado no topo de Meus Dados.
class ProfileHeader extends StatelessWidget {
  final String nome;
  final String cargoDepartamento;
  final String desde;
  final String initials;

  const ProfileHeader({
    super.key,
    required this.nome,
    required this.cargoDepartamento,
    required this.desde,
    this.initials = 'JS',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 56,
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.whiteOverlay15, width: 6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.relogioSegundos(color: AppColors.primary).copyWith(fontSize: 32, height: 1),
                  ),
                ),
                const SizedBox(height: 14),
                Text(nome, style: AppTextStyles.nomePerfil(), textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text(
                  cargoDepartamento,
                  style: AppTextStyles.smallRegular14(color: AppColors.whiteOverlay80),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.whiteOverlay15, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.calendar, size: 14, color: AppColors.white),
                      const SizedBox(width: 6),
                      Text(desde, style: AppTextStyles.captionMedium12(color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -50,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(color: AppColors.whiteOverlay10, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(color: AppColors.whiteOverlay10, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
