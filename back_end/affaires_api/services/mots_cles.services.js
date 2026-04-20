const db = require("../db");

class MotsClesService {
  static async createRecord(record) {
    const query = `INSERT INTO mots_cles (libelle) VALUES (?)`;
    const [result] = await db.execute(query, [record.libelle]);
    return { id: result.insertId, ...record };
  }

  static async updateRecordById(record) {
    const query = `UPDATE mots_cles SET libelle = ? WHERE id = ?`;
    await db.execute(query, [record.libelle, record.id]);
    return { success: true };
  }

  static async deleteRecordById(id) {
    const query = `DELETE FROM mots_cles WHERE id = ?`;
    await db.execute(query, [id]);
    return { message: `Le mot-clé (${id}) a été supprimé.` };
  }

  static async getAllRecords() {
    const [rows] = await db.execute(`SELECT * FROM mots_cles ORDER BY libelle ASC`);
    return rows;
  }

  static async getRecordById(id) {
    const [rows] = await db.execute(`SELECT * FROM mots_cles WHERE id = ?`, [id]);
    return rows[0];
  }

  static async getByLibelle(libelle) {
    const [rows] = await db.execute(`SELECT * FROM mots_cles WHERE libelle = ?`, [libelle]);
    return rows[0];
  }
}

module.exports = MotsClesService;