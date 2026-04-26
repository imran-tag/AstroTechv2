const db = require('../db');
const bcrypt = require('bcrypt');

const SALT_ROUNDS = 10;

class TechnicienService {

  // Keep users table in sync with technician credentials
  static async _syncUserAccount({ email, pwd, nom, prenom, oldEmail = null }) {
    if (!email || !pwd) return;

    const fullName = `${prenom} ${nom}`.trim();
    const hash = await bcrypt.hash(pwd, SALT_ROUNDS);

    if (oldEmail && oldEmail !== email) {
      // Email changed — update the existing user row
      await db.execute(
        `UPDATE users SET email = ?, password_hash = ?, full_name = ? WHERE email = ? AND role = 'technician'`,
        [email, hash, fullName, oldEmail]
      );
      return;
    }

    // Upsert: update if exists, insert if not
    const [rows] = await db.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (rows.length) {
      await db.execute(
        `UPDATE users SET password_hash = ?, full_name = ? WHERE email = ?`,
        [hash, fullName, email]
      );
    } else {
      await db.execute(
        `INSERT INTO users (email, password_hash, full_name, role) VALUES (?, ?, ?, 'technician')`,
        [email, hash, fullName]
      );
    }
  }

  static async _deleteUserAccount(email) {
    if (!email) return;
    await db.execute(`DELETE FROM users WHERE email = ? AND role = 'technician'`, [email]);
  }

  static async createRecord(record) {
    const query = `
      INSERT INTO technicien
      (nom, prenom, dateNaissance, adresse, telephone, email, pwd, specialite, certifications, experience, zoneIntervention, dateEmbauche, typeContrat, salaire, statut, createur_id)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const [result] = await db.execute(query, [
      record.nom,
      record.prenom,
      record.dateNaissance,
      record.adresse,
      record.telephone,
      record.email,
      record.pwd,
      record.specialite,
      record.certifications,
      record.experience,
      record.zoneIntervention,
      record.dateEmbauche,
      record.typeContrat,
      record.salaire,
      record.statut,
      record.createur_id
    ]);

    await TechnicienService._syncUserAccount({
      email: record.email,
      pwd: record.pwd,
      nom: record.nom,
      prenom: record.prenom,
    });

    return { id: result.insertId, ...record };
  }

  static async updateRecordById(record, id) {
    // Fetch the current email before updating so we can detect changes
    const existing = await TechnicienService.getRecordById(id);

    const query = `
      UPDATE technicien
      SET nom = ?, prenom = ?, dateNaissance = ?, adresse = ?, telephone = ?, email = ?,
          pwd = ?, specialite = ?, certifications = ?, experience = ?, zoneIntervention = ?,
          dateEmbauche = ?, typeContrat = ?, salaire = ?, statut = ?
      WHERE id = ?
    `;

    await db.execute(query, [
      record.nom,
      record.prenom,
      record.dateNaissance,
      record.adresse,
      record.telephone,
      record.email,
      record.pwd,
      record.specialite,
      record.certifications,
      record.experience,
      record.zoneIntervention,
      record.dateEmbauche,
      record.typeContrat,
      record.salaire,
      record.statut,
      id,
    ]);

    await TechnicienService._syncUserAccount({
      email: record.email,
      pwd: record.pwd,
      nom: record.nom,
      prenom: record.prenom,
      oldEmail: existing?.email,
    });

    return { message: `Technicien (${id}) mis à jour avec succès.` };
  }

  static async deleteRecordById(id) {
    const existing = await TechnicienService.getRecordById(id);

    const query = `DELETE FROM technicien WHERE id = ?;`;
    await db.execute(query, [id]);

    await TechnicienService._deleteUserAccount(existing?.email);

    return { message: `L'identifiant (${id}) est supprimé avec succès.` };
  }

  static async getAllRecords() {
    const query = `SELECT * FROM technicien;`;
    const [rows] = await db.execute(query);
    return rows;
  }

  static async getAllRecordsPaginated({ page = 1, limit = 10, search = '', userId = null }) {
    try {
      page = Number(page);
      limit = Number(limit);

      if (!Number.isInteger(page) || page < 1) page = 1;
      if (!Number.isInteger(limit) || limit < 1) limit = 10;

      const offset = (page - 1) * limit;

      /* ===================== WHERE ===================== */
      let whereClause = 'WHERE 1=1';
      const params = [];

      if (search && search.trim() !== '') {
        whereClause += `
        AND (
          t.nom LIKE ?
          OR t.prenom LIKE ?
          OR t.email LIKE ?
        )
      `;
        const keyword = `%${search}%`;
        params.push(keyword, keyword, keyword);
      }

      if (userId) {
        whereClause += ' AND t.createur_id = ?';
        params.push(userId);
      }

      /* ===================== QUERY ===================== */
      const sql = `
      SELECT SQL_CALC_FOUND_ROWS
        t.id,
        t.nom,
        t.prenom,
        t.email,
        t.telephone,
        t.specialite,
        t.pwd,
        t.createur_id,
        t.date_creation
      FROM technicien t
      ${whereClause}
      ORDER BY t.id DESC
      LIMIT ${limit} OFFSET ${offset}
    `;

      // ✅ utiliser query()
      const [rows] = await db.query(sql, params);

      /* ===================== TOTAL ===================== */
      const [[{ total }]] = await db.query(
        'SELECT FOUND_ROWS() AS total'
      );

      return {
        total,
        data: rows
      };

    } catch (err) {
      console.error('Erreur getAllRecordsPaginated:', err);
      throw err;
    }
  }

  static async getRecordById(id) {
    const query = `SELECT * FROM technicien WHERE id = ?;`;
    const [rows] = await db.execute(query, [id]);
    return rows[0] || null;
  }
}

module.exports = TechnicienService;
