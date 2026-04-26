const pool = require('../db');
const path = require('path');
const fs = require('fs');

const UPLOADS_DIR = path.join(__dirname, '../uploads');

class MobileService {

  // ─── Table initialisation ────────────────────────────────────────────────
  static async initTables() {
    const conn = await pool.getConnection();
    try {
      await conn.execute(`
        CREATE TABLE IF NOT EXISTS intervention_workflow (
          id                                    INT AUTO_INCREMENT PRIMARY KEY,
          intervention_id                       INT NOT NULL UNIQUE,
          security_checklist                    TEXT,
          security_checklist_completed_at       DATETIME,
          comment                               TEXT,
          comment_completed_at                  DATETIME,
          quality_control                       TEXT,
          quality_control_completed_at          DATETIME,
          signature_path                        VARCHAR(500),
          signature_completed_at                DATETIME,
          current_step                          INT DEFAULT 0,
          started_at                            DATETIME,
          completed_at                          DATETIME,
          local_id                              VARCHAR(255),
          client_observations                   TEXT,
          client_observations_completed_at      DATETIME,
          client_rating                         INT,
          rating_completed_at                   DATETIME,
          client_signature_path                 VARCHAR(500),
          client_signature_completed_at         DATETIME,
          technical_observations_choice         VARCHAR(255),
          technical_observations_completed_at   DATETIME,
          additional_work_description           TEXT,
          additional_work_signature_path        VARCHAR(500),
          quote_comment                         TEXT,
          quote_signature_path                  VARCHAR(500),
          completed_branches                    JSON,
          loop_count                            INT DEFAULT 0,
          travel_start_time                     DATETIME,
          travel_end_time                       DATETIME,
          travel_duration_minutes               INT,
          technician_signature_path             VARCHAR(500),
          technician_signature_completed_at     DATETIME,
          FOREIGN KEY (intervention_id) REFERENCES intervention(id) ON DELETE CASCADE
        )
      `);

      await conn.execute(`
        CREATE TABLE IF NOT EXISTS intervention_photos (
          id               INT AUTO_INCREMENT PRIMARY KEY,
          intervention_id  INT NOT NULL,
          photo_type       VARCHAR(50) NOT NULL,
          file_name        VARCHAR(500),
          file_path        VARCHAR(500),
          file_size        INT,
          mime_type        VARCHAR(100),
          captured_at      DATETIME,
          latitude         DECIMAL(10,8),
          longitude        DECIMAL(11,8),
          local_id         VARCHAR(255),
          comment          TEXT,
          drawing_enabled  TINYINT(1) DEFAULT 0,
          drawing_data     LONGTEXT,
          photo_context    VARCHAR(255),
          FOREIGN KEY (intervention_id) REFERENCES intervention(id) ON DELETE CASCADE
        )
      `);

      await conn.execute(`
        CREATE TABLE IF NOT EXISTS intervention_interruptions (
          id                VARCHAR(255) PRIMARY KEY,
          intervention_id   INT NOT NULL,
          reason            VARCHAR(255) NOT NULL,
          custom_reason     TEXT,
          started_at        DATETIME NOT NULL,
          ended_at          DATETIME,
          duration_minutes  INT,
          FOREIGN KEY (intervention_id) REFERENCES intervention(id) ON DELETE CASCADE
        )
      `);

      await conn.execute(`
        CREATE TABLE IF NOT EXISTS intervention_signatures (
          id               INT AUTO_INCREMENT PRIMARY KEY,
          intervention_id  INT NOT NULL,
          signature_type   VARCHAR(100) NOT NULL DEFAULT 'technician',
          file_path        VARCHAR(500),
          signed_at        DATETIME DEFAULT NOW(),
          FOREIGN KEY (intervention_id) REFERENCES intervention(id) ON DELETE CASCADE
        )
      `);
    } finally {
      conn.release();
    }
  }

  // ─── Profile ─────────────────────────────────────────────────────────────
  static async getMobileProfile(userId) {
    const [users] = await pool.execute(
      'SELECT id, email, full_name, role FROM users WHERE id = ?',
      [userId]
    );
    if (!users.length) return null;

    const [techs] = await pool.execute(
      'SELECT id, nom, prenom, telephone, email, specialite, statut FROM technicien WHERE email = ? LIMIT 1',
      [users[0].email]
    );

    return { user: users[0], technician: techs[0] || null };
  }

