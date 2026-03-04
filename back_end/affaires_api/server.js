// server.js
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

// === Auth ===
const { register, login, me } = require('./controllers/_auth.controller');
const { authenticateToken } = require('./middlewares/auth.js');

app.post(`${URI}/auth/register`, register);
app.post(`${URI}/auth/login`, login);
app.get(`${URI}/auth/me`, authenticateToken, me);


const InterventionController = require('./controllers/intervention.controller.js');
const PlanningController = require('./controllers/planning.controller.js');
const controllerAffaire = require('./controllers/affaires.controller.js');
const DashboardController = require('./controllers/dashboard.controller');

// === Dashboard ===
app.get(`${URI}/dashboard/interventions`, DashboardController.getInterventionsDashboard);

// === Interventions ===
// GET nextNumero avans GET by id
app.get(`${URI}/interventions/nextNumero`, authenticateToken, InterventionController.apiGetNextNumero);

// Routes interventions
// 📌 Routes “spéciales” ou globales d’abord
app.get(`${URI}/interventions/all`, authenticateToken, InterventionController.apiGetAll); // récupère toutes les interventions (sans pagination)
// 📌 Création
app.post(`${URI}/interventions`, authenticateToken, InterventionController.apiCreate);
// 📌 Pagination / recherche
app.get(`${URI}/interventions`, authenticateToken, InterventionController.apiGetAllPaginated);
// 📌 Actions spécifiques sur une intervention (mettre :id avant les routes globales comme /all)
app.get(`${URI}/interventions/:id`, authenticateToken, InterventionController.apiGetById);
app.put(`${URI}/interventions/:id`, authenticateToken, InterventionController.apiUpdateById);
app.delete(`${URI}/interventions/:id`, authenticateToken, InterventionController.apiDeleteById);
// 📌 Actions sur ressources liées à une intervention
app.post(`${URI}/interventions/:id/assign-techniciens`, authenticateToken, InterventionController.assignTechniciens);
app.post(`${URI}/interventions/:id/add-planning`, authenticateToken, InterventionController.addPlanning);
app.put(`${URI}/interventions/:id/assign-equipe`, authenticateToken, InterventionController.assignEquipe);
app.put(`${URI}/interventions/:id/type`, authenticateToken, InterventionController.updateEtat);
app.get(`${URI}/interventions/by-type/:type_id`, authenticateToken, InterventionController.getByTypePaginated);
app.get(`${URI}/interventions/type/all`, authenticateToken, InterventionController.getInterventionTypes);
app.post(`${URI}/interventions/:id/add-prevision`, authenticateToken, InterventionController.addPrevision);
app.get(`${URI}/interventions/:id/details`, InterventionController.apiGetDetails);


// ➕ Ajouter une planification pour une intervention
app.post(`${URI}/interventions/:id/planning`, authenticateToken, PlanningController.addPlanning);
app.get(`${URI}/planning`, authenticateToken, PlanningController.getAll);
app.put(`${URI}/planning/:id`, authenticateToken, PlanningController.updatePlanning);
app.delete(`${URI}/planning/:id`, authenticateToken, PlanningController.deletePlanning);

// === Affaires ===
// CREATE
app.post(`${URI}`, authenticateToken, controllerAffaire.apiCreate);
// GET (statique AVANT dynamique)
app.get(`${URI}/all`, authenticateToken, controllerAffaire.apiGetAll);
app.get(`${URI}`, authenticateToken, controllerAffaire.apiGetAllPaginated);
// GET / UPDATE / DELETE par ID (dynamiques à la fin)
app.get(`${URI}/:id`, authenticateToken, controllerAffaire.apiGetById);
app.put(`${URI}/:id`, authenticateToken, controllerAffaire.apiUpdateById);
app.delete(`${URI}/:id`, authenticateToken, controllerAffaire.apiDeleteById);


// === Start the server ===
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
});
