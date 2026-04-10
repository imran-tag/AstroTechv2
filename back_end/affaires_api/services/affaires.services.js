const pool = require('../db'); // connexion MySQL2/promise

class AffaireService {
  /**
   * 🔹 Créer une nouvelle affaire
   */
  static async apiCreate(data) {
    // 🔹 Création de safeData pour garantir que toutes les valeurs existent
    const safeData = {
      reference: data.reference || '',
      titre: data.titre || '',
      description: data.description || '',
      etatLogement: data.etatLogement || '',
      technicienId: data.technicienId != null ? Number(data.technicienId) : null,
      equipeTechnicienId: data.equipeTechnicienId != null ? Number(data.equipeTechnicienId) : null,
      referents: Array.isArray(data.referents) ? data.referents.map(r => Number(r)) : [],
      dateDebut: data.dateDebut || null,
      dateFin: data.dateFin || null,
      motsCles: data.motsCles || '',
      dureePrevueHeures: data.dureePrevueHeures != null ? Number(data.dureePrevueHeures) : 0,
      dureePrevueMinutes: data.dureePrevueMinutes != null ? Number(data.dureePrevueMinutes) : 0,
      memo: data.memo || '',
      memoPiecesJointes: data.memoPiecesJointes || '',
      client_id: data.client_id != null ? Number(data.client_id) : null,
      zone_intervention_client_id: data.zone_intervention_client_id != null ? Number(data.zone_intervention_client_id) : null,
      type_client_zone_intervention: data.type_client_zone_intervention || '',
      createur_id: data.createur_id != null ? Number(data.createur_id) : null
    };

    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      // 🔹 Insertion dans la table affaire
      const sql = `
      INSERT INTO affaire (
        reference, titre, description,
        etatLogement, technicienId, equipeTechnicienId,
        dateDebut, dateFin, motsCles, dureePrevueHeures, dureePrevueMinutes,
        memo, memoPiecesJointes, client_id, zone_intervention_client_id, type_client_zone_intervention, createur_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

      const values = [
        safeData.reference,
        safeData.titre,
        safeData.description,
        safeData.etatLogement,
        safeData.technicienId,
        safeData.equipeTechnicienId,
        safeData.dateDebut,
        safeData.dateFin,
        safeData.motsCles,
        safeData.dureePrevueHeures,
        safeData.dureePrevueMinutes,
        safeData.memo,
        safeData.memoPiecesJointes,
        safeData.client_id,
        safeData.zone_intervention_client_id,
        safeData.type_client_zone_intervention,
        safeData.createur_id
      ];

      const [result] = await connection.execute(sql, values);
      const affaireId = result.insertId;

      // 🔹 Insertion des référents
      if (safeData.referents.length > 0) {
        const valuesRef = safeData.referents.map(refId => [affaireId, refId]);
        await connection.query(
          "INSERT INTO affaire_referent (idAffaire, idReferent) VALUES ?",
          [valuesRef]
        );
      }

      await connection.commit();
      return { id: affaireId, ...safeData };

    } catch (error) {
      await connection.rollback();
      console.error("❌ Erreur création affaire:", error);
      throw error;

    } finally {
      connection.release();
    }
  }



  /**
   * 🔹 Récupérer toutes les affaires
   */
  // Récupération des affaires avec fichiers, référents et équipe
  static async apiGetAll() {
    try {
      // 🔹 Requête principale : récupère les affaires avec le nom exact du client
      const sql = `
      SELECT
        a.id AS affaireId,
        a.reference,
        a.titre,
        a.dateDebut,
        a.dateFin,
        a.etatLogement,
        a.dureePrevueHeures,
        a.dureePrevueMinutes,
        a.memo,
        -- Nom du client : particulier > agence > organisation
        COALESCE(p.nom_complet, ag.nom_agence, o.nom_entreprise, 'Client inconnu') AS nomClient,
        e.id AS equipeId,
        e.nom AS equipeNom,
        e.description AS equipeDescription,
        tc.id AS chefEquipeId,
        tc.nom AS chefEquipeNom,
        tc.prenom AS chefEquipePrenom
      FROM affaire a
      LEFT JOIN client c ON a.client_id = c.id
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence ag ON ag.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id
      LEFT JOIN equipe_technicien e ON a.equipeTechnicienId = e.id
      LEFT JOIN technicien tc ON e.chefId = tc.id
      ORDER BY a.id DESC;
    `;

      const [rows] = await pool.execute(sql);

      for (const affaire of rows) {
        const affaireId = affaire.affaireId;

        // 🔹 Fichiers associés
        affaire.fichiers = affaireId
          ? (await pool.execute(
            `SELECT id, nom, chemin FROM fichier WHERE idAffaire = ?`,
            [affaireId]
          ))[0]
          : [];

        // 🔹 Référents associés
        const referents = affaireId
          ? (await pool.execute(
            `SELECT r.id, r.nom, r.prenom, r.email, r.telephone
             FROM referent r
             JOIN affaire_referent ar ON r.id = ar.idReferent
             WHERE ar.idAffaire = ?`,
            [affaireId]
          ))[0]
          : [];
        affaire.referents = referents.length > 0 ? referents : [{ message: 'Aucun référent assigné' }];

        // 🔹 Membres de l'équipe
        const membres = affaire.equipeId
          ? (await pool.execute(
            `SELECT t.id, t.nom, t.prenom
             FROM technicien t
             JOIN technicien_equipe te ON t.id = te.technicienId
             WHERE te.equipeId = ?`,
            [affaire.equipeId]
          ))[0]
          : [];
        affaire.membresEquipe = membres || [];
      }

      return rows;

    } catch (err) {
      console.error('Erreur apiGetAll:', err);
      throw err;
    }
  }

  // static async apiGetAllPaginated({ page = 1, limit = 10, search = '', userId }) {
  //   try {
  //     if (!userId) throw new Error('userId manquant');

  //     page = Number(page);
  //     limit = Number(limit);

  //     if (!Number.isInteger(page) || page < 1) page = 1;
  //     if (!Number.isInteger(limit) || limit < 1) limit = 10;

  //     const offset = (page - 1) * limit;

  //     /* ===================== WHERE ===================== */
  //     let whereClause = `WHERE a.createur_id = ?`;
  //     const params = [userId];

  //     if (search && search.trim() !== '') {
  //       whereClause += `
  //         AND (
  //           a.reference LIKE ?
  //           OR a.titre LIKE ?
  //           OR p.nom_complet LIKE ?
  //           OR ag.nom_agence LIKE ?
  //           OR o.nom_entreprise LIKE ?
  //         )
  //       `;
  //       const like = `%${search}%`;
  //       params.push(like, like, like, like, like);
  //     }

  //     /* ===================== QUERY PRINCIPALE ===================== */
  //     const sql = `
  //       SELECT SQL_CALC_FOUND_ROWS DISTINCT
  //         a.id AS affaireId,
  //         a.reference,
  //         a.titre,
  //         a.dateDebut,
  //         a.dateFin,
  //         a.etatLogement,
  //         a.dureePrevueHeures,
  //         a.dureePrevueMinutes,
  //         a.memo,

  //         COALESCE(
  //           p.nom_complet,
  //           ag.nom_agence,
  //           o.nom_entreprise,
  //           'Client inconnu'
  //         ) AS nomClient,

  //         e.id AS equipeId,
  //         e.nom AS equipeNom,
  //         e.description AS equipeDescription,
  //         tc.id AS chefEquipeId,
  //         tc.nom AS chefEquipeNom,
  //         tc.prenom AS chefEquipePrenom

  //       FROM affaire a
  //       LEFT JOIN client c ON a.client_id = c.id
  //       LEFT JOIN particulier p ON p.client_id = c.id
  //       LEFT JOIN agence ag ON ag.client_id = c.id
  //       LEFT JOIN organisation o ON o.client_id = c.id
  //       LEFT JOIN equipe_technicien e ON a.equipeTechnicienId = e.id
  //       LEFT JOIN technicien tc ON e.chefId = tc.id

  //       ${whereClause}
  //       ORDER BY a.id DESC
  //       LIMIT ? OFFSET ?
  //     `;

  //     params.push(limit, offset);

  //     const [rows] = await pool.query(sql, params);

  //     /* ===================== TOTAL ===================== */
  //     const [[{ total }]] = await pool.query(
  //       `SELECT FOUND_ROWS() AS total`
  //     );

  //     /* ===================== FICHIERS ===================== */
  //     const affaireIds = rows.map(r => r.affaireId);

  //     let fichiersMap = {};
  //     if (affaireIds.length) {
  //       const [fichiers] = await pool.query(
  //         `SELECT id, nom, chemin, idAffaire
  //          FROM fichier
  //          WHERE idAffaire IN (?)`,
  //         [affaireIds]
  //       );

  //       fichiers.forEach(f => {
  //         fichiersMap[f.idAffaire] = fichiersMap[f.idAffaire] || [];
  //         fichiersMap[f.idAffaire].push({
  //           id: f.id,
  //           nom: f.nom,
  //           chemin: f.chemin
  //         });
  //       });
  //     }

  //     /* ===================== ATTACHER LES FICHIERS ===================== */
  //     rows.forEach(affaire => {
  //       affaire.fichiers = fichiersMap[affaire.affaireId] || [];
  //     });

  //     return {
  //       total,
  //       page,
  //       limit,
  //       data: rows
  //     };

  //   } catch (err) {
  //     console.error('Erreur apiGetAllPaginated:', err);
  //     throw err;
  //   }
  // }

  /*static async apiGetAllPaginated({ page = 1, limit = 10, search = '', userId }) {
  try {
    if (!userId) throw new Error('userId manquant');

    page = Number(page);
    limit = Number(limit);
    const offset = (page - 1) * limit;

    let whereClause = `WHERE a.createur_id = ?`;
    const params = [userId];

    if (search && search.trim() !== '') {
      whereClause += ` AND (a.reference LIKE ? OR a.titre LIKE ? OR p.nom_complet LIKE ? OR ag.nom_agence LIKE ? OR o.nom_entreprise LIKE ?)`;
      const like = `%${search}%`;
      params.push(like, like, like, like, like);
    }

    const sql = `
      SELECT SQL_CALC_FOUND_ROWS 
        a.id AS affaireId,
        a.reference,
        a.titre,
        a.dateDebut,
        a.dateFin,
        COALESCE(p.nom_complet, ag.nom_agence, o.nom_entreprise, 'Client inconnu') AS nomClient,
        e.id AS equipeId,
        e.nom AS equipeNom,
        
        -- Sous-requête pour garantir une seule chaîne de techniciens par affaire
        (
          SELECT GROUP_CONCAT(DISTINCT 
            CASE 
              WHEN t_direct.id IS NOT NULL THEN CONCAT(t_direct.prenom, ' ', t_direct.nom)
              ELSE CONCAT(tm.prenom, ' ', tm.nom)
            END 
            SEPARATOR ', '
          )
          FROM affaire a2
          LEFT JOIN technicien t_direct ON a2.technicienId = t_direct.id
          LEFT JOIN technicien_equipe te ON a2.equipeTechnicienId = te.equipeId
          LEFT JOIN technicien tm ON te.technicienId = tm.id
          WHERE a2.id = a.id
        ) AS techniciensNoms

      FROM affaire a
      LEFT JOIN client c ON a.client_id = c.id
      LEFT JOIN particulier p ON p.client_id = c.id
      LEFT JOIN agence ag ON ag.client_id = c.id
      LEFT JOIN organisation o ON o.client_id = c.id
      LEFT JOIN equipe_technicien e ON a.equipeTechnicienId = e.id

      ${whereClause}
      GROUP BY a.id, p.nom_complet, ag.nom_agence, o.nom_entreprise, e.id, e.nom
      ORDER BY a.id DESC
      LIMIT ? OFFSET ?
    `;

    params.push(limit, offset);
    const [rows] = await pool.query(sql, params);
    
    const [[{ total }]] = await pool.query(`SELECT FOUND_ROWS() AS total`);

    const data = rows.map(affaire => ({
      ...affaire,
      listeTechniciens: affaire.techniciensNoms ? [...new Set(affaire.techniciensNoms.split(', '))] : []
    }));

    return { total, page, limit, data };
  } catch (err) {
    console.error('Erreur apiGetAllPaginated:', err);
    throw err;
  }
}*/

   static async apiGetAllPaginated({ page = 1, limit = 10, search = '', userId }) {
  try {
    if (!userId) throw new Error('userId manquant');

    page = Number(page);
    limit = Number(limit);
    const offset = (page - 1) * limit;

    let whereClause = `WHERE a.createur_id = ?`;
    const params = [userId];

    if (search && search.trim() !== '') {
      whereClause += ` AND (a.reference LIKE ? OR a.titre LIKE ? OR p.nom_complet LIKE ? OR ag.nom_agence LIKE ? OR o.nom_entreprise LIKE ?)`;
      const like = `%${search}%`;
      params.push(like, like, like, like, like);
    }

    const sql = `
  SELECT SQL_CALC_FOUND_ROWS 
    a.id AS affaireId,
    a.reference,
    a.titre,
    a.dateDebut,
    a.dateFin,
    COALESCE(p.nom_complet, ag.nom_agence, o.nom_entreprise, 'Client inconnu') AS nomClient,
    e.id AS equipeId,
    e.nom AS equipeNom,
    
    -- Sous-requête techniciens (déjà agrégée, donc OK)
    (
      SELECT GROUP_CONCAT(DISTINCT 
        CASE 
          WHEN t_direct.id IS NOT NULL THEN CONCAT(t_direct.prenom, ' ', t_direct.nom)
          ELSE CONCAT(tm.prenom, ' ', tm.nom)
        END 
        SEPARATOR ', '
      )
      FROM affaire a2
      LEFT JOIN technicien t_direct ON a2.technicienId = t_direct.id
      LEFT JOIN technicien_equipe te ON a2.equipeTechnicienId = te.equipeId
      LEFT JOIN technicien tm ON te.technicienId = tm.id
      WHERE a2.id = a.id
    ) AS techniciensNoms,

    -- Sous-requête fichiers (déjà agrégée, donc OK)
    IFNULL(
      (SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
          'id', f.id,
          'nom', f.nom,
          'chemin', f.chemin,
          'type', f.type
        )
      ) FROM fichier f WHERE f.idAffaire = a.id), 
      JSON_ARRAY()
    ) AS fichiersJoints

  FROM affaire a
  LEFT JOIN client c ON a.client_id = c.id
  LEFT JOIN particulier p ON p.client_id = c.id
  LEFT JOIN agence ag ON ag.client_id = c.id
  LEFT JOIN organisation o ON o.client_id = c.id
  LEFT JOIN equipe_technicien e ON a.equipeTechnicienId = e.id

  ${whereClause}
  
  /* Correction ici : On groupe par toutes les colonnes sélectionnées */
  GROUP BY 
    a.id, 
    a.reference, 
    a.titre, 
    a.dateDebut, 
    a.dateFin, 
    p.nom_complet, 
    ag.nom_agence, 
    o.nom_entreprise, 
    e.id, 
    e.nom
    
  ORDER BY a.id DESC
  LIMIT ? OFFSET ?
`;

    params.push(limit, offset);
    const [rows] = await pool.query(sql, params);
    
    // Récupération du total pour la pagination
    const [[{ total }]] = await pool.query(`SELECT FOUND_ROWS() AS total`);

    const data = rows.map(affaire => ({
      ...affaire,
      // On transforme la chaîne GROUP_CONCAT en tableau propre
      listeTechniciens: affaire.techniciensNoms ? [...new Set(affaire.techniciensNoms.split(', '))] : [],
      // S'assurer que fichiersJoints est bien parsé s'il arrive en string (selon driver DB)
      fichiersJoints: typeof affaire.fichiersJoints === 'string' ? JSON.parse(affaire.fichiersJoints) : affaire.fichiersJoints
    }));

    return { total, page, limit, data };
  } catch (err) {
    console.error('Erreur apiGetAllPaginated:', err);
    throw err;
  }
}



  /**
   * 🔹 Modifier une affaire
   */
  // Exemple de service basique pour mettre à jour une affaire
  static async updateAffaire(record) {
    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      // 🔹 Helper : '' ou undefined → NULL (important pour MySQL DATE)
      const cleanDate = (value) =>
        value && value !== '' ? value : null;

      // 🔹 1. Mise à jour de l'affaire
      const query = `
      UPDATE affaire 
      SET 
        reference = ?, 
        titre = ?, 
        description = ?, 
        etatLogement = ?, 
        technicienId = ?, 
        equipeTechnicienId = ?, 
        dateDebut = ?, 
        dateFin = ?, 
        motsCles = ?, 
        dureePrevueHeures = ?, 
        dureePrevueMinutes = ?, 
        memo = ?, 
        memoPiecesJointes = ?, 
        client_id = ?, 
        zone_intervention_client_id = ?,
        type_client_zone_intervention = ?
      WHERE id = ?
    `;

      const values = [
        record.reference ?? null,                        // 1
        record.titre ?? null,                            // 2
        record.description ?? null,                      // 3
        record.etatLogement ?? null,                     // 4
        record.technicienId ?? null,                     // 5
        record.equipeTechnicienId ?? null,               // 6
        cleanDate(record.dateDebut),                     // 7
        cleanDate(record.dateFin),                       // 8
        record.motsCles ?? [],                           // 9
        record.dureePrevueHeures ?? null,                // 10
        record.dureePrevueMinutes ?? null,               // 11
        record.memo ?? null,                             // 12
        record.memoPiecesJointes ?? null,  // 13
        record.client_id ?? null,                        // 14
        record.zone_intervention_client_id ?? null,      // 15
        record.type_client_zone_intervention ?? null,    // 16
        record.id                                        // 17
      ];

      console.log("✅ UPDATE affaire VALUES COUNT =", values.length);

      await connection.execute(query, values);

      // 🔹 2. Mise à jour des référents
      if (Array.isArray(record.referents)) {

        // Supprimer anciens référents
        await connection.execute(
          `DELETE FROM affaire_referent WHERE idAffaire = ?`,
          [record.id]
        );

        // Insérer nouveaux référents
        if (record.referents.length > 0) {
          const valuesRef = record.referents.map(refId => [
            record.id,
            Number(refId)
          ]);

          await connection.query(
            `INSERT INTO affaire_referent (idAffaire, idReferent) VALUES ?`,
            [valuesRef]
          );
        }
      }

      await connection.commit();
      return { success: true, message: "Affaire mise à jour avec succès" };

    } catch (error) {
      await connection.rollback();
      console.error('❌ Erreur updateAffaire:', error);
      throw error;

    } finally {
      connection.release();
    }
  }



