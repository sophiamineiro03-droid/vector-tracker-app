# Documentação de Implementação iOS - Vector Tracker

Esta documentação detalha o processo, requisitos e estratégias para compilar e publicar a versão iOS do aplicativo Vector Tracker, considerando que o desenvolvimento principal é feito em ambiente Windows.

---

## 1. Visão Geral
O projeto é desenvolvido em **Flutter**, o que significa que o mesmo código fonte utilizado no Android funciona no iOS. No entanto, a **compilação** (geração do arquivo instalável `.ipa`) exige obrigatoriamente ferramentas da Apple (Xcode) que só rodam no sistema macOS.

### Situação Atual
- **Código:** 100% compatível com mobile (Android/iOS).
- **Ambiente de Dev:** Windows (Android Studio).
- **Desafio:** Gerar o executável iOS sem um Mac físico conectado via USB.

---

## 2. Requisitos Obrigatórios

Para ter o aplicativo rodando em um iPhone (mesmo que para testes), você precisará:

1.  **Apple Developer Account (Conta de Desenvolvedor Apple)**
    *   **Custo:** US$ 99 / ano (aprox. R$ 500~600).
    *   **Onde fazer:** [developer.apple.com](https://developer.apple.com/)
    *   **Por que é necessário?** A Apple não permite instalar apps desconhecidos via cabo (sideload) facilmente como o Android. É necessário assinar digitalmente o app, e essa conta é quem fornece os certificados.

2.  **Um Dispositivo iOS (iPhone ou iPad)**
    *   Essencial para validar GPS, Câmera e Performance real.
    *   Não é possível rodar o Simulador de iOS no Windows.

---

## 3. Estratégias de Build (Como gerar o App)

Existem dois caminhos para transformar seu código Flutter em um app instalado no iPhone:

### Caminho A: Build na Nuvem (Recomendado para quem usa Windows)
Utiliza serviços de CI/CD que "alugam" um Mac virtual para compilar seu código.

*   **Ferramenta Sugerida:** [Codemagic](https://codemagic.io/) (Especializado em Flutter).
*   **Fluxo de Trabalho:**
    1.  Você coda no Android Studio (Windows).
    2.  Sobe o código para o **GitHub/GitLab**.
    3.  O Codemagic detecta a mudança, baixa o código em um Mac na nuvem.
    4.  O Codemagic gera o arquivo `.ipa` e envia para a **App Store Connect**.
    5.  Você baixa o app no seu iPhone usando o aplicativo **TestFlight**.

### Caminho B: Mac Físico (Caso você adquira um Mac)
Se você comprar um MacBook ou Mac Mini no futuro:

*   **Fluxo de Trabalho:**
    1.  Instalar o **Xcode** e o **CocoaPods** no Mac.
    2.  Clonar seu projeto do GitHub para o Mac.
    3.  Conectar o iPhone no cabo USB.
    4.  Rodar `flutter run` diretamente no terminal do Mac.

---

## 4. Desenvolvimento e Visualização no Windows

Como não há emulador de iOS no Windows, usamos técnicas para garantir que o layout não quebre.

### Ferramenta: Device Preview
Pacote Flutter que simula a "moldura" e características do iPhone (Notch, Home Indicator, cantos arredondados) dentro do emulador Android ou Windows.

**Instalação:**
No `pubspec.yaml`:
```yaml
dev_dependencies:
  device_preview: ^1.2.0
```

No `main.dart` (apenas durante desenvolvimento):
```dart
import 'package:device_preview/device_preview.dart';

void main() => runApp(
  DevicePreview(
    enabled: true, // !kReleaseMode
    builder: (context) => MyApp(),
  ),
);
```

---

## 5. Ajustes Específicos para iOS

Embora o código Dart seja o mesmo, o iOS exige configurações de permissão no arquivo `ios/Runner/Info.plist`. Você precisará editar este arquivo (pode ser feito pelo Windows mesmo, pois é um arquivo de texto XML).

### Permissões Necessárias (Adicionar ao Info.plist)
O iOS exige que você explique ao usuário **por que** precisa de cada permissão.

```xml
<!-- Localização -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Precisamos da sua localização para registrar onde o foco do vetor foi encontrado.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Precisamos da sua localização para rastrear o trajeto da visita.</string>

<!-- Câmera -->
<key>NSCameraUsageDescription</key>
<string>O aplicativo precisa da câmera para fotografar os insetos encontrados.</string>

<!-- Galeria de Fotos -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Precisamos acessar sua galeria para anexar fotos de denúncias anteriores.</string>
```

---

## 6. Diferenças do Android vs iOS neste Projeto

| Funcionalidade | Android | iOS | Ação Necessária |
| :--- | :--- | :--- | :--- |
| **Mapas** | Google Maps Nativo | Apple Maps ou Google Maps | A biblioteca `flutter_map` ou `google_maps_flutter` funcionam em ambos. |
| **Arquivos** | `path_provider` | `path_provider` | Nenhuma (o plugin abstrai a diferença). |
| **Banco Local** | Hive | Hive | Nenhuma (Hive é Dart puro). |
| **Navegação** | Botão Voltar Físico/Gesto | Gesto de arrastar e botão na tela | Garantir que todas as telas tenham `AppBar` com botão de voltar (já feito). |
| **Design** | Material Design (Google) | Cupertino (Apple) | O Flutter renderiza o Material Design no iOS, o que é aceitável. O App ficará com cara de Android no iPhone, a menos que usemos widgets adaptativos. |

---

## 7. Checklist para Publicação (Futuro)

Quando for subir para a Apple App Store:

1.  [ ] Criar conta Apple Developer.
2.  [ ] Gerar ícones do App para iOS (tamanhos variados: 20pt, 29pt, 40pt, 60pt, etc).
3.  [ ] Criar Screenshots do App rodando em iPhone (pode usar o emulador na nuvem para tirar os prints).
4.  [ ] Preencher formulário de privacidade na App Store Connect.
