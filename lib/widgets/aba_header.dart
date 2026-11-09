import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cabeçalho de Aba — gradiente da marca com círculo decorativo, usado no
/// topo de Falar com RH e Holerite (mesmo componente do Início, mas com
/// título/subtítulo próprios de cada aba).
class AbaHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String initials;

  /// Se true, deixa espaço extra embaixo para um card seguinte se sobrepor
  /// (como no Início). Se false, é só o cabeçalho "puro".
  final bool comSobreposicao;

  const AbaHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.initials = 'JS',
    this.comSobreposicao = true,
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
              bottom: comSobreposicao ? 76 : 24,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitulo,
                        style: AppTextStyles.smallRegular14(color: AppColors.whiteOverlay80),
                      ),
                      const SizedBox(height: 2),
                      Text(titulo, style: AppTextStyles.nomePerfil()),
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
