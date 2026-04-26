const InterventionService = require("../services/intervention.service");

class Intervention {

    // 🔄 Modifier le type d'une intervention
    static async updateEtat(req, res) {
        try {
            const interventionId = Number(req.params.id);
            const { type } = req.body;
            const userId = req.user.id; // depuis authenticateToken

            if (!interventionId || !type) {
                return res.status(400).json({
                    success: false,
                    message: "ID de l'intervention et type sont obligatoires"
                });
            }

            const result = await InterventionService.updateEtat({
                interventionId,
                type,
                userId
            });

            if (!result.updated) {
                return res.status(404).json({
                    success: false,
                    message: "Intervention introuvable ou non autorisée"
                });
            }

            res.status(200).json({
                success: true,
                message: "Type de l'intervention mis à jour avec succès"
            });

        } catch (error) {
            console.error("Erreur updateType:", error);
            res.status(500).json({
                success: false,
                message: "Erreur interne du serveur"
            });
        }
    }

    // ➕ Créer une nouvelle intervention
    static async apiCreate(req, res) {

        try {
            const {
                numero,
                titre,
                type_id,
                description,
                client_id,
                zone_intervention_client_id,
                type_client_zone_intervention,
                priorite,
                etat,
                date_butoir_realisation,
                date_cloture_estimee,
                // On extrait 'motsCles' tel que reçu dans le log (camelCase)
                motsCles,
                referent_ids,
                montant_intervention,
                montant_main_oeuvre,
                montant_fournitures,
                createur_id = req.user?.id
            } = req.body;

            // 1. Validation
            if (!titre || !type_id || numero == null) {
                return res.status(400).json({
                    error: "Les champs titre, type_id et numero sont obligatoires"
                });
            }

            // 2. Helper dates
            const parseDate = (d) => {
                if (!d || d === '') return null;
                const date = new Date(d);
                return isNaN(date.getTime()) ? null : date.toISOString().split('T')[0];
            };

            // 3. Préparation de l'objet Record
            const record = {
                numero,
                titre,
                type_id,
                description,
                client_id,
                zone_intervention_client_id,
                type_client_zone_intervention,
                priorite,
                etat,
                date_butoir_realisation: parseDate(date_butoir_realisation),
                date_cloture_estimee: parseDate(date_cloture_estimee),
                // ✅ On utilise la variable extraite correctement
                motsCles: Array.isArray(motsCles) ? motsCles : [],
                // ✅ On utilise referent_ids extrait du body pour remplir 'referents'
                referents: Array.isArray(referent_ids) ? referent_ids : [],
                montant_intervention,
                montant_main_oeuvre,
                montant_fournitures,
                createur_id
            };

            // 4. Appel au service
            const response = await InterventionService.apiCreate(record);

            // 5. Réponse
            return res.status(201).json({
                success: true,
                message: "Intervention créée avec succès",
                data: response
            });

        } catch (error) {
            console.error("❌ Controller Error (Intervention):", error);
            return res.status(500).json({
                success: false,
                error: error.message
            });
        }

        const parseDate = (d) => {
            if (!d || d === '' || typeof d !== 'string') return null;
            const date = new Date(d);
            return isNaN(date.getTime()) ? null : date.toISOString().split('T')[0];
        };

        // Préparation de l'objet pour le Service
        const record = {
            numero: Number(numero),
            titre,
            type_id,
            description: description || '',
            client_id: client_id ? Number(client_id) : null,
            zone_intervention_client_id: zone_intervention_client_id ? Number(zone_intervention_client_id) : null,
            type_client_zone_intervention: type_client_zone_intervention || '',
            priorite: priorite || 'Normale',
            etat: etat || 'Ouvert',
            date_butoir_realisation: parseDate(date_butoir_realisation),
            date_cloture_estimee: parseDate(date_cloture_estimee),
            // Gestion des mots clés (si tableau, on joint, sinon texte brut)
            mots_cles: Array.isArray(mots_cles) ? mots_cles.join(',') : (mots_cles || ''),
            montant_intervention: Number(montant_intervention || 0),
            montant_main_oeuvre: Number(montant_main_oeuvre || 0),
            montant_fournitures: Number(montant_fournitures || 0),
            // On transforme referent_ids en referents pour le service
            referents: Array.isArray(referent_ids)
                ? referent_ids.map(Number).filter(id => !isNaN(id))
                : [],
            createur_id: createur_id ? Number(createur_id) : null
        };

        const response = await InterventionService.apiCreate(record);

        return res.status(201).json({
            success: true,
            message: "Intervention créée avec succès",
            data: response
        });

    } catch(error) {
        console.error("❌ Controller Error:", error);
        return res.status(500).json({ success: false, error: error.message });
    }


