import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class NavDestination {
  final String label;
  final IconData icon;
  const NavDestination(this.label, this.icon);
}

const List<NavDestination> kNavDestinations = [
  NavDestination('Início', LucideIcons.house),
  NavDestination('Falar com RH', LucideIcons.messageSquare),
  NavDestination('Holerite', LucideIcons.fileText),
  NavDestination('Meus Dados', LucideIcons.user),
];

/// Barra de Navegação inferior do app — 4 destinos com indicador em pílula
/// no item ativo, replicando o componente "App / Barra de Navegação" do
/// design system no Penpot.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.foreground.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // IMPORTANTE: sem isso, este Column (mainAxisSize padrão é .max)
        // tenta ocupar toda a altura que o Scaffold permite para a
        // bottomNavigationBar — que é a tela inteira, já que Scaffold dá
        // a ela uma restrição solta até a altura total. Isso empurra o
        // body para quase zero de altura, mesmo sem lançar nenhuma
        // exceção. .min faz a barra encolher para a altura do conteúdo.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: List.generate(kNavDestinations.length, (i) {
                  final dest = kNavDestinations[i];
                  final ativo = i == currentIndex;
                  final color = ativo ? AppColors.primary : AppColors.mutedForeground;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 56,
                              height: 30,
                              decoration: BoxDecoration(
                                color: ativo ? AppColors.primary10 : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Icon(dest.icon, size: 22, color: color),
                            ),
                            const SizedBox(height: 4),
                            Text(dest.label, style: AppTextStyles.labelNavegacao(color: color)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
