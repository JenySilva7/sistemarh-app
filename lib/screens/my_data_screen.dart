import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/grouped_info.dart';
import '../widgets/profile_header.dart';
import '../widgets/resumo_perfil_card.dart';

/// Tela "Meus Dados" — perfil do colaborador com informações pessoais e de
/// contato. Cargo, tempo de casa e gestor já aparecem no card de resumo
/// acima, então não se repetem aqui.
///
/// Nome, e-mail, cargo/departamento e banco de horas vêm do backend (sessão
/// autenticada); os demais campos (CPF, telefone, endereço etc.) ainda não
/// existem no modelo da API, então seguem como dados de exemplo fixos.
class MyDataScreen extends StatelessWidget {
  final Sessao sessao;
  final VoidCallback onSair;

  const MyDataScreen({super.key, required this.sessao, required this.onSair});

  @override
  Widget build(BuildContext context) {
    final cargoDepartamento = [sessao.cargo, sessao.departamento].where((s) => s.isNotEmpty).join(' · ');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ProfileHeader(
          nome: sessao.nome,
          cargoDepartamento: cargoDepartamento.isEmpty ? 'Colaborador' : cargoDepartamento,
          desde: 'Na empresa desde 01/06/2020',
          initials: sessao.iniciais,
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResumoPerfilCard(
              tempoDeCasa: '6 anos',
              gestor: 'Maria Santos',
              bancoDeHoras: sessao.bancoDeHorasFormatado,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInformacoes(),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onSair,
                icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.danger),
                label: const Text('Sair'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformacoes() {
    return InfoGroup(
      titulo: 'Dados pessoais',
      campos: [
        InfoField(LucideIcons.user, 'Nome completo', sessao.nome),
        InfoField(LucideIcons.mail, 'E-mail', sessao.email),
        const InfoField(LucideIcons.hash, 'CPF', '123.456.789-00'),
        const InfoField(LucideIcons.phone, 'Telefone', '(11) 98765-4321'),
      ],
    );
  }
}