    // ✏️ Modifier une intervention par ID
    static async apiUpdateById(req, res) {
        try {
            const { id } = req.params;
            const data = req.body;

            // 1. Validation minimale
            if (!data.titre || !data.description || !data.numero) {
                return res.status(400).json({ error: "titre, description et numero sont requis" });
            }

            // 2. Préparation des données pour le service
            // On s'assure que le service reçoit les noms de clés qu'il attend (referents, motsCles)
            const record = {
                ...data,
                referents: data.referent_ids || data.referents || [],
                motsCles: data.motsCles || data.mots_cles || []
            };

            // 3. ✅ APPEL CORRIGÉ : On appelle le nom exact défini dans le service
            const response = await InterventionService.updateIntervention(id, record);

            if (!response) {
                return res.status(404).json({ success: false, message: "Intervention non trouvée" });
            }

            return res.json({
                success: true,
                message: "Intervention mise à jour avec succès",
                data: response
            });

        } catch (error) {
            console.error("❌ Controller Update Error:", error.message);
            return res.status(500).json({ success: false, error: error.message });
        }
    }

    // ❌ Supprimer une intervention par ID
    static async apiDeleteById(req, res) {
        try {
            const { id } = req.params;
            const deleted = await InterventionService.apiDeleteById(id);
            if (!deleted) return res.status(404).json({ error: "Intervention non trouvée" });
            res.send();
        } catch (error) {
            console.error(error.message);
            res.status(500).send();
        }
    }

    // 📜 Pagination + recherche + user
    static async apiGetAllPaginated(req, res) {
        try {
            let { page = 1, limit = 10, search = '' } = req.query;
            const userId = Number(req.user.id);

            page = Number(page);
            limit = Number(limit);

            const result = await InterventionService.apiGetAllPaginated({
                page,
                limit,
                search,
                userId
            });

            res.status(200).json({
                success: true,
                page,
                limit,
                total: result.total,
                data: result.data
            });

        } catch (error) {
            console.error('Erreur apiGetAllPaginated:', error);
            res.status(500).json({
                success: false,
                error: 'Internal Server Error'
            });
        }
    }

    // 🔍 Récupérer une intervention par ID
    static async apiGetById(req, res) {
        try {
            const { id } = req.params;

            // 🔹 Appel direct à la méthode service apiGetById
            const intervention = await InterventionService.apiGetById(Number(id));

            if (!intervention) {
                return res.status(404).json({ message: 'Intervention non trouvée' });
            }

            res.json(intervention);

        } catch (error) {
            console.error('Erreur apiGetById:', error.message);
            res.status(500).json({ message: 'Erreur serveur' });
        }
    }


    // 🔹 Endpoint pour récupérer le prochain numéro
    static async apiGetNextNumero(req, res) {
        try {
            const nextNumero = await InterventionService.getNextNumero();
            res.json({ nextNumero });
        } catch (error) {
            res.status(500).json({ message: "Erreur serveur" });
        }
    }


    // 📜 Récupérer toutes les interventions
    static async apiGetAll(req, res) {
        try {
            const userId = req.user?.id;

            if (!userId) {
                return res.status(401).json({ error: 'Utilisateur non authentifié' });
            }

            const response = await InterventionService.apiGetAll(userId);
            res.json(response);

        } catch (error) {
            console.error(error);
            res.status(500).json({ error: 'Internal Server Error' });
        }
    }

