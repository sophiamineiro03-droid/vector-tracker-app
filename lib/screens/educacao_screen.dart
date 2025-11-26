import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_tracker_app/widgets/gradient_app_bar.dart';

class EducacaoScreen extends StatelessWidget {
  const EducacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Estilos de texto padronizados
    final titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF2C3E50),
    );
    
    final bodyStyle = GoogleFonts.lato(
      fontSize: 15,
      height: 1.5, 
      color: Colors.black87,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const GradientAppBar(title: 'Aprenda e Previna-se'),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // 1. Card: Identificação (TEXTO ATUALIZADO)
          _buildCard(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Como identificar o barbeiro?', Icons.search, titleStyle),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    'assets/barbeiro.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Não confunda com outros insetos. Verifique estas características principais:',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                
                // Tópicos Agrupados
                _buildFeatureRow(
                  Icons.bug_report_outlined, 
                  'CORPO', 
                  'Achatado e marrom. Possui listras claras (amarelas ou laranjas) nas bordas laterais.', 
                  Colors.brown[800]!, 
                  bodyStyle
                ),
                _buildFeatureRow(
                  Icons.change_history, 
                  'CABEÇA E BICO', // Unificado
                  'A cabeça é fina e alongada, com antenas laterais. O bico é curto, reto e dobrado para baixo.', 
                  Colors.brown[700]!, 
                  bodyStyle
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Card: Esconderijos
          _buildCard(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Onde ele se esconde?', Icons.home_work, titleStyle),
                const SizedBox(height: 12),
                Text(
                  'Fique atento a estes locais durante o dia:',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildIconRow(Icons.grid_view, 'Fendas e Paredes', 'Buracos em casas de barro ou madeira.', Colors.brown, bodyStyle),
                _buildIconRow(Icons.layers, 'Depósitos', 'Pilhas de lenha, telhas, tijolos ou entulho.', Colors.brown, bodyStyle),
                _buildIconRow(Icons.pets, 'Abrigos de Animais', 'Galinheiros, chiqueiros e ninhos.', Colors.brown, bodyStyle),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[800], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ele foge da luz! Só sai para se alimentar quando está escuro.',
                          style: bodyStyle.copyWith(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Card: Contágio e Sintomas
          _buildCard(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Como ocorre o contágio?', Icons.health_and_safety, titleStyle),
                const SizedBox(height: 12),
                Text(
                  'Ao picar, o barbeiro defeca. As fezes contêm o parasita. Ao coçar a picada, você empurra o parasita para dentro do corpo.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SINAL DE ALERTA',
                              style: GoogleFonts.poppins(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Se o olho ou a pálpebra inchar muito após uma picada, procure o posto imediatamente!',
                              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          'assets/chagas_sintomas.jpeg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Card: Ação Imediata
          _buildCard(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Encontrei um barbeiro!', Icons.warning_amber_rounded, titleStyle.copyWith(color: Colors.blue[900])),
                const SizedBox(height: 16),
                
                // Alerta de Não Esmagar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'NÃO ESMAGUE O INSETO!',
                          style: GoogleFonts.poppins(
                            color: Colors.red[800], 
                            fontWeight: FontWeight.bold, 
                            fontSize: 14
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('1. Capture com cuidado', style: titleStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Use um pote ou plástico. Não toque nele diretamente.', style: bodyStyle),
                
                const SizedBox(height: 20),
                
                Text('2. Encaminhe para análise:', style: titleStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 12),

                // Opção A: Levar ao posto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.local_hospital, color: Colors.green[600], size: 28),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Text(
                           "Leve-o vivo ao Posto de Saúde ou PIT mais próximo.", 
                           style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                         )
                       ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OU", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                ),

                // Opção B: Botão do App com Gradiente
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39A2AE), Color(0xFF2979FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/denuncia'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_location_alt_outlined, color: Colors.white, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'REGISTRAR UMA DENÚNCIA',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16, 
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    "Notifique o agente de combate às endemias",
                    style: bodyStyle.copyWith(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Card: Prevenção
          _buildCard(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Como manter a casa segura?', Icons.shield_outlined, titleStyle.copyWith(color: Colors.green[800])),
                const SizedBox(height: 16),
                _buildChecklistRow('Vede buracos e frestas nas paredes e no chão.', bodyStyle),
                _buildChecklistRow('Limpe o quintal e retire pilhas de entulho.', bodyStyle),
                _buildChecklistRow('Coloque telas nas janelas se possível.', bodyStyle),
                _buildChecklistRow('Olhe atrás de quadros e embaixo dos colchões.', bodyStyle),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------- WIDGETS AUXILIARES ----------------

  Widget _buildCard({required Widget content}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon, TextStyle style) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2979FF), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _buildIconRow(IconData icon, String title, String text, Color color, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, String desc, Color color, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: color)), 
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: style),
          ),
        ],
      ),
    );
  }
}
