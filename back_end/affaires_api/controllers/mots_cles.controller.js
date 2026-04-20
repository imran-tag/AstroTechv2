const MotsClesService = require("../services/mots_cles.services");

class MotsClesController {
  static async apiCreate(req, res) {
    try {
      const { libelle } = req.body;
      if (!libelle) return res.status(400).json({ error: "Le libellé est requis" });

      // Vérifier si le libellé existe déjà (car UNIQUE dans ta DB)
      const existing = await MotsClesService.getByLibelle(libelle);
      if (existing) return res.status(409).json({ error: "Ce mot-clé existe déjà" });

      const response = await MotsClesService.createRecord({ libelle });
      res.status(201).json({ success: true, data: response });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async apiGetAll(req, res) {
    try {
      const response = await MotsClesService.getAllRecords();
      res.json(response);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async apiGetById(req, res) {
    try {
      const response = await MotsClesService.getRecordById(req.params.id);
      if (!response) return res.status(404).json({ error: "Mot-clé non trouvé" });
      res.json(response);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async apiUpdateById(req, res) {
    try {
      const { id } = req.params;
      const { libelle } = req.body;
      await MotsClesService.updateRecordById({ id, libelle });
      res.json({ success: true });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  static async apiDeleteById(req, res) {
    try {
      await MotsClesService.deleteRecordById(req.params.id);
      res.json({ success: true, message: "Supprimé avec succès" });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = MotsClesController;