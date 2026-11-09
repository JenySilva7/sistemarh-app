import 'package:flutter/material.dart';

/// Tokens de cor extraídos do Design System (Penpot) do Sistema RH.
class AppColors {
  AppColors._();

  // Marca
  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFFA5B4FC);
  static const primarySoft = Color(0xFFE0E7FF);

  // Gradiente Hero
  static const gradientStart = Color(0xFF4F46E5);
  static const gradientEnd = Color(0xFF8B5CF6);
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  // Neutros
  static const foreground = Color(0xFF1A1D29);
  static const gray800 = Color(0xFF1E2939);
  static const gray500 = Color(0xFF6A7282);
  static const mutedForeground = Color(0xFF6B7280);
  static const gray300 = Color(0xFFD1D5DC);
  static const border = Color(0xFFE5E7EB);
  static const borderCard = Color(0xFFDDDDDD);
  static const gray100 = Color(0xFFF3F4F6);
  static const background = Color(0xFFF8F9FA);
  static const white = Color(0xFFFFFFFF);

  // Sidebar / Navegação escura (não usado nesta tela, mantido para consistência)
  static const sidebarBg = Color(0xFF1F2937);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);
  static const successText = Color(0xFF047857);
  static const warningText = Color(0xFFB45309);

  // Acentos (Tailwind v4)
  static const red600 = Color(0xFFE7000B);
  static const green600 = Color(0xFF00A63E);

  // Superfícies (tons suaves)
  static const primary10 = Color(0x1A4F46E5); // 10%
  static const primary5 = Color(0x0D4F46E5); // 5%
  static const primary20 = Color(0x334F46E5); // 20%
  static const success10 = Color(0x1F10B981); // 12%
  static const warning10 = Color(0x23F59E0B); // 14%
  static const danger10 = Color(0x1FEF4444); // 12%
  static const neutro10 = Color(0x1F6B7280); // 12%
  static const whiteOverlay15 = Color(0x26FFFFFF);
  static const whiteOverlay10 = Color(0x1AFFFFFF);
  static const whiteOverlay80 = Color(0xCCFFFFFF);
}
