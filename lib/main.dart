import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Importa as telas personalizadas
import 'screens/conscientizacao/conscientizacao_menu_screen.dart';
import 'screens/agente/painel_ace_screen.dart';

void main() {
  runApp(VectorTrackerApp());
}

class VectorTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp(
      title: 'Vector Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(textTheme),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

//-------------------------------------------------------------------
// TELA DE LOGIN COM ABAS
//-------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF39B5A5), Color(0xFF8BC34A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Image.asset("assets/images/logo_vector_tracker.png", height: 120),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.8),
                        indicator: BoxDecoration(
                          color: Color(0xFF00695C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: [
                          Tab(child: Text("Comunidade", style: TextStyle(fontWeight: FontWeight.bold))),
                          Tab(child: Text("Agente", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLoginForm(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomeScreen()),
                              );
                            },
                          ),
                          _buildLoginForm(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => PainelAceScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm({required VoidCallback onPressed}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          decoration: _buildInputDecoration(label: "Usuário", icon: Icons.person_outline),
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: _buildInputDecoration(label: "Senha", icon: Icons.lock_outline),
          obscureText: true,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          child: const Text("Entrar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00695C),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {},
          child: Text("Esqueceu sua senha?", style: TextStyle(color: Colors.white.withOpacity(0.9))),
        )
      ],
    );
  }
}

//-------------------------------------------------------------------
// TELA PRINCIPAL (HOME)
//-------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(title: "Vector Tracker", actions: [
        IconButton(icon: Icon(Icons.notifications_none, size: 28), onPressed: () {})
      ]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.camera_alt_outlined, size: 32, color: Colors.white),
            label: Text("Registrar Ocorrência", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DenunciaScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2F80ED),
              minimumSize: const Size(double.infinity, 80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(context),
    );
  }

  Widget _buildCustomBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, icon: Icons.school_outlined, label: "Educação", screen: ConscientizacaoMenuScreen()),
          _buildNavItem(context, icon: Icons.map_outlined, label: "Mapa", screen: MapaScreen()),
          _buildNavItem(context, icon: Icons.person_outline, label: "Meu Perfil", screen: PerfilScreen()),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String label, required Widget screen}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700], size: 28),
            SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

//-------------------------------------------------------------------
// TELA DE DENÚNCIA
//-------------------------------------------------------------------
class DenunciaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(title: "Enviar Relato", hasBackArrow: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey[600]),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text("Anexar Foto", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00796B)),
                  )
                ],
              ),
            ),
            SizedBox(height: 30),
            Text("Localização", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              decoration: _buildInputDecoration(label: "Geolocalização automática (Piauí)", icon: Icons.location_on_outlined),
              readOnly: true,
            ),
            SizedBox(height: 30),
            Text("Breve Descrição", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              decoration: _buildInputDecoration(label: "Ex: Encontrei um inseto...", icon: Icons.description_outlined).copyWith(prefixIcon: null),
              maxLines: 4,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Enviar Relato", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2F80ED),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

//-------------------------------------------------------------------
// TELAS PLACEHOLDER
//-------------------------------------------------------------------
class MapaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(title: "Mapa de Ocorrências", hasBackArrow: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 100, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text("Aqui ficará o mapa interativo", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class PerfilScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildGradientAppBar(title: "Meu Perfil", hasBackArrow: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 100, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text("Aqui ficarão os dados do usuário", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

//-------------------------------------------------------------------
// WIDGETS E FUNÇÕES REUTILIZÁVEIS
//-------------------------------------------------------------------
AppBar _buildGradientAppBar({required String title, bool hasBackArrow = false, List<Widget>? actions}) {
  return AppBar(
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF39B5A5), Color(0xFF2F80ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    iconTheme: IconThemeData(color: Colors.white),
    actions: actions,
    automaticallyImplyLeading: hasBackArrow,
    elevation: 4,
  );
}

InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.grey[500]),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFF00796B)),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}