  // ─── Interventions ────────────────────────────────────────────────────────
  static async getInterventions(userId) {
    const [users] = await pool.execute('SELECT email FROM users WHERE id = ?', [userId]);
    if (!users.length) return [];

    const [techs] = await pool.execute(
      'SELECT id FROM technicien WHERE email = ? LIMIT 1',
      [users[0].email]
    );

    let rows;
    if (techs.length) {
      const techId = techs[0].id;
      [rows] = await pool.execute(`
        SELECT DISTINCT i.*, it.libelle AS type_intervention
        FROM intervention i
        LEFT JOIN intervention_type it ON it.id = i.type_id
        LEFT JOIN intervention_technicien itech ON itech.id_intervention = i.id
        LEFT JOIN equipe_technicien eq ON eq.id = i.equipe_id
        LEFT JOIN technicien_equipe te ON te.equipeId = eq.id
        WHERE itech.id_technicien = ? OR te.technicienId = ?
        ORDER BY i.id DESC
      `, [techId, techId]);
    } else {
      [rows] = await pool.execute(`
        SELECT i.*, it.libelle AS type_intervention
        FROM intervention i
        LEFT JOIN intervention_type it ON it.id = i.type_id
        WHERE i.createur_id = ?
        ORDER BY i.id DESC
      `, [userId]);
    }

    for (const row of rows) await MobileService._enrich(row);
    return rows;
  }

  static async getInterventionById(id) {
    const [rows] = await pool.execute(`
      SELECT i.*, it.libelle AS type_intervention
      FROM intervention i
      LEFT JOIN intervention_type it ON it.id = i.type_id
      WHERE i.id = ?
    `, [id]);
    if (!rows.length) return null;
    await MobileService._enrich(rows[0]);
    return rows[0];
  }

  static async _enrich(intervention) {
    const id = intervention.id;

    const [techs] = await pool.execute(`
      SELECT t.id, t.nom, t.prenom, t.telephone, it.role
      FROM technicien t
      JOIN intervention_technicien it ON t.id = it.id_technicien
      WHERE it.id_intervention = ?
    `, [id]);
    intervention.techniciens = techs;

    const [refs] = await pool.execute(`
      SELECT r.id, r.nom, r.prenom, r.email, r.telephone
      FROM referent r
      JOIN intervention_referent ir ON r.id = ir.referent_id
      WHERE ir.intervention_id = ?
    `, [id]);
    intervention.referents = refs;

    const [[{ before_count }]] = await pool.execute(
      'SELECT COUNT(*) AS before_count FROM intervention_photos WHERE intervention_id = ? AND photo_type = "before"',
      [id]
    );
    const [[{ after_count }]] = await pool.execute(
      'SELECT COUNT(*) AS after_count FROM intervention_photos WHERE intervention_id = ? AND photo_type = "after"',
      [id]
    );
    intervention.photos_before_count = before_count;
    intervention.photos_after_count = after_count;

    const [wf] = await pool.execute(
      'SELECT * FROM intervention_workflow WHERE intervention_id = ? LIMIT 1',
      [id]
    );
    intervention.workflow = wf[0] || null;

    const [interruptions] = await pool.execute(
      'SELECT * FROM intervention_interruptions WHERE intervention_id = ?',
      [id]
    );
    intervention.interruptions = interruptions;
  }

  // ─── Status ───────────────────────────────────────────────────────────────
  static async updateStatus(interventionId, status) {
    const [result] = await pool.execute(
      'UPDATE intervention SET etat = ? WHERE id = ?',
      [status, interventionId]
    );
    return result.affectedRows > 0;
  }

  // ─── Workflow ─────────────────────────────────────────────────────────────
  static async getWorkflow(interventionId) {
    const [rows] = await pool.execute(
      'SELECT * FROM intervention_workflow WHERE intervention_id = ? LIMIT 1',
      [interventionId]
    );
    return rows[0] || null;
  }

