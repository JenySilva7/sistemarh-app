import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/horario_brasilia.dart';
import '../widgets/grouped_info.dart';
import '../widgets/profile_header.dart';
import '../widgets/resumo_perfil_card.dart';

/// Tela "Meus Dados" — perfil do colaborador. Tudo vem do backend (sessão
/// autenticada): o que a API ainda não fornece (CPF, telefone, endereço...)
/// simplesmente não aparece, e o que o RH ainda não preencheu (admissão,
/// gestor) aparece como "—" — nunca com valores de exemplo.
class MyDataScreen extends StatelessWidget {
  final Sessao sessao;
  final VoidCallback onSair;

  const MyDataScreen({super.key, required this.sessao, required this.onSair});

  @override
  Widget build(BuildContext context) {
    final cargoDepartamento = [sessao.cargo, sessao.departamento].where((s) => s.isNotEmpty).join(' · ');
    final admissao = sessao.dataAdmissao;
    final agora = agoraBrasilia();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ProfileHeader(
          nome: sessao.nome,
          cargoDepartamento: cargoDepartamento.isEmpty ? 'Colaborador' : cargoDepartamento,
          desde: admissao == null ? 'Data de admissão não informada' : 'Na empresa desde ${formatarData(admissao)}',
          initials: sessao.iniciais,
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResumoPerfilCard(
              tempoDeCasa: admissao == null ? '—' : formatarTempoDeCasa(admissao, hoje),
              gestor: sessao.gerenteNome ?? '—',
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
    String ouTraco(String valor) => valor.trim().isEmpty ? '—' : valor;

    return InfoGroup(
      titulo: 'Dados pessoais',
      campos: [
        InfoField(LucideIcons.user, 'Nome completo', sessao.nome),
        InfoField(LucideIcons.mail, 'E-mail', sessao.email),
        InfoField(LucideIcons.briefcase, 'Cargo', ouTraco(sessao.cargo)),
        InfoField(LucideIcons.building2, 'Departamento', ouTraco(sessao.departamento)),
      ],
    );
  }
}
