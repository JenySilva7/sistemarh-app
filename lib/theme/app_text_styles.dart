import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto extraídos do Design System (Penpot) do Sistema RH,
/// usando a família Inter (Google Fonts) como no app web original.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    required double height,
    Color color = AppColors.foreground,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Mobile / Nome Perfil (usado em "Bom dia, João")
  static TextStyle nomePerfil({Color color = AppColors.white}) => _inter(
    size: 22,
    weight: FontWeight.w600,
    height: 28,
    color: color,
  );

  // Mobile / Relógio
  static TextStyle relogio({Color color = AppColors.foreground}) => _inter(
    size: 52,
    weight: FontWeight.w700,
    height: 60,
    color: color,
    letterSpacing: -1,
  );

  // Mobile / Relógio Segundos
  static TextStyle relogioSegundos({Color color = AppColors.mutedForeground}) =>
      _inter(size: 22, weight: FontWeight.w600, height: 28, color: color, letterSpacing: -1);

  // Mobile / Título Seção
  static TextStyle tituloSecao({Color color = AppColors.foreground}) =>
      _inter(size: 17, weight: FontWeight.w600, height: 24, color: color);

  // Mobile / Botão Grande
  static TextStyle botaoGrande({Color color = AppColors.white}) =>
      _inter(size: 17, weight: FontWeight.w600, height: 24, color: color);

  // Mobile / Label Navegação
  static TextStyle labelNavegacao({Color color = AppColors.mutedForeground}) =>
      _inter(size: 12, weight: FontWeight.w500, height: 16, color: color);

  // Mobile / Valor Resumo
  static TextStyle valorResumo({Color color = AppColors.foreground}) =>
      _inter(size: 16, weight: FontWeight.w600, height: 22, color: color);

  // Body / Medium 16
  static TextStyle bodyMedium16({Color color = AppColors.foreground}) =>
      _inter(size: 16, weight: FontWeight.w500, height: 24, color: color);

  // Body / Semibold 16
  static TextStyle bodySemibold16({Color color = AppColors.foreground}) =>
      _inter(size: 16, weight: FontWeight.w600, height: 24, color: color);

  // Body / Regular 16
  static TextStyle bodyRegular16({Color color = AppColors.foreground}) =>
      _inter(size: 16, weight: FontWeight.w400, height: 24, color: color);

  // Small / Regular 14 Tight
  static TextStyle smallRegular14({Color color = AppColors.mutedForeground}) =>
      _inter(size: 14, weight: FontWeight.w400, height: 20, color: color);

  // Small / Medium 14 · Label
  static TextStyle smallMedium14({Color color = AppColors.foreground}) =>
      _inter(size: 14, weight: FontWeight.w500, height: 20, color: color);

  // Caption / Regular 12 Tight
  static TextStyle captionRegular12({Color color = AppColors.mutedForeground}) =>
      _inter(size: 12, weight: FontWeight.w400, height: 16, color: color);

  // Caption / Medium 12 · Pill
  static TextStyle captionMedium12({Color color = AppColors.foreground}) =>
      _inter(size: 12, weight: FontWeight.w500, height: 16, color: color);

  // Mobile / Hora Status Bar
  static TextStyle horaStatusBar({Color color = AppColors.white}) =>
      _inter(size: 15, weight: FontWeight.w600, height: 20, color: color);
}