  static async createWorkflow(interventionId, data) {
    const FIELDS = [
      'security_checklist', 'security_checklist_completed_at',
      'comment', 'comment_completed_at',
      'quality_control', 'quality_control_completed_at',
      'signature_path', 'signature_completed_at',
      'current_step', 'started_at', 'completed_at', 'local_id',
      'client_observations', 'client_observations_completed_at',
      'client_rating', 'rating_completed_at',
      'client_signature_path', 'client_signature_completed_at',
      'technical_observations_choice', 'technical_observations_completed_at',
      'additional_work_description', 'additional_work_signature_path',
      'quote_comment', 'quote_signature_path',
      'completed_branches', 'loop_count',
      'travel_start_time', 'travel_end_time', 'travel_duration_minutes',
      'technician_signature_path', 'technician_signature_completed_at',
    ];

    const cols = ['intervention_id'];
    const vals = [interventionId];

    for (const f of FIELDS) {
      if (f in data) {
        cols.push(f);
        vals.push(f === 'completed_branches' && Array.isArray(data[f])
          ? JSON.stringify(data[f])
          : data[f] ?? null);
      }
    }

    await pool.execute(
      `INSERT INTO intervention_workflow (${cols.join(', ')}) VALUES (${vals.map(() => '?').join(', ')})`,
      vals
    );
    return MobileService.getWorkflow(interventionId);
  }

  static async updateWorkflow(interventionId, data) {
    const FIELDS = [
      'security_checklist', 'security_checklist_completed_at',
      'comment', 'comment_completed_at',
      'quality_control', 'quality_control_completed_at',
      'signature_path', 'signature_completed_at',
      'current_step', 'started_at', 'completed_at', 'local_id',
      'client_observations', 'client_observations_completed_at',
      'client_rating', 'rating_completed_at',
      'client_signature_path', 'client_signature_completed_at',
      'technical_observations_choice', 'technical_observations_completed_at',
      'additional_work_description', 'additional_work_signature_path',
      'quote_comment', 'quote_signature_path',
      'completed_branches', 'loop_count',
      'travel_start_time', 'travel_end_time', 'travel_duration_minutes',
      'technician_signature_path', 'technician_signature_completed_at',
    ];

    const sets = [];
    const vals = [];

    for (const f of FIELDS) {
      if (f in data) {
        sets.push(`${f} = ?`);
        vals.push(f === 'completed_branches' && Array.isArray(data[f])
          ? JSON.stringify(data[f])
          : data[f] ?? null);
      }
    }

    if (!sets.length) return MobileService.getWorkflow(interventionId);

    vals.push(interventionId);
    await pool.execute(
      `UPDATE intervention_workflow SET ${sets.join(', ')} WHERE intervention_id = ?`,
      vals
    );
    return MobileService.getWorkflow(interventionId);
  }

  // ─── Photos ───────────────────────────────────────────────────────────────
  static async getPhotos(interventionId, type) {
    const params = [interventionId];
    let sql = 'SELECT * FROM intervention_photos WHERE intervention_id = ?';
    if (type) { sql += ' AND photo_type = ?'; params.push(type); }
    const [rows] = await pool.execute(sql, params);
    return rows;
  }

