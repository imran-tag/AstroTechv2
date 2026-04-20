const AdresseService = require("../services/adresses.services");

class Adresse {

    // 🔹 CREATE
    static async apiCreate(req, res) {
        try {
            const {
                adresse,
                code_postal,
                ville,
                province,
                pays,
                etage,
                appartement_local,
                batiment,
                interphone_digicode,
                escalier,
                porte_entree,
                createur_id = req.user.id
            } = req.body;

            if (!adresse || !ville || !pays)
                return res.status(400).json({ error: "adresse, ville et pays sont obligatoires." });

            const record = {
                adresse,
                code_postal,
                ville,
                province,
                pays,
                etage,
                appartement_local,
                batiment,
                interphone_digicode,
                escalier,
                porte_entree,
                createur_id
            };

            const response = await AdresseService.createRecord(record);
            res.status(201).json({ success: true, data: response });

        } catch (error) {
            console.error(error);
            res.status(500).json({ error: error.message });
        }
    }

    // 🔹 UPDATE
    static async apiUpdateById(req, res) {
        try {
            const { id } = req.params;

            const {
                adresse,
                code_postal,
                ville,
                province,
                pays,
                etage,
                appartement_local,
                batiment,
                interphone_digicode,
                escalier,
                porte_entree,
                createur_id
            } = req.body;

            if (!adresse || !ville || !pays)
                return res.status(400).json({ error: "adresse, ville et pays sont obligatoires." });

            const record = {
                id,
                adresse,
                code_postal,
                ville,
                province,
                pays,
                etage,
                appartement_local,
                batiment,
                interphone_digicode,
                escalier,
                porte_entree,
                createur_id
            };

            await AdresseService.updateRecordById(record);

            res.json({ success: true, message: "Adresse mise à jour avec succès." });

        } catch (error) {
            console.error(error.message);
            res.status(500).json({ error: "Erreur serveur" });
        }
    }

    // 🔹 DELETE
    static async apiDeleteById(req, res) {
        try {
            const { id } = req.params;

            await AdresseService.deleteRecordById(id);

            res.json({ success: true, message: "Adresse supprimée avec succès." });

        } catch (error) {
            console.log(error.message);
            res.status(500).send();
        }
    }

    // 🔹 GET ALL
    static async apiGetAll(req, res) {
        try {
            // req.query.q récupère le "?q=..." dans l'URL
            const searchTerm = req.query.q || null;

            const response = await AdresseService.getAllRecords(searchTerm);
            res.json(response);
        } catch (error) {
            console.error("Erreur Controller:", error);
            res.status(500).json({ error: "Internal Server Error" });
        }
    }

    // 🔹 GET BY ID
    static async apiGetById(req, res) {
        try {
            const { id } = req.params;

            const response = await AdresseService.getRecordById(id);
            if (!response) return res.status(404).json({ error: "Adresse introuvable." });

            res.json(response);

        } catch (error) {
            console.error(error.message);
            res.status(500).send();
        }
    }
}

module.exports = Adresse;