const MotCleLienService = require("../services/mot_cle_liens.services");

class MotCleLien {
  static async apiCreate(req, res) {
    try {
      const { mot_cle_id, target_id, target_type } = req.body;
      
      if (!mot_cle_id || !target_id || !target_type) {
        return res.status(400).json({ error: "mot_cle_id, target_id et target_type sont requis" });
      }

      const record = { mot_cle_id, target_id, target_type };
      const response = await MotCleLienService.createRecord(record);

      res.status(201).json({ success: true, data: response });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: error.message });
    }
  }

  static async apiUpdateById(req, res) {
    try {
      const { id } = req.params;
      const { mot_cle_id, target_id, target_type } = req.body;

      if (!mot_cle_id || !target_id || !target_type) {
        return res.status(400).json({ error: "Tous les champs sont requis" });
      }

      const record = { id, mot_cle_id, target_id, target_type };
      const response = await MotCleLienService.updateRecordById(record);
      res.json(response);
    } catch (error) {
      console.error(error.message);
      res.status(500).json({ error: "Erreur lors de la mise à jour" });
    }
  }

  static async apiDeleteById(req, res) {
    try {
      const { id } = req.params;
      const response = await MotCleLienService.deleteRecordById(id);
      res.json(response);
    } catch (error) {
      console.log(error.message);
      res.status(500).send();
    }
  }

  static async apiGetAll(req, res) {
    try {
      const response = await MotCleLienService.getAllRecords();
      res.json(response);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  }

  static async apiGetById(req, res) {
    try {
      const { id } = req.params;
      const response = await MotCleLienService.getRecordById(id);
      if (!response) return res.status(404).json({ message: "Lien non trouvé" });
      res.json(response);
    } catch (error) {
      console.error(error.message);
      res.status(500).send();
    }
  }

  // Nouvel endpoint utile : Voir les mots-clés d'un objet précis
  static async apiGetByTarget(req, res) {
    try {
      const { target_type, target_id } = req.params;
      const response = await MotCleLienService.getByTarget(target_id, target_type);
      res.json(response);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = MotCleLien;