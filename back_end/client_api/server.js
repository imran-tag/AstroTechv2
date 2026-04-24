// server.js
const express = require("express");
const app = express();
require("dotenv").config();
const bodyParser = require('body-parser');
const cors = require('cors');

// Configuration
const PORT = process.env.PORT || 3000;
const API_URI = "/api/v1"; // préfixe pour l'API
const CLIENT_URI = process.env.URI || `${API_URI}/clients`; // routes clients

// Middleware global
app.disable('x-powered-by');
app.use(cors());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// === Auth ===
const { 
  register,
  login,
  me,
  updateProfile,
  updatePassword,
  forgotPassword,
  resetPassword
} = require('./controllers/_auth.controller');

const { authenticateToken } = require('./middlewares/auth.js');

// Routes publiques (Auth)
app.post(`${API_URI}/auth/register`, register);
app.post(`${API_URI}/auth/login`, login);

// Routes sécurisées (Auth)
app.get(`${API_URI}/auth/me`, authenticateToken, me);

// Les nouvelles routes basées sur le même pattern
// Note : 'authenticateToken' est ton middleware qui vérifie le JWT
app.put(`${API_URI}/auth/profile`, authenticateToken, updateProfile);
app.put(`${API_URI}/auth/password`, authenticateToken, updatePassword);
app.post(`${API_URI}/auth/forgot-password`, forgotPassword);
app.post(`${API_URI}/auth/reset-password/:token`, resetPassword);


// app.put(`${API_URI}/auth/profile`, authenticateToken, updateProfile);
// app.put(`${API_URI}/auth/password`, authenticateToken, updatePassword);
// app.post(`${API_URI}/auth/forgot-password`, forgotPassword);
// app.post(`${API_URI}/auth/reset-password/:token`, resetPassword);

// === Controllers ===
const controllerClient = require('./controllers/clients.controller');
const controllerOrganisation = require('./controllers/organisations.controller');
const controllerAgence = require('./controllers/agences.controller');
const controllerParticulier = require('./controllers/particuliers.controller');
const controllerAdresse = require('./controllers/adresses.controller');
const controllerContact = require('./controllers/contacts.controller');
const controllerAdresseEmail = require('./controllers/adresse_email.controller');
const controllerNumTel = require('./controllers/num_tel.controller');
const controllerSecteur = require('./controllers/secteur.controller.js');
const controllerHabitation = require('./controllers/habitation.controller.js');

/*** num_tel ***/
app.get(`${CLIENT_URI}/num_tel`, authenticateToken, controllerNumTel.apiGetAll);
app.post(`${CLIENT_URI}/num_tel`, authenticateToken, controllerNumTel.apiCreate);
app.put(`${CLIENT_URI}/num_tel/:id`, authenticateToken, controllerNumTel.apiUpdateById);
app.get(`${CLIENT_URI}/num_tel/:id`, authenticateToken, controllerNumTel.apiGetById);
app.delete(`${CLIENT_URI}/num_tel/:id`, authenticateToken, controllerNumTel.apiDeleteById);
app.get(`${CLIENT_URI}/num_tel/byTel/:contact_id`, authenticateToken, controllerNumTel.apiGetByTelAndContact);

/*** adresse_email ***/
app.get(`${CLIENT_URI}/adresse_email`, authenticateToken, controllerAdresseEmail.apiGetAll);
app.post(`${CLIENT_URI}/adresse_email`, authenticateToken, controllerAdresseEmail.apiCreate);
app.put(`${CLIENT_URI}/adresse_email/:id`, authenticateToken, controllerAdresseEmail.apiUpdateById);
app.get(`${CLIENT_URI}/adresse_email/:id`, authenticateToken, controllerAdresseEmail.apiGetById);
app.delete(`${CLIENT_URI}/adresse_email/:id`, authenticateToken, controllerAdresseEmail.apiDeleteById);
app.get(`${CLIENT_URI}/adresse_email/byEmail/:contact_id`, authenticateToken, controllerAdresseEmail.apiGetByEmailAndContact);

/*** contact ***/
app.get(`${CLIENT_URI}/contact`, authenticateToken, controllerContact.apiGetAll);
app.post(`${CLIENT_URI}/contact`, authenticateToken, controllerContact.apiCreate);
app.get(`${CLIENT_URI}/contact/byNameAndPoste`, authenticateToken, controllerContact.apiGetByNameAndPoste);
app.put(`${CLIENT_URI}/contact/:id`, authenticateToken, controllerContact.apiUpdateById);
app.get(`${CLIENT_URI}/contact/:id`, authenticateToken, controllerContact.apiGetById);
app.delete(`${CLIENT_URI}/contact/:id`, authenticateToken, controllerContact.apiDeleteById);

/*** adresse ***/
app.get(`${CLIENT_URI}/adresse`, authenticateToken, controllerAdresse.apiGetAll);
app.post(`${CLIENT_URI}/adresse`, authenticateToken, controllerAdresse.apiCreate);
app.put(`${CLIENT_URI}/adresse/:id`, authenticateToken, controllerAdresse.apiUpdateById);
app.get(`${CLIENT_URI}/adresse/:id`, authenticateToken, controllerAdresse.apiGetById);
app.delete(`${CLIENT_URI}/adresse/:id`, authenticateToken, controllerAdresse.apiDeleteById);

