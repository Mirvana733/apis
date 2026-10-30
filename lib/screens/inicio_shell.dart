import 'package:flutter/material.dart';

import 'amigos_screen.dart';
import 'estrellas_screen.dart';
import 'pantalla_principal.dart';
import 'perfil_personal_screen.dart';
import 'top_semana_screen.dart';

class InicioShell extends StatefulWidget {
  const InicioShell({super.key});

  @override
  State<InicioShell> createState() => _InicioShellState();
}

class _InicioShellState extends State<InicioShell> {
  int _indice = 0;

  late final List<Widget> _paginas = [
    PantallaPrincipal(onPerfilTap: () => _seleccionar(1)),
    const PerfilPersonalScreen(),
    const TopSemanaScreen(),
    const EstrellasScreen(),
    const AmigosScreen(),
  ];

  void _seleccionar(int indice) {
    if (indice == _indice) return;

    setState(() => _indice = indice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _seleccionar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Top',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Estrellas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Amigos',
          ),
        ],
      ),
    );
  }
}
