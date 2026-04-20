const db = require("../db"); // Assure-toi que db est ton pool mysql2/promise

class MotCleLienService {
  static async createRecord(record) {
    const query = `INSERT INTO mot_cle_liens (mot_cle_id, target_id, target_type) VALUES (?, ?, ?)`;
    const [result] = await db.execute(query, [
      record.mot_cle_id,
      record.target_id,
      record.target_type
    ]);
    return { id: result.insertId, ...record };
  }

  static async updateRecordById(record) {
    const query = `UPDATE mot_cle_liens SET mot_cle_id = ?, target_id = ?, target_type = ? WHERE id = ?`;
    await db.execute(query, [
      record.mot_cle_id,
      record.target_id,
      record.target_type,
      record.id
    ]);
    return { success: true };
  }

  static async deleteRecordById(id) {
    const query = `DELETE FROM mot_cle_liens WHERE id = ?`;
    await db.execute(query, [id]);
    return { message: `Le lien (${id}) a été supprimé avec succès.` };
  }

  static async getAllRecords() {
    const query = `SELECT * FROM mot_cle_liens`;
    const [rows] = await db.execute(query);
    return rows;
  }

  static async getRecordById(id) {
    const query = `SELECT * FROM mot_cle_liens WHERE id = ?`;
    const [rows] = await db.execute(query, [id]);
    return rows[0];
  }

  // Pour filtrer par affaire ou intervention
  static async getByTarget(target_id, target_type) {
    const query = `SELECT * FROM mot_cle_liens WHERE target_id = ? AND target_type = ?`;
    const [rows] = await db.execute(query, [target_id, target_type]);
    return rows;
  }
}

module.exports = MotCleLienService;