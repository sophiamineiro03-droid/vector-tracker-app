# Documentação do Painel Web (React)

Este documento contém o código fonte e as instruções para configurar o Painel Administrativo Web do projeto Vector Tracker. Este painel foi desenvolvido em React e deve rodar separadamente do aplicativo Flutter, preferencialmente no VS Code.

## 1. Estrutura de Pastas Necessária

No seu projeto React (`painel-vector-trackers`), a estrutura dentro de `src` deve ficar assim:

```
painel-vector-trackers/
└── src/
    ├── assets/
    │   └── logo.png          <-- Sua logo deve estar aqui
    ├── components/
    │   ├── LoginScreen.js
    │   ├── LoginScreen.css
    │   ├── Dashboard.js
    │   └── Dashboard.css
    ├── App.js
    ├── App.css
    ├── index.js
    └── index.css
```

## 2. Códigos Fonte

### A. Arquivo Principal (`src/App.js`)

Este arquivo gerencia as rotas entre o Login e o Dashboard.

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import './App.css';

// Importando os componentes
import LoginScreen from './components/LoginScreen';
import Dashboard from './components/Dashboard';

function App() {
  return (
    <Router>
      <Routes>
        {/* Rota inicial vai para o Login */}
        <Route path="/" element={<LoginScreen />} />
        
        {/* Rota do Painel */}
        <Route path="/dashboard" element={<Dashboard />} />

        {/* Qualquer outro link volta para o Login */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
```

### B. Tela de Login (`src/components/LoginScreen.js`)

```javascript
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './LoginScreen.css';
import logo from '../assets/logo.png'; 

const LoginScreen = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = (e) => {
    e.preventDefault();
    // Simulação de login - Futuramente integrar com Supabase Auth
    console.log("Tentando logar com:", email);
    navigate('/dashboard');
  };

  return (
    <div className="login-container">
      <div className="brand-section">
        <form className="login-form" onSubmit={handleLogin}>
          <h2>Acesse o Painel</h2>
          <input 
            type="text" 
            placeholder="Usuário ou Email" 
            className="login-input"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <input 
            type="password" 
            placeholder="Senha" 
            className="login-input"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <button type="submit" className="login-button">
            Entrar
          </button>
        </form>
      </div>

      <div className="form-section">
        <img src={logo} alt="Vector Trackers Logo" className="login-logo" />
        <h1>Vector Trackers</h1>
        <p>Digitalizando a vigilância...</p>
      </div>
    </div>
  );
};

export default LoginScreen;
```

### C. Estilo do Login (`src/components/LoginScreen.css`)

```css
.login-container {
  display: flex;
  height: 100vh;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.brand-section {
  width: 50%;
  background: linear-gradient(135deg, #2ECC71, #3498DB);
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 40px;
}

.form-section {
  width: 50%;
  background-color: #FFFFFF;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: 40px;
}

.login-logo { max-width: 250px; margin-bottom: 20px; }
.form-section h1 { font-size: 2.5rem; font-weight: 700; color: #333; margin: 0; }
.form-section p { font-size: 1.2rem; font-weight: 300; color: #555; margin-top: 8px; }

.login-form { width: 100%; max-width: 400px; display: flex; flex-direction: column; gap: 20px; }
.login-form h2 { font-size: 28px; font-weight: 600; color: #FFFFFF; text-align: center; margin-bottom: 10px; }

.login-input {
  border-radius: 12px; border: 1px solid #ccc; background-color: #FFFFFF;
  padding: 12px; font-size: 16px; color: #333; width: 100%; box-sizing: border-box;
}
.login-input:focus { border-color: #1e90ff; outline: none; }

.login-button {
  border-radius: 12px; border: none; padding: 12px; font-size: 18px;
  color: white; cursor: pointer; background: linear-gradient(90deg, #007bff, #00bfff);
  width: 100%; font-weight: 600; transition: 0.2s;
}
.login-button:hover { background: linear-gradient(90deg, #0056b3, #0099cc); }

@media (max-width: 768px) {
  .login-container { flex-direction: column; height: auto; min-height: 100vh; }
  .brand-section, .form-section { width: 100%; padding: 60px 20px; }
  .brand-section { order: 2; } .form-section { order: 1; }
}
```

### D. Tela de Dashboard (`src/components/Dashboard.js`)

```javascript
import React, { useState } from 'react';
import './Dashboard.css';
import logo from '../assets/logo.png';

const Dashboard = () => {
  // Dados fictícios (Mock)
  const [dados] = useState([
    { id: 1, data: '20/11/2025', localidade: 'Centro', rua: 'Rua das Flores, 123', agente: 'Carlos Silva', atividade: 'Pesquisa', status: 'Concluído' },
    { id: 2, data: '20/11/2025', localidade: 'Vila Nova', rua: 'Av. Brasil, 450', agente: 'Ana Maria', atividade: 'Borrifação', status: 'Pendente' },
    { id: 3, data: '19/11/2025', localidade: 'Zona Rural', rua: 'Sítio Boa Vista', agente: 'Roberto Lima', atividade: 'Pesquisa', status: 'Positivo' },
  ]);

  return (
    <div className="dashboard-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <img src={logo} alt="Logo" className="sidebar-logo" />
          <h3>Vector Admin</h3>
        </div>
        <nav className="sidebar-nav">
          <a href="#" className="nav-item active">📊 Visão Geral</a>
          <a href="#" className="nav-item">📍 Mapa de Calor</a>
          <a href="#" className="nav-item">📝 Denúncias</a>
          <a href="#" className="nav-item">💾 Exportar SIOCHAGAS</a>
        </nav>
        <div className="sidebar-footer">
          <button className="logout-button">Sair do Sistema</button>
        </div>
      </aside>

      {/* Conteúdo */}
      <main className="main-content">
        <header className="top-bar">
          <h2>Painel de Controle</h2>
          <div className="user-info">
            <span>Olá, <strong>Coordenador</strong></span>
            <div className="avatar">C</div>
          </div>
        </header>

        {/* Cards */}
        <section className="stats-grid">
          <div className="stat-card">
            <h3>Denúncias Hoje</h3>
            <p className="stat-number">12</p>
            <span className="stat-detail text-orange">🟠 4 Pendentes</span>
          </div>
          <div className="stat-card">
            <h3>Visitas Realizadas</h3>
            <p className="stat-number">45</p>
            <span className="stat-detail text-green">🟢 Meta atingida</span>
          </div>
          <div className="stat-card">
            <h3>Focos Encontrados</h3>
            <p className="stat-number">3</p>
            <span className="stat-detail text-red">🔴 Atenção Requerida</span>
          </div>
        </section>

        {/* Tabela */}
        <section className="data-section">
          <div className="section-header">
            <h3>Últimos Registros de Campo</h3>
            <button className="btn-export">📥 Baixar CSV (SIOCHAGAS)</button>
          </div>
          
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Data</th><th>Localidade</th><th>Endereço</th><th>Agente</th><th>Atividade</th><th>Status</th><th>Ações</th>
                </tr>
              </thead>
              <tbody>
                {dados.map((item) => (
                  <tr key={item.id}>
                    <td>{item.data}</td>
                    <td>{item.localidade}</td>
                    <td>{item.rua}</td>
                    <td>{item.agente}</td>
                    <td>{item.atividade}</td>
                    <td><span className={`status-badge ${item.status.toLowerCase()}`}>{item.status}</span></td>
                    <td><button className="btn-action">Ver</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </div>
  );
};

export default Dashboard;
```

### E. Estilo do Dashboard (`src/components/Dashboard.css`)

```css
.dashboard-container { display: flex; height: 100vh; background-color: #f4f6f9; font-family: sans-serif; }

/* Sidebar */
.sidebar { width: 260px; background: linear-gradient(180deg, #2ECC71, #3498DB); color: white; display: flex; flex-direction: column; }
.sidebar-header { padding: 30px 20px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.2); }
.sidebar-logo { width: 60px; background: white; border-radius: 50%; padding: 5px; }
.sidebar-nav { flex: 1; padding: 20px 0; }
.nav-item { display: block; padding: 15px 25px; color: rgba(255,255,255,0.9); text-decoration: none; border-left: 4px solid transparent; }
.nav-item:hover, .nav-item.active { background-color: rgba(255,255,255,0.2); color: white; border-left-color: white; }
.sidebar-footer { padding: 20px; }
.logout-button { width: 100%; padding: 10px; background-color: rgba(0,0,0,0.2); border: none; color: white; border-radius: 8px; cursor: pointer; }

/* Conteúdo */
.main-content { flex: 1; overflow-y: auto; padding: 30px; }
.top-bar { display: flex; justify-content: space-between; margin-bottom: 30px; }
.user-info { display: flex; gap: 10px; align-items: center; }
.avatar { width: 40px; height: 40px; background-color: #3498DB; color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; }

/* Cards */
.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
.stat-card { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 2px 5px rgba(0,0,0,0.05); }
.stat-number { font-size: 36px; font-weight: bold; color: #333; margin: 10px 0; }
.text-orange { color: #ff9f43; } .text-green { color: #2ecc71; } .text-red { color: #ee5253; }

/* Tabela */
.data-section { background: white; border-radius: 12px; padding: 25px; }
.section-header { display: flex; justify-content: space-between; margin-bottom: 20px; }
.btn-export { background-color: #2ecc71; color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; }
.data-table { width: 100%; border-collapse: collapse; }
.data-table th { text-align: left; padding: 15px; color: #888; border-bottom: 2px solid #f0f0f0; }
.data-table td { padding: 15px; border-bottom: 1px solid #f0f0f0; }
.status-badge { padding: 5px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; }
.status-badge.concluído { background-color: #d4edda; color: #155724; }
.status-badge.pendente { background-color: #fff3cd; color: #856404; }
.status-badge.positivo { background-color: #f8d7da; color: #721c24; }
.btn-action { padding: 5px 10px; border: 1px solid #3498DB; color: #3498DB; background: transparent; border-radius: 5px; cursor: pointer; }

@media (max-width: 768px) { .dashboard-container { flex-direction: column; } .sidebar { width: 100%; height: auto; } }
```

## 3. Como Rodar

No terminal (dentro da pasta `painel-vector-trackers`):

```bash
# 1. Instalar dependências (apenas na primeira vez)
npm install

# 2. Iniciar o servidor
npm start
```
