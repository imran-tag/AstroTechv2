const AffaireService = require("../services/affaires.services");

class Affaire {

    // ➕ Créer une nouvelle affaire
    static async apiCreate(req, res) {
        try {
            const {
                reference, titre, zoneIntervention, description,
                etatLogement, technicienId, equipeTechnicienId, referents,
                dateDebut, dateFin, motsCles, dureePrevueHeures, dureePrevueMinutes,
                memo, memoPiecesJointes, client_id, zone_intervention_client_id,
                type_client_zone_intervention,
                createur_id = req.user.id
            } = req.body;

            if (!reference || !titre || !client_id) {
                return res.status(400).json({ error: "reference, titre et client_id sont requis" });
            }

            const record = {
                reference, titre, zoneIntervention, description,
                etatLogement, technicienId, equipeTechnicienId, referents,
                dateDebut, dateFin, motsCles, dureePrevueHeures, dureePrevueMinutes,
                memo, memoPiecesJointes, client_id, zone_intervention_client_id,
                type_client_zone_intervention, createur_id
            };

            const response = await AffaireService.apiCreate(record);
            res.status(201).json({ success: true, data: response });

        } catch (error) {
            console.error("❌ Erreur apiCreate controller:", error);
            res.status(500).json({ error: error.message });
        }
    }



    // ✏️ Modifier une affaire par ID
    static async apiUpdateById(req, res) {
        try {
            const { id } = req.params;

            const {
                reference,
                titre,
                description,
                etatLogement,
                technicienId,
                equipeTechnicienId,
                referents,
                memo,
                memoPiecesJointes,
                dateDebut,
                dateFin,
                motsCles,
                dureePrevueHeures,
                dureePrevueMinutes,
                client_id,
                zone_intervention_client_id,
                type_client_zone_intervention
            } = req.body;

            if (!reference || !titre || !client_id) {
                return res.status(400).json({
                    error: "reference, titre et client_id sont requis"
                });
            }

            const record = {
                id,
                reference,
                titre,
                description,
                etatLogement,
                technicienId,
                equipeTechnicienId,
                referents,
                memo,
                memoPiecesJointes,
                dateDebut,
                dateFin,
                motsCles,
                dureePrevueHeures,
                dureePrevueMinutes,
                client_id,
                zone_intervention_client_id,
                type_client_zone_intervention
            };

            const response = await AffaireService.updateAffaire(record);
            res.json(response);

        } catch (error) {
            console.error("❌ apiUpdateById:", error);
            res.status(500).json({ error: "Erreur serveur" });
        }
    }


    // ❌ Supprimer une affaire par ID
    static async apiDeleteById(req, res) {
        try {
            const { id } = req.params;
            await AffaireService.apiDeleteById(id);
            res.send();
        } catch (error) {
            console.error(error.message);
            res.status(500).send();
        }
    }

    // 📜 Récupérer toutes les affaires
    static async apiGetAll(req, res) {
        try {
            const response = await AffaireService.apiGetAll();
            res.json(response);
        } catch (error) {
            console.error(error);
            res.status(500).json({ error: "Internal Server Error" });
        }
    }

    // 📜 Récupérer les affaires (pagination + recherche + user)
    static async apiGetAllPaginated(req, res) {
        try {
            let { page = 1, limit = 10, search = '' } = req.query;
            const userId = Number(req.user.id);

            page = Number(page);
            limit = Number(limit);

            const result = await AffaireService.apiGetAllPaginated({
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

    // 🔍 Récupérer une affaire par ID
    static async apiGetById(req, res) {
        try {
            const { id } = req.params;
            const response = await AffaireService.apiGetById(id);
            if (!response) return res.status(404).send();
            res.json(response);
        } catch (error) {
            console.error(error.message);
            res.status(500).send();
        }
    }
}

module.exports = Affaire;