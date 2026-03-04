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
                motsCles,

                montant_intervention,
                montant_main_oeuvre,
                montant_fournitures,

                referents,
                createur_id = req.user.id
            } = req.body;

            if (!titre || !type_id || numero == null) {
                return res.status(400).json({ error: "Les champs titre, type et numero sont obligatoires" });
            }

            const parseDate = (d) => {
                if (!d || d === '' || typeof d !== 'string') return null;
                const date = new Date(d);
                return isNaN(date.getTime()) ? null : date.toISOString().split('T')[0];
            };

            const record = {
                numero,
                titre,
                type_id,
                description,

                client_id: Number(client_id || 0),
                zone_intervention_client_id: Number(zone_intervention_client_id || 0),
                type_client_zone_intervention: type_client_zone_intervention || '',

                priorite: priorite || '',
                etat: etat || '',

                date_butoir_realisation: parseDate(date_butoir_realisation),
                date_cloture_estimee: parseDate(date_cloture_estimee),

                mots_cles: Array.isArray(motsCles) ? motsCles.join(',') : (motsCles || ''),

                montant_intervention: Number(montant_intervention || 0),
                montant_main_oeuvre: Number(montant_main_oeuvre || 0),
                montant_fournitures: Number(montant_fournitures || 0),

                referents: Array.isArray(referents) ? referents.map(Number) : [],

                createur_id
            };

            const response = await InterventionService.apiCreate(record);

            return res.status(201).json({
                success: true,
                message: "Intervention créée avec succès",
                data: response
            });

        } catch (error) {
            console.error("❌ Controller apiCreate intervention:", error);
            return res.status(500).json({ success: false, error: error.message });
        }
    }

    // ✏️ Modifier une intervention par ID
    static async apiUpdateById(req, res) {
        try {
            const { id } = req.params;
            const data = req.body;

            if (!data.titre || !data.description || !data.numero)
                return res.status(400).json({ error: "titre, description et numero sont requis" });

            const response = await InterventionService.updateIntervention(id, data);
            res.json(response);

        } catch (error) {
            console.error(error.message);
            res.status(500).send();
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

}

module.exports = Intervention;