  /**
   * 🔹 Supprimer une affaire
   */
  static async apiDeleteById(id) {
    const [result] = await pool.query('DELETE FROM affaire WHERE id = ?', [id]);
    return result.affectedRows > 0;
  }

  /** 🔹 Récupérer une affaire par son ID */
  static async apiGetById(id) {
    try {
      const [rows] = await pool.query(
        `SELECT 
        a.id, a.reference, a.titre, a.description, a.client_id, a.zone_intervention_client_id, a.type_client_zone_intervention,
        a.etatLogement, a.technicienId, a.equipeTechnicienId, a.dateDebut, a.dateFin,
        a.dureePrevueHeures, a.dureePrevueMinutes, a.motsCles, a.memo, a.memoPiecesJointes
      FROM affaire a
      WHERE a.id = ?`,
        [id]
      );

      if (!rows || rows.length === 0) {
        return { success: false, message: 'Affaire non trouvée' };
      }

      const affaire = rows[0];

      // 🔹 Charger uniquement les IDs des référents
      const [referents] = await pool.query(
        `SELECT r.id
       FROM referent r
       JOIN affaire_referent ar ON r.id = ar.idReferent
       WHERE ar.idAffaire = ?`,
        [id]
      );
      // Tableau vide si aucun référent
      affaire.referents = referents ? referents.map(r => r.id) : [];

      // 🔹 Charger les fichiers associés (optionnel)
      const [files] = await pool.query(
        `SELECT id, nom, chemin FROM fichier WHERE idAffaire = ?`,
        [id]
      );
      affaire.fichiers = files || [];

      return { success: true, data: affaire };

    } catch (error) {
      console.error('Erreur apiGetById:', error);
      return { success: false, message: 'Erreur serveur' };
    }
  }


}

module.exports = AffaireService;
