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
    │   ├── Dashboard.css
    │   ├── CollectionDetailsModal.js
    │   └── CollectionDetailsModal.css
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
 
```

### E. Estilo do Dashboard (`src/components/Dashboard.css`)

> **Atualizado:** Logo maior, Ranking melhorado e Tabela mais legível.

```css
.dashboard-container { display: flex; height: 100vh; background-color: #F4F6F9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }

/* SIDEBAR */
.sidebar { 
  width: 280px; /* Um pouco mais larga */
  background: linear-gradient(180deg, #2ECC71, #3498DB); 
  color: white; 
  display: flex; 
  flex-direction: column; 
  box-shadow: 4px 0 10px rgba(0,0,0,0.1);
}
.sidebar-header { 
  padding: 40px 20px; /* Mais espaço em cima */
  text-align: center; 
  border-bottom: 1px solid rgba(255,255,255,0.2); 
}
.logo-container {
  background: white;
  width: 110px; /* AUMENTADO DE 80 PARA 110 */
  height: 110px; /* AUMENTADO */
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 15px auto;
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}
.sidebar-logo { width: 75px; /* AUMENTADO A LOGO INTERNA */ }
.sidebar h3 { margin: 0; font-size: 1.3rem; font-weight: 700; letter-spacing: 0.5px; text-shadow: 0 2px 4px rgba(0,0,0,0.1); }

.sidebar-nav { flex: 1; padding: 20px 0; }
.nav-item { 
  display: block; padding: 18px 30px; color: rgba(255,255,255,0.95); text-decoration: none; font-weight: 500; border-left: 6px solid transparent; transition: all 0.3s ease; font-size: 1.05rem;
}
.nav-item:hover, .nav-item.active { background-color: rgba(255,255,255,0.2); color: white; border-left-color: white; font-weight: 700; }
.sidebar-footer { padding: 20px; }
.logout-button { width: 100%; padding: 14px; background-color: rgba(0,0,0,0.2); border: 1px solid rgba(255,255,255,0.3); color: white; border-radius: 8px; cursor: pointer; font-weight: 600; transition: 0.2s; }
.logout-button:hover { background-color: rgba(0,0,0,0.4); }

/* CONTEÚDO */
.main-content { flex: 1; overflow-y: auto; padding: 40px; position: relative; }
.top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px; }
.top-bar h2 { color: #2C3E50; margin: 0; font-size: 1.8rem; }
.user-info { display: flex; align-items: center; gap: 12px; background: white; padding: 10px 24px; border-radius: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }
.avatar { width: 40px; height: 40px; background: linear-gradient(135deg, #3498DB, #2980B9); color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 1.2rem; }

/* KPI GRID */
.kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 25px; margin-bottom: 35px; }
.kpi-card { background: white; padding: 25px; border-radius: 15px; display: flex; align-items: center; gap: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); position: relative; overflow: hidden; transition: transform 0.2s; }
.kpi-card:hover { transform: translateY(-3px); }
.kpi-card::after { content: ''; position: absolute; bottom: 0; left: 0; width: 100%; height: 4px; }
.kpi-card.critical::after { background: #EF4444; }
.kpi-card.warning::after { background: #F59E0B; }
.kpi-card.service::after { background: #3B82F6; }
.kpi-card.meta::after { background: #2ECC71; }
.kpi-icon { font-size: 2.2rem; background: #F8F9FA; padding: 18px; border-radius: 16px; }
.kpi-info { display: flex; flex-direction: column; }
.kpi-label { font-size: 0.9rem; color: #7F8C8D; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; }
.kpi-value { font-size: 2rem; font-weight: 800; color: #2C3E50; margin-top: 5px; }

/* MIDDLE SECTION */
.middle-section { display: flex; gap: 25px; margin-bottom: 35px; height: 420px; }
.map-container { flex: 7; background: white; border-radius: 15px; padding: 25px; display: flex; flex-direction: column; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
.section-header h3 { margin: 0; color: #2C3E50; font-size: 1.3rem; }
.map-legend { font-size: 0.85rem; color: #7F8C8D; display: flex; align-items: center; gap: 15px; background: #F8F9FA; padding: 8px 15px; border-radius: 20px; }
.ranking-container { flex: 3; background: white; border-radius: 15px; padding: 25px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); display: flex; flex-direction: column; }

/* RANKING MELHORADO */
.ranking-list { list-style: none; padding: 0; margin-top: 15px; overflow-y: auto; flex: 1; }
.ranking-item { 
  display: flex; justify-content: space-between; align-items: center; 
  padding: 15px; margin-bottom: 10px; 
  background-color: #F8FAFC; border-radius: 10px; /* Caixinha para cada item */
  border-left: 4px solid transparent;
  transition: 0.2s;
}
.ranking-item:hover { background-color: #F1F5F9; transform: translateX(2px); }
.rank-left { display: flex; align-items: center; gap: 12px; }
.rank-pos { 
  width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; 
  border-radius: 50%; font-size: 0.9rem; font-weight: bold; color: white; background: #94A3B8;
}
.rank-pos.pos-1 { background: #EF4444; box-shadow: 0 2px 5px rgba(239, 68, 68, 0.3); } /* Vermelho para o 1º */
.rank-pos.pos-2 { background: #F59E0B; } /* Laranja para o 2º */
.rank-pos.pos-3 { background: #3B82F6; } /* Azul para o 3º */
.rank-name { font-weight: 600; color: #334155; font-size: 1rem; }
.rank-val { font-size: 0.9rem; color: #64748B; font-weight: 700; }

/* TABELA MELHORADA */
.data-section { background: white; border-radius: 15px; padding: 30px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
.btn-export { background: linear-gradient(90deg, #2ECC71, #27AE60); color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: 700; cursor: pointer; box-shadow: 0 4px 10px rgba(46, 204, 113, 0.2); transition: 0.2s; }
.btn-export:hover { transform: translateY(-2px); box-shadow: 0 6px 14px rgba(46, 204, 113, 0.3); }

.data-table { width: 100%; border-collapse: separate; border-spacing: 0 5px; margin-top: 10px; } /* Espaçamento entre linhas */
.data-table th { 
  text-align: left; padding: 15px; 
  color: #2C3E50; /* Mais escuro */
  font-size: 0.95rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; 
  border-bottom: 2px solid #E2E8F0;
}
.data-table td { 
  padding: 18px 15px; /* Mais espaçamento */
  font-size: 1rem; color: #2C3E50; 
  background: white; border-bottom: 1px solid #F1F5F9; 
}
.data-table tr:hover td { background-color: #F8FAFC; } /* Efeito hover na linha */
.text-center { text-align: center; }

/* BADGES */
.badge { padding: 6px 12px; border-radius: 30px; font-size: 0.8rem; font-weight: 700; display: inline-block; letter-spacing: 0.5px; }
.badge-capture { background: #FFEBEE; color: #C0392B; border: 1px solid rgba(192, 57, 43, 0.1); }
.badge-trace { background: #FFF3E0; color: #E67E22; border: 1px solid rgba(230, 126, 34, 0.1); }
.badge-clean { background: #E8F8F5; color: #27AE60; border: 1px solid rgba(39, 174, 96, 0.1); }

.btn-action { background: white; border: 1px solid #3498DB; color: #3498DB; padding: 8px 18px; border-radius: 6px; cursor: pointer; font-weight: 600; transition: 0.2s; }
.btn-action:hover { background: #3498DB; color: white; box-shadow: 0 2px 5px rgba(52, 152, 219, 0.3); }

@media (max-width: 1024px) { .middle-section { flex-direction: column; height: auto; } .map-container, .ranking-container { width: 100%; height: 400px; } }
@media (max-width: 768px) { .dashboard-container { flex-direction: column; } .sidebar { width: 100%; height: auto; flex-direction: row; justify-content: space-between; padding: 15px; } .sidebar-nav, .sidebar-footer { display: none; } .logo-container { width: 50px; height: 50px; margin: 0; } .sidebar-logo { width: 30px; } }
```

### F. Modal de Detalhes (`src/components/CollectionDetailsModal.js`)

(Mantenha o mesmo código anterior).

### G. Estilo do Modal (`src/components/CollectionDetailsModal.css`)

(Mantenha o mesmo código anterior).

## 3. Como Rodar

No terminal (dentro da pasta `painel-vector-trackers`):

```bash
# 1. Instalar dependências (apenas na primeira vez)
npm install

# 2. Iniciar o servidor
npm start
```
