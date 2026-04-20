const express = require("express");
const app = express();
require("dotenv").config();
const bodyParser = require('body-parser');
const cors = require('cors');

// Configuration
const PORT = process.env.PORT || 3000;
const URI = process.env.URI || "/api/v1";

// Middleware global
app.disable('x-powered-by');
app.use(cors());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// === Import des Contrôleurs et Middlewares ===
const { register, login, me } = require('./controllers/_auth.controller');
const { authenticateToken } = require('./middlewares/auth.js');

const InterventionController = require('./controllers/intervention.controller.js');
const PlanningController = require('./controllers/planning.controller.js');
const controllerAffaire = require('./controllers/affaires.controller.js');
const DashboardController = require('./controllers/dashboard.controller');
const MotCleLien = require('./controllers/mot_cle_liens.controller.js');
const MotsClesController = require('./controllers/mots_cles.controller.js');

// ==========================================
// 🔐 AUTHENTIFICATION
// ==========================================
app.post(`${URI}/auth/register`, register);
app.post(`${URI}/auth/login`, login);
app.get(`${URI}/auth/me`, authenticateToken, me);

// ==========================================
// 📊 DASHBOARD
// ==========================================
app.get(`${URI}/dashboard/interventions`, authenticateToken, DashboardController.getInterventionsDashboard);

// ==========================================
// 🛠️ INTERVENTIONS
// ==========================================

// 1. Routes statiques ou spécifiques (AVANT les :id)
app.get(`${URI}/interventions/nextNumero`, authenticateToken, InterventionController.apiGetNextNumero);
app.get(`${URI}/interventions/all`, authenticateToken, InterventionController.apiGetAll);
app.get(`${URI}/interventions/type/all`, authenticateToken, InterventionController.getInterventionTypes);
app.get(`${URI}/interventions/by-type/:type_id`, authenticateToken, InterventionController.getByTypePaginated);

// 2. Pagination et Recherche globale
app.get(`${URI}/interventions`, authenticateToken, InterventionController.apiGetAllPaginated);
app.post(`${URI}/interventions`, authenticateToken, InterventionController.apiCreate);

// 3. Routes avec ID (Actions sur une intervention spécifique)
app.get(`${URI}/interventions/:id`, authenticateToken, InterventionController.apiGetById);
app.get(`${URI}/interventions/:id/details`, authenticateToken, InterventionController.apiGetDetails);
app.put(`${URI}/interventions/:id`, authenticateToken, InterventionController.apiUpdateById);
app.delete(`${URI}/interventions/:id`, authenticateToken, InterventionController.apiDeleteById);

// 4. Sous-ressources d'interventions
app.put(`${URI}/interventions/:id/type`, authenticateToken, InterventionController.updateEtat);
app.post(`${URI}/interventions/:id/assign-techniciens`, authenticateToken, InterventionController.assignTechniciens);
app.put(`${URI}/interventions/:id/assign-equipe`, authenticateToken, InterventionController.assignEquipe);
app.post(`${URI}/interventions/:id/add-planning`, authenticateToken, InterventionController.addPlanning); // Option 1
app.post(`${URI}/interventions/:id/planning`, authenticateToken, PlanningController.addPlanning);     // Option 2 (via planning controller)
app.post(`${URI}/interventions/:id/add-prevision`, authenticateToken, InterventionController.addPrevision);

// ==========================================
// 📅 PLANNING (Général)
// ==========================================
app.get(`${URI}/planning`, authenticateToken, PlanningController.getAll);
app.put(`${URI}/planning/:id`, authenticateToken, PlanningController.updatePlanning);
app.delete(`${URI}/planning/:id`, authenticateToken, PlanningController.deletePlanning);

// ==========================================
// DICTIONNAIRE DES MOTS CLÉS
// ==========================================
app.post(`${URI}/mots-cles`, authenticateToken, MotsClesController.apiCreate);
app.get(`${URI}/mots-cles`, authenticateToken, MotsClesController.apiGetAll);
app.get(`${URI}/mots-cles/:id`, authenticateToken, MotsClesController.apiGetById);
app.put(`${URI}/mots-cles/:id`, authenticateToken, MotsClesController.apiUpdateById);
app.delete(`${URI}/mots-cles/:id`, authenticateToken, MotsClesController.apiDeleteById);

// ==========================================
// MOTS CLÉS (LIENS POLYMORPHIQUE)
// ==========================================
app.post(`${URI}/mot-cle-liens`, authenticateToken, MotCleLien.apiCreate);
app.get(`${URI}/mot-cle-liens`, authenticateToken, MotCleLien.apiGetAll);
app.get(`${URI}/mot-cle-liens/:id`, authenticateToken, MotCleLien.apiGetById);
app.put(`${URI}/mot-cle-liens/:id`, authenticateToken, MotCleLien.apiUpdateById);
app.delete(`${URI}/mot-cle-liens/:id`, authenticateToken, MotCleLien.apiDeleteById);
app.get(`${URI}/mot-cle-liens/target/:target_type/:target_id`, authenticateToken, MotCleLien.apiGetByTarget);

// ==========================================
// 💼 AFFAIRES
// ==========================================
// Note : Ajout du préfixe /affaires pour éviter les conflits avec la racine de l'API
app.post(`${URI}`, authenticateToken, controllerAffaire.apiCreate);
app.get(`${URI}/all`, authenticateToken, controllerAffaire.apiGetAll);
app.get(`${URI}`, authenticateToken, controllerAffaire.apiGetAllPaginated);

// Routes dynamiques à la fin
app.get(`${URI}/:id`, authenticateToken, controllerAffaire.apiGetById);
app.put(`${URI}/:id`, authenticateToken, controllerAffaire.apiUpdateById);
app.delete(`${URI}/:id`, authenticateToken, controllerAffaire.apiDeleteById);

// ==========================================
// 🚀 LANCEMENT DU SERVEUR
// ==========================================
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ AstroTech Server running at http://localhost:${PORT}`);
    console.log(`🌐 API Base URL: ${URI}`);
});