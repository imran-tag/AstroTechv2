const MobileService = require('../services/mobile.service');

const MobileController = {

  // GET /mobile/me
  async getProfile(req, res) {
    try {
      const profile = await MobileService.getMobileProfile(req.user.id);
      if (!profile) return res.status(404).json({ message: 'Utilisateur introuvable' });
      res.json({ data: profile.user, technician: profile.technician });
    } catch (err) {
      console.error('mobile.getProfile:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // GET /mobile/interventions
  async getInterventions(req, res) {
    try {
      const data = await MobileService.getInterventions(req.user.id);
      res.json({ data });
    } catch (err) {
      console.error('mobile.getInterventions:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // GET /mobile/interventions/:id
  async getInterventionById(req, res) {
    try {
      const intervention = await MobileService.getInterventionById(req.params.id);
      if (!intervention) return res.status(404).json({ message: 'Intervention introuvable' });
      res.json({ data: intervention });
    } catch (err) {
      console.error('mobile.getInterventionById:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // PUT /mobile/interventions/:id/status
  async updateStatus(req, res) {
    try {
      const { status } = req.body;
      if (!status) return res.status(400).json({ message: 'status requis' });
      await MobileService.updateStatus(req.params.id, status);
      res.status(204).end();
    } catch (err) {
      console.error('mobile.updateStatus:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // GET /mobile/interventions/:id/workflow
  async getWorkflow(req, res) {
    try {
      const data = await MobileService.getWorkflow(req.params.id);
      res.json({ data });
    } catch (err) {
      console.error('mobile.getWorkflow:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // POST /mobile/interventions/:id/workflow
  async createWorkflow(req, res) {
    try {
      const data = await MobileService.createWorkflow(req.params.id, req.body);
      res.status(201).json({ data });
    } catch (err) {
      console.error('mobile.createWorkflow:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // PATCH /mobile/interventions/:id/workflow
  async updateWorkflow(req, res) {
    try {
      const data = await MobileService.updateWorkflow(req.params.id, req.body);
      res.json({ data });
    } catch (err) {
      console.error('mobile.updateWorkflow:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // GET /mobile/interventions/:id/photos
  async getPhotos(req, res) {
    try {
      const data = await MobileService.getPhotos(req.params.id, req.query.type);
      res.json({ data });
    } catch (err) {
      console.error('mobile.getPhotos:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // POST /mobile/interventions/:id/photos
  async uploadPhoto(req, res) {
    try {
      if (!req.file) return res.status(400).json({ message: 'Fichier photo requis' });
      const data = await MobileService.createPhoto(req.params.id, req.body, req.file);
      res.status(201).json({ data });
    } catch (err) {
      console.error('mobile.uploadPhoto:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // DELETE /mobile/interventions/:id/photos/:photoId
  async deletePhoto(req, res) {
    try {
      await MobileService.deletePhoto(req.params.id, req.params.photoId);
      res.status(204).end();
    } catch (err) {
      console.error('mobile.deletePhoto:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // POST /mobile/interventions/:id/signature
  async uploadSignature(req, res) {
    try {
      const { signature_data } = req.body;
      if (!signature_data) return res.status(400).json({ message: 'signature_data requis' });
      const filePath = await MobileService.saveSignature(req.params.id, 'technician', signature_data);
      res.status(201).json({ data: { path: filePath } });
    } catch (err) {
      console.error('mobile.uploadSignature:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // POST /mobile/interventions/:id/signatures/:type
  async uploadTypedSignature(req, res) {
    try {
      const { signature_data } = req.body;
      if (!signature_data) return res.status(400).json({ message: 'signature_data requis' });
      const filePath = await MobileService.saveSignature(req.params.id, req.params.type, signature_data);
      res.status(201).json({ data: { path: filePath } });
    } catch (err) {
      console.error('mobile.uploadTypedSignature:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // POST /mobile/interventions/:id/interruptions
  async createInterruption(req, res) {
    try {
      const data = await MobileService.createInterruption(req.params.id, req.body);
      res.status(201).json({ data });
    } catch (err) {
      console.error('mobile.createInterruption:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // PATCH /mobile/interventions/:id/interruptions/:interruptionId
  async updateInterruption(req, res) {
    try {
      const data = await MobileService.updateInterruption(
        req.params.id,
        req.params.interruptionId,
        req.body
      );
      res.json({ data });
    } catch (err) {
      console.error('mobile.updateInterruption:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },

  // POST /mobile/sync
  async bulkSync(req, res) {
    try {
      const data = await MobileService.bulkSync(req.user.id, req.body);
      res.json({ data });
    } catch (err) {
      console.error('mobile.bulkSync:', err);
      res.status(500).json({ message: 'Erreur serveur' });
    }
  },
};

module.exports = MobileController;