  static async createPhoto(interventionId, body, file) {
    const [result] = await pool.execute(`
      INSERT INTO intervention_photos
        (intervention_id, photo_type, file_name, file_path, file_size, mime_type,
         captured_at, latitude, longitude, local_id, comment, drawing_enabled, drawing_data, photo_context)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      interventionId,
      body.photo_type || 'before',
      file.originalname,
      file.path,
      file.size,
      file.mimetype,
      body.captured_at || null,
      body.latitude ? parseFloat(body.latitude) : null,
      body.longitude ? parseFloat(body.longitude) : null,
      body.local_id || null,
      body.comment || null,
      body.drawing_enabled ? 1 : 0,
      body.drawing_data || null,
      body.photo_context || null,
    ]);

    const [rows] = await pool.execute('SELECT * FROM intervention_photos WHERE id = ?', [result.insertId]);
    return rows[0];
  }

  static async deletePhoto(interventionId, photoId) {
    const [rows] = await pool.execute(
      'SELECT file_path FROM intervention_photos WHERE id = ? AND intervention_id = ?',
      [photoId, interventionId]
    );
    if (!rows.length) return false;
    try {
      if (rows[0].file_path && fs.existsSync(rows[0].file_path)) fs.unlinkSync(rows[0].file_path);
    } catch (_) {}
    const [res] = await pool.execute(
      'DELETE FROM intervention_photos WHERE id = ? AND intervention_id = ?',
      [photoId, interventionId]
    );
    return res.affectedRows > 0;
  }

  // ─── Signatures ───────────────────────────────────────────────────────────
  static async saveSignature(interventionId, signatureType, base64Data) {
    const dir = path.join(UPLOADS_DIR, 'signatures');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    const filename = `sig_${interventionId}_${signatureType}_${Date.now()}.png`;
    const filePath = path.join(dir, filename);
    fs.writeFileSync(filePath, Buffer.from(base64Data.replace(/^data:image\/\w+;base64,/, ''), 'base64'));

    const pathField = signatureType === 'client'     ? 'client_signature_path'
                    : signatureType === 'technician' ? 'technician_signature_path'
                    : 'signature_path';
    const completedField = pathField.replace('_path', '_completed_at');

    const existing = await MobileService.getWorkflow(interventionId);
    if (existing) {
      await pool.execute(
        `UPDATE intervention_workflow SET ${pathField} = ?, ${completedField} = NOW() WHERE intervention_id = ?`,
        [filePath, interventionId]
      );
    } else {
      await MobileService.createWorkflow(interventionId, { [pathField]: filePath });
    }

    await pool.execute(
      'INSERT INTO intervention_signatures (intervention_id, signature_type, file_path, signed_at) VALUES (?, ?, ?, NOW())',
      [interventionId, signatureType, filePath]
    );

    return filePath;
  }

  // ─── Interruptions ────────────────────────────────────────────────────────
  static async createInterruption(interventionId, data) {
    await pool.execute(`
      INSERT INTO intervention_interruptions (id, intervention_id, reason, custom_reason, started_at, ended_at, duration_minutes)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [
      data.id,
      interventionId,
      data.reason,
      data.custom_reason || null,
      data.started_at,
      data.ended_at || null,
      data.duration_minutes || null,
    ]);
    const [rows] = await pool.execute('SELECT * FROM intervention_interruptions WHERE id = ?', [data.id]);
    return rows[0];
  }

  static async updateInterruption(interventionId, interruptionId, data) {
    const sets = [];
    const vals = [];

    if ('ended_at' in data)          { sets.push('ended_at = ?');          vals.push(data.ended_at); }
    if ('duration_minutes' in data)  { sets.push('duration_minutes = ?');  vals.push(data.duration_minutes); }
    if (!sets.length) return null;

    vals.push(interruptionId, interventionId);
    await pool.execute(
      `UPDATE intervention_interruptions SET ${sets.join(', ')} WHERE id = ? AND intervention_id = ?`,
      vals
    );
    const [rows] = await pool.execute('SELECT * FROM intervention_interruptions WHERE id = ?', [interruptionId]);
    return rows[0] || null;
  }

  // ─── Bulk sync ────────────────────────────────────────────────────────────
  static async bulkSync(userId, syncData) {
    const results = { synced: [], errors: [] };

    for (const u of (syncData.status_updates || [])) {
      try {
        await MobileService.updateStatus(u.intervention_id, u.status);
        results.synced.push({ type: 'status', id: u.intervention_id });
      } catch (e) {
        results.errors.push({ type: 'status', id: u.intervention_id, error: e.message });
      }
    }

    for (const wf of (syncData.workflows || [])) {
      try {
        const existing = await MobileService.getWorkflow(wf.intervention_id);
        existing
          ? await MobileService.updateWorkflow(wf.intervention_id, wf)
          : await MobileService.createWorkflow(wf.intervention_id, wf);
        results.synced.push({ type: 'workflow', id: wf.intervention_id });
      } catch (e) {
        results.errors.push({ type: 'workflow', id: wf.intervention_id, error: e.message });
      }
    }

    for (const intr of (syncData.interruptions || [])) {
      try {
        await MobileService.createInterruption(intr.intervention_id, intr);
        results.synced.push({ type: 'interruption', id: intr.id });
      } catch (e) {
        results.errors.push({ type: 'interruption', id: intr.id, error: e.message });
      }
    }

    return results;
  }
}

module.exports = MobileService;
