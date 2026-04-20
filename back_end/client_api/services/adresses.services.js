const db = require("../db");

class AdresseService {

  // 🔹 CREATE
  static async createRecord(record) {
    const query = `
      INSERT INTO adresse (
        adresse, code_postal, ville, province, pays,
        etage, appartement_local, batiment, interphone_digicode,
        escalier, porte_entree, createur_id
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const values = [
      record.adresse,
      record.code_postal,
      record.ville,
      record.province,
      record.pays,
      record.etage,
      record.appartement_local,
      record.batiment,
      record.interphone_digicode,
      record.escalier,
      record.porte_entree,
      record.createur_id
    ].map(v => v ?? null);

    const [result] = await db.execute(query, values);

    return { id: result.insertId, ...record };
  }

  // 🔹 UPDATE
  static async updateRecordById(record) {
    const query = `
      UPDATE adresse SET
        adresse = ?, 
        code_postal = ?, 
        ville = ?, 
        province = ?, 
        pays = ?, 
        etage = ?, 
        appartement_local = ?, 
        batiment = ?, 
        interphone_digicode = ?, 
        escalier = ?, 
        porte_entree = ?, 
        createur_id = ?
      WHERE id = ?
    `;

    const values = [
      record.adresse,
      record.code_postal,
      record.ville,
      record.province,
      record.pays,
      record.etage,
      record.appartement_local,
      record.batiment,
      record.interphone_digicode,
      record.escalier,
      record.porte_entree,
      record.createur_id,
      record.id
    ].map(v => v ?? null);

    await db.execute(query, values);
    return { ...record };
  }

  // 🔹 DELETE
  static async deleteRecordById(id) {
    const query = `DELETE FROM adresse WHERE id = ?`;
    await db.execute(query, [id]);
    return { message: `Adresse ${id} supprimée.` };
  }

  // 🔹 GET ALL
  static async getAllRecords(searchTerm = null) {
    let query = `SELECT * FROM adresse`;
    let params = [];

    // On vérifie si searchTerm contient une vraie valeur
    if (searchTerm && searchTerm.trim() !== '') {
      // Cas : Recherche active
      query += ` WHERE adresse LIKE ? 
                   OR ville LIKE ? 
                   OR code_postal LIKE ? 
                   ORDER BY date_creation DESC`;

      const wildCard = `%${searchTerm}%`;
      params = [wildCard, wildCard, wildCard];
    } else {
      // Cas : Pas de recherche, on affiche tout
      query += ` ORDER BY date_creation DESC`;
    }

    // db.execute gère dynamiquement les params (tableau vide si pas de recherche)
    const [rows] = await db.execute(query, params);
    return rows;
  }

  // 🔹 GET BY ID
  static async getRecordById(id) {
    const query = `SELECT * FROM adresse WHERE id = ?`;
    const [rows] = await db.execute(query, [id]);
    return rows[0] || null;
  }
}

module.exports = AdresseService;