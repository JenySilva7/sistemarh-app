import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cabeçalho de Aba (variante "Sobreposição: Sim") — gradiente da marca com
/// círculo decorativo, saudação e avatar, usado no topo do Início.
/// Deixa 60px de espaço extra embaixo para o card seguinte se sobrepor.
class HomeHeader extends StatelessWidget {
  final String greeting;
  final String dateLabel;
  final String initials;

  const HomeHeader({
    super.key,
    required this.greeting,
    required this.dateLabel,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 76,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: AppTextStyles.smallRegular14(color: AppColors.whiteOverlay80),
                      ),
                      const SizedBox(height: 2),
                      Text(greeting, style: AppTextStyles.nomePerfil()),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.whiteOverlay15, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: AppTextStyles.bodySemibold16(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Decoração: círculo translúcido no canto superior direito.
          Positioned(
            right: -40,
            top: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: AppColors.whiteOverlay10,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