    static async getInterventionTypes(req, res) {
        try {
            const types = await InterventionService.getInterventionTypes();

            res.status(200).json({
                success: true,
                data: types
            });

        } catch (error) {
            console.error("Erreur apiGetInterventionTypes:", error);
            res.status(500).json({
                success: false,
                message: "Erreur serveur"
            });
        }
    }



    // Assigner des techniciens à une intervention
    static async assignTechniciens(req, res) {
        try {
            const interventionId = req.params.id; // ID de l'intervention
            const { techniciens } = req.body; // tableau d'IDs de techniciens
            if (!Array.isArray(techniciens) || techniciens.length === 0) {
                return res.status(400).json({ message: 'Aucun technicien fourni' });
            }
            // Appeler le service pour assigner les techniciens
            const result = await InterventionService.assignTechniciens(interventionId, techniciens);
            res.status(200).json({
                message: 'Techniciens affectés avec succès',
                data: result
            });

        } catch (err) {
            console.error(err);
            res.status(500).json({ message: 'Erreur lors de l’affectation des techniciens' });
        }
    }

    static async addPlanning(req, res) {
        try {
            const interventionId = req.params.id;
            const { date, heure } = req.body;

            if (!date || !heure) {
                return res.status(400).json({ message: 'Date et heure sont obligatoires' });
            }

            const result = await InterventionService.addPlanning(interventionId, { date, heure });

            res.status(200).json({
                message: 'Planning ajouté avec succès',
                data: result
            });

        } catch (err) {
            console.error(err);
            res.status(500).json({ message: 'Erreur lors de l’ajout du planning' });
        }
    }

    // controllers/intervention.controller.js
    static async assignEquipe(req, res) {
        try {
            const interventionId = req.params.id;
            const { equipe_id } = req.body;

            if (!equipe_id) {
                return res.status(400).json({ message: 'L\'ID de l\'équipe est obligatoire' });
            }

            // Appel au service pour mettre à jour l'équipe de l'intervention
            const result = await InterventionService.assignEquipe(interventionId, equipe_id);

            res.status(200).json({
                message: 'Équipe affectée avec succès',
                data: result
            });

        } catch (err) {
            console.error(err);
            res.status(500).json({ message: 'Erreur lors de l’affectation de l’équipe' });
        }
    }

    static async getByTypePaginated(req, res) {
        try {
            const { type_id } = req.params;
            const user_id = req.user.id;
            const { page = 1, limit = 10, etat } = req.query; // 🔹 état depuis query param

            const result = await InterventionService.apiGetByTypePaginated({
                type_id,
                user_id,
                etat,
                page,
                limit
            });

            res.status(200).json({
                success: true,
                ...result
            });

        } catch (error) {
            console.error(error);
            res.status(500).json({
                success: false,
                message: 'Erreur chargement interventions'
            });
        }
    }

    static async addPrevision(req, res) {
        try {
            const interventionId = req.params.id;
            const { date_debut, duree_heures = 0, duree_minutes = 0 } = req.body;

            if (!date_debut) {
                return res.status(400).json({ message: 'La date prévisionnelle est obligatoire' });
            }

            const result = await InterventionService.addPrevision(interventionId, { date_debut, duree_heures, duree_minutes });

            res.status(200).json({
                message: 'Date prévisionnelle ajoutée avec succès',
                data: result
            });

        } catch (err) {
            console.error(err);
            res.status(500).json({ message: 'Erreur lors de l’ajout de la date prévisionnelle' });
        }
    }

    // 📜 Récupérer détails intervention
    static async apiGetDetails(req, res) {
        try {
            const { id } = req.params;
            const response = await InterventionService.apiGetDetails(id);
            res.json(response);
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: "Internal Server Error" });
        }
    }

    static async apiGetRecap(req, res) {
        try {
            const { id } = req.params;
            const response = await InterventionService.getRecap(id);
            res.json(response);
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: "Internal Server Error" });
        }
    }

}

module.exports = Intervention;