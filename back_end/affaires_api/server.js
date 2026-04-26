const express = require("express");
const app = express();
require("dotenv").config();
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configuration
const PORT = process.env.PORT || 3000;
const URI = process.env.URI || "/api/v1";

// Middleware global
app.disable('x-powered-by');
app.use(cors());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Serve uploaded photos and signatures as static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Photo upload storage
const PHOTOS_DIR = path.join(__dirname, 'uploads', 'photos');
if (!fs.existsSync(PHOTOS_DIR)) fs.mkdirSync(PHOTOS_DIR, { recursive: true });
const photoUpload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => cb(null, PHOTOS_DIR),
    filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
  }),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
});

// === Import des Contrôleurs et Middlewares ===
const { register, login, me } = require('./controllers/_auth.controller');
const { authenticateToken } = require('./middlewares/auth.js');

const InterventionController = require('./controllers/intervention.controller.js');
const PlanningController = require('./controllers/planning.controller.js');
const controllerAffaire = require('./controllers/affaires.controller.js');
const DashboardController = require('./controllers/dashboard.controller');
const MotCleLien = require('./controllers/mot_cle_liens.controller.js');
const MotsClesController = require('./controllers/mots_cles.controller.js');
const MobileController = require('./controllers/mobile.controller.js');
const MobileService = require('./services/mobile.service.js');

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
app.get(`${URI}/interventions/:id/recap`, authenticateToken, InterventionController.apiGetRecap);
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
// 📱 MOBILE API
// ==========================================
app.get(`${URI}/mobile/me`, authenticateToken, MobileController.getProfile);
app.post(`${URI}/mobile/sync`, authenticateToken, MobileController.bulkSync);

app.get(`${URI}/mobile/interventions`, authenticateToken, MobileController.getInterventions);
app.get(`${URI}/mobile/interventions/:id`, authenticateToken, MobileController.getInterventionById);
app.put(`${URI}/mobile/interventions/:id/status`, authenticateToken, MobileController.updateStatus);

app.get(`${URI}/mobile/interventions/:id/workflow`, authenticateToken, MobileController.getWorkflow);
app.post(`${URI}/mobile/interventions/:id/workflow`, authenticateToken, MobileController.createWorkflow);
app.patch(`${URI}/mobile/interventions/:id/workflow`, authenticateToken, MobileController.updateWorkflow);

app.get(`${URI}/mobile/interventions/:id/photos`, authenticateToken, MobileController.getPhotos);
app.post(`${URI}/mobile/interventions/:id/photos`, authenticateToken, photoUpload.single('photo'), MobileController.uploadPhoto);
app.delete(`${URI}/mobile/interventions/:id/photos/:photoId`, authenticateToken, MobileController.deletePhoto);

app.post(`${URI}/mobile/interventions/:id/signature`, authenticateToken, MobileController.uploadSignature);
app.post(`${URI}/mobile/interventions/:id/signatures/:type`, authenticateToken, MobileController.uploadTypedSignature);

app.post(`${URI}/mobile/interventions/:id/interruptions`, authenticateToken, MobileController.createInterruption);
app.patch(`${URI}/mobile/interventions/:id/interruptions/:interruptionId`, authenticateToken, MobileController.updateInterruption);

// ==========================================
// 🚀 LANCEMENT DU SERVEUR
// ==========================================
MobileService.initTables()
  .then(() => console.log('✅ Mobile tables ready'))
  .catch(err => console.error('⚠️  Mobile table init error:', err.message));

app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ AstroTech Server running at http://localhost:${PORT}`);
    console.log(`🌐 API Base URL: ${URI}`);
});