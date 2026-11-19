import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/carregamento_controller.dart';
import '../services/auth_service.dart';
import '../services/cadastro_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../utils/horario_brasilia.dart';
import '../widgets/grouped_info.dart';
import '../widgets/profile_header.dart';
import '../widgets/resumo_perfil_card.dart';

/// Tela "Meus Dados" — perfil do colaborador. O topo vem da sessão
/// (`/api/auth/me`); CPF, telefone, nascimento, salário e vale vêm do
/// cadastro que o RH preencheu (`GET /api/me/cadastro`, buscado pelo
/// RootShell ao abrir a aba). Se a conta não estiver ligada a um cadastro
/// (404), a tela mostra só o que a sessão tem e avisa o motivo. O que o RH
/// ainda não preencheu aparece como "—" — nunca com valores de exemplo.
class MyDataScreen extends StatelessWidget {
  final Sessao sessao;
  final CarregamentoController<CadastroColaborador> cadastro;
  final VoidCallback onAlterarSenha;
  final VoidCallback onSair;

  /// true enquanto o logout está a caminho do servidor.
  final bool saindo;

  const MyDataScreen({
    super.key,
    required this.sessao,
    required this.cadastro,
    required this.onAlterarSenha,
    required this.onSair,
    this.saindo = false,
  });

  static String _ouTraco(String? valor) => valor == null || valor.trim().isEmpty ? '—' : valor.trim();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cadastro,
      builder: (context, _) {
        final dados = cadastro.dados;
        final cargoDepartamento = [sessao.cargo, sessao.departamento].where((s) => s.isNotEmpty).join(' · ');
        final admissao = sessao.dataAdmissao ?? dados?.dataAdmissao;
        final agora = agoraBrasilia();
        final hoje = DateTime(agora.year, agora.month, agora.day);

        return RefreshIndicator(
          onRefresh: cadastro.recarregar,
          color: AppColors.primary,
          edgeOffset: MediaQuery.of(context).padding.top,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
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
                    gestor: sessao.gerenteNome ?? dados?.gerenteNome ?? '—',
                    bancoDeHoras: sessao.bancoDeHorasFormatado,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._buildInformacoes(dados),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: saindo ? null : onAlterarSenha,
                      icon: const Icon(LucideIcons.keyRound, size: 18, color: AppColors.primary),
                      label: const Text('Alterar senha'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: saindo ? null : onSair,
                      icon: saindo
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
                            )
                          : const Icon(LucideIcons.logOut, size: 18, color: AppColors.danger),
                      label: Text(saindo ? 'Saindo…' : 'Sair'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        disabledForegroundColor: AppColors.danger.withValues(alpha: 0.6),
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildInformacoes(CadastroColaborador? dados) {
    final nascimento = dados?.dataNascimento;
    final pessoais = InfoGroup(
      titulo: 'Dados pessoais',
      campos: [
        InfoField(LucideIcons.user, 'Nome completo', sessao.nome),
        InfoField(LucideIcons.mail, 'E-mail', sessao.email),
        if (dados != null) ...[
          InfoField(LucideIcons.idCard, 'CPF', dados.cpf.isEmpty ? '—' : formatarCpf(dados.cpf)),
          InfoField(LucideIcons.phone, 'Telefone', _ouTraco(dados.telefone)),
          InfoField(LucideIcons.cake, 'Data de nascimento', nascimento == null ? '—' : formatarData(nascimento)),
        ],
      ],
    );
    final trabalho = InfoGroup(
      titulo: 'Trabalho',
      campos: [
        InfoField(LucideIcons.briefcase, 'Cargo', _ouTraco(sessao.cargo.isEmpty ? dados?.cargo : sessao.cargo)),
        InfoField(
          LucideIcons.building2,
          'Departamento',
          _ouTraco(sessao.departamento.isEmpty ? dados?.departamento : sessao.departamento),
        ),
      ],
    );

    if (dados != null) {
      return [
        pessoais,
        const SizedBox(height: 20),
        trabalho,
        const SizedBox(height: 20),
        InfoGroup(
          titulo: 'Remuneração',
          campos: [
            InfoField(LucideIcons.wallet, 'Salário', formatarMoeda(dados.salario)),
            InfoField(LucideIcons.utensils, 'Vale alimentação', formatarMoeda(dados.valeAlimentacao)),
          ],
        ),
      ];
    }

    return [pessoais, const SizedBox(height: 12), _buildAvisoCadastro(), const SizedBox(height: 20), trabalho];
  }

  /// O que aparece no lugar de CPF, telefone, nascimento e remuneração
  /// enquanto o cadastro não chega, se a conta não tem cadastro (404) ou se
  /// a busca falhou.
  Widget _buildAvisoCadastro() {
    final falha = cadastro.falha;
    final semCadastro = falha?.statusCode == 404;
    final Widget icone;
    final String texto;
    Color cor = AppColors.mutedForeground;
    Widget? acao;

    if (falha == null) {
      icone = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
      texto = 'Carregando seus dados do cadastro…';
    } else if (semCadastro) {
      icone = const Icon(LucideIcons.info, size: 18, color: AppColors.mutedForeground);
      texto = falha.mensagem;
    } else {
      icone = const Icon(LucideIcons.circleAlert, size: 18, color: AppColors.danger);
      texto = falha.mensagem;
      cor = AppColors.danger;
      acao = TextButton(
        onPressed: cadastro.recarregar,
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        child: const Text('Tentar novamente'),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          icone,
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: AppTextStyles.captionRegular12(color: cor))),
          ?acao,
        ],
      ),
    );
  }
}