/*** habitation ***/
app.get(`${CLIENT_URI}/habitation`, authenticateToken, controllerHabitation.apiGetAll);
app.post(`${CLIENT_URI}/habitation`, authenticateToken, controllerHabitation.apiCreate);
app.get(`${CLIENT_URI}/habitation/details/:id`, authenticateToken, controllerHabitation.apiGetRecordDetails);
app.put(`${CLIENT_URI}/habitation/:id`, authenticateToken, controllerHabitation.apiUpdateById);
app.get(`${CLIENT_URI}/habitation/:id`, authenticateToken, controllerHabitation.apiGetById);
app.delete(`${CLIENT_URI}/habitation/:id`, authenticateToken, controllerHabitation.apiDeleteById);
app.put(`${CLIENT_URI}/habitation/:id/note`, controllerHabitation.setRecordNote);

/*** secteur ***/
app.get(`${CLIENT_URI}/secteur`, authenticateToken, controllerSecteur.apiGetAll);
app.post(`${CLIENT_URI}/secteur`, authenticateToken, controllerSecteur.apiCreate);
app.put(`${CLIENT_URI}/secteur/:id`, authenticateToken, controllerSecteur.apiUpdateById);
app.get(`${CLIENT_URI}/secteur/:id`, authenticateToken, controllerSecteur.apiGetById);
app.delete(`${CLIENT_URI}/secteur/:id`, authenticateToken, controllerSecteur.apiDeleteById);
app.get(`${CLIENT_URI}/secteur/details/:id`, authenticateToken, controllerSecteur.apiGetRecordDetails);
app.put(`${CLIENT_URI}/secteur/:id/note`, controllerSecteur.setRecordNote);

/*** particulier ***/
app.get(`${CLIENT_URI}/particulier`, authenticateToken, controllerParticulier.apiGetAll);
app.post(`${CLIENT_URI}/particulier`, authenticateToken, controllerParticulier.apiCreate);
app.put(`${CLIENT_URI}/particulier/:id`, authenticateToken, controllerParticulier.apiUpdateById);
app.get(`${CLIENT_URI}/particulier/:id`, authenticateToken, controllerParticulier.apiGetById);
app.delete(`${CLIENT_URI}/particulier/:id`, authenticateToken, controllerParticulier.apiDeleteById);
app.put(`${CLIENT_URI}/particulier/:id/note`, controllerParticulier.setRecordNote);

/*** agence ***/
app.get(`${CLIENT_URI}/agence`, authenticateToken, controllerAgence.apiGetAll);
app.post(`${CLIENT_URI}/agence`, authenticateToken, controllerAgence.apiCreate);
app.put(`${CLIENT_URI}/agence/:id`, authenticateToken, controllerAgence.apiUpdateById);
app.get(`${CLIENT_URI}/agence/:id`, authenticateToken, controllerAgence.apiGetById);
app.delete(`${CLIENT_URI}/agence/:id`, authenticateToken, controllerAgence.apiDeleteById);
app.put(`${CLIENT_URI}/agence/:id/note`, controllerAgence.setRecordNote);

/*** organisations ***/
app.get(`${CLIENT_URI}/organisation`, authenticateToken, controllerOrganisation.apiGetAll);
app.post(`${CLIENT_URI}/organisation`, authenticateToken, controllerOrganisation.apiCreate);
app.put(`${CLIENT_URI}/organisation/:id`, authenticateToken, controllerOrganisation.apiUpdateById);
app.get(`${CLIENT_URI}/organisation/:id`, authenticateToken, controllerOrganisation.apiGetById);
app.delete(`${CLIENT_URI}/organisation/:id`, authenticateToken, controllerOrganisation.apiDeleteById);
app.put(`${CLIENT_URI}/organisation/:id/note`, controllerOrganisation.setRecordNote);

/*** clients ***/

// Routes statiques / "spécifiques" en premier
app.get(`${CLIENT_URI}/contacts/all`, authenticateToken, controllerClient.apigetAllClientsWithContacts);
app.get(`${CLIENT_URI}/contacts`, authenticateToken, controllerClient.getAllClientsWithContactsPaginated);
app.get(`${CLIENT_URI}/parent/:parentId`, authenticateToken, controllerClient.getClientsByParentWithDetails);
app.get(`${CLIENT_URI}/:clientId/interventions`, authenticateToken, controllerClient.getClientInterventions);
app.get(`${CLIENT_URI}/details/:id`, authenticateToken, controllerClient.getRecordDetails);

// Route pour récupérer l'historique des affaires
app.get(`${CLIENT_URI}/:clientId/affaires`, controllerClient.getAffairesByClientId);

// CRUD générique
app.get(`${CLIENT_URI}`, authenticateToken, controllerClient.apiGetAll);
app.get(`${CLIENT_URI}/:id`, authenticateToken, controllerClient.apiGetById);
app.post(`${CLIENT_URI}`, authenticateToken, controllerClient.apiCreate);
app.put(`${CLIENT_URI}/:id`, authenticateToken, controllerClient.apiUpdateById);
app.delete(`${CLIENT_URI}/:id`, authenticateToken, controllerClient.apiDeleteById);


// Démarrage du serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
